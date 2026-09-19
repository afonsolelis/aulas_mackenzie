/**
 * Validação ponta a ponta do TBL da Aula 06.
 *
 *   node scripts/tbl_e2e.mjs [slug-da-sala] [dir-de-screenshots]
 *
 * O token do professor vem do .env local (TBL_HOST_TOKEN ou QUIZ_HOST_TOKEN);
 * ele nunca é passado por argumento nem impresso.
 *
 * Roda nos arquivos locais (file://), com o mesmo código das páginas, falando
 * com o Supabase de verdade. Um painel e dois alunos percorrem as duas
 * questões: lobby com o caso → primeira decisão → discussão → segunda decisão
 * → síntese, conferindo que o dado novo da questão 2 só aparece a partir da
 * discussão e que as quatro táticas permanecem na tela em todas as fases,
 * inclusive na síntese e no fechamento. No fim, DESCARTA a sala (zera sem
 * arquivar): a validação não deixa aluno de teste no histórico da turma.
 *
 * Não rode durante a aula: descartar desconecta quem estiver na sala.
 */
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '@playwright/test';

const [SALA = 'mack-dv-a06-2026-2', SHOTS] = process.argv.slice(2);
const env = fs.readFileSync(process.env.QUIZ_ENV_FILE || '.env', 'utf8');
const tk = env.match(/^\s*TBL_HOST_TOKEN\s*=\s*(.+)\s*$/m) || env.match(/^\s*QUIZ_HOST_TOKEN\s*=\s*(.+)\s*$/m);
if (!tk) { console.error('TBL_HOST_TOKEN (ou QUIZ_HOST_TOKEN) ausente no arquivo de ambiente.'); process.exit(2); }
const TOKEN = tk[1].trim().replace(/^(['"])(.*)\1$/, '$2');

const BASE = 'file://' + path.resolve('aulas/data_visualization/aula_06_heuristicas_e_vieses/tbl') + '/';
const RPC = 'https://lwamaovuxcevsjfvtqhf.supabase.co/rest/v1/rpc/';
const KEY = 'sb_publishable_j0O_u0t7-lDCtBbmqaIz3A_8vAIGcyJ';
const PADRAO = SALA === 'mack-dv-a06-2026-2' ? '' : `?sala=${SALA}`;

const rpc = async (fn, body) => (await fetch(RPC + fn, {
  method: 'POST',
  headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
})).json();

const erros = [];
const ok = (m) => console.log('  ok   ' + m);
const falha = (m) => { console.log(' FALHA ' + m); erros.push(m); };
const shot = async (p, nome) => { if (SHOTS) await p.screenshot({ path: `${SHOTS}/tbl-a06-${nome}.png`, fullPage: false }); };
const confere = (cond, m) => (cond ? ok(m) : falha(m));
const espera = async (p, fn, arg, m, timeout = 15000) => {
  try { await p.waitForFunction(fn, arg, { timeout }); ok(m); }
  catch { falha(m); }
};

const inicial = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
if (!inicial.ok) { console.error('não foi possível falar com a sala:', inicial.erro || inicial); process.exit(1); }
ok(`sala ${SALA} zerada para o teste (${inicial.total_questoes} questões carregadas)`);

const browser = await chromium.launch();
try {
  const painelCtx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const painel = await painelCtx.newPage();
  painel.on('dialog', (d) => d.accept());
  await painel.goto(BASE + `painel_aula_06.html${PADRAO}`);
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
    await p.goto(BASE + `tbl_aula_06.html${PADRAO}`);
    await p.fill('#nome', nome);
    await p.click('#form-entrada button');
    await espera(p, () => !document.querySelector('#tela-sala').hidden, null, `${nome} entrou na sala`);
    alunos.push(p);
  }
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('Leia o caso com atenção'), null, 'aluno lê o caso no lobby');
  confere(!(await alunos[0].locator('button.opcao').count()), 'lobby não mostra alternativas ao aluno');

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
  // As quatro táticas precisam estar na tela: é a condição que a síntese e o
  // fechamento quebravam antes, deixando o professor sem o que discutir.
  const taticasNaTela = async (p, onde) => {
    await p.waitForTimeout(500);
    const n = await p.locator('.opcao .troca').count();
    confere(n >= 4, `${onde}: as quatro táticas continuam na tela (${n} cartões)`);
  };

  // Questão 1 — ciclo completo.
  await acao('avancar');
  await fase(alunos[0], 'Primeira decisão · questão 1');
  confere(await alunos[0].locator('button.opcao').count() === 4, 'questão 1 mostra quatro táticas');
  confere(!(await alunos[0].locator('text=Dado novo').count()), 'questão 1 não tem dado novo');
  await decidir(alunos[0], 0, 'a proporção ataca o denominador onde ele nasce');
  await decidir(alunos[1], 2, 'a decisão real é com quem falar, não o placar');
  await espera(painel, () => document.querySelector('#decidiram').textContent === '2', null, 'painel conta 2 decisões');

  await acao('avancar');
  await fase(alunos[0], 'Discussão');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('Perguntas que organizam a discussão'), null, 'discussão mostra o roteiro');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('a decisão real é com quem falar'), null, 'justificativas circulam na discussão');
  await taticasNaTela(alunos[0], 'discussão (aluno)');
  await taticasNaTela(painel, 'discussão (painel)');
  confere(await painel.locator('.placar').count() >= 4, 'painel imprime o placar dentro de cada tática na discussão');
  await shot(painel, 'painel-discussao');

  await acao('avancar');
  await fase(alunos[0], 'Segunda decisão');
  await decidir(alunos[0], 2, 'mudei: a tela precisa responder a decisão, não medi-la');
  await decidir(alunos[1], 2, 'mantive depois de ouvir o custo da curadoria');

  await acao('avancar');
  await fase(alunos[0], 'Síntese');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('mudaram a decisão'), null, 'síntese mostra quem mudou');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('A → C'), null, 'síntese mostra a trajetória A → C');
  await taticasNaTela(alunos[0], 'síntese (aluno)');
  await taticasNaTela(painel, 'síntese (painel)');
  await espera(painel, () => /1ª/.test(document.querySelector('#projecao').textContent) && /2ª/.test(document.querySelector('#projecao').textContent), null, 'síntese do painel traz os dois placares por tática');
  await shot(painel, 'painel-sintese');
  await shot(alunos[0], 'aluno-sintese');

  // Questão 2 — a do dado novo.
  await acao('avancar');
  await fase(alunos[0], 'Primeira decisão · questão 2');
  confere(!(await alunos[0].locator('text=Dado novo').count()), 'questão 2: dado novo oculto na primeira decisão');
  await decidir(alunos[0], 1, 'reconciliar a origem antes de publicar');
  await decidir(alunos[1], 3, 'sem autoria resolvida a tela não deveria existir');

  await acao('avancar');
  await fase(alunos[0], 'Discussão');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('O que os leitores fizeram'), null, 'questão 2: dado novo liberado na discussão');
  confere(await painel.evaluate(() => !document.querySelector('#reservado').hidden), 'painel mantém o dado novo em área reservada');
  await shot(alunos[0], 'aluno-dado-novo');

  await acao('avancar');
  await fase(alunos[0], 'Segunda decisão');
  await espera(alunos[0], () => document.querySelector('label[for=justificativa]').textContent.includes('sobrevive ao dado novo'), null, 'questão 2: segunda decisão pergunta sobre o dado novo');
  await decidir(alunos[0], 0, 'o reteste mostrou que a faixa precisa ser rotulada');
  await decidir(alunos[1], 0, 'mudei: recusar a tela não impede a inferência');

  await acao('avancar');
  await fase(alunos[0], 'Síntese');
  await taticasNaTela(painel, 'síntese da questão 2 (painel)');

  await acao('avancar');
  await fase(alunos[0], 'Fechamento');
  await espera(alunos[0], () => document.querySelector('#conteudo').textContent.includes('Duas decisões sobre o mesmo painel'), null, 'aluno vê o fechamento');
  const cartoes = await painel.locator('#projecao .opcao .troca').count();
  confere(cartoes >= 8, `fechamento projeta as oito táticas por extenso (${cartoes})`);
  await shot(painel, 'painel-fechamento');
  await shot(alunos[0], 'aluno-fechamento');
} finally {
  await browser.close();
  const fim = await rpc('hubtbl_host', { p_slug: SALA, p_token: TOKEN, p_acao: 'descartar' });
  console.log(fim.ok && fim.fase === 'lobby' && fim.inscritos === 0
    ? '  ok   sala descartada e de volta ao lobby'
    : ' FALHA não foi possível descartar a sala: ' + JSON.stringify(fim).slice(0, 200));
}

console.log(erros.length ? `\n${erros.length} falha(s).` : '\nTBL da Aula 06 validado de ponta a ponta.');
process.exit(erros.length ? 1 : 0);
