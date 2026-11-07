/**
 * Ensaio de carga do TBL que abre a Aula 05 de Data Collection and Storage:
 * 20 alunos e o professor na sala real, nas páginas publicadas, falando com o
 * PostgREST da VPS (https://aulas-mackenzie-api.afonsolelis.tech).
 *
 *   node scripts/tbl_carga_dc_aula05.mjs [url-base] [n-alunos]
 *
 * url-base padrão: o GitHub Pages da pasta tbl/ da Aula 05. O token do
 * professor vem do .env local (DCS_HOST_TOKEN) e nunca é impresso.
 *
 * Mede quanto tempo cada entrada leva para aparecer no painel e quanto tempo
 * cada virada de fase leva para chegar a todos os alunos. Todos votam nas duas
 * rodadas das três questões. No fim, DESCARTA a sala (lobby, sem participantes).
 *
 * Não rode durante a aula: descartar desconecta quem estiver na sala.
 */
import fs from 'node:fs';
import { chromium } from '@playwright/test';

const SALA = 'mack-dcs-a04-2026-2';
const BASE = (process.argv[2] || 'https://afonsolelis.github.io/aulas_mackenzie/aulas/data_collection_and_storage/aula_05_modelagem_dimensional_views_e_observabilidade_no_clickhouse/tbl/').replace(/\/?$/, '/');
const N = Number(process.argv[3] || 20);
const API = 'https://aulas-mackenzie-api.afonsolelis.tech';

