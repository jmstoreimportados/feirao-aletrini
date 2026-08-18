/* ============================================================
   Feirão Aletrini + Kalil — configuração
   ============================================================ */
window.CONFIG = {
  // Projeto Supabase (já preenchido e testado)
  SUPABASE_URL: "https://zmcvvgtfiftsiarjidrp.supabase.co",

  // Chave pública (anon). Pode ficar visível no site: testado, com ela
  // NÃO se lê a lista, NÃO se apaga e NÃO se insere direto na tabela.
  SUPABASE_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptY3Z2Z3RmaWZ0c2lhcmppZHJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNzIxMDYsImV4cCI6MjEwMjY0ODEwNn0.3kyTj-0nhF54qpeiPeiHrIgchaoSqQfIt07TtThlL64",

  // Textos do evento — mude à vontade
  EVENTO: "Feirão Boulevard Rio",
  TITULO: "Concorra ao brinde",
  BRINDE: "uma Alexa",
  RESULTADO: "",           // ex.: "Domingo, 30/08, às 17h, no estande."
  WHATSAPP_LOJA: "1999214110",

  // Meta de cadastros por dia — aparece como barra de progresso no painel
  META_DIA: 60,

  // Mensagem que abre no WhatsApp ao clicar em "Chamar no WhatsApp".
  // {nome} vira o primeiro nome, {cupom} vira o número do cupom.
  MSG_WHATSAPP: "Oi {nome}! Aqui é da Aletrini Multimarcas. Você pegou o cupom {cupom} no nosso feirão no Boulevard Rio. Posso te mostrar as condições que a gente fechou pra quem participou?"
};
