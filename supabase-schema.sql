create extension if not exists pgcrypto;

create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  whatsapp_phone text,
  created_at timestamptz not null default now()
);

create table public.clinic_members (
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'staff' check (role in ('owner', 'staff')),
  created_at timestamptz not null default now(),
  primary key (clinic_id, user_id)
);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  phone text,
  interest text not null default 'Avaliação',
  source text,
  status text not null default 'new' check (status in ('new', 'follow_up', 'contacted', 'booked', 'lost')),
  notes text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (clinic_id, id)
);

create index leads_clinic_status_idx on public.leads (clinic_id, status, created_at desc);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  assigned_to uuid references auth.users(id) on delete set null,
  kind text not null default 'follow_up',
  due_at timestamptz not null,
  completed_at timestamptz,
  note text not null default '',
  created_at timestamptz not null default now(),
  constraint tasks_lead_clinic_fk foreign key (clinic_id, lead_id)
    references public.leads(clinic_id, id) on delete cascade
);

create index tasks_clinic_due_idx on public.tasks (clinic_id, due_at) where completed_at is null;

create table public.lead_events (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint events_lead_clinic_fk foreign key (clinic_id, lead_id)
    references public.leads(clinic_id, id) on delete cascade
);

create table public.message_templates (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create or replace function private.is_clinic_member(target_clinic_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.clinic_members m
    where m.clinic_id = target_clinic_id and m.user_id = (select auth.uid())
  );
$$;
revoke all on function private.is_clinic_member(uuid) from public, anon;
grant execute on function private.is_clinic_member(uuid) to authenticated;

create or replace function private.is_clinic_owner(target_clinic_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.clinic_members m
    where m.clinic_id = target_clinic_id
      and m.user_id = (select auth.uid())
      and m.role = 'owner'
  );
$$;
revoke all on function private.is_clinic_owner(uuid) from public, anon;
grant execute on function private.is_clinic_owner(uuid) to authenticated;

create or replace function private.create_clinic_for_current_user(clinic_name text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_clinic_id uuid;
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;
  if nullif(trim(clinic_name), '') is null then
    raise exception 'Clinic name is required';
  end if;

  insert into public.clinics (name)
  values (trim(clinic_name))
  returning id into new_clinic_id;

  insert into public.clinic_members (clinic_id, user_id, role)
  values (new_clinic_id, current_user_id, 'owner');

  insert into public.message_templates (clinic_id, title, body)
  values
    (new_clinic_id, 'Primeiro contato', 'Olá, {{nome}}! 😊 Sou da clínica. Vi seu interesse em {{interesse}}. Posso ajudar a encontrar o melhor horário para sua avaliação?'),
    (new_clinic_id, 'Retomar conversa', 'Oi, {{nome}}! Passando para saber se ficou alguma dúvida sobre {{interesse}}. Estamos por aqui quando quiser conversar.');

  return new_clinic_id;
end;
$$;
revoke all on function private.create_clinic_for_current_user(text) from public, anon, authenticated;
grant execute on function private.create_clinic_for_current_user(text) to authenticated;

create or replace function public.create_clinic_for_current_user(clinic_name text)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.create_clinic_for_current_user(clinic_name);
$$;

revoke all on function public.create_clinic_for_current_user(text) from public, anon;
grant execute on function public.create_clinic_for_current_user(text) to authenticated;

alter table public.clinics enable row level security;
alter table public.clinic_members enable row level security;
alter table public.leads enable row level security;
alter table public.tasks enable row level security;
alter table public.lead_events enable row level security;
alter table public.message_templates enable row level security;

create policy "Members can view their clinics" on public.clinics
  for select to authenticated using (private.is_clinic_member(id));
create policy "Owners can update their clinics" on public.clinics
  for update to authenticated using (private.is_clinic_owner(id))
  with check (private.is_clinic_owner(id));
create policy "Members can view clinic membership" on public.clinic_members
  for select to authenticated using (private.is_clinic_member(clinic_id));
create policy "Members can read leads" on public.leads
  for select to authenticated using (private.is_clinic_member(clinic_id));
create policy "Members can add leads" on public.leads
  for insert to authenticated with check (private.is_clinic_member(clinic_id));
create policy "Members can update leads" on public.leads
  for update to authenticated using (private.is_clinic_member(clinic_id))
  with check (private.is_clinic_member(clinic_id));
create policy "Members can delete leads" on public.leads
  for delete to authenticated using (private.is_clinic_member(clinic_id));
create policy "Members can read tasks" on public.tasks
  for select to authenticated using (private.is_clinic_member(clinic_id));
create policy "Members can manage tasks" on public.tasks
  for all to authenticated using (private.is_clinic_member(clinic_id))
  with check (private.is_clinic_member(clinic_id));
create policy "Members can read lead events" on public.lead_events
  for select to authenticated using (private.is_clinic_member(clinic_id));
create policy "Members can add lead events" on public.lead_events
  for insert to authenticated with check (private.is_clinic_member(clinic_id));
create policy "Members can read templates" on public.message_templates
  for select to authenticated using (private.is_clinic_member(clinic_id));
create policy "Members can manage templates" on public.message_templates
  for all to authenticated using (private.is_clinic_member(clinic_id))
  with check (private.is_clinic_member(clinic_id));

grant select on public.clinics, public.clinic_members to authenticated;
grant update on public.clinics to authenticated;
grant select, insert, update, delete on public.leads, public.tasks, public.message_templates to authenticated;
grant select, insert on public.lead_events to authenticated;
