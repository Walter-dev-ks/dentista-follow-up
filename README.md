# Sorriso — acompanhamento de leads

Painel web simples para clínicas odontológicas organizarem leads, retornos e agendamentos. A primeira versão não envia mensagens automaticamente e não usa IA ou integração com WhatsApp.

## Demonstração rápida

1. Publique este repositório como site estático na Vercel, ou sirva a pasta localmente por HTTP.
2. Abra o site e escolha **Explorar demonstração com dados fictícios**.
3. Cadastre um lead, defina um retorno, conclua o contato e marque o agendamento.

Os dados da demonstração ficam no navegador e não são compartilhados com a clínica.

## Conectar ao Supabase

O arquivo `supabase-config.js` já aponta para o projeto Supabase configurado e contém somente a chave pública `publishable`. Nunca coloque uma chave `service_role` ou `secret` no navegador ou neste repositório.

1. No painel Supabase, abra o SQL Editor e execute `supabase-schema.sql`.
2. Em Authentication, habilite acesso por e-mail e defina a URL do site publicado em **URL Configuration**. Inclua a URL exata também em **Redirect URLs**.
3. Publique a pasta como site estático. O `index.html` é a página inicial.
4. Crie uma conta com e-mail e senha no painel. O primeiro acesso cria a clínica e os modelos iniciais.
5. Teste o fluxo usando dados fictícios antes de convidar a clínica.

Para testar localmente no Windows, abra um terminal nesta pasta e execute `py -m http.server 8000`; depois visite `http://localhost:8000`. Durante esse teste, inclua `http://localhost:8000/**` nas URLs de redirecionamento do Supabase.

## Escopo do MVP

- Login e criação de clínica com Supabase Auth.
- Separação de dados por clínica com PostgreSQL e políticas RLS.
- Cadastro e acompanhamento de leads, tarefas, status e modelos de mensagem.
- Dashboard para visualizar pendências e agendamentos.
- Edição de dados básicos da clínica pelo responsável, perfil da conta e senha.
- Criação, edição, cópia e exclusão de modelos de mensagem por clínica.
- Demonstração com registros fictícios, sem necessidade de conta.
- Contato manual: a equipe copia o modelo e envia pelo canal já usado pela clínica.

Antes de usar dados de pacientes reais, revise privacidade, consentimento, acesso dos usuários e retenção com a clínica. Integração oficial com WhatsApp, mensagens automáticas, convites de equipe e recuperação de senha não fazem parte desta versão.
