# Portal Horizonte (JE Strategy OS v4)

Plataforma integrada de planejamento estratégico para Empresa Júnior construída com **SvelteKit 2**, **Svelte 5 (Runes)**, **Tailwind CSS**, **Supabase** e pronta para deploy na **Vercel**.

---

## 🚀 Quick Start (Desenvolvimento Local)

### Modo Local (Zero configuração externa)
Se as variáveis do Supabase não estiverem configuradas no `.env`, o sistema roda automaticamente no **Modo Local Store** (`.data/local-db.json`):

```bash
npm install
npm run dev
```

---

## 🗄️ Configuração do Supabase

### 1. Criar Tabelas e Carregar Dados (Seed)
1. Acesse o [Painel do seu Projeto Supabase](https://supabase.com/dashboard).
2. Abra a aba **SQL Editor** no menu lateral esquerdo.
3. Copie todo o conteúdo do arquivo [`supabase/full_setup.sql`](./supabase/full_setup.sql) e cole no editor.
4. Clique em **Run**. Isso criará todas as tabelas, tipos ENUM, triggers de integridade, políticas RLS e já carregará a Missão, Valores, Objetivos 2026, KRs e Equipes.

### 2. Primeiro Administrador
O trigger já está configurado para conceder automaticamente permissão de **Administrador (`admin`)** para:
- `vitor.kunz@nuvemjr.com.br`

Assim que esse e-mail se cadastrar pelo Auth do Supabase (ou for convidado), seu perfil receberá permissão de admin completa.

---

## ☁️ Deploy na Vercel

1. Crie um repositório no GitHub chamado `Portal-Horizonte` e faça o push deste código:
   ```bash
   git remote add origin https://github.com/<SEU_USUARIO>/Portal-Horizonte.git
   git branch -M main
   git push -u origin main
   ```
2. Acesse [vercel.com](https://vercel.com) e clique em **Add New... > Project**.
3. Importe o repositório `Portal-Horizonte`.
4. Configure as **Environment Variables** no projeto da Vercel:
   - `PUBLIC_SUPABASE_URL`: `https://ptpcafftqlwxcdexofos.supabase.co`
   - `PUBLIC_SUPABASE_ANON_KEY`: `sb_publishable_7dvgutK2lSMz7tzbAc0-jg_T9TQimpb`
   - `SUPABASE_SERVICE_ROLE_KEY`: `(sua service role key encontrada em Project Settings > API)`
5. Clique em **Deploy**.
6. No painel do Supabase em **Authentication > URL Configuration**:
   - Adicione a URL da Vercel (ex: `https://portal-horizonte.vercel.app`) em **Site URL**.
   - Adicione `https://portal-horizonte.vercel.app/**` em **Redirect URLs**.

---

## 🛠️ Scripts Disponíveis

- `npm run dev` — Inicia o servidor local de desenvolvimento
- `npm test` — Executa testes unitários com Vitest
- `npm run check` — Executa verificação de tipagem com `svelte-check`
- `npm run build` — Gera a compilação de produção para Vercel