const env = fs.readFileSync(process.env.QUIZ_ENV_FILE || '.env', 'utf8');
const tk = env.match(/^\s*DCS_HOST_TOKEN\s*=\s*(.+)\s*$/m);
if (!tk) { console.error('DCS_HOST_TOKEN ausente no arquivo de ambiente.'); process.exit(2); }
const TOKEN = tk[1].trim().replace(/^(['"])(.*)\1$/, '$2');

const rpc = async (fn, body) => (await fetch(`${API}/rpc/${fn}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
})).json();

const erros = [];
const ok = (m) => console.log('  ok   ' + m);
const falha = (m) => { console.log(' FALHA ' + m); erros.push(m); };
const confere = (c, m) => (c ? ok(m) : falha(m));
const ms = (v) => `${Math.round(v)} ms`;
const resumo = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  const q = (p) => s[Math.min(s.length - 1, Math.floor(p * s.length))];
  return `mediana ${ms(q(0.5))} · p90 ${ms(q(0.9))} · pior ${ms(s[s.length - 1])}`;
};

const inicial = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
if (!inicial.ok) { console.error('não foi possível falar com a sala:', inicial.erro || inicial); process.exit(1); }
ok(`sala ${SALA} zerada para o ensaio (${inicial.total_questoes} questões)`);
console.log(`       páginas em ${BASE}`);

const chamadas = { total: 0, falhas: 0, supabase: 0, duracoes: [] };
const consoleErros = [];
const vigiar = (p, quem) => {
  p.on('request', (r) => { if (r.url().includes('supabase')) chamadas.supabase++; });
  p.on('requestfinished', async (r) => {
    if (!r.url().startsWith(API)) return;
    chamadas.total++;
    const t = r.timing();
    if (t.responseEnd > 0) chamadas.duracoes.push(t.responseEnd - t.requestStart);
    const resp = await r.response();
    if (resp && resp.status() >= 400) chamadas.falhas++;
  });
  p.on('requestfailed', (r) => { if (r.url().startsWith(API)) { chamadas.total++; chamadas.falhas++; } });
  p.on('console', (m) => { if (m.type() === 'error') consoleErros.push(`${quem}: ${m.text().slice(0, 160)}`); });
};

const browser = await chromium.launch();
try {
  const painel = await (await browser.newContext({ viewport: { width: 1440, height: 900 } })).newPage();
  vigiar(painel, 'painel');
  painel.on('dialog', (d) => d.accept());
  await painel.goto(BASE + 'painel_aula_05.html');
  await painel.fill('#token', TOKEN);
  await painel.click('#form-token button');
  await painel.waitForFunction(() => !document.querySelector('#painel').hidden, null, { timeout: 15000 });
  ok('professor autenticado no painel');

  // Entradas: cada aluno entra e mede-se quando o painel passa a contá-lo.
  const alunos = [];
  const entradas = [];
  for (let i = 1; i <= N; i++) {
    const nome = `Ensaio ${String(i).padStart(2, '0')}`;
    const p = await (await browser.newContext({ viewport: { width: 390, height: 844 } })).newPage();
    vigiar(p, nome);
    await p.goto(BASE + 'tbl_aula_05.html');
    await p.fill('#nome', nome);
    const t0 = Date.now();
    await p.click('#form-entrada button');
    await p.waitForFunction(() => !document.querySelector('#tela-sala').hidden, null, { timeout: 15000 });
    await painel.waitForFunction((n) => Number(document.querySelector('#conectados').textContent) >= n, i, { timeout: 15000 });
    entradas.push(Date.now() - t0);
    alunos.push(p);
  }
  confere(Number(await painel.textContent('#conectados')) === N, `painel conta ${N} alunos na sala`);
  console.log(`       entrada do aluno até aparecer no painel: ${resumo(entradas)}`);

  const viradas = [];
  const avancar = async (textoFase) => {
    const t0 = Date.now();
    await painel.click('[data-acao="avancar"]');
    const tempos = await Promise.all(alunos.map((p) => p
      .waitForFunction((t) => document.querySelector('#selo-fase').textContent.startsWith(t), textoFase, { timeout: 20000 })
      .then(() => Date.now() - t0).catch(() => null)));
    const chegaram = tempos.filter((t) => t !== null);
    confere(chegaram.length === N, `"${textoFase}" chegou a ${chegaram.length}/${N} alunos (todos em ${ms(Math.max(...chegaram))})`);
    viradas.push(...chegaram);
  };
  const votarTodos = async (rodada, q) => {
    await Promise.all(alunos.map(async (p, i) => {
      const escolha = (i + q + rodada) % 4;
      await p.locator(`button.opcao[data-escolha="${escolha}"]`).click();
      await p.fill('#justificativa', `ensaio de carga: questão ${q}, rodada ${rodada}, aluno ${i + 1}`);
      await p.click('#registrar');
      await p.waitForFunction(() => document.querySelector('#recado').textContent.startsWith('Decisão registrada'), null, { timeout: 15000 });
    }));
    try {
      await painel.waitForFunction((n) => document.querySelector('#decidiram').textContent === String(n), N, { timeout: 15000 });
      ok(`questão ${q}, rodada ${rodada}: painel conta ${N} decisões`);
    } catch { falha(`questão ${q}, rodada ${rodada}: painel mostra ${await painel.textContent('#decidiram')} decisões`); }
  };

  for (let q = 1; q <= 3; q++) {
    await avancar(`Primeira decisão · questão ${q}`);
    await votarTodos(1, q);
    await avancar('Discussão');
    await avancar('Segunda decisão');
    await votarTodos(2, q);
    await avancar('Síntese');
    try {
      await painel.waitForFunction(() => /1ª/.test(document.querySelector('#projecao').textContent) && /2ª/.test(document.querySelector('#projecao').textContent), null, { timeout: 15000 });
      ok(`síntese da questão ${q} projeta os dois placares`);
    } catch { falha(`síntese da questão ${q} sem os dois placares`); }
  }
  await avancar('Fechamento');

  console.log(`       virada de fase até chegar ao aluno: ${resumo(viradas)}`);
  console.log(`       chamadas à API: ${chamadas.total}, com falha ${chamadas.falhas}; tempo de resposta ${resumo(chamadas.duracoes)}`);
  confere(chamadas.falhas === 0, 'nenhuma chamada à API falhou');
  confere(chamadas.supabase === 0, 'nenhuma página falou com o Supabase');
  confere(consoleErros.length === 0, `sem erros no console${consoleErros.length ? ': ' + consoleErros.slice(0, 3).join(' | ') : ''}`);
} finally {
  await browser.close();
  const fim = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
  console.log(fim.ok && fim.fase === 'lobby' && fim.inscritos === 0
    ? '  ok   sala descartada e de volta ao lobby, sem participantes'
    : ' FALHA não foi possível descartar a sala: ' + JSON.stringify(fim).slice(0, 200));
}

console.log(erros.length ? `\n${erros.length} falha(s).` : `\nEnsaio com ${N} alunos e o professor aprovado.`);
process.exit(erros.length ? 1 : 0);
