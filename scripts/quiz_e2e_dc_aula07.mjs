/**
 * Validação ponta a ponta do quiz da Aula 07 de Data Collection and Storage.
 *
 *   node scripts/quiz_e2e_dc_aula07.mjs [slug-da-sala] [dir-de-screenshots]
 *
 * O token do professor vem do .env local (DCS_HOST_TOKEN); ele nunca é passado
 * por argumento nem impresso.
 *
 * Roda nos arquivos locais (file://), com o mesmo código das páginas, falando
 * com o Supabase de verdade. Um painel e dois alunos percorrem as dez
 * perguntas: lobby → pergunta → respostas → revelação disparada sozinha pelo
 * painel → placar → encerramento → relatório. O aluno A acerta tudo; o aluno B
 * erra a primeira, sai da aba na segunda (strike) e acerta o resto, o que
 * permite conferir veredito, strike e o peso dobrado da última pergunta. No
 * fim, DESCARTA a sala (zera sem arquivar): a validação não deixa aluno de
 * teste no placar nem na série histórica da turma.
 *
 * Pré-requisito: seed supabase/quiz_seed_aula_07_data_collection.sql aplicado
 * (npm run quiz:dc-aula07:apply). Não rode durante a aula: descartar
 * desconecta quem estiver na sala.
 */
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '@playwright/test';

