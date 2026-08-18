/* ============================================================
   Gestão de usuários — roda no servidor da Vercel, nunca no navegador.
   A chave service_role fica nas variáveis de ambiente da Vercel e
   NUNCA é devolvida para o site.

   Toda chamada passa por duas conferências:
     1. o token enviado é de um usuário real do Supabase?
     2. esse usuário está na tabela perfis com papel = 'master'?
   Só depois disso a chave de administrador é usada.
   ============================================================ */

function limpaUrl(v) {
  let u = (v || "").trim().replace(/[\r\n]/g, "");
  if (!u) return "";
  if (!/^https?:\/\//i.test(u)) u = "https://" + u;   // colaram sem o https://
  return u.replace(/\/+$/, "");                        // barra sobrando no fim
}
const URL_SB  = limpaUrl(process.env.SUPABASE_URL);
const SERVICE = (process.env.SUPABASE_SERVICE_ROLE || "").trim().replace(/[\r\n\s]/g, "");

/* lê o "role" de dentro do token, só para diagnóstico — não expõe a chave */
function papelDaChave(jwt) {
  try {
    const meio = jwt.split(".")[1];
    const json = JSON.parse(Buffer.from(meio, "base64").toString("utf8"));
    return json.role || "?";
  } catch (e) { return "?"; }
}

async function sb(caminho, opcoes = {}) {
  const r = await fetch(URL_SB + caminho, {
    ...opcoes,
    headers: {
      apikey: SERVICE,
      Authorization: "Bearer " + SERVICE,
      "Content-Type": "application/json",
      ...(opcoes.headers || {})
    }
  });
  const texto = await r.text();
  let corpo = null;
  try { corpo = texto ? JSON.parse(texto) : null; } catch (e) { corpo = texto; }
  if (!r.ok) {
    const err = new Error((corpo && (corpo.msg || corpo.message || corpo.error_description)) || "erro");
    err.status = r.status;
    throw err;
  }
  return corpo;
}

/* quem está chamando, e é master? */
async function quemChama(req) {
  const auth = req.headers.authorization || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!token) return null;

  let r;
  try {
    r = await fetch(URL_SB + "/auth/v1/user", {
      headers: { apikey: SERVICE, Authorization: "Bearer " + token }
    });
  } catch (e) {
    const err = new Error("não alcancei o Supabase em " + URL_SB + " (" + e.message + ")");
    err.status = 502; throw err;
  }
  if (!r.ok) return null;
  const user = await r.json();
  if (!user || !user.id) return null;

  const perfis = await sb("/rest/v1/perfis?select=papel&user_id=eq." + user.id);
  const papel = perfis && perfis[0] ? perfis[0].papel : "nenhum";
  return { id: user.id, email: user.email, papel };
}

module.exports = async function handler(req, res) {
  /* GET = diagnóstico da configuração. Não devolve a chave, só o formato dela. */
  if (req.method === "GET") {
    let alcanca = null;
    if (URL_SB) {
      try {
        const t = await fetch(URL_SB + "/auth/v1/settings", { headers: { apikey: SERVICE } });
        alcanca = t.status;
      } catch (e) { alcanca = "falhou: " + e.message; }
    }
    return res.status(200).json({
      SUPABASE_URL: URL_SB || "FALTANDO",
      SUPABASE_SERVICE_ROLE: SERVICE
        ? SERVICE.length + " caracteres, role=" + papelDaChave(SERVICE)
        : "FALTANDO",
      alcanca_supabase: alcanca,
      esperado: "role=service_role e alcanca_supabase=200"
    });
  }

  if (req.method !== "POST") return res.status(405).json({ erro: "método não permitido" });
  if (!URL_SB || !SERVICE) {
    return res.status(500).json({ erro: "Faltam as variáveis SUPABASE_URL e SUPABASE_SERVICE_ROLE na Vercel." });
  }

  let chamador;
  try { chamador = await quemChama(req); }
  catch (e) {
    return res.status(e.status || 500).json({
      erro: "não consegui validar a sessão: " + (e.message || e),
      dica: "Abra /api/usuarios no navegador para ver o diagnóstico da configuração."
    });
  }

  if (!chamador) return res.status(401).json({ erro: "sessão inválida" });
  if (chamador.papel !== "master") return res.status(403).json({ erro: "só o master gerencia usuários" });

  const corpo = typeof req.body === "string" ? JSON.parse(req.body || "{}") : (req.body || {});
  const { acao, email, senha, nome, papel, user_id } = corpo;

  try {
    /* -------- listar -------- */
    if (acao === "listar") {
      const perfis = await sb("/rest/v1/perfis?select=user_id,nome,papel");
      const lista = await sb("/auth/v1/admin/users?per_page=200");
      const usuarios = (lista.users || lista || []).map(u => {
        const p = perfis.find(x => x.user_id === u.id);
        return {
          id: u.id, email: u.email, criado: u.created_at,
          ultimo_acesso: u.last_sign_in_at,
          nome: p ? p.nome : null,
          papel: p ? p.papel : "sem acesso"
        };
      });
      return res.status(200).json({ usuarios });
    }

    /* -------- criar -------- */
    if (acao === "criar") {
      if (!email || !senha || senha.length < 6)
        return res.status(400).json({ erro: "informe e-mail e uma senha de pelo menos 6 caracteres" });
      const novo = await sb("/auth/v1/admin/users", {
        method: "POST",
        body: JSON.stringify({ email, password: senha, email_confirm: true })
      });
      await sb("/rest/v1/perfis", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates" },
        body: JSON.stringify({
          user_id: novo.id,
          nome: nome || email.split("@")[0],
          papel: papel === "master" ? "master" : "consulta"
        })
      });
      return res.status(200).json({ ok: true, id: novo.id });
    }

    /* -------- trocar senha -------- */
    if (acao === "senha") {
      if (!user_id || !senha || senha.length < 6)
        return res.status(400).json({ erro: "senha precisa de pelo menos 6 caracteres" });
      await sb("/auth/v1/admin/users/" + user_id, {
        method: "PUT",
        body: JSON.stringify({ password: senha })
      });
      return res.status(200).json({ ok: true });
    }

    /* -------- mudar papel / nome -------- */
    if (acao === "papel") {
      if (!user_id) return res.status(400).json({ erro: "usuário não informado" });
      if (user_id === chamador.id && papel !== "master")
        return res.status(400).json({ erro: "você não pode rebaixar o seu próprio acesso" });
      await sb("/rest/v1/perfis", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates" },
        body: JSON.stringify({
          user_id,
          nome: nome || "equipe",
          papel: papel === "master" ? "master" : "consulta"
        })
      });
      return res.status(200).json({ ok: true });
    }

    /* -------- remover -------- */
    if (acao === "remover") {
      if (!user_id) return res.status(400).json({ erro: "usuário não informado" });
      if (user_id === chamador.id)
        return res.status(400).json({ erro: "você não pode remover o seu próprio acesso" });
      const masters = await sb("/rest/v1/perfis?select=user_id&papel=eq.master");
      if (masters.length <= 1 && masters.some(m => m.user_id === user_id))
        return res.status(400).json({ erro: "precisa sobrar pelo menos um master" });
      await sb("/auth/v1/admin/users/" + user_id, { method: "DELETE" });
      return res.status(200).json({ ok: true });
    }

    return res.status(400).json({ erro: "ação desconhecida" });
  } catch (e) {
    return res.status(e.status || 500).json({ erro: e.message || "erro inesperado" });
  }
};
