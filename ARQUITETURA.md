# MVP Sorriso — arquitetura e execução

## Estado atual

O painel atual é uma página estática em `index.html`, com JavaScript e CSS embutidos. Oferece dois modos: demonstração com registros fictícios guardados no navegador e modo conectado ao projeto Supabase `Dentista-follow-up`. No modo conectado, login e cadastro por e-mail, clínica, leads, follow-ups, histórico e leitura de modelos usam o banco remoto. `supabase-config.js` contém a URL e a chave pública do projeto; nunca colocar uma chave `service_role` no frontend.

Para abrir localmente, iniciar um servidor estático na raiz do repositório (por exemplo, `py -m http.server 8000`) e acessar `http://localhost:8000`. O cadastro exige uma URL de redirecionamento autorizada no Supabase Auth. Em **Authentication → URL Configuration**, definir o Site URL como `http://localhost:8000` durante o desenvolvimento e incluir `http://localhost:8000/**` em Redirect URLs. Ao publicar, adicionar o endereço da hospedagem a essas configurações.

No primeiro cadastro, criar uma conta com e-mail, senha e nome da clínica. Se a confirmação de e-mail estiver ativa, confirmar a mensagem recebida e entrar com a mesma conta; o painel conclui o cadastro da clínica. Cada primeira clínica recebe dois modelos de mensagem iniciais. A opção “Explorar demonstração” continua disponível na tela de login.

## Arquitetura atual e evolução mínima

- **Painel web:** página estática responsiva em HTML, CSS e JavaScript, hospedável na Vercel sem build ou servidor próprio. Evoluir para React/Next.js apenas quando a complexidade justificar.
- **Autenticação e dados:** Supabase Auth e PostgreSQL. O MVP começa com e-mail e senha, sem login social.
- **Clínicas e usuários:** `clinics` representa a clínica; `clinic_members` liga o usuário autenticado à clínica e define `owner` ou `staff`. Todas as tabelas operacionais carregam `clinic_id`.
- **Leads e pipeline:** `leads` contém paciente, telefone, origem, interesse, observações e status (`new`, `follow_up`, `contacted`, `booked`, `lost`). O histórico de mudanças fica em `lead_events`.
- **Follow-ups:** `tasks` guarda lead, responsável, vencimento, conclusão e tipo. Marcar contato como feito atualiza a tarefa e permite definir a próxima. Agendamento e perda encerram os lembretes abertos daquele lead.
- **Templates:** `message_templates` armazena texto editável por clínica. Nesta versão a equipe copia, personaliza e envia manualmente; nenhuma mensagem é enviada pelo sistema.
- **Dashboard:** consultas agregadas de leads abertos, tarefas vencidas/para hoje, contatos feitos e consultas agendadas.
- **WhatsApp futuro:** uma camada de integração isolada, com `provider`, identificadores externos, consentimento e logs de entrega. A versão inicial não pede tokens nem chama APIs. Quando houver integração, usar apenas a API oficial da Meta ou provedor oficial, com credenciais no servidor e webhooks validados.

## Sequência curta

1. **Validar o acesso:** ajustar URLs de redirecionamento do Auth, criar a conta do responsável e confirmar a clínica no primeiro login.
2. **Testar o fluxo:** criar lead fictício, marcar retorno, registrar contato e agendar; confirmar que outro navegador autorizado vê os mesmos registros.
3. **Publicar:** hospedar a raiz do repositório como site estático na Vercel, mantendo o arquivo de configuração pública e ajustando URLs do Auth.
4. **Piloto:** validar com a clínica antes de inserir dados reais. Adiar automações, IA, relatórios avançados e cobrança.

## Custo e limites

O modo demo não envia dados ao Supabase. O modo conectado autentica os usuários e aplica RLS para separar clínicas. Vercel e Supabase têm opções gratuitas para validar um piloto pequeno, sujeitas aos limites vigentes. Antes de operar com pacientes reais, revisar consentimento, acesso da equipe, retenção e requisitos de privacidade aplicáveis à clínica. A versão atual não inclui convite de funcionários, redefinição de senha pelo painel, envio automático de mensagens ou confirmação de consulta externa.