const [SALA = 'mack-dcs-a07-2026-2', SHOTS] = process.argv.slice(2);
const env = fs.readFileSync(process.env.QUIZ_ENV_FILE || '.env', 'utf8');
const tk = env.match(/^\s*DCS_HOST_TOKEN\s*=\s*(.+)\s*$/m);
if (!tk) { console.error('DCS_HOST_TOKEN ausente no arquivo de ambiente.'); process.exit(2); }
const TOKEN = tk[1].trim().replace(/^(['"])(.*)\1$/, '$2');

const BASE = 'file://' + path.resolve('aulas/data_collection_and_storage/aula_07_validacao_com_pydantic_e_testes_integrados/quiz') + '/';
const RPC = 'https://lwamaovuxcevsjfvtqhf.supabase.co/rest/v1/rpc/';
const KEY = 'sb_publishable_j0O_u0t7-lDCtBbmqaIz3A_8vAIGcyJ';

const rpc = async (fn, body) => (await fetch(RPC + fn, {
  method: 'POST',
  headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
})).json();
const host = (acao) => rpc('quiz_host', { p_slug: SALA, p_token: TOKEN, p_acao: acao });

const erros = [];
const ok = (m) => console.log('  ok   ' + m);
const falha = (m) => { console.log(' FALHA ' + m); erros.push(m); };
const confere = (cond, m) => (cond ? ok(m) : falha(m));
const shot = async (p, nome) => { if (SHOTS) await p.screenshot({ path: `${SHOTS}/quiz-dc-a07-${nome}.png` }); };
const espera = async (p, fn, arg, m, timeout = 20000) => {
  try { await p.waitForFunction(fn, arg, { timeout }); ok(m); return true; }
  catch { falha(m); return false; }
};
const tela = (p, nome, m) => espera(p, (t) => !!document.querySelector(`[data-tela="${t}"].ativa`), nome, m);

// Simula o aluno trocando de aba por menos de um segundo.
const sairDaAba = (p) => p.evaluate(() => {
  const definir = (oculta) => {
    Object.defineProperty(document, 'hidden', { value: oculta, configurable: true });
    Object.defineProperty(document, 'visibilityState', { value: oculta ? 'hidden' : 'visible', configurable: true });
    document.dispatchEvent(new Event('visibilitychange'));
  };
  definir(true);
  return new Promise((r) => setTimeout(() => { definir(false); r(); }, 800));
});

const inicial = await host('descartar');
if (!inicial.ok) { console.error('não foi possível falar com a sala:', inicial.erro || 'resposta inesperada'); process.exit(1); }
ok(`sala ${SALA} zerada para o teste (${inicial.total} perguntas carregadas)`);
if (inicial.total !== 10) falha(`a sala deveria ter 10 perguntas e tem ${inicial.total}`);

const browser = await chromium.launch();
try {
  const vigiar = (p, nome) => {
    p.on('pageerror', (e) => falha(`[${nome}] erro de página: ${e.message}`));
    p.on('console', (m) => { if (m.type() === 'error' && !/net::|websocket/i.test(m.text())) falha(`[${nome}] console: ${m.text()}`); });
  };

  // ---- painel ---------------------------------------------------------
  const painelCtx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const painel = await painelCtx.newPage();
  painel.on('dialog', (d) => d.accept());
  vigiar(painel, 'painel');
  await painel.goto(BASE + 'painel_aula_07.html');
  await painel.fill('#token', 'token-errado');
  await painel.click('#btn-auth');
  await espera(painel, () => document.getElementById('aviso-auth').textContent.length > 0, null, 'painel recusa token inválido');
  await painel.fill('#token', TOKEN);
  await painel.click('#btn-auth');
  await tela(painel, 'lobby', 'painel autenticado no lobby');
  confere((await painel.textContent('#url-quiz')).includes('quiz_aula_07.html'), 'painel projeta o endereço do quiz da Aula 07');
  confere(await painel.locator('#qr *').count() > 0, 'painel preenche a área do QR (aviso de arquivo local em file://)');

  // ---- alunos ---------------------------------------------------------
  const alunos = [];
  for (const nome of ['Teste Quiz A', 'Teste Quiz B']) {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const p = await ctx.newPage();
    vigiar(p, nome);
    await p.goto(BASE + 'quiz_aula_07.html');
    await tela(p, 'entrada', `${nome} vê a tela de entrada`);
    await p.fill('#nome', nome);
    await p.click('#btn-entrar');
    await tela(p, 'espera', `${nome} entrou na sala`);
    alunos.push(p);
  }
  const [a, b] = alunos;
  confere(await a.locator('a.botao-professor[href="painel_aula_07.html"]').count() === 1, 'sala do aluno tem o botão Área do professor');
  await espera(painel, () => document.querySelectorAll('#nomes .chip').length === 2, null, 'painel lista os dois alunos no lobby');
  await shot(painel, 'painel-lobby');

  // ---- dez perguntas --------------------------------------------------
  for (let i = 1; i <= 10; i++) {
    await painel.click('#btn-abrir');
    await espera(painel, (o) => document.getElementById('m-pergunta').textContent === o, `${i}/10`, `painel abriu a pergunta ${i}`);
    const v = await host('ver');
    const q = v.pergunta || {};
    confere(q.alternativas && q.alternativas.length === 4, `pergunta ${i} tem quatro alternativas`);
    confere(q.segundos === 90, `pergunta ${i} tem 90 segundos`);
    confere((q.peso || 1) === (i === 10 ? 2 : 1), `pergunta ${i} tem peso ${i === 10 ? 2 : 1}`);
    const certa = q.correta;
    const errada = (certa + 1) % 4;

    for (const p of alunos) await tela(p, 'pergunta', `pergunta ${i} chegou ao aluno`);
    if (i === 10) confere(await a.isVisible('#selo-dobro'), 'aluno vê o selo "Vale o dobro" na pergunta 10');
    if (i === 2) {
      await sairDaAba(b);
      await espera(b, () => !document.getElementById('strike-pergunta').hidden, null, 'aluno B saiu da aba e recebeu o aviso de strike');
    }
    await a.click(`.alt >> nth=${certa}`);
    await b.click(`.alt >> nth=${i === 1 ? errada : certa}`);
    for (const p of alunos) await tela(p, 'respondido', `resposta da pergunta ${i} registrada`);

    // Ninguém clica em "Revelar": com todos respondidos, o painel revela sozinho.
    await tela(painel, 'revelacao', `painel revelou a pergunta ${i} sozinho`);
    await tela(a, 'revelacao', `aluno A vê a revelação da pergunta ${i}`);
    confere((await a.textContent('#veredito-titulo')) === 'Resposta correta', `aluno A acertou a pergunta ${i}`);
    confere(((await a.textContent('#explicacao')) || '').length > 80, `pergunta ${i} mostra a explicação`);
    if (i === 1) {
      await tela(b, 'revelacao', 'aluno B vê a revelação da pergunta 1');
      confere((await b.textContent('#veredito-titulo')) === 'Resposta incorreta', 'aluno B errou a pergunta 1');
      await shot(painel, 'painel-revelacao');
    }
    if (i === 2) {
      await tela(b, 'revelacao', 'aluno B vê a revelação da pergunta 2');
      confere((await b.textContent('#veredito-pontos')) === '+0', 'strike zerou os pontos do aluno B na pergunta 2');
    }
  }

  // ---- encerramento ---------------------------------------------------
  await painel.click('#btn-encerrar');
  await tela(painel, 'final', 'painel mostra o placar geral');
  await tela(a, 'final', 'aluno A vê o placar final');
  await tela(b, 'final', 'aluno B vê o placar final');
  confere((await a.textContent('#final-resumo')).includes('10 de 10'), 'aluno A fechou com 10 de 10');
  confere((await a.textContent('#final-resumo')).includes('1º lugar'), 'aluno A ficou em primeiro');
  confere((await b.textContent('#meus-temas')).includes('Aulas 06 e 07'), 'aluno B recebe os temas a retomar das Aulas 06 e 07');
  await shot(painel, 'painel-final');
  await shot(b, 'aluno-final');

  // ---- relatório ------------------------------------------------------
  const rel = await painelCtx.newPage();
  vigiar(rel, 'relatorio');
  await rel.goto(BASE + 'relatorio_aula_07.html');
  await espera(rel, () => document.querySelector('[data-painel="dados"]').classList.contains('ativo'), null, 'relatório abre com o token guardado pelo painel');
  confere((await rel.textContent('#m-alunos')) === '2', 'relatório conta dois estudantes');
  await espera(rel, () => document.querySelectorAll('#lista-perguntas .item').length === 10, null, 'relatório lista as dez perguntas com gabarito');
} finally {
  await browser.close();
  const fim = await host('descartar');
  confere(fim.ok && fim.estado === 'lobby' && (fim.jogadores || 0) === 0, 'sala descartada e de volta ao lobby');
}

console.log(erros.length ? `\n${erros.length} falha(s).` : '\nQuiz da Aula 07 de Data Collection validado de ponta a ponta.');
process.exit(erros.length ? 1 : 0);
