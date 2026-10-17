/**
 * Validação ponta a ponta do quiz da Aula 05 de Data Collection and Storage (modelagem relacional e dimensional).
 *
 *   node scripts/quiz_e2e_dc_aula05.mjs [slug-da-sala] [dir-de-screenshots]
 *
 * O token do professor vem do .env local (DCS_HOST_TOKEN); ele nunca é
 * passado por argumento nem impresso.
 *
 * Roda nos arquivos locais (file://), com o mesmo código das páginas, falando
 * com o Supabase de verdade. Um painel e dois alunos percorrem as dez
 * perguntas: o aluno A responde sempre a alternativa correta e o aluno B
 * sempre uma errada. O painel revela sozinho quando os dois respondem. No fim
 * confere o placar, o peso dobrado da pergunta 10 e os temas a retomar, e
 * ZERA a sala: tenta a ação 'descartar' (zera sem arquivar) e, se o servidor
 * não a conhecer, usa 'reiniciar', que arquiva a rodada de teste no histórico.
 *
 * Pré-requisito: seed aplicado (npm run quiz:dc-aula05:apply).
 * Não rode durante a aula: zerar a sala desconecta quem estiver nela.
 */
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '@playwright/test';

const PADRAO_SALA = 'mack-dcs-a05-2026-2';
const [SALA = PADRAO_SALA, SHOTS] = process.argv.slice(2);
const env = fs.readFileSync(process.env.QUIZ_ENV_FILE || '.env', 'utf8');
const tk = env.match(/^\s*DCS_HOST_TOKEN\s*=\s*(.+)\s*$/m);
if (!tk) { console.error('DCS_HOST_TOKEN ausente no arquivo de ambiente.'); process.exit(2); }
const TOKEN = tk[1].trim().replace(/^(['"])(.*)\1$/, '$2');

const BASE = 'file://' + path.resolve('aulas/data_collection_and_storage/aula_05_modelagem_de_dados_relacional_e_dimensional/quiz') + '/';
const RPC = 'https://lwamaovuxcevsjfvtqhf.supabase.co/rest/v1/rpc/';
const KEY = 'sb_publishable_j0O_u0t7-lDCtBbmqaIz3A_8vAIGcyJ';
const PADRAO = SALA === PADRAO_SALA ? '' : `?sala=${SALA}`;

const rpc = async (fn, body) => (await fetch(RPC + fn, {
  method: 'POST',
  headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
})).json();
const host = (acao) => rpc('quiz_host', { p_slug: SALA, p_token: TOKEN, p_acao: acao });

const erros = [];
const ok = (m) => console.log('  ok   ' + m);
const falha = (m) => { console.log(' FALHA ' + m); erros.push(m); };
const shot = async (p, nome) => { if (SHOTS) await p.screenshot({ path: `${SHOTS}/quiz-dc-a05-${nome}.png`, fullPage: false }); };
const confere = (cond, m) => (cond ? ok(m) : falha(m));
const espera = async (p, fn, arg, m, timeout = 20000) => {
  try { await p.waitForFunction(fn, arg, { timeout }); ok(m); return true; }
  catch { falha(m); return false; }
};
const tela = (p, nome, m, timeout) => espera(p, (t) => {
  const s = document.querySelector(`[data-tela="${t}"]`);
  return Boolean(s && s.classList.contains('ativa'));
}, nome, m, timeout);

/* Zera a sala sem deixar aluno de teste no histórico quando possível. */
async function zerar() {
  let r = await host('descartar');
  if (r && r.ok) return { ...r, via: 'descartar' };
  r = await host('reiniciar');
  return { ...(r || {}), via: 'reiniciar' };
}

const inicial = await host('ver');
if (!inicial || !inicial.ok) {
  console.error('não foi possível falar com a sala:', (inicial && inicial.erro) || 'resposta inesperada');
  process.exit(1);
}
const z0 = await zerar();
if (!z0.ok) { console.error('não foi possível zerar a sala antes do teste:', z0.erro || 'sem detalhe'); process.exit(1); }
ok(`sala ${SALA} zerada para o teste via '${z0.via}' (${inicial.total} perguntas carregadas)`);
confere(inicial.total === 10, 'a sala tem 10 perguntas');

const gab = await rpc('quiz_gabarito', { p_slug: SALA, p_token: TOKEN });
if (!gab || !gab.ok) { console.error('quiz_gabarito indisponível:', (gab && gab.erro) || 'sem detalhe'); process.exit(1); }
const corretas = Object.fromEntries(gab.perguntas.map((q) => [q.ordem, q.correta]));
confere(gab.perguntas.length === 10, 'gabarito traz 10 perguntas');
confere(gab.perguntas.every((q) => q.alternativas.length === 4 && q.segundos === 90), 'todas com 4 alternativas e 90 s');
const posicoes = new Set(gab.perguntas.map((q) => q.correta));
confere(posicoes.size >= 3, `posição da correta varia (${[...posicoes].sort().join(', ')})`);

const browser = await chromium.launch();
try {
  const painelCtx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const painel = await painelCtx.newPage();
  const errosJs = [];
  painel.on('pageerror', (e) => errosJs.push('painel: ' + e.message));
  await painel.goto(BASE + `painel_aula_05.html${PADRAO}`);
  await painel.fill('#token', TOKEN);
  await painel.click('#btn-auth');
  await tela(painel, 'lobby', 'painel autenticado e no lobby');
  await espera(painel, () => document.querySelector('#url-quiz').textContent.includes('afonsolelis.github.io/aulas_mackenzie/aulas/data_collection_and_storage/aula_05_modelagem_de_dados_relacional_e_dimensional/quiz/quiz_aula_05.html'), null, 'painel aberto por file:// projeta o endereço publicado do quiz');
  await shot(painel, 'painel-lobby');

  const alunos = [];
  for (const nome of ['Teste Quiz A', 'Teste Quiz B']) {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const p = await ctx.newPage();
    p.on('pageerror', (e) => errosJs.push(nome + ': ' + e.message));
    await p.goto(BASE + `quiz_aula_05.html${PADRAO}`);
    await tela(p, 'entrada', `${nome} vê a tela de entrada`);
    confere(await p.locator('a.botao-professor[href="painel_aula_05.html"]').count() === 1, `${nome}: rodapé tem o botão Área do professor`);
    await p.fill('#nome', nome);
    await p.click('#btn-entrar');
    await tela(p, 'espera', `${nome} entrou e aguarda a primeira pergunta`);
    alunos.push(p);
  }
  await espera(painel, () => document.querySelector('#m-jogadores').textContent === '2', null, 'painel conta 2 alunos na sala');
  await espera(painel, () => document.querySelectorAll('#nomes .chip').length === 2, null, 'painel lista os dois nomes');

  for (let ordem = 1; ordem <= 10; ordem += 1) {
    await painel.click('#btn-abrir');
    for (const p of alunos) {
      await espera(p, (o) => {
        const s = document.querySelector('[data-tela="pergunta"]');
        return s.classList.contains('ativa') && document.querySelector('#pergunta-selo').textContent === `Pergunta ${o} de 10`;
      }, ordem, `pergunta ${ordem} aberta no aluno`);
    }
    confere(await alunos[0].locator('#alternativas .alt').count() === 4, `pergunta ${ordem}: quatro alternativas`);
    const dobro = await alunos[0].evaluate(() => !document.querySelector('#selo-dobro').hidden);
    confere(dobro === (ordem === 10), `pergunta ${ordem}: selo de peso ${ordem === 10 ? 'dobrado visível' : 'oculto'}`);
    if (ordem === 1) await shot(alunos[0], 'aluno-pergunta');

    const certa = corretas[ordem];
    await alunos[0].locator('#alternativas .alt').nth(certa).click();
    await alunos[1].locator('#alternativas .alt').nth((certa + 1) % 4).click();
    for (const p of alunos) await tela(p, 'respondido', `pergunta ${ordem}: resposta registrada`);

    // O painel revela sozinho quando todos respondem (leitura a cada 2 s).
    await tela(painel, 'revelacao', `pergunta ${ordem}: painel revelou sozinho`);
    await espera(alunos[0], () => document.querySelector('#veredito').classList.contains('acerto'), null, `pergunta ${ordem}: aluno A acertou`);
    await espera(alunos[1], () => document.querySelector('#veredito').classList.contains('erro'), null, `pergunta ${ordem}: aluno B errou`);
    if (ordem === 1) {
      await espera(alunos[0], () => document.querySelector('#explicacao').textContent.length > 40, null, 'revelação mostra a explicação');
      await shot(painel, 'painel-revelacao');
    }
  }

  await painel.click('#btn-encerrar');
  await tela(painel, 'final', 'painel mostra o placar geral');
  for (const p of alunos) await tela(p, 'final', 'aluno vê o placar geral');
  await espera(alunos[0], () => /10 de 10 corretas/.test(document.querySelector('#final-resumo').textContent), null, 'aluno A: 10 de 10 corretas');
  await espera(alunos[0], () => /1º lugar/.test(document.querySelector('#final-resumo').textContent), null, 'aluno A em 1º lugar');
  await espera(alunos[1], () => /0 de 10 corretas/.test(document.querySelector('#final-resumo').textContent), null, 'aluno B: 0 de 10 corretas');
  await espera(alunos[1], () => document.querySelectorAll('#meus-temas li').length > 0, null, 'aluno B recebe os temas a retomar');
  await shot(painel, 'painel-final');
  await shot(alunos[1], 'aluno-final');

  const fimHost = await host('ver');
  const a = (fimHost.ranking || []).find((r) => r.nome === 'Teste Quiz A');
  confere(a && a.acertos === 10, 'servidor registra 10 acertos para o aluno A');
  confere(!errosJs.length, 'nenhum erro de JavaScript nas páginas' + (errosJs.length ? ': ' + errosJs.join(' | ') : ''));
} finally {
  await browser.close();
  const fim = await zerar();
  const limpo = fim.ok && fim.estado === 'lobby' && !fim.jogadores;
  console.log(limpo
    ? `  ok   sala zerada via '${fim.via}' e de volta ao lobby`
    : ' FALHA não foi possível zerar a sala: ' + JSON.stringify({ ok: fim.ok, erro: fim.erro, estado: fim.estado, via: fim.via }));
  if (!limpo) erros.push('sala não zerada');
}

console.log(erros.length ? `\n${erros.length} falha(s).` : '\nQuiz da Aula 05 validado de ponta a ponta.');
process.exit(erros.length ? 1 : 0);
