/**
 * Validação ponta a ponta do TBL da Aula 02 de Data Collection and Storage.
 *
 *   node scripts/tbl_e2e_dc_aula02.mjs [slug-da-sala] [dir-de-screenshots]
 *
 * O token do professor vem do .env local (DCS_HOST_TOKEN); ele nunca
 * é passado por argumento nem impresso.
 *
 * Roda nos arquivos locais (file://), com o mesmo código das páginas, falando
 * com o Supabase de verdade. Um painel e dois alunos percorrem as três
 * questões, conferindo que o dado novo só aparece na questão 2 a partir da
 * discussão e que as quatro táticas permanecem na tela em todas as fases.
 * No fim, DESCARTA a sala (zera sem arquivar).
 *
 * Não rode durante a aula: descartar desconecta quem estiver na sala.
 */
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '@playwright/test';

const PADRAO_SALA = 'mack-dcs-a02-2026-2';
const [SALA = PADRAO_SALA, SHOTS] = process.argv.slice(2);
const env = fs.readFileSync(process.env.QUIZ_ENV_FILE || '.env', 'utf8');
const tk = env.match(/^\s*DCS_HOST_TOKEN\s*=\s*(.+)\s*$/m);
if (!tk) { console.error('DCS_HOST_TOKEN ausente no arquivo de ambiente.'); process.exit(2); }
const TOKEN = tk[1].trim().replace(/^(['"])(.*)\1$/, '$2');

const BASE = 'file://' + path.resolve('aulas/data_collection_and_storage/aula_02_tipos_de_storage_e_coleta_em_object_storage_com_minio/tbl') + '/';
const RPC = 'https://lwamaovuxcevsjfvtqhf.supabase.co/rest/v1/rpc/';
const KEY = 'sb_publishable_j0O_u0t7-lDCtBbmqaIz3A_8vAIGcyJ';
const PADRAO = SALA === PADRAO_SALA ? '' : `?sala=${SALA}`;

const rpc = async (fn, body) => (await fetch(RPC + fn, {
  method: 'POST',
  headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
})).json();

const erros = [];
const ok = (m) => console.log('  ok   ' + m);
const falha = (m) => { console.log(' FALHA ' + m); erros.push(m); };
const shot = async (p, nome) => { if (SHOTS) await p.screenshot({ path: `${SHOTS}/tbl-dc-a02-${nome}.png`, fullPage: false }); };
const confere = (cond, m) => (cond ? ok(m) : falha(m));
const espera = async (p, fn, arg, m, timeout = 15000) => {
  try { await p.waitForFunction(fn, arg, { timeout }); ok(m); }
  catch { falha(m); }
};

const inicial = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
if (!inicial.ok) { console.error('não foi possível falar com a sala:', inicial.erro || inicial); process.exit(1); }
ok(`sala ${SALA} zerada para o teste (${inicial.total_questoes} questões carregadas)`);
confere(inicial.total_questoes === 3, 'a sala tem exatamente três questões');

const browser = await chromium.launch();
try {
  const painelCtx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const painel = await painelCtx.newPage();
  painel.on('dialog', (d) => d.accept());
  await painel.goto(BASE + `painel_aula_02.html${PADRAO}`);
  await painel.fill('#token', TOKEN);
  await painel.click('#form-token button');
  await espera(painel, () => !document.querySelector('#painel').hidden, null, 'painel autenticado');
  await espera(painel, () => document.querySelector('#projecao').textContent.includes('Caso em projeção'), null, 'painel projeta o caso no lobby');
  confere(await painel.locator('#qr-alvo img, #qr-alvo canvas').count() > 0, 'painel desenha o código QR');
  await shot(painel, 'painel-lobby');

  const alunos = [];
  for (const nome of ['Teste TBL A', 'Teste TBL B']) {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const p = await ctx.newPage();
    await p.goto(BASE + `tbl_aula_02.html${PADRAO}`);
    confere(await p.locator('a.botao-professor[href="painel_aula_02.html"]').count() === 1, `${nome}: rodapé tem o botão da área do professor`);
    await p.fill('#nome', nome);
    await p.click('#form-entrada button');
    await espera(p, () => !document.querySelector('#tela-sala').hidden, null, `${nome} entrou na sala`);
    alunos.push(p);
  }
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('O coletor que a demonstração colocou no ar'), null, 'aluno lê o caso no lobby');
  await shot(alunos[0], 'aluno-lobby');

  const fase = (p, texto) => espera(p, (t) => document.querySelector('#selo-fase').textContent.startsWith(t), texto, `aluno em "${texto}"`);
  const decidir = async (p, escolha, texto) => {
    await p.locator(`button.opcao[data-escolha="${escolha}"]`).click();
    await p.fill('#justificativa', texto);
    await p.click('#registrar');
    await espera(p, () => document.querySelector('#recado').textContent.startsWith('Decisão registrada'), null, `decisão ${'ABCD'[escolha]} registrada`);
  };
  const acao = async (a) => {
    await painel.click(`[data-acao="${a}"]`);
    await painel.waitForFunction(() => !document.querySelector('#recado').textContent.startsWith('Atualizando'), null, { timeout: 15000 });
  };
  const taticasNaTela = async (p, onde) => {
    await p.waitForTimeout(500);
    const n = await p.locator('.opcao .troca').count();
    confere(n >= 4, `${onde}: as quatro táticas continuam na tela (${n} cartões)`);
  };

  const votos = [
    [[0, 'espelhar é barato e protege a prova da jornada'], [3, 'risco declarado com gatilho de revisão']],
    [[0, 'a primeira gravação mantém a idempotência'], [3, 'o PUT condicional fecha a corrida']],
    [[1, 'raw bruta e bronze depois preservam a prova'], [0, 'o painel precisa de registros desde o primeiro dia']],
  ];
  for (let q = 1; q <= 3; q++) {
    await acao('avancar');
    await fase(alunos[0], `Primeira decisão · questão ${q}`);
    confere(await alunos[0].locator('button.opcao').count() === 4, `questão ${q} mostra quatro táticas`);
    confere(!(await alunos[0].locator('text=Dado novo').count()), `questão ${q}: nenhum dado novo na primeira decisão`);
    await decidir(alunos[0], ...votos[q - 1][0]);
    await decidir(alunos[1], ...votos[q - 1][1]);
    await espera(painel, () => document.querySelector('#decidiram').textContent === '2', null, 'painel conta 2 decisões');

    await acao('avancar');
    await fase(alunos[0], 'Discussão');
    await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('Reversibilidade'), null, 'discussão mostra o roteiro da aula');
    const temDado = await alunos[0].evaluate(() => document.querySelector('#conteudo').textContent.includes('O que a semana registrou'));
    confere(temDado === (q === 2), q === 2 ? 'questão 2: dado novo liberado na discussão' : `questão ${q}: sem dado novo`);
    await taticasNaTela(alunos[0], `discussão q${q} (aluno)`);
    await taticasNaTela(painel, `discussão q${q} (painel)`);
    if (q === 2) { await shot(alunos[0], 'aluno-dado-novo'); await shot(painel, 'painel-discussao'); }

    await acao('avancar');
    await fase(alunos[0], 'Segunda decisão');
    await decidir(alunos[0], 1, 'mudei depois de ouvir o custo da alternativa');
    await decidir(alunos[1], votos[q - 1][1][0], 'mantive a escolha depois da discussão');

    await acao('avancar');
    await fase(alunos[0], 'Síntese');
    await taticasNaTela(painel, `síntese q${q} (painel)`);
    await espera(painel, () => /1ª/.test(document.querySelector('#projecao').textContent) && /2ª/.test(document.querySelector('#projecao').textContent), null, `síntese q${q} traz os dois placares`);
  }

  await acao('avancar');
  await fase(alunos[0], 'Fechamento');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('Três decisões sobre a camada bruta'), null, 'aluno vê o fechamento');
  const cartoes = await painel.locator('#projecao .opcao .troca').count();
  confere(cartoes >= 12, `fechamento projeta as doze táticas por extenso (${cartoes})`);
  await shot(painel, 'painel-fechamento');
  await shot(alunos[0], 'aluno-fechamento');
} finally {
  await browser.close();
  const fim = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
  console.log(fim.ok && fim.fase === 'lobby' && fim.inscritos === 0
    ? '  ok   sala descartada e de volta ao lobby'
    : ' FALHA não foi possível descartar a sala: ' + JSON.stringify(fim).slice(0, 200));
}

console.log(erros.length ? `\n${erros.length} falha(s).` : '\nTBL da Aula 02 validado de ponta a ponta.');
process.exit(erros.length ? 1 : 0);
