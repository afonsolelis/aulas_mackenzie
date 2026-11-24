/* Bancada da Aula 07: pytest de verdade no navegador, via Pyodide.
   O motor (bancada.py) é o mesmo que o professor roda no terminal para conferir
   o manifesto. Este arquivo só monta a tela, guarda o que o aluno escreve e
   chama o motor. */
(function () {
  'use strict';

  const PYODIDE = 'https://cdn.jsdelivr.net/pyodide/v0.27.7/full/';
  const VERSAO = '1';
  const CHAVE = 'bancada_aula07_v1';
  const EMBED = new URLSearchParams(location.search).has('embed');

  const ESTACOES = [
    {
      id: 'ex0_aquecimento', n: 0, aba: 'Aquecimento',
      titulo: 'Primeiro pytest no navegador',
      resumo: 'Uma função do coletor da Aula 03 soma as linhas que foram gravadas na bronze. Os dois testes já passam. A estação serve para ler o relatório do pytest antes de escrever testes de verdade.',
      passos: [
        'Clique em Rodar pytest e confira os dois testes aprovados.',
        'Troque 60 por 61 no primeiro teste e rode de novo. Leia o relatório: a linha do assert, o valor esperado e o valor recebido.',
        'Volte para 60 e clique em Avaliar. O mutante M1 esquece o último arquivo do lote; veja se os seus testes o pegam.'
      ],
      meta: 'Meta: 1 de 1 mutante morto e os testes aprovados na versão correta.'
    },
    {
      id: 'ex1_contrato', n: 1, aba: 'Contrato',
      titulo: 'Partições e valores-limite do contrato do sensor',
      resumo: 'O contrato da leitura da estufa (Aula 06) aceita temperatura de -10 °C a 60 °C e umidade de 0 % a 100 %, limites incluídos. Os dois testes iniciais usam valores típicos e quase não pegam defeito algum. O contrato é somente leitura: a tarefa é escrever os testes.',
      passos: [
        'Clique em Avaliar com os testes iniciais e anote quantos dos nove mutantes morreram.',
        'Para cada faixa, acrescente na tabela parametrizada o valor no limite (aceito) e o vizinho de fora (recusado), com o motivo esperado.',
        'Cubra também a conversão de Fahrenheit (140 °F são 60 °C), a unidade desconhecida, o device_id fora do padrão e o campo extra.',
        'Avalie de novo. Cada mutante que sobreviver indica a partição ou o limite que ainda não tem teste.'
      ],
      meta: 'Meta: 9 de 9 mutantes mortos.'
    },
    {
      id: 'ex2_limpeza', n: 2, aba: 'Limpeza (TDD)',
      titulo: 'TDD na limpeza dos campos de livros',
      resumo: 'O scraper da Aula 03 grava o preço como "Â£51.77": o books.toscrape.com não declara charset, e o requests decodifica a página como ISO-8859-1. A função atual só funciona com "£51.77". Estoque e nota ainda não existem. Aqui você edita o código e os testes.',
      passos: [
        'Vermelho: descomente o teste do preço com "Â£51.77" e rode. Leia o erro.',
        'Verde: corrija preco_em_libras com o menor código que faz o teste passar. O preço precisa continuar Decimal.',
        'Refatore se precisar, rode de novo, e repita o ciclo para unidades_em_estoque e nota_em_estrelas, um teste de cada vez.',
        'Decida o que acontece com texto fora do formato (ValueError) e teste essa decisão.',
        'Avaliar mostra duas coisas: se o seu código passa na verificação do professor e quantos mutantes os seus testes pegam.'
      ],
      meta: 'Meta: verificação aprovada e 7 de 7 mutantes mortos.'
    },
    {
      id: 'ex3_relogio', n: 3, aba: 'Relógio',
      titulo: 'O teste que quebra no sábado',
      resumo: 'A função lê date.today() e procura o boletim PTAX do dia. O teste passou numa terça-feira, em 24/11/2026. Em dia sem boletim (fim de semana, feriado de 20/11 ou qualquer dia depois de 24/11) ele quebra. O defeito fica no código: o relógio está escondido dentro da função.',
      passos: [
        'Rode o teste e leia o KeyError.',
        'Mude a assinatura para cotacao_vigente(boletins, hoje): o dia passa a ser parâmetro.',
        'Implemente a regra: boletim do próprio dia ou do dia mais recente antes dele, até 5 dias para trás. Fora dessa janela, levante SemCotacao (crie a classe como subclasse de LookupError).',
        'Troque o teste antigo por testes com dias escolhidos: dia útil, feriado de 20/11, domingo 22/11, o limite da janela e um dia fora dela.'
      ],
      meta: 'Meta: verificação aprovada e 5 de 5 mutantes mortos.'
    },
    {
      id: 'ex4_dubles', n: 4, aba: 'Dublês',
      titulo: 'Stub e spy no coletor da PTAX',
      resumo: 'O coletor recebe a função de HTTP e a função de espera como parâmetros. No teste, a rede é trocada por dublês que devolvem a resposta real da API, gravada em 24/11/2026. O coletor é somente leitura.',
      passos: [
        'Leia coletor_ptax.py e boletim_ptax.json. Note o formato das datas na URL e os números da resposta.',
        'Use o stub para conferir valores exatos (Decimal) de um dia, e o Espiao para conferir a URL que o coletor montou.',
        'Simule o feriado com {"value": []}.',
        'Simule falhas: 503 seguido de 200, três 503 e um 404. Troque esperar por uma lista (esperas.append) para registrar os segundos sem esperar de verdade.'
      ],
      meta: 'Meta: 7 de 7 mutantes mortos.'
    },
    {
      id: 'ex5_lote', n: 5, aba: 'Lote',
      titulo: 'Testes sobre o dado antes de publicar a gold',
      resumo: 'O lote tem 22 linhas reais da bronze de livros com quatro defeitos plantados: dois livros coletados duas vezes, um preço vazio, uma nota vazia e a categoria "Poetry " com espaço no fim. O pipeline é somente leitura. Os testes rodam sobre a saída dele e decidem se o lote publica.',
      passos: [
        'Rode o pipeline pelos testes e examine o que sai na silver, na quarentena, nas duplicadas e na gold.',
        'Escreva um teste por dimensão de qualidade: unicidade do UPC, reconciliação de contagens, motivo na quarentena, categoria sem espaço e gold recalculada a partir da silver.',
        'Avalie. Cada mutante é um defeito de pipeline que já apareceu em projeto de turma.'
      ],
      meta: 'Meta: 6 de 6 mutantes mortos.'
    }
  ];

  const $ = id => document.getElementById(id);
  const el = (tag, attrs, ...filhos) => {
    const e = document.createElement(tag);
    Object.entries(attrs || {}).forEach(([k, v]) => {
      if (k === 'class') e.className = v; else if (k === 'text') e.textContent = v; else e.setAttribute(k, v);
    });
    filhos.forEach(f => e.append(f));
    return e;
  };

  let manifesto = null;
  const originais = {};   // id -> {nome: conteúdo}
  const ocultos = {};     // id -> {nome: conteúdo}
  let estado = { arquivos: {}, placar: {}, abertos: {} };
  let py = null;
  let pyCarregando = null;
  let ocupado = false;
  let aba = 'inicio';

  function carregarEstado() {
    try { const s = JSON.parse(localStorage.getItem(CHAVE)); if (s) estado = Object.assign(estado, s); } catch (e) { /* sem storage */ }
  }
  function salvarEstado() {
    try { localStorage.setItem(CHAVE, JSON.stringify(estado)); } catch (e) { /* sem storage */ }
  }

  function status(texto, classe) {
    $('status-texto').textContent = texto;
    $('status').className = 'bc-status' + (classe ? ' ' + classe : '');
    try { parent.postMessage({ bancadaStatus: texto, pronto: classe === 'is-pronto' }, '*'); } catch (e) { /* sem pai */ }
  }

  async function texto(url) {
    const r = await fetch(url + '?v=' + VERSAO);
    if (!r.ok) throw new Error('não foi possível ler ' + url + ' (HTTP ' + r.status + ')');
    return r.text();
  }

  async function carregarArquivos() {
    manifesto = JSON.parse(await texto('exercicios/manifesto.json'));
    await Promise.all(ESTACOES.map(async est => {
      const ex = manifesto[est.id];
      originais[est.id] = {}; ocultos[est.id] = {};
      await Promise.all(ex.arquivos.map(async a => { originais[est.id][a.nome] = await texto('exercicios/' + est.id + '/' + a.nome); }));
      await Promise.all((ex.ocultos || []).map(async o => { ocultos[est.id][o] = await texto('exercicios/' + est.id + '/' + o); }));
    }));
  }

  function carregarPython() {
    if (pyCarregando) return pyCarregando;
    pyCarregando = (async () => {
      const t0 = performance.now();
      status('Baixando o Pyodide');
      await new Promise((ok, erro) => {
        const s = document.createElement('script');
        s.src = PYODIDE + 'pyodide.js';
        s.onload = ok; s.onerror = () => erro(new Error('sem acesso ao CDN do Pyodide'));
        document.head.appendChild(s);
      });
      const p = await window.loadPyodide({ indexURL: PYODIDE });
      status('Instalando pytest e pydantic');
      await p.loadPackage(['pytest', 'pydantic']);
      p.FS.writeFile('/home/pyodide/bancada.py', await texto('bancada.py'));
      p.runPython('import os, sys; os.environ["BANCADA_TMP"] = "/tmp"; sys.path.insert(0, "/home/pyodide"); import bancada');
      py = p;
      const s = ((performance.now() - t0) / 1000).toFixed(1).replace('.', ',');
      status('Python pronto em ' + s + ' s', 'is-pronto');
      window.__bancada.carregadoEm = performance.now() - t0;
      document.querySelectorAll('.bc-rodar').forEach(b => { b.disabled = false; });
      return p;
    })().catch(e => { status('Falha ao carregar o Python: ' + e.message, 'is-erro'); pyCarregando = null; throw e; });
    return pyCarregando;
  }

  function arquivosDe(id) {
    return Object.assign({}, originais[id], estado.arquivos[id] || {});
  }

  // ---------- tela ----------
  function montarAbas() {
    const nav = $('abas');
    nav.append(el('a', { href: '#inicio' }, el('span', { class: 'n', text: '·' }), 'Início'));
    ESTACOES.forEach(est => nav.append(el('a', { href: '#' + est.id }, el('span', { class: 'n', text: String(est.n) }), est.aba)));
  }

  function montarEstacao(est) {
    const ex = manifesto[est.id];
    const sec = el('section', { class: 'sim-view', id: 'v-' + est.id });
    const head = el('div', { class: 'sim-head' },
      el('span', { class: 'sim-kicker', text: 'Estação ' + est.n }),
      el('h1', { text: est.titulo }),
      el('p', { text: est.resumo }));
    const grid = el('div', { class: 'sim-grid' });

    const guia = el('div', { class: 'sim-panel sim-col-12 bc-guia' }, el('h2', { text: 'O que fazer' }));
    const ol = el('ol', { class: 'bc-passos' });
    est.passos.forEach(p => ol.append(el('li', { text: p })));
    guia.append(ol, el('p', { class: 'sim-hint', text: est.meta }));

    const editor = el('div', { class: 'sim-panel sim-col-7 bc-col-editor' }, el('h2', { text: 'Arquivos' }));
    const tabs = el('div', { class: 'bc-arquivos', role: 'tablist' });
    const area = el('textarea', { class: 'bc-editor', spellcheck: 'false', 'aria-label': 'Editor do arquivo' });
    ex.arquivos.forEach(a => {
      const b = el('button', { type: 'button', 'data-arquivo': a.nome }, a.nome);
      if (!a.editavel) b.append(el('small', { text: 'leitura' }));
      b.addEventListener('click', () => abrirArquivo(est.id, a.nome));
      tabs.append(b);
    });
    area.addEventListener('input', () => {
      const nome = estado.abertos[est.id];
      estado.arquivos[est.id] = estado.arquivos[est.id] || {};
      estado.arquivos[est.id][nome] = area.value;
      salvarEstado();
    });
    area.addEventListener('keydown', e => {
      if (e.key === 'Tab' && !area.readOnly) {
        e.preventDefault();
        const i = area.selectionStart;
        area.setRangeText('    ', i, area.selectionEnd, 'end');
        area.dispatchEvent(new Event('input'));
      }
      if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); rodar(est.id); }
    });
    const acoes = el('div', { class: 'bc-acoes' });
    const bRodar = el('button', { type: 'button', class: 'is-primary bc-rodar' }, 'Rodar pytest');
    const bAvaliar = el('button', { type: 'button', class: 'bc-rodar' }, 'Avaliar com mutantes');
    const bRestaurar = el('button', { type: 'button' }, 'Restaurar arquivo');
    bRodar.addEventListener('click', () => rodar(est.id));
    bAvaliar.addEventListener('click', () => avaliar(est.id));
    bRestaurar.addEventListener('click', () => restaurar(est.id));
    if (!py) { bRodar.disabled = true; bAvaliar.disabled = true; }
    acoes.append(bRodar, bAvaliar, bRestaurar, el('span', { class: 'sim-hint', text: 'Ctrl+Enter roda' }));
    editor.append(tabs, area, acoes);

    const saida = el('div', { class: 'sim-panel sim-col-5 bc-col-saida' },
      el('h2', { text: 'Resultado' }),
      el('div', { class: 'bc-placar', id: 'placar-' + est.id }),
      el('pre', { class: 'sim-code bc-saida', id: 'saida-' + est.id, text: py ? 'Rode o pytest para ver o relatório.' : 'Aguardando o Python carregar.' }),
      el('div', { id: 'mutantes-' + est.id }));

    grid.append(guia, editor, saida);
    sec.append(head, grid);
    $('vistas').append(sec);
    abrirArquivo(est.id, estado.abertos[est.id] || ex.arquivos.find(a => a.editavel).nome);
    pintarPlacar(est.id);
  }

  function abrirArquivo(id, nome) {
    estado.abertos[id] = nome;
    const sec = $('v-' + id);
    const a = manifesto[id].arquivos.find(x => x.nome === nome);
    sec.querySelectorAll('.bc-arquivos button').forEach(b => b.classList.toggle('is-active', b.dataset.arquivo === nome));
    const area = sec.querySelector('.bc-editor');
    area.value = arquivosDe(id)[nome];
    area.readOnly = !a.editavel;
    salvarEstado();
  }

  function restaurar(id) {
    const nome = estado.abertos[id];
    if (!manifesto[id].arquivos.find(a => a.nome === nome).editavel) return;
    if (!window.confirm('Voltar ' + nome + ' ao conteúdo original da estação?')) return;
    if (estado.arquivos[id]) delete estado.arquivos[id][nome];
    abrirArquivo(id, nome);
  }

  function pintarPlacar(id) {
    const p = estado.placar[id];
    const alvo = $('placar-' + id);
    alvo.innerHTML = '';
    const total = manifesto[id].mutantes.length;
    const item = (valor, rotulo) => el('div', {}, el('b', { text: valor }), el('span', { text: rotulo }));
    alvo.append(item(p ? p.mortos + ' de ' + total : '- de ' + total, 'mutantes mortos (melhor)'));
    if (p && p.verificacao !== undefined) alvo.append(item(p.verificacao ? 'aprovada' : 'pendente', 'verificação'));
    pintarPlacarGeral();
  }

  function pintarPlacarGeral() {
    const tb = $('placar-geral');
    tb.innerHTML = '';
    ESTACOES.forEach(est => {
      const p = estado.placar[est.id];
      const total = manifesto[est.id].mutantes.length;
      const completo = p && p.mortos === total && p.referencia && (p.verificacao === undefined || p.verificacao);
      const tr = el('tr', {},
        el('td', {}, el('a', { href: '#' + est.id, text: est.n + ' · ' + est.aba })),
        el('td', { class: 'num', text: p ? p.mortos + ' / ' + total : '- / ' + total }),
        el('td', {}, el('span', { class: 'sim-badge' + (completo ? ' is-on' : ' is-soft'), text: completo ? 'meta atingida' : (p ? 'em andamento' : 'não avaliada') })));
      tb.append(tr);
    });
  }

  function resumoExecucao(r) {
    const partes = [];
    if (r.aprovados.length) partes.push(r.aprovados.length + ' aprovado' + (r.aprovados.length > 1 ? 's' : ''));
    if (r.reprovados.length) partes.push(r.reprovados.length + ' reprovado' + (r.reprovados.length > 1 ? 's' : ''));
    if (r.erros.length) partes.push(r.erros.length + ' com erro');
    if (r.codigo === 5) partes.push('nenhum teste coletado');
    return partes.join(', ') + ' · ' + r.ms + ' ms';
  }

  async function pronto() {
    if (py) return true;
    try { await carregarPython(); return true; } catch (e) { return false; }
  }

  async function executarPython(codigo, vars) {
    Object.entries(vars).forEach(([k, v]) => py.globals.set(k, v));
    await new Promise(r => setTimeout(r, 30)); // deixa a tela pintar o "rodando"
    return JSON.parse(py.runPython(codigo));
  }

  async function rodar(id) {
    if (ocupado || !(await pronto())) return;
    ocupado = true;
    const saida = $('saida-' + id);
    saida.textContent = 'Rodando o pytest...';
    saida.classList.remove('bc-falhou');
    try {
      const r = await executarPython('bancada.rodar_json(_aluno, _testes)', {
        _aluno: JSON.stringify(arquivosDe(id)), _testes: JSON.stringify(manifesto[id].testes_do_aluno)
      });
      saida.textContent = (r.codigo === 0 ? 'PASSOU' : 'FALHOU') + ' · ' + resumoExecucao(r) + '\n\n' + r.saida;
      saida.classList.toggle('bc-falhou', r.codigo !== 0);
    } catch (e) {
      saida.textContent = 'Erro ao rodar: ' + e.message;
    } finally { ocupado = false; }
  }

  async function avaliar(id) {
    if (ocupado || !(await pronto())) return;
    ocupado = true;
    const saida = $('saida-' + id);
    const lista = $('mutantes-' + id);
    saida.textContent = 'Avaliando: versão do aluno, versão correta e ' + manifesto[id].mutantes.length + ' mutantes...';
    saida.classList.remove('bc-falhou');
    lista.innerHTML = '';
    try {
      const r = await executarPython('bancada.avaliar_json(_ex, _aluno, _ocultos)', {
        _ex: JSON.stringify(manifesto[id]), _aluno: JSON.stringify(arquivosDe(id)), _ocultos: JSON.stringify(ocultos[id])
      });
      const linhas = [];
      linhas.push('Seus testes no código da estação: ' + (r.principal.codigo === 0 ? 'PASSOU' : 'FALHOU') + ' · ' + resumoExecucao(r.principal));
      if (r.verificacao) linhas.push('Verificação do professor sobre o seu código: ' + (r.verificacao.codigo === 0 ? 'APROVADA' : 'PENDENTE') + ' · ' + resumoExecucao(r.verificacao));
      const refOk = r.referencia.codigo === 0;
      linhas.push('Seus testes na versão correta: ' + (refOk ? 'PASSOU' : 'FALHOU') + ' · ' + resumoExecucao(r.referencia));
      if (!refOk) linhas.push('\nUm teste que reprova a versão correta está testando a coisa errada (ou ainda usa a assinatura antiga). Os mutantes só rodam depois que os testes aprovam a versão correta.\n\n' + r.referencia.saida);
      else if (r.verificacao && r.verificacao.codigo !== 0) linhas.push('\nRelatório da verificação:\n' + r.verificacao.saida);
      else if (r.principal.codigo !== 0) linhas.push('\n' + r.principal.saida);
      saida.textContent = linhas.join('\n');
      saida.classList.toggle('bc-falhou', Boolean(!refOk || r.principal.codigo !== 0 || (r.verificacao && r.verificacao.codigo !== 0)));

      const mortos = r.mutantes.filter(m => m.morto).length;
      if (refOk) {
        const ul = el('ul', { class: 'bc-mutantes' });
        r.mutantes.forEach(m => ul.append(el('li', {},
          el('code', { text: m.id }),
          el('span', { class: 'sim-badge' + (m.morto ? ' is-on' : ' is-soft'), text: m.morto ? 'morto' : 'vivo' }),
          el('span', { text: m.descricao + (m.morto && m.pegou.length ? ' · pego por ' + m.pegou[0] : '') }))));
        lista.append(ul);
      }
      const antes = estado.placar[id];
      const novo = { mortos: refOk ? mortos : 0, referencia: refOk, verificacao: r.verificacao ? r.verificacao.codigo === 0 : undefined, em: new Date().toISOString() };
      if (!antes || novo.mortos > antes.mortos || (novo.mortos === antes.mortos && novo.verificacao && !antes.verificacao)) estado.placar[id] = novo;
      salvarEstado();
      pintarPlacar(id);
    } catch (e) {
      saida.textContent = 'Erro ao avaliar: ' + e.message;
    } finally { ocupado = false; }
  }

  function exportar() {
    const linhas = ['# Evidência da bancada da Aula 07', '', 'Gerado em ' + new Date().toLocaleString('pt-BR') + '.', '',
      '| Estação | Mutantes mortos | Verificação |', '|---|---|---|'];
    ESTACOES.forEach(est => {
      const p = estado.placar[est.id];
      const total = manifesto[est.id].mutantes.length;
      linhas.push('| ' + est.n + ' · ' + est.aba + ' | ' + (p ? p.mortos : '-') + ' de ' + total + ' | ' +
        (p && p.verificacao !== undefined ? (p.verificacao ? 'aprovada' : 'pendente') : 'não se aplica') + ' |');
    });
    ESTACOES.forEach(est => {
      linhas.push('', '## Estação ' + est.n + ' · ' + est.titulo, '');
      manifesto[est.id].arquivos.filter(a => a.editavel).forEach(a => {
        linhas.push('### ' + a.nome, '', '```python', arquivosDe(est.id)[a.nome].replace(/\s+$/, ''), '```', '');
      });
    });
    const blob = new Blob([linhas.join('\n')], { type: 'text/markdown;charset=utf-8' });
    const link = el('a', { href: URL.createObjectURL(blob), download: 'evidencia_bancada.md' });
    document.body.append(link); link.click(); link.remove();
  }

  function trocarAba() {
    const h = location.hash.slice(1);
    aba = $('v-' + h) ? h : 'inicio';
    document.querySelectorAll('.sim-view').forEach(v => v.classList.toggle('is-active', v.id === 'v-' + aba));
    document.querySelectorAll('#abas a').forEach(a => a.classList.toggle('is-active', a.getAttribute('href') === '#' + aba));
    window.scrollTo(0, 0);
  }

  async function iniciar() {
    if (EMBED) document.body.classList.add('sim-embed');
    carregarEstado();
    montarAbas();
    $('btn-exportar').addEventListener('click', exportar);
    window.__bancada = { estado: () => estado, rodar, avaliar, pronto: () => !!py, carregadoEm: null };
    try {
      await carregarArquivos();
    } catch (e) {
      status('Falha ao ler os exercícios: ' + e.message, 'is-erro');
      return;
    }
    ESTACOES.forEach(montarEstacao);
    pintarPlacarGeral();
    window.addEventListener('hashchange', trocarAba);
    window.addEventListener('message', e => {
      if (e.data && e.data.bancadaAba && $('v-' + e.data.bancadaAba)) location.hash = e.data.bancadaAba;
    });
    trocarAba();
    carregarPython().catch(() => {});
  }

  document.addEventListener('DOMContentLoaded', iniciar);
})();
