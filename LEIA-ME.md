# Feirão Aletrini + Kalil — como colocar no ar

Siga na ordem. Some uns 30 minutos no total.
Cada etapa termina com algo que dá para conferir na tela.

---

## Etapa 1 — Supabase (o banco de dados)

1. Entre em **supabase.com** → *Start your project* → crie a conta (Google ou GitHub). Não pede cartão.
2. **New project**:
   - Name: `feirao-aletrini`
   - Database Password: gere uma e **guarde** (você não usa no dia a dia, mas não dá para recuperar)
   - Region: **South America (São Paulo)**
   - Plan: Free
3. Espere terminar de criar (uns 2 minutos).
4. Menu lateral → **SQL Editor** → *New query* → abra o arquivo `schema.sql`, copie **tudo**, cole e clique em **Run**.
   - Deve aparecer *Success. No rows returned*. É isso mesmo.
5. Menu lateral → **Project Settings → API**. Anote os dois valores:
   - **Project URL** (ex.: `https://abcdefgh.supabase.co`)
   - **anon public** (uma chave longa começando com `eyJ...` ou `sb_publishable_...`)

> Essa chave pode ficar visível no site. Pelas regras que o `schema.sql` criou, com ela só dá para
> **criar** cadastro — não dá para ler, alterar nem apagar a lista de ninguém.

---

## Etapa 2 — os logins da equipe

1. Supabase → **Authentication → Users → Add user → Create new user**.
2. Crie um usuário para cada pessoa (e-mail + senha). Marque **Auto Confirm User**.
   - `matheussrosa@live.com` — será o master
   - os demais (dono da Aletrini, pessoal da Kalil) conforme a necessidade
3. Volte ao **SQL Editor** e rode isto, trocando os e-mails:

```sql
insert into public.perfis (user_id, nome, papel)
select id, 'Matheus', 'master'   from auth.users where email = 'matheussrosa@live.com';

insert into public.perfis (user_id, nome, papel)
select id, 'Aletrini', 'consulta' from auth.users where email = 'EMAIL_DA_LOJA';
```

- **master** — vê tudo, exclui cadastro, escolhe o ganhador
- **consulta** — só vê a lista e exporta a planilha

Quem não estiver na tabela `perfis` não entra no painel, mesmo tendo login.

---

## Etapa 3 — preencher o `config.js`

Abra o arquivo `config.js` e troque as duas primeiras linhas pelos valores da Etapa 1:

```js
SUPABASE_URL: "https://abcdefgh.supabase.co",
SUPABASE_KEY: "eyJhbGciOi...",
```

Aproveite e ajuste `RESULTADO` com a data e o local da escolha do ganhador.

---

## Etapa 4 — GitHub

1. Crie um repositório novo (pode ser privado): `feirao-aletrini`.
2. Suba **o conteúdo desta pasta** na raiz do repositório:

```
index.html
painel.html
estilo.css
config.js
schema.sql
LEIA-ME.md
img/
```

---

## Etapa 5 — Vercel

1. Entre em **vercel.com** com a conta do GitHub.
2. **Add New → Project** → escolha o repositório `feirao-aletrini` → **Import**.
3. Não mexa em nada nas configurações (é site estático, sem build) → **Deploy**.
4. Em **Settings → Deployment Protection**, confirme que *Vercel Authentication* está **desligado**.
   Se ficar ligado, o cliente vê tela de login em vez do formulário.

Ao final você recebe um endereço `algumacoisa.vercel.app`. **Abra e teste um cadastro de verdade.**

---

## Etapa 6 — o domínio `feiraoaletrini.com.br`

1. Vercel → seu projeto → **Settings → Domains** → digite `feiraoaletrini.com.br` → **Add**.
2. A Vercel mostra os registros de DNS que ela quer. Normalmente:
   - registro **A** do domínio raiz apontando para o IP que ela informar
   - registro **CNAME** do `www` apontando para `cname.vercel-dns.com`
3. Entre no **registro.br**, no seu domínio → **Editar zona DNS** → cadastre exatamente esses registros.
4. Propagação leva de 10 minutos a algumas horas. A Vercel emite o certificado HTTPS sozinha.

Enquanto o domínio não propaga, **o endereço `.vercel.app` já funciona** — pode usar para testar
e até para gerar o QR: ele continua valendo depois.

---

## Etapa 7 — o QR code

Gere o QR apontando para: `https://feiraoaletrini.com.br`

Qualquer gerador gratuito serve. Imprima grande, em fundo claro, com uma chamada acima:

> **GANHE UMA ALEXA**
> Aponte a câmera e faça seu cadastro

Cole na testeira do estande e em um cavalete na altura dos olhos.

---

## Como a equipe usa

- **Cliente:** aponta a câmera → preenche → recebe o número do cupom na tela.
- **Equipe:** `feiraoaletrini.com.br/painel.html` → login → Resumo, Cadastros, Brinde.
- **Tablet da loja:** use `feiraoaletrini.com.br/?estande=1` — os cadastros feitos ali ficam
  marcados como "Estande", para você saber o que veio do QR e o que veio da equipe.

---

## Perguntas que vão aparecer

**"E se a internet do shopping cair?"**
O cadastro pelo QR precisa de internet. Tenha o tablet com a ferramenta antiga
(`cupom-aletrini.html`, que funciona offline) como plano B, e junte as listas depois.

**"Dá para ver de casa?"**
Sim. O painel abre em qualquer navegador, de qualquer lugar, com login.

**"Alguém pode roubar a lista de clientes?"**
Com a chave que está no site, não: ela só cria cadastro. Para ler a lista é preciso
login, e só quem estiver na tabela `perfis` entra.
