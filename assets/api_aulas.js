/*
 * Cliente das atividades interativas (TBL, quiz, entregas).
 *
 * As páginas falam com o PostgREST do projeto aulas_mackenzie na VPS
 * (Coolify), que substituiu o Supabase cloud em novembro de 2026.
 * A API só expõe RPCs; as tabelas ficam fechadas para o papel anon.
 *
 * O cliente imita a parte do supabase-js que as páginas usavam:
 *   const db = window.aulasApi.cliente();
 *   const { data, error } = await db.rpc('hubtbl_estado', { p_slug, ... });
 * Não há Realtime: db.channel(...) existe só para não quebrar as páginas,
 * que consultam o estado a cada segundo.
 */
(function () {
  const URL_API = 'https://aulas-mackenzie-api.afonsolelis.tech';

  async function rpc(fn, args) {
    try {
      const r = await fetch(URL_API + '/rpc/' + fn, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(args || {}),
      });
      const texto = await r.text();
      const corpo = texto ? JSON.parse(texto) : null;
      if (!r.ok) {
        const msg = (corpo && corpo.message) || ('Falha na chamada ' + fn + ' (' + r.status + ')');
        return { data: null, error: { message: msg, code: corpo && corpo.code, status: r.status } };
      }
      return { data: corpo, error: null };
    } catch (e) {
      return { data: null, error: { message: e.message || 'Sem conexão com o servidor.' } };
    }
  }

  function canalVazio() {
    const canal = {
      on() { return canal; },
      subscribe() { return canal; },
      unsubscribe() { return Promise.resolve('ok'); },
    };
    return canal;
  }

  window.AULAS_API_URL = URL_API;
  window.aulasApi = {
    url: URL_API,
    cliente() {
      return { rpc, channel: canalVazio, removeChannel() { return Promise.resolve('ok'); } };
    },
  };
})();
