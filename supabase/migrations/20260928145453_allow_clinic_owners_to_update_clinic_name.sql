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
create policy "Owners can update their clinics" on public.clinics
  for update to authenticated
  using (private.is_clinic_owner(id))
  with check (private.is_clinic_owner(id));
grant update on public.clinics to authenticated;
