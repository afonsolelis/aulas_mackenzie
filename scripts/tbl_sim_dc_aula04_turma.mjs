/**
 * Simulação de turma no TBL da Aula 04 de Data Collection and Storage.
 *
 *   node scripts/tbl_sim_dc_aula04_turma.mjs [n-alunos] [slug-da-sala]
 *
 * Abre o painel do professor e N alunos (padrão 10) em celulares simulados,
 * com as páginas locais (file://) falando com o Supabase de verdade. Os
 * alunos entram em momentos diferentes, votam com escolhas variadas nas
 * duas decisões das três questões, um deles recarrega a página no meio da
 * rodada e outro entra atrasado. A cada fase, o script confere que todos
 * os alunos chegaram nela, quanto tempo levaram e se o painel contou todas
 * as decisões. Não depende do texto das questões: serve antes e depois do
 * seed.
 *
 * O token do professor vem do .env local (DCS_HOST_TOKEN). No começo e no
 * fim, DESCARTA a sala (zera sem arquivar). Não rode durante a aula.
 */
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '@playwright/test';

const PADRAO_SALA = 'mack-dcs-a04-2026-2';
const N = Number(process.argv[2] || 10);
const SALA = process.argv[3] || PADRAO_SALA;
const env = fs.readFileSync(process.env.QUIZ_ENV_FILE || '.env', 'utf8');
const tk = env.match(/^\s*DCS_HOST_TOKEN\s*=\s*(.+)\s*$/m);
if (!tk) { console.error('DCS_HOST_TOKEN ausente no arquivo de ambiente.'); process.exit(2); }
const TOKEN = tk[1].trim().replace(/^(['"])(.*)\1$/, '$2');

const BASE = 'file://' + path.resolve('aulas/data_collection_and_storage/aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse/tbl') + '/';
const RPC = 'https://lwamaovuxcevsjfvtqhf.supabase.co/rest/v1/rpc/';
const KEY = 'sb_publishable_j0O_u0t7-lDCtBbmqaIz3A_8vAIGcyJ';
const QS = SALA === PADRAO_SALA ? '' : `?sala=${SALA}`;

const rpc = async (fn, body) => (await fetch(RPC + fn, {
  method: 'POST',
  headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
})).json();

const erros = [];
const ok = (m) => console.log('  ok   ' + m);
const falha = (m) => { console.log(' FALHA ' + m); erros.push(m); };
const confere = (cond, m) => (cond ? ok(m) : falha(m));
const espera = async (p, fn, arg, timeout = 20000) => {
  try { await p.waitForFunction(fn, arg, { timeout }); return true; } catch { return false; }
};

const inicial = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
if (!inicial.ok) { console.error('não foi possível falar com a sala:', inicial.erro || inicial); process.exit(1); }
ok(`sala ${SALA} zerada (${inicial.total_questoes} questões carregadas)`);

const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {});
const errosConsole = [];
try {
  const painel = await (await browser.newContext({ viewport: { width: 1440, height: 900 } })).newPage();
  painel.on('dialog', (d) => d.accept());
  painel.on('pageerror', (e) => errosConsole.push('painel: ' + e.message));
  await painel.goto(BASE + `painel_aula_04.html${QS}`);
  await painel.fill('#token', TOKEN);
  await painel.click('#form-token button');
  confere(await espera(painel, () => !document.querySelector('#painel').hidden), 'painel autenticado');

  const nomes = Array.from({ length: N }, (_, i) => `Aluno Sim ${String(i + 1).padStart(2, '0')}`);
  const alunos = [];
  const abrir = async (nome) => {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
    const p = await ctx.newPage();
    p.on('pageerror', (e) => errosConsole.push(nome + ': ' + e.message));
    await p.goto(BASE + `tbl_aula_04.html${QS}`);
    await p.fill('#nome', nome);
    await p.click('#form-entrada button');
    const entrou = await espera(p, () => !document.querySelector('#tela-sala').hidden);
    if (!entrou) falha(`${nome} não entrou na sala`);
    return { nome, p };
  };

  // O último aluno entra atrasado, já com a questão 1 aberta.
  const t0 = Date.now();
  const entradas = await Promise.all(nomes.slice(0, N - 1).map((n, i) =>
    new Promise((r) => setTimeout(r, i * 150)).then(() => abrir(n))));
  alunos.push(...entradas);
  ok(`${alunos.length} alunos entraram em ${((Date.now() - t0) / 1000).toFixed(1)} s`);
  confere(await espera(painel, (n) => document.querySelector('#conectados').textContent === String(n), alunos.length),
    `painel mostra ${alunos.length} na sala`);

  const acao = async (a) => {
    await painel.click(`[data-acao="${a}"]`);
    await painel.waitForFunction(() => !document.querySelector('#recado').textContent.startsWith('Atualizando'), null, { timeout: 15000 });
  };
  const todosEm = async (prefixo, rotulo) => {
    const t = Date.now();
    const r = await Promise.all(alunos.map(async (a) => ({
      a, ok: await espera(a.p, (x) => document.querySelector('#selo-fase').textContent.startsWith(x), prefixo),
    })));
    const atrasados = r.filter((x) => !x.ok).map((x) => x.a.nome);
    confere(!atrasados.length, `${rotulo}: ${alunos.length - atrasados.length}/${alunos.length} alunos na fase em ${((Date.now() - t) / 1000).toFixed(1)} s`
      + (atrasados.length ? ` (faltaram ${atrasados.join(', ')})` : ''));
  };
  const decidir = async (a, escolha, texto) => {
    await a.p.locator(`button.opcao[data-escolha="${escolha}"]`).click();
    await a.p.fill('#justificativa', texto);
    await a.p.click('#registrar');
    const r = await espera(a.p, () => document.querySelector('#recado').textContent.startsWith('Decisão registrada'));
    if (!r) falha(`${a.nome}: decisão não registrada (${await a.p.locator('#recado').textContent()})`);
    return r;
  };
  const rodada = async (escolhas, rotulo) => {
    const r = await Promise.all(alunos.map((a, i) => decidir(a, escolhas[i], `${rotulo}: justificativa de ${a.nome}, com o custo que aceito`)));
    const n = r.filter(Boolean).length;
    confere(n === alunos.length, `${rotulo}: ${n}/${alunos.length} decisões registradas`);
    confere(await espera(painel, (k) => document.querySelector('#decidiram').textContent === String(k), alunos.length),
      `${rotulo}: painel conta ${alunos.length} decisões (mostra ${await painel.locator('#decidiram').textContent()})`);
  };

  for (let q = 1; q <= 3; q++) {
    await acao('avancar');
    if (q === 1) {
      alunos.push(await abrir(nomes[N - 1]));
      ok(`${nomes[N - 1]} entrou atrasado, com a questão 1 aberta`);
    }
    await todosEm(`Primeira decisão · questão ${q}`, `q${q} primeira decisão`);
    const opcoes = await alunos[0].p.locator('button.opcao').count();
    confere(opcoes === 4, `q${q}: quatro táticas na tela do aluno (${opcoes})`);
    const escolhas1 = alunos.map((_, i) => (i * (q + 1)) % 4);
    if (q === 2) {
      // Um aluno recarrega a página antes de votar: precisa voltar para a sala sem novo cadastro.
      await alunos[3].p.reload();
      confere(await espera(alunos[3].p, () => !document.querySelector('#tela-sala').hidden), `${alunos[3].nome} recarregou e voltou direto para a sala`);
    }
    await rodada(escolhas1, `q${q} 1ª`);
    confere(await espera(painel, (n) => document.querySelector('#conectados').textContent === String(n), N),
      `q${q}: painel mostra ${N} na sala, sem duplicar quem recarregou (mostra ${await painel.locator('#conectados').textContent()})`);

    await acao('avancar');
    await todosEm('Discussão', `q${q} discussão`);
    const dado = await alunos[0].p.evaluate(() => /dado novo/i.test(document.querySelector('#conteudo').textContent));
    ok(`q${q} discussão: ${dado ? 'com' : 'sem'} dado novo na tela do aluno`);

    await acao('avancar');
    await todosEm('Segunda decisão', `q${q} segunda decisão`);
    // Na segunda decisão, metade da turma muda de tática.
    await rodada(escolhas1.map((e, i) => (i % 2 ? (e + 1) % 4 : e)), `q${q} 2ª`);

    await acao('avancar');
    await todosEm('Síntese', `q${q} síntese`);
    const placar = await painel.locator('#projecao').textContent();
    confere(/1ª/.test(placar) && /2ª/.test(placar), `q${q} síntese: painel projeta os dois placares`);
  }

  await acao('avancar');
  await todosEm('Fechamento', 'fechamento');
  const cartoes = await painel.locator('#projecao .opcao .troca').count();
  confere(cartoes >= 12, `fechamento projeta as doze táticas (${cartoes})`);

  const est = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'estado' }).catch(() => null);
  if (est && est.ok) ok(`estado final no servidor: fase ${est.fase}, ${est.inscritos ?? est.participantes ?? '?'} inscritos`);
  confere(!errosConsole.length, `sem erro de JavaScript nas páginas${errosConsole.length ? ': ' + errosConsole.slice(0, 3).join(' | ') : ''}`);
} finally {
  await browser.close();
  const fim = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
  console.log(fim.ok && fim.fase === 'lobby' && fim.inscritos === 0
    ? '  ok   sala descartada e de volta ao lobby'
    : ' FALHA não foi possível descartar a sala: ' + JSON.stringify(fim).slice(0, 200));
}

console.log(erros.length ? `\n${erros.length} falha(s).` : `\nTBL da Aula 04 simulado com ${N} alunos sem falhas.`);
process.exit(erros.length ? 1 : 0);
