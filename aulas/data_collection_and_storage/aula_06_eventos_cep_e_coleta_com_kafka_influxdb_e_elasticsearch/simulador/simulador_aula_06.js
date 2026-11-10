/* Simulador da Aula 06 (Data Collection and Storage).
   Roda inteiro no navegador e guarda o estado em localStorage.
   Rede Tatame: rede fictícia. Amostra de um décimo: 24 academias, 3.600 alunos. */
(() => {
  'use strict';

  const CHAVE = 'dcs_aula06_simulador_v1';
  const MIN = 60000, HORA = 3600000, DIA = 86400000;
  const INICIO = Date.UTC(2026, 10, 14, 11, 30); // 8h30 em São Paulo
  const TICK_MS = 250;
  const N_PART = 6;
  const RETENCAO = 3000;
  const ALUNOS_POR = 150;
  const RAZAO_GZIP = 6.1;
  const CAP = { 'cep': 1200, 'sink-influxdb': 600, 'sink-lake': 600 };
  const VAZAO_OUTBOX = 1200; // eventos por minuto simulado no retorno do cluster
  const OUTBOX_MAX = 6000;

  const REGIOES = [
    { id: 'sa-saopaulo', pre: 'BR-SAO', n: 10, fuso: -3, cidade: 'São Paulo' },
    { id: 'us-virginia', pre: 'US-VIR', n: 7, fuso: -5, cidade: 'Virgínia' },
    { id: 'eu-estocolmo', pre: 'SE-STO', n: 5, fuso: 1, cidade: 'Estocolmo' },
    { id: 'ap-sydney', pre: 'AU-SYD', n: 2, fuso: 11, cidade: 'Sydney' },
  ];
  const ACADEMIAS = [];
  REGIOES.forEach((r, ri) => {
    r.acad = [];
    for (let i = 1; i <= r.n; i++) {
      const a = { cod: `${r.pre}-${String(i).padStart(3, '0')}`, reg: ri, idx: ACADEMIAS.length, nome: `Tatame ${r.cidade} ${String(i).padStart(2, '0')}` };
      ACADEMIAS.push(a); r.acad.push(a);
    }
  });
  const ACAD_POR_COD = Object.fromEntries(ACADEMIAS.map(a => [a.cod, a]));
  const N_ALUNOS = ACADEMIAS.length * ALUNOS_POR;

  // Proporção dos eventos de aluno (soma 100).
  const TIPOS = [
    ['app_aberto', 54], ['video_assistido', 30], ['reserva_aula', 8], ['checkin', 4],
    ['cobranca_aprovada', 3.35], ['cobranca_falhou', 0.3], ['aula_experimental', 0.15],
    ['graduacao', 0.08], ['matricula', 0.07], ['cancelamento', 0.05],
  ];
  const TIPO_IDX = Object.fromEntries(TIPOS.map((t, i) => [t[0], i]));
  const ORIGEM = { checkin: 'catraca', cobranca_aprovada: 'gestao', cobranca_falhou: 'gestao', matricula: 'gestao', cancelamento: 'gestao', graduacao: 'gestao', aula_experimental: 'gestao' };
  const TURMAS = ['adulto-fundamentos', 'adulto-avancado', 'kids-4-6', 'kids-7-10', 'juvenil', 'feminino'];
  const FAIXAS = [['branca', 55], ['azul', 25], ['roxa', 12], ['marrom', 5], ['preta', 3]];
  const VALORES = ['ate-50', '50-100', '100-150'];
  const DISPOSITIVOS = ['catraca-1', 'leitor-facial-1'];
  // Curva do dia por hora local; a média é normalizada para 1.
  const CURVA = (() => {
    const c = [.1, .1, .1, .1, .1, .2, 1.2, 1.3, 1.1, .8, .8, .8, 1, 1, .7, .7, .8, 2.4, 2.8, 2.8, 2.4, 1.6, .6, .4];
    const m = c.reduce((a, b) => a + b, 0) / 24;
    return c.map(x => x / m);
  })();

  // Motivos de cancelamento, com peso por região (SP, VA, STO, SYD).
  const MOTIVOS = [
    ['achou o preço da mensalidade alto depois do reajuste', [5, 3, 2, 2]],
    ['preço alto e pouca turma no horário da noite', [3, 2, 1, 1]],
    ['mudou de cidade e não há academia da rede perto', [2, 3, 2, 3]],
    ['lesão no joelho, médico pediu pausa de seis meses', [2, 2, 2, 2]],
    ['horário das turmas não encaixa no trabalho', [3, 3, 2, 2]],
    ['trocou por outra modalidade, foi para a musculação', [2, 2, 1, 1]],
    ['inverno escuro e frio, parou de sair de casa à noite', [0, 1, 6, 0]],
    ['deslocamento longo no inverno, a academia fica longe do metrô', [0, 0, 4, 0]],
    ['a turma kids ficou cheia e o filho perdeu o interesse', [2, 2, 1, 2]],
    ['cobrança falhou três vezes e a matrícula foi encerrada', [2, 2, 1, 1]],
    ['preço', [0.3, 0, 0, 0]],
    ['professor da turma mudou e a aula perdeu o ritmo', [1, 2, 1, 1]],
    ['viagem longa a trabalho, volta no ano que vem', [1, 1, 1, 2]],
    ['academia concorrente abriu mais perto de casa com preço menor', [2, 1, 0, 2]],
  ];
  const STOP = new Set('a o e de da do das dos em no na nos nas um uma por para com que foi ficou fica à às ao não há se seu sua mais pouca três seis vem como'.split(' '));

  const NOMES = ['Marina', 'Lucas', 'Chloe', 'Erik', 'Beatriz', 'Noah', 'Astrid', 'Rafael', 'Olivia', 'Mateus', 'Ingrid', 'Liam', 'Helena', 'Oscar', 'Camila', 'Ethan', 'Freja', 'Thiago', 'Isla', 'Gustavo', 'Sofia', 'Axel', 'Laura', 'Henrique'];
  const SOBRENOMES = ['Costa', 'Martin', 'Lindqvist', 'Oliveira', 'Walker', 'Souza', 'Berg', 'Almeida', 'Nguyen', 'Ferreira', 'Johansson', 'Ribeiro', 'Clark', 'Santos', 'Nyström', 'Carvalho', 'Hughes', 'Lima', 'Ekström', 'Gomes', 'Kelly', 'Rocha', 'Sandberg', 'Moraes'];

  const PERGUNTAS = [
    'Por que os alunos cancelam na região eu-estocolmo?',
    'Quais academias concentram os cancelamentos do período?',
    'Quantos alunos únicos passaram pela rede no período?',
  ];

  const REGRAS = {
    cobranca_reincidente: { rotulo: 'janela', opcoes: [1, 3, 7, 14], un: 'dias', txt: 'Sequência: 2 cobranca_falhou do mesmo aluno dentro da janela.' },
    academia_silenciosa: { rotulo: 'silêncio', opcoes: [2, 5, 15], un: 'min', txt: 'Ausência: nenhum heartbeat da academia pelo tempo indicado.' },
    pico_de_cancelamentos: { rotulo: 'limiar', opcoes: [2, 3, 5], un: 'em 24 h', txt: 'Limiar em janela: cancelamentos da mesma academia em 24 horas.' },
    experimental_sem_matricula: { rotulo: 'prazo', opcoes: [1, 3, 7], un: 'dias', txt: 'Sequência com ausência: aula experimental sem matrícula no prazo.' },
  };

  // ------------------------------------------------------------ utilidades
  const $ = id => document.getElementById(id);
  const fmt = n => Math.round(n).toLocaleString('pt-BR');
  const fmt1 = n => n.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const p2 = n => String(n).padStart(2, '0');
  const iso = t => new Date(t).toISOString();
  const dataUTC = t => { const d = new Date(t); return `${d.getUTCFullYear()}-${p2(d.getUTCMonth() + 1)}-${p2(d.getUTCDate())}`; };
  const horaUTC = t => p2(new Date(t).getUTCHours());
  const curto = t => { const d = new Date(t); return `${p2(d.getUTCDate())}/${p2(d.getUTCMonth() + 1)} ${p2(d.getUTCHours())}:${p2(d.getUTCMinutes())}`; };
  const mesUTC = t => { const d = new Date(t); return `${d.getUTCFullYear()}.${p2(d.getUTCMonth() + 1)}`; };
  const duracao = min => min < 90 ? `${fmt1(min)} min` : min < 2880 ? `${fmt1(min / 60)} h` : `${fmt1(min / 1440)} dias`;

  function mix(h) { h ^= h >>> 16; h = Math.imul(h, 0x85ebca6b); h ^= h >>> 13; h = Math.imul(h, 0xc2b2ae35); h ^= h >>> 16; return h >>> 0; }
  function fnv(s, semente) { let h = (0x811c9dc5 ^ semente) >>> 0; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193); } return mix(h); }
  const hashInt = s => fnv(s, 0);
  const hash16 = s => fnv(s, 0x9e3779b9).toString(16).padStart(8, '0') + fnv(s, 0x51ed270b).toString(16).padStart(8, '0');
  function uuid() {
    if (window.crypto && crypto.randomUUID) return crypto.randomUUID();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => { const r = Math.random() * 16 | 0; return (c === 'x' ? r : (r & 3 | 8)).toString(16); });
  }
  function poisson(l) {
    if (l <= 0) return 0;
    if (l > 30) { const u = Math.random() || 1e-9, v = Math.random(); return Math.max(0, Math.round(l + Math.sqrt(l) * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v))); }
    const L = Math.exp(-l); let k = 0, p = 1;
    do { k++; p *= Math.random(); } while (p > L);
    return k - 1;
  }
  function sorteio(pares, rnd = Math.random) { let tot = 0; for (const p of pares) tot += p[1]; let x = rnd() * tot; for (const p of pares) { x -= p[1]; if (x <= 0) return p[0]; } return pares[pares.length - 1][0]; }
  function semente(a) { return () => { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
  const nomeAluno = i => `${NOMES[i % 24]} ${SOBRENOMES[(i * 7 + Math.floor(i / 24)) % 24]}`;
  const hashAluno = (acad, n) => hash16(`${acad.cod}:${n}`);
  const tamanho = e => JSON.stringify(e).length;
  const motivoDe = (ri, rnd) => sorteio(MOTIVOS.map(m => [m[0], m[1][ri]]), rnd);

  // ------------------------------------------------------------ estado
  let S;
  function novoEstado() {
    return {
      v: 1, relogio: INICIO, vel: 1, rodando: false,
      total: { gerados: 0, kafka: 0, descartados: 0 },
      reg: REGIOES.map(() => ({ up: true, outbox: [], hbAcc: 0, hbRod: 0, flushAcc: 0, taxa: 0 })),
      kafka: {
        part: Array.from({ length: N_PART }, () => ({ base: 0, recs: [] })),
        grupos: Object.fromEntries(Object.keys(CAP).map(g => [g, { pausado: false, off: Array(N_PART).fill(0), perdidos: 0, acc: 0 }])),
      },
      retries: [], prospects: [],
      cep: {
        regras: { cobranca_reincidente: { on: true, p: 7 }, academia_silenciosa: { on: true, p: 5 }, pico_de_cancelamentos: { on: true, p: 3 }, experimental_sem_matricula: { on: true, p: 7 } },
        marca: 0, lidos: 0, atrasados: 0, falhas: {}, hb: {}, silenciosa: {}, cancel: {}, pend: {}, alertas: [], n: 0,
      },
      influx: { tagAluno: false, min: [{}, {}, {}, {}], late: [{}, {}, {}, {}], hbDisp: {}, series: {}, seriesAluno: [], linhas: [], pontos: 0, marca: 0, janela: 60 },
      lake: { lote: 5, part: 'evento', buf: {}, objetos: [], nObj: 0, bytes: 0, eventos: 0, atrasoSoma: 0, atrasoN: 0, previa: [], fech: [], desde: INICIO },
      es: { indices: {}, docs: [], exatos: [], hll: { 8: [], 10: [], 12: [], 14: [] }, nDocs: 0, historico: false, relatorio: [], p: 14 },
      manuais: [],
      ms: {
        m1: { evId: null, part: null, off: null, localizado: false, mesma: false },
        m2: { pausadoMin: 0, lagMax: 0, retomouEm: null, drenagem: null },
        m3: { foraMin: 0, outboxMax: 0, restaurouEm: null, escoou: null, silencio: false, atrasados: 0 },
        m4: { alerta: false, janelas: [] },
        m5: { antes: null, max: 0, ligou: false, desligou: false },
        m6: { lotes: {}, trocouPart: false },
        m7: { busca: null, p8: null, p14: null, exato: null, historico: false, influx13: false },
      },
      respostas: {}, grupo: '',
    };
  }

  let seriesAluno = new Set();   // espelho em memória de S.influx.seriesAluno
  let exatos = new Set();        // espelho de S.es.exatos
  let manuaisIds = new Set();
  let ultimoSalvo = 0, tamanhoSalvo = 0;

  function salvar() {
    try {
      const k = S.kafka;
      const copia = Object.assign({}, S, {
        rodando: false,
        kafka: {
          part: k.part.map(p => { const corte = Math.max(0, p.recs.length - 40); return { base: p.base + corte, recs: p.recs.slice(corte) }; }),
          grupos: k.grupos,
        },
        influx: Object.assign({}, S.influx, { seriesAluno: [...seriesAluno] }),
        es: Object.assign({}, S.es, { exatos: [...exatos] }),
        lake: Object.assign({}, S.lake, { buf: {} }),
      });
      let txt = JSON.stringify(copia);
      if (txt.length > 3500000) { copia.reg = copia.reg.map(r => Object.assign({}, r, { outbox: r.outbox.slice(-500) })); txt = JSON.stringify(copia); }
      localStorage.setItem(CHAVE, txt);
      tamanhoSalvo = txt.length;
    } catch (e) { tamanhoSalvo = -1; }
    ultimoSalvo = Date.now();
  }

  function carregar() {
    S = novoEstado();
    try {
      const txt = localStorage.getItem(CHAVE);
      if (txt) {
        const d = JSON.parse(txt);
        if (d && d.v === 1) {
          const base = novoEstado();
          S = Object.assign(base, d);
          for (const m of Object.keys(base.ms)) S.ms[m] = Object.assign(novoEstado().ms[m], d.ms && d.ms[m]);
          tamanhoSalvo = txt.length;
        }
      }
    } catch (e) { S = novoEstado(); }
    S.rodando = false;
    // o que não foi salvo do log já foi lido: os offsets recomeçam no que restou
    S.kafka.part.forEach((p, i) => { for (const g of Object.values(S.kafka.grupos)) if (g.off[i] < p.base) g.off[i] = p.base; });
    seriesAluno = new Set(S.influx.seriesAluno); S.influx.seriesAluno = [];
    exatos = new Set(S.es.exatos); S.es.exatos = [];
    manuaisIds = new Set(S.manuais.map(m => m.id));
  }

  // ------------------------------------------------------------ geração
  function eventoAluno(acad, n, tipo, te, extras) {
    const r = REGIOES[acad.reg];
    const ev = {
      event_id: uuid(), tipo, ocorrido_em: iso(te), regiao: r.id, academia: acad.cod,
      aluno: n < 0 ? 'p' + hash16('prospecto' + Math.random()).slice(1) : hashAluno(acad, n),
      turma: TURMAS[(n < 0 ? 0 : n) % TURMAS.length], faixa: n < 0 ? 'branca' : FAIXAS[[0, 0, 0, 0, 0, 1, 1, 2, 3, 4][n % 10]][0],
      origem: ORIGEM[tipo] || 'app',
    };
    if (tipo === 'cancelamento') ev.motivo = (extras && extras.motivo) || motivoDe(acad.reg);
    if (tipo.startsWith('cobranca')) ev.faixa_valor = VALORES[(n < 0 ? 0 : n) % 3];
    return ev;
  }
  function eventoHb(acad, disp, te) {
    return { event_id: uuid(), tipo: 'heartbeat', ocorrido_em: iso(te), regiao: REGIOES[acad.reg].id, academia: acad.cod, dispositivo: DISPOSITIVOS[disp], origem: 'dispositivo', latencia_ms: 8 + Math.floor(Math.random() * 230) };
  }

  function gerar(t0, t1, dtMin) {
    const lote = [];
    const span = t1 - t0;
    REGIOES.forEach((r, ri) => {
      const st = S.reg[ri];
      const hLocal = ((new Date(t0).getUTCHours() + r.fuso) % 24 + 24) % 24;
      const n = poisson(r.n * ALUNOS_POR * 10 / 1440 * CURVA[hLocal] * dtMin);
      for (let i = 0; i < n; i++) {
        const acad = r.acad[Math.floor(Math.random() * r.n)];
        const tipo = sorteio(TIPOS);
        const te = t0 + Math.random() * span;
        if (tipo === 'aula_experimental') {
          const ev = eventoAluno(acad, -1, tipo, te);
          lote.push({ e: ev, t: te, ai: -1, ri });
          if (Math.random() < .55 && S.prospects.length < 400) S.prospects.push({ t: te + (1 + Math.random() * 5) * DIA, ac: acad.idx, aluno: ev.aluno });
        } else {
          const al = Math.floor(Math.random() * ALUNOS_POR);
          lote.push({ e: eventoAluno(acad, al, tipo, te), t: te, ai: acad.idx * ALUNOS_POR + al, ri });
          if (tipo === 'cobranca_falhou' && S.retries.length < 600) S.retries.push({ t: te + 2 * DIA, ac: acad.idx, al, n: 1 });
        }
      }
      st.hbAcc += r.n * 2 * 2 * dtMin;
      const nh = Math.floor(st.hbAcc); st.hbAcc -= nh;
      for (let i = 0; i < nh; i++) {
        const k = st.hbRod++ % (r.n * 2);
        const te = t0 + Math.random() * span;
        lote.push({ e: eventoHb(r.acad[k >> 1], k & 1, te), t: te, ai: -1, ri });
      }
      st.taxa = st.taxa * .7 + ((n + nh) / dtMin) * .3;
    });
    if (S.retries.length) {
      const fica = [];
      for (const x of S.retries) {
        if (x.t > t1) { fica.push(x); continue; }
        const acad = ACADEMIAS[x.ac], falhou = Math.random() < .4;
        lote.push({ e: eventoAluno(acad, x.al, falhou ? 'cobranca_falhou' : 'cobranca_aprovada', x.t), t: x.t, ai: x.ac * ALUNOS_POR + x.al, ri: acad.reg });
        if (falhou && x.n < 2) fica.push({ t: x.t + 2 * DIA, ac: x.ac, al: x.al, n: x.n + 1 });
      }
      S.retries = fica;
    }
    if (S.prospects.length) {
      const fica = [];
      for (const x of S.prospects) {
        if (x.t > t1) { fica.push(x); continue; }
        const acad = ACADEMIAS[x.ac];
        const ev = eventoAluno(acad, -1, 'matricula', x.t); ev.aluno = x.aluno;
        lote.push({ e: ev, t: x.t, ai: -1, ri: acad.reg });
      }
      S.prospects = fica;
    }
    lote.sort((a, b) => a.t - b.t);
    for (const x of lote) publicar(x, x.t);
  }

  function publicar(x, chegada) {
    S.total.gerados++;
    const st = S.reg[x.ri];
    if (!st.up) {
      st.outbox.push({ e: x.e, t: x.t, ai: x.ai });
      if (st.outbox.length > OUTBOX_MAX) { st.outbox.shift(); S.total.descartados++; }
      return null;
    }
    return kafkaPub(x.e, x.t, x.ai, chegada);
  }

  function kafkaPub(e, t, ai, chegada) {
    const p = hashInt(e.academia) % N_PART, part = S.kafka.part[p];
    const o = part.base + part.recs.length;
    part.recs.push({ o, e, t, a: chegada, ai });
    if (part.recs.length > RETENCAO + 300) { const corte = part.recs.length - RETENCAO; part.recs.splice(0, corte); part.base += corte; }
    S.total.kafka++;
    return { p, o };
  }

  function escoarOutbox(dtMin, agora) {
    S.reg.forEach(st => {
      if (!st.up || !st.outbox.length) { st.flushAcc = 0; return; }
      st.flushAcc += VAZAO_OUTBOX * dtMin;
      const n = Math.min(st.outbox.length, Math.floor(st.flushAcc)); st.flushAcc -= n;
      const sai = st.outbox.splice(0, n);
      for (const x of sai) kafkaPub(x.e, x.t, x.ai, agora);
    });
  }

  // ------------------------------------------------------------ consumidores
  const lagDe = g => S.kafka.part.reduce((s, p, i) => s + Math.max(0, p.base + p.recs.length - Math.max(g.off[i], p.base)), 0);

  function consumir(dtMin) {
    for (const [nome, g] of Object.entries(S.kafka.grupos)) {
      if (g.pausado) { g.acc = 0; continue; }
      g.acc = Math.min(g.acc + CAP[nome] * dtMin, CAP[nome] * dtMin + 1);
      let n = Math.floor(g.acc); g.acc -= n;
      const ler = nome === 'cep' ? cepLer : nome === 'sink-influxdb' ? influxLer : lakeLer;
      while (n > 0) {
        let melhor = -1, ma = Infinity;
        for (let i = 0; i < N_PART; i++) {
          const p = S.kafka.part[i];
          if (g.off[i] < p.base) { g.perdidos += p.base - g.off[i]; g.off[i] = p.base; }
          const k = g.off[i] - p.base;
          if (k < p.recs.length && p.recs[k].a < ma) { ma = p.recs[k].a; melhor = i; }
        }
        if (melhor < 0) break;
        const p = S.kafka.part[melhor];
        ler(p.recs[g.off[melhor] - p.base]);
        g.off[melhor]++; n--;
      }
    }
  }

  // ------------------------------------------------------------ CEP
  function alerta(regra, chave, texto, evs) {
    const c = S.cep; c.n++;
    const a = { id: c.n, regra, quando: c.marca, chave, texto, resolvido: null, evs: evs.map(x => ({ tipo: x.tipo, ocorrido_em: x.ocorrido_em, event_id: x.event_id })) };
    c.alertas.unshift(a); if (c.alertas.length > 80) c.alertas.pop();
    if (regra === 'cobranca_reincidente' && evs.some(x => manuaisIds.has(x.event_id))) { S.ms.m4.alerta = true; if (!S.ms.m4.janelas.includes(c.regras[regra].p)) S.ms.m4.janelas.push(c.regras[regra].p); }
    if (regra === 'academia_silenciosa' && chave.startsWith('SE-STO')) S.ms.m3.silencio = true;
    return a;
  }

  function cepLer(rec) {
    const c = S.cep, e = rec.e, t = rec.t, R = c.regras;
    c.lidos++;
    if (t < c.marca - 5 * MIN) { c.atrasados++; if (e.regiao === 'eu-estocolmo') S.ms.m3.atrasados++; }
    if (t > c.marca) c.marca = t;
    if (e.tipo === 'heartbeat') {
      if (!(c.hb[e.academia] > t)) c.hb[e.academia] = t;
      const idA = c.silenciosa[e.academia];
      if (idA && t > c.marca - R.academia_silenciosa.p * MIN) {
        const a = c.alertas.find(x => x.id === idA); if (a) a.resolvido = t;
        delete c.silenciosa[e.academia];
      }
    } else if (e.tipo === 'cobranca_falhou') {
      if (!R.cobranca_reincidente.on) return;
      const lista = (c.falhas[e.aluno] || []).filter(x => t - x.t <= R.cobranca_reincidente.p * DIA && t >= x.t);
      lista.push({ t, tipo: e.tipo, ocorrido_em: e.ocorrido_em, event_id: e.event_id });
      if (lista.length >= 2) { alerta('cobranca_reincidente', e.aluno, `Aluno ${e.aluno} da ${e.academia} teve ${lista.length} cobranças recusadas em ${R.cobranca_reincidente.p} dias.`, lista); delete c.falhas[e.aluno]; }
      else c.falhas[e.aluno] = lista;
    } else if (e.tipo === 'cancelamento') {
      if (!R.pico_de_cancelamentos.on) return;
      const lista = (c.cancel[e.academia] || []).filter(x => t - x.t <= DIA && t >= x.t);
      lista.push({ t, tipo: e.tipo, ocorrido_em: e.ocorrido_em, event_id: e.event_id });
      if (lista.length >= R.pico_de_cancelamentos.p) { alerta('pico_de_cancelamentos', e.academia, `${e.academia} teve ${lista.length} cancelamentos em 24 horas.`, lista); delete c.cancel[e.academia]; }
      else c.cancel[e.academia] = lista;
    } else if (e.tipo === 'aula_experimental') {
      c.pend[e.aluno] = { t, tipo: e.tipo, ocorrido_em: e.ocorrido_em, event_id: e.event_id, academia: e.academia };
    } else if (e.tipo === 'matricula') {
      delete c.pend[e.aluno];
    }
  }

  function cepRelogio() {
    const c = S.cep, R = c.regras;
    if (!c.marca) return;
    if (R.academia_silenciosa.on) {
      for (const a of ACADEMIAS) {
        if (c.hb[a.cod] === undefined) { c.hb[a.cod] = c.marca; continue; }
        if (!c.silenciosa[a.cod] && c.marca - c.hb[a.cod] > R.academia_silenciosa.p * MIN) {
          const al = alerta('academia_silenciosa', a.cod, `${a.cod} (${REGIOES[a.reg].id}) está sem heartbeat há mais de ${R.academia_silenciosa.p} minutos.`, [{ tipo: 'heartbeat (último recebido)', ocorrido_em: iso(c.hb[a.cod]), event_id: 'sem evento novo' }]);
          c.silenciosa[a.cod] = al.id;
        }
      }
    }
    for (const k of Object.keys(c.pend)) {
      const x = c.pend[k];
      if (c.marca - x.t > R.experimental_sem_matricula.p * DIA) {
        if (R.experimental_sem_matricula.on) alerta('experimental_sem_matricula', k, `Aula experimental na ${x.academia} sem matrícula depois de ${R.experimental_sem_matricula.p} dias.`, [x]);
        delete c.pend[k];
      }
    }
    for (const k of Object.keys(c.falhas)) if (c.marca - c.falhas[k][c.falhas[k].length - 1].t > 15 * DIA) delete c.falhas[k];
  }

  // ------------------------------------------------------------ InfluxDB
  function influxLer(rec) {
    const ix = S.influx, e = rec.e, t = rec.t;
    if (t > ix.marca) ix.marca = t;
    ix.pontos++;
    const ri = ACAD_POR_COD[e.academia].reg;
    ix.series[e.academia + '|' + e.tipo] = 1;
    if (e.tipo === 'heartbeat') {
      const k = e.academia + '/' + e.dispositivo;
      if (!(ix.hbDisp[k] > t)) ix.hbDisp[k] = t;
      if (ix.pontos % 25) return;
    } else {
      const m = Math.floor(t / MIN);
      ix.min[ri][m] = (ix.min[ri][m] || 0) + 1;
      if (t < ix.marca - 5 * MIN) ix.late[ri][m] = 1;
      if (ix.tagAluno && rec.ai >= 0) seriesAluno.add(rec.ai * 10 + TIPO_IDX[e.tipo]);
    }
    const tagAl = ix.tagAluno && e.aluno ? `,aluno=${e.aluno}` : '';
    ix.linhas.push(`eventos,regiao=${e.regiao},academia=${e.academia},tipo=${e.tipo}${tagAl} contagem=1i ${Math.floor(t)}000000`);
    if (ix.linhas.length > 9) ix.linhas.shift();
  }

  function influxPoda() {
    const lim = Math.floor(S.relogio / MIN) - 240;
    for (const mapa of [...S.influx.min, ...S.influx.late]) for (const k of Object.keys(mapa)) if (+k < lim) delete mapa[k];
  }

  const nSeries = () => Object.keys(S.influx.series).length + seriesAluno.size;

  // ------------------------------------------------------------ object storage
  function lakeLer(rec) {
    const lk = S.lake, e = rec.e;
    lk.eventos++;
    const w = Math.floor(rec.a / (lk.lote * MIN));
    const ref = lk.part === 'evento' ? rec.t : rec.a;
    const k = `${w}|${e.regiao}|${dataUTC(ref)}|${horaUTC(ref)}`;
    const b = lk.buf[k] || (lk.buf[k] = { w, n: 0, bytes: 0, somaT: 0, prim: [], evs: [] });
    b.n++; b.bytes += tamanho(e); b.somaT += rec.t;
    if (b.prim.length < 3) b.prim.push(e);
    if (e.tipo !== 'heartbeat') b.evs.push(rec);
  }

  function lakeFechar(tudo) {
    const lk = S.lake, wAtual = Math.floor(S.relogio / (lk.lote * MIN));
    for (const k of Object.keys(lk.buf)) {
      const b = lk.buf[k];
      if (!tudo && b.w >= wAtual) continue;
      const [, regiao, data, hora] = k.split('|');
      lk.nObj++;
      const o = { chave: `regiao=${regiao}/data=${data}/hora=${hora}/lote-${String(lk.nObj).padStart(6, '0')}.jsonl.gz`, n: b.n, bytes: b.bytes, gz: Math.round(b.bytes / RAZAO_GZIP), fechado: S.relogio };
      lk.objetos.unshift(o); if (lk.objetos.length > 60) lk.objetos.pop();
      lk.bytes += b.bytes; lk.atrasoSoma += b.n * S.relogio - b.somaT; lk.atrasoN += b.n;
      lk.previa = b.prim; lk.fech.push(S.relogio);
      esIndexar(b.evs);
      delete lk.buf[k];
    }
    const lim = S.relogio - HORA;
    while (lk.fech.length && lk.fech[0] < lim) lk.fech.shift();
    if (lk.fech.length > 4000) lk.fech.splice(0, lk.fech.length - 4000);
  }

  function lakeResumo() {
    const lk = S.lake;
    const horaCheia = S.relogio - lk.desde >= HORA;
    return {
      teorico: REGIOES.length * 1440 / lk.lote,
      observado: horaCheia ? lk.fech.length * 24 : null,
      atraso: lk.atrasoN ? lk.atrasoSoma / lk.atrasoN / MIN : null,
    };
  }

  function lakeConfig(campo, valor) {
    const lk = S.lake;
    lakeFechar(true);
    const r = lakeResumo();
    S.ms.m6.lotes[`${lk.lote} min, por ${lk.part === 'evento' ? 'data do evento' : 'data de chegada'}`] = { obj: r.observado || r.teorico, atraso: r.atraso };
    if (campo === 'part') S.ms.m6.trocouPart = true;
    lk[campo] = valor; lk.fech = []; lk.atrasoSoma = 0; lk.atrasoN = 0; lk.desde = S.relogio;
  }

  // ------------------------------------------------------------ Elasticsearch
  function hllAdd(s) {
    const h1 = fnv(s, 0x1b873593), h2 = fnv(s, 0x7ed55d16);
    for (const p of [8, 10, 12, 14]) {
      const reg = S.es.hll[p], idx = h1 >>> (32 - p);
      const resto = ((h1 << p) | (h2 >>> (32 - p))) >>> 0;
      const rank = resto === 0 ? 33 : Math.clz32(resto) + 1;
      if (!(reg[idx] >= rank)) reg[idx] = rank;
    }
  }
  function hllEstimar(p) {
    const m = 1 << p, reg = S.es.hll[p];
    let soma = 0, zeros = 0;
    for (let i = 0; i < m; i++) { const r = reg[i] || 0; if (!r) zeros++; soma += Math.pow(2, -r); }
    let e = (0.7213 / (1 + 1.079 / m)) * m * m / soma;
    if (e <= 2.5 * m && zeros) e = m * Math.log(m / zeros);
    return e;
  }
  function esIndice(nome) { return S.es.indices[nome] || (S.es.indices[nome] = { docs: 0, shards: [0, 0, 0] }); }

  function esIndexar(recs) {
    const es = S.es;
    for (const rec of recs) {
      const e = rec.e, ind = esIndice('tatame-eventos-' + mesUTC(rec.t));
      ind.docs++; ind.shards[hashInt(e.event_id) % 3]++; es.nDocs++;
      if (rec.ai >= 0 && !exatos.has(rec.ai)) { exatos.add(rec.ai); hllAdd(e.aluno); }
      if (e.tipo === 'cancelamento') {
        es.docs.unshift({ id: e.event_id, t: rec.t, regiao: e.regiao, academia: e.academia, motivo: e.motivo });
        if (es.docs.length > 1500) es.docs.pop();
      }
    }
  }

  function carregarHistorico() {
    const es = S.es;
    if (es.historico) return;
    const rnd = semente(20261114);
    const rel = [];
    let ex = 0;
    for (let k = 13; k >= 1; k--) {
      const d = new Date(Date.UTC(2026, 10 - k, 1)), ano = d.getUTCFullYear(), mes = d.getUTCMonth() + 1;
      const dias = new Date(Date.UTC(ano, mes, 0)).getUTCDate();
      const linha = { mes: `${ano}-${p2(mes)}`, ativos: 0, matriculas: 0, cancelamentos: 0, checkins: 0, regioes: {} };
      const ind = esIndice(`tatame-eventos-${ano}.${p2(mes)}`);
      REGIOES.forEach((r, ri) => {
        const ativos = Math.round(r.n * ALUNOS_POR * (0.86 + 0.14 * (13 - k) / 12));
        const sul = r.fuso === -3 || r.fuso === 11;
        let txM = 0.035 + (mes === 1 ? 0.02 : 0) + (mes === 8 ? 0.008 : 0) + (sul && mes === 3 ? 0.01 : 0);
        let txC = 0.028 + (mes === 12 || mes === 7 ? 0.01 : 0) + (r.id === 'eu-estocolmo' && (mes >= 11 || mes <= 2) ? 0.018 : 0);
        txM *= 0.9 + rnd() * 0.2; txC *= 0.9 + rnd() * 0.2;
        const mat = Math.round(ativos * txM), can = Math.round(ativos * txC), chk = Math.round(ativos * 0.4 * dias);
        linha.ativos += ativos; linha.matriculas += mat; linha.cancelamentos += can; linha.checkins += chk;
        linha.regioes[r.id] = { ativos, matriculas: mat, cancelamentos: can };
        const docs = ativos * 10 * dias;
        ind.docs += docs; es.nDocs += docs;
        const terco = Math.floor(docs / 3), j = Math.round((rnd() - .5) * docs * .004);
        ind.shards[0] += terco + j; ind.shards[1] += terco - j; ind.shards[2] += docs - 2 * terco;
        for (let i = 0; i < Math.min(can, 12); i++) {
          const acad = r.acad[Math.floor(rnd() * r.n)];
          const t = Date.UTC(ano, mes - 1, 1 + Math.floor(rnd() * dias), Math.floor(rnd() * 24));
          es.docs.push({ id: `hist-${ano}${p2(mes)}-${r.pre}-${p2(i)}`, t, regiao: r.id, academia: acad.cod, motivo: motivoDe(ri, rnd) });
        }
        for (let i = 0; i < can && ex < 2400; i++, ex++) { exatos.add(N_ALUNOS + ex); hllAdd('ex-aluno-' + ex); }
      });
      rel.push(linha);
    }
    for (let i = 0; i < N_ALUNOS; i++) if (!exatos.has(i)) { exatos.add(i); hllAdd(hashAluno(ACADEMIAS[Math.floor(i / ALUNOS_POR)], i % ALUNOS_POR)); }
    es.docs.sort((a, b) => b.t - a.t);
    es.relatorio = rel; es.historico = true; S.ms.m7.historico = true;
  }

  const tokenizar = s => s.toLowerCase().replace(/[^\p{L}\p{N}\s]/gu, ' ').split(/\s+/).filter(Boolean);

  function bm25(consulta, docs) {
    const k1 = 1.2, b = 0.75, termos = tokenizar(consulta);
    const toks = docs.map(d => tokenizar(d.motivo));
    const N = docs.length, avgdl = N ? toks.reduce((s, t) => s + t.length, 0) / N : 0;
    const info = termos.map(termo => { const n = toks.filter(t => t.includes(termo)).length; return { termo, n, idf: Math.log(1 + (N - n + .5) / (n + .5)) }; });
    const res = [];
    docs.forEach((d, i) => {
      let s = 0;
      for (const x of info) { if (!x.n) continue; const f = toks[i].filter(t => t === x.termo).length; if (f) s += x.idf * f * (k1 + 1) / (f + k1 * (1 - b + b * toks[i].length / avgdl)); }
      if (s > 0) res.push({ d, s, dl: toks[i].length });
    });
    res.sort((a, b2) => b2.s - a.s || b2.d.t - a.d.t);
    return { res, info, N, avgdl };
  }

  function termosFrequentes(docs, n) {
    const c = {};
    for (const d of docs) for (const t of new Set(tokenizar(d.motivo))) if (!STOP.has(t) && t.length > 2) c[t] = (c[t] || 0) + 1;
    return Object.entries(c).sort((a, b) => b[1] - a[1]).slice(0, n).map(([termo, docsComTermo]) => ({ termo, docs: docsComTermo }));
  }

  function montarContexto(i) {
    const es = S.es, ctx = { pergunta: PERGUNTAS[i], fonte: 'Elasticsearch, índices tatame-eventos-*', periodo: es.historico ? 'outubro de 2025 até o relógio do simulador' : 'só o que foi simulado nesta sessão' };
    if (i === 0) {
      const docs = es.docs.filter(d => d.regiao === 'eu-estocolmo');
      const termos = termosFrequentes(docs, 6);
      const r = bm25(termos.slice(0, 3).map(t => t.termo).join(' '), docs);
      ctx.agregacoes = { cancelamentos_com_motivo_na_regiao: docs.length, termos_mais_frequentes: termos, cancelamentos_por_mes: es.relatorio.map(l => ({ mes: l.mes, eu_estocolmo: l.regioes['eu-estocolmo'].cancelamentos, rede: l.cancelamentos })) };
      const vistos = new Set();
      ctx.documentos = r.res.filter(x => !vistos.has(x.d.motivo) && vistos.add(x.d.motivo)).slice(0, 5).map(x => ({ id: x.d.id, academia: x.d.academia, mes: mesUTC(x.d.t), motivo: x.d.motivo, bm25: +x.s.toFixed(3) }));
      ctx.nota_da_recuperacao = 'um documento por motivo distinto, na ordem do BM25';
    } else if (i === 1) {
      const c = {};
      for (const d of es.docs) c[d.academia] = (c[d.academia] || 0) + 1;
      ctx.agregacoes = { cancelamentos_com_motivo: es.docs.length, por_academia: Object.entries(c).sort((a, b) => b[1] - a[1]).slice(0, 6).map(([academia, docs]) => ({ academia, docs })) };
      ctx.documentos = es.docs.slice(0, 4).map(d => ({ id: d.id, academia: d.academia, mes: mesUTC(d.t), motivo: d.motivo }));
    } else {
      ctx.agregacoes = { alunos_unicos_exato: exatos.size, alunos_unicos_hyperloglog: Math.round(hllEstimar(es.p)), precisao_p: es.p, aviso: 'a agregação cardinality é uma estimativa; cite o erro esperado ao responder' };
      ctx.documentos = [];
    }
    ctx.instrucao = 'Responda só com o que está neste contexto. Cite o id de cada documento usado e diga quando o dado não bastar.';
    return ctx;
  }

  // ------------------------------------------------------------ laço
  function passo(dtMin) {
    const t0 = S.relogio, t1 = t0 + dtMin * MIN;
    gerar(t0, t1, dtMin);
    escoarOutbox(dtMin, t1);
    S.relogio = t1;
    consumir(dtMin);
    cepRelogio();
    lakeFechar(false);
    influxPoda();
    missoesRelogio(dtMin);
  }

  function missoesRelogio(dtMin) {
    const ms = S.ms, g = S.kafka.grupos['sink-influxdb'], lag = lagDe(g);
    if (g.pausado) { ms.m2.pausadoMin += dtMin; if (lag > ms.m2.lagMax) ms.m2.lagMax = lag; }
    else if (ms.m2.retomouEm && ms.m2.drenagem === null && lag < 5) ms.m2.drenagem = (S.relogio - ms.m2.retomouEm) / MIN;
    const eu = S.reg[2];
    if (!eu.up) { ms.m3.foraMin += dtMin; if (eu.outbox.length > ms.m3.outboxMax) ms.m3.outboxMax = eu.outbox.length; }
    else if (ms.m3.restaurouEm && ms.m3.escoou === null && !eu.outbox.length) ms.m3.escoou = (S.relogio - ms.m3.restaurouEm) / MIN;
    if (S.influx.tagAluno) { const n = nSeries(); if (n > ms.m5.max) ms.m5.max = n; }
  }

  let timer = null;
  function rodar(sim) {
    S.rodando = sim;
    $('btn-rodar').textContent = sim ? 'Pausar' : 'Iniciar';
    if (timer) { clearInterval(timer); timer = null; }
    if (sim) timer = setInterval(() => { passo(S.vel * TICK_MS / 1000); pintar(); if (Date.now() - ultimoSalvo > 3000) salvar(); }, TICK_MS);
    else salvar();
  }

  // ------------------------------------------------------------ pintura
  let aba = 'rede';
  const pintores = {};

  function pintar() {
    $('relogio').textContent = curto(S.relogio) + ' UTC';
    const d = new Date(S.relogio - 3 * HORA);
    $('relogio-sub').textContent = `dia ${Math.floor((S.relogio - INICIO) / DIA) + 1} · São Paulo ${p2(d.getUTCHours())}:${p2(d.getUTCMinutes())}`;
    if (pintores[aba]) pintores[aba]();
  }

  const stat = pares => pares.map(([v, r]) => `<div><b>${v}</b><span>${r}</span></div>`).join('');

  // --- rede
  function montarRede() {
    $('rede-regioes').innerHTML = REGIOES.map((r, i) => `
      <div class="sim-panel sim-col-3 sim-region" id="rg-${i}">
        <h3>${r.id}</h3>
        <p class="sim-hint">${r.n} academias · ${fmt(r.n * ALUNOS_POR)} alunos</p>
        <div><span class="sim-badge" id="rg-st-${i}"></span></div>
        <div class="sim-stat"><div><b id="rg-tx-${i}">0</b><span>eventos/min</span></div><div><b id="rg-ob-${i}">0</b><span>no outbox</span></div></div>
        <button data-reg="${i}" id="rg-bt-${i}"></button>
      </div>`).join('');
    $('rede-regioes').addEventListener('click', ev => {
      const b = ev.target.closest('button[data-reg]'); if (!b) return;
      const i = +b.dataset.reg, st = S.reg[i];
      st.up = !st.up;
      if (i === 2 && st.up && S.ms.m3.foraMin > 0) { S.ms.m3.restaurouEm = S.relogio; S.ms.m3.escoou = null; }
      pintar(); salvar();
    });
  }
  pintores.rede = () => {
    const retidos = S.reg.reduce((s, r) => s + r.outbox.length, 0);
    $('rede-fluxo').innerHTML = stat([[fmt(S.total.gerados), 'eventos gerados'], [fmt(S.total.kafka), 'publicados no Kafka'], [fmt(retidos), 'retidos em outbox'], [fmt(S.cep.n), 'eventos complexos'], [fmt(S.influx.pontos), 'pontos no InfluxDB'], [fmt(S.lake.nObj), 'objetos no bucket'], [fmt(S.es.nDocs), 'docs no Elasticsearch']]);
    S.reg.forEach((st, i) => {
      $('rg-' + i).classList.toggle('is-down', !st.up);
      const b = $('rg-st-' + i); b.textContent = st.up ? 'cluster no ar' : 'cluster fora do ar'; b.classList.toggle('is-on', !st.up);
      $('rg-tx-' + i).textContent = fmt(st.taxa);
      $('rg-ob-' + i).textContent = fmt(st.outbox.length);
      $('rg-bt-' + i).textContent = st.up ? 'Derrubar cluster' : 'Restaurar cluster';
    });
    $('rede-storage').textContent = tamanhoSalvo < 0
      ? 'O navegador recusou a gravação em localStorage. A simulação segue em memória e se perde ao recarregar.'
      : `Estado salvo na chave ${CHAVE}: ${fmt(tamanhoSalvo / 1024)} KB. Ficam guardados o relógio, as configurações, os offsets, os 40 registros finais de cada partição, o outbox, os alertas, as séries, os objetos recentes, os documentos de cancelamento, os registradores do HyperLogLog, as missões e as respostas. O restante do log do Kafka é descartado ao recarregar, como se já tivesse sido lido.`;
  };

  // --- evento
  function montarEvento() {
    $('ev-academia').innerHTML = ACADEMIAS.map(a => `<option value="${a.idx}">${a.cod} · ${REGIOES[a.reg].id}</option>`).join('');
    $('ev-academia').value = ACADEMIAS.find(a => a.cod === 'SE-STO-003').idx;
    $('ev-tipo').innerHTML = TIPOS.map(t => `<option>${t[0]}</option>`).join('');
    $('ev-tipo').value = 'checkin';
    const alunos = () => { const a = ACADEMIAS[+$('ev-academia').value]; $('ev-aluno').innerHTML = Array.from({ length: 12 }, (_, n) => `<option value="${n}">${nomeAluno(a.idx * ALUNOS_POR + n)}</option>`).join(''); };
    alunos();
    $('ev-academia').addEventListener('change', alunos);
    $('ev-tipo').addEventListener('change', () => { $('ev-motivo-wrap').hidden = $('ev-tipo').value !== 'cancelamento'; });
    $('ev-registrar').addEventListener('click', registrarManual);
  }

  function registrarManual() {
    const acad = ACADEMIAS[+$('ev-academia').value], n = +$('ev-aluno').value, tipo = $('ev-tipo').value, r = REGIOES[acad.reg];
    const te = S.relogio + S.manuais.length % 50; // desempate entre registros no mesmo instante
    const ev = eventoAluno(acad, n, tipo, te, { motivo: $('ev-motivo').value.trim() || undefined });
    const ai = acad.idx * ALUNOS_POR + n;
    const dl = new Date(te + r.fuso * HORA);
    const local = { academia: acad.nome, aluno: nomeAluno(ai), matricula_local: `${acad.cod}/${String(n + 1).padStart(4, '0')}`, telefone: 'fica só no sistema da academia', tipo, horario_local: `${dl.getUTCFullYear()}-${p2(dl.getUTCMonth() + 1)}-${p2(dl.getUTCDate())} ${p2(dl.getUTCHours())}:${p2(dl.getUTCMinutes())} (UTC${r.fuso >= 0 ? '+' : ''}${r.fuso})`, turma: ev.turma };
    if (ev.motivo) local.motivo = ev.motivo;
    manuaisIds.add(ev.event_id);
    const pos = publicar({ e: ev, t: te, ai, ri: acad.reg }, te);
    const m = { id: ev.event_id, tipo, academia: acad.cod, aluno: ev.aluno, t: te, p: pos ? pos.p : null, o: pos ? pos.o : null };
    S.manuais.unshift(m); if (S.manuais.length > 30) S.manuais.pop();
    const m1 = S.ms.m1;
    if (pos && tipo === 'checkin' && !m1.evId) { m1.evId = ev.event_id; m1.part = pos.p; m1.off = pos.o; }
    if (pos && S.manuais.filter(x => x.academia === acad.cod && x.p === pos.p).length >= 2) m1.mesma = true;
    $('ev-local').textContent = JSON.stringify(local, null, 2);
    $('ev-saida').textContent = JSON.stringify(ev, null, 2);
    $('ev-destino').textContent = pos
      ? `Publicado em tatame.eventos: partição ${pos.p}, offset ${fmt(pos.o)}. A chave do registro é ${acad.cod}.`
      : `O cluster ${r.id} está fora do ar. O evento ficou retido no outbox da academia e será enviado quando o cluster voltar, com o mesmo ocorrido_em.`;
    $('ev-status').textContent = S.rodando ? '' : 'A simulação está pausada: o evento entra no log, mas os consumidores só leem com a simulação rodando.';
    pintar(); salvar();
  }

  pintores.evento = () => {
    $('ev-manuais').innerHTML = '<thead><tr><th>event_id</th><th>Tipo</th><th>Academia</th><th>Aluno</th><th>Tempo do evento</th><th class="num">Partição</th><th class="num">Offset</th></tr></thead><tbody>' +
      (S.manuais.length ? S.manuais.map(m => `<tr><td><code>${m.id}</code></td><td>${m.tipo}</td><td>${m.academia}</td><td><code>${m.aluno}</code></td><td>${curto(m.t)}</td><td class="num">${m.p === null ? 'outbox' : m.p}</td><td class="num">${m.o === null ? '' : fmt(m.o)}</td></tr>`).join('') : '<tr><td colspan="7" class="sim-hint">Nenhum evento registrado à mão.</td></tr>') + '</tbody>';
  };

  // --- kafka
  function montarKafka() {
    $('kf-grupos').innerHTML = '<thead><tr><th>Grupo</th><th class="num">Lag</th><th class="num">Capacidade</th><th class="num">Perdidos</th><th></th></tr></thead><tbody>' +
      Object.keys(CAP).map(g => `<tr><td><code>${g}</code><br><span class="sim-badge is-soft" id="kg-st-${g}"></span></td><td class="num" id="kg-lag-${g}">0</td><td class="num">${fmt(CAP[g])}/min</td><td class="num" id="kg-per-${g}">0</td><td><button data-grupo="${g}" id="kg-bt-${g}"></button></td></tr>`).join('') + '</tbody>';
    $('kf-grupos').addEventListener('click', ev => {
      const b = ev.target.closest('button[data-grupo]'); if (!b) return;
      const nome = b.dataset.grupo, g = S.kafka.grupos[nome];
      g.pausado = !g.pausado;
      if (nome === 'sink-influxdb' && !g.pausado && S.ms.m2.pausadoMin > 0) { S.ms.m2.retomouEm = S.relogio; S.ms.m2.drenagem = null; }
      pintar(); salvar();
    });
    $('kf-localizar').addEventListener('click', localizar);
    $('kf-busca').addEventListener('keydown', e => { if (e.key === 'Enter') localizar(); });
  }

  function localizar() {
    const id = $('kf-busca').value.trim();
    if (!id) return;
    let txt = null;
    S.kafka.part.forEach((p, i) => {
      const rec = p.recs.find(r => r.e.event_id === id); if (!rec) return;
      const leram = Object.entries(S.kafka.grupos).map(([n, g]) => `  ${n}: ${g.off[i] > rec.o ? 'já leu' : 'ainda não leu'}`).join('\n');
      txt = `partição: ${i}\noffset: ${rec.o}\nchave: ${rec.e.academia}\ntipo: ${rec.e.tipo}\ntempo do evento: ${rec.e.ocorrido_em}\nchegada ao Kafka: ${iso(rec.a)}\ngrupos:\n${leram}`;
      if (manuaisIds.has(id)) S.ms.m1.localizado = true;
    });
    if (!txt) S.reg.forEach((st, i) => { if (st.outbox.some(x => x.e.event_id === id)) txt = `O evento ainda não chegou ao Kafka. Está no outbox da academia, porque o cluster ${REGIOES[i].id} está fora do ar.`; });
    $('kf-achado').textContent = txt || 'Não encontrado nas partições nem no outbox. O registro pode ter saído pela retenção.';
    salvar();
  }

  pintores.kafka = () => {
    $('kf-particoes').innerHTML = '<thead><tr><th class="num">Partição</th><th class="num">Primeiro offset retido</th><th class="num">Próximo offset</th><th class="num">Registros retidos</th><th>Última chave</th></tr></thead><tbody>' +
      S.kafka.part.map((p, i) => `<tr><td class="num">${i}</td><td class="num">${fmt(p.base)}</td><td class="num">${fmt(p.base + p.recs.length)}</td><td class="num">${fmt(p.recs.length)}</td><td><code>${p.recs.length ? p.recs[p.recs.length - 1].e.academia : ''}</code></td></tr>`).join('') + '</tbody>';
    for (const [n, g] of Object.entries(S.kafka.grupos)) {
      $('kg-lag-' + n).textContent = fmt(lagDe(g));
      $('kg-per-' + n).textContent = fmt(g.perdidos);
      const st = $('kg-st-' + n); st.textContent = g.pausado ? 'pausado' : 'lendo'; st.classList.toggle('is-on', g.pausado); st.classList.toggle('is-soft', !g.pausado);
      $('kg-bt-' + n).textContent = g.pausado ? 'Retomar' : 'Pausar';
    }
    const semHb = $('kf-sem-hb').checked, cauda = [];
    S.kafka.part.forEach((p, i) => { for (let k = p.recs.length - 1, n = 0; k >= 0 && n < 40; k--) { const r = p.recs[k]; if (semHb && r.e.tipo === 'heartbeat') continue; cauda.push([i, r]); n++; } });
    cauda.sort((a, b) => b[1].a - a[1].a || b[1].o - a[1].o);
    $('kf-cauda').innerHTML = '<thead><tr><th class="num">Part.</th><th class="num">Offset</th><th>Chave</th><th>Tipo</th><th>Tempo do evento</th><th>Chegada</th></tr></thead><tbody>' +
      cauda.slice(0, 12).map(([i, r]) => `<tr><td class="num">${i}</td><td class="num">${fmt(r.o)}</td><td><code>${r.e.academia}</code></td><td>${r.e.tipo}${manuaisIds.has(r.e.event_id) ? ' <span class="sim-badge">manual</span>' : ''}</td><td>${curto(r.t)}</td><td>${curto(r.a)}${r.a - r.t > 5 * MIN ? ' <span class="sim-badge is-on">atrasado</span>' : ''}</td></tr>`).join('') + '</tbody>';
  };

  // --- cep
  let assinaturaAlertas = '';
  function montarCep() {
    $('cep-regras').innerHTML = Object.entries(REGRAS).map(([k, r]) => `
      <div class="sim-rule">
        <input type="checkbox" data-regra="${k}" id="cr-on-${k}" aria-label="ligar ${k}">
        <div><strong>${k}</strong><p>${r.txt}</p></div>
        <div class="sim-inline"><label for="cr-p-${k}">${r.rotulo}</label><select data-regra="${k}" id="cr-p-${k}">${r.opcoes.map(o => `<option value="${o}">${o} ${r.un}</option>`).join('')}</select></div>
      </div>`).join('');
    for (const k of Object.keys(REGRAS)) { $('cr-on-' + k).checked = S.cep.regras[k].on; $('cr-p-' + k).value = S.cep.regras[k].p; }
    $('cep-regras').addEventListener('change', ev => {
      const k = ev.target.dataset.regra; if (!k) return;
      if (ev.target.type === 'checkbox') S.cep.regras[k].on = ev.target.checked; else S.cep.regras[k].p = +ev.target.value;
      salvar();
    });
  }
  pintores.cep = () => {
    const c = S.cep;
    $('cep-stat').innerHTML = stat([[fmt(c.lidos), 'eventos lidos'], [fmt(c.atrasados), 'atrasados (+5 min)'], [c.marca ? curto(c.marca) : '--', "marca d'água"], [fmt(Object.keys(c.falhas).length), 'alunos em estado']]);
    $('cep-total').textContent = `${fmt(c.n)} no total, ${c.alertas.length} na lista`;
    const ass = c.n + '|' + c.alertas.filter(a => a.resolvido).length;
    if (ass === assinaturaAlertas) return;
    assinaturaAlertas = ass;
    $('cep-alertas').innerHTML = c.alertas.length ? c.alertas.slice(0, 40).map(a => `
      <li><span class="sim-badge${a.resolvido ? ' is-soft' : ' is-on'}">${a.regra}</span> <span class="sim-mono">#${a.id} · ${curto(a.quando)} UTC${a.resolvido ? ' · voltou em ' + curto(a.resolvido) : ''}</span>
        <div>${esc(a.texto)}</div>
        <details><summary>eventos simples que formaram o padrão (${a.evs.length})</summary><pre class="sim-code is-wrap">${esc(a.evs.map(x => `${x.ocorrido_em}  ${x.tipo}  ${x.event_id}`).join('\n'))}</pre></details>
      </li>`).join('') : '<li class="sim-hint">Nenhum padrão detectado ainda. Inicie a simulação.</li>';
  };

  // --- influxdb
  function montarInflux() {
    $('ix-tag-aluno').checked = S.influx.tagAluno; $('ix-janela').value = S.influx.janela;
    $('ix-tag-aluno').addEventListener('change', e => {
      const m5 = S.ms.m5;
      if (e.target.checked) { if (m5.antes === null) m5.antes = nSeries(); m5.ligou = true; } else if (m5.ligou) m5.desligou = true;
      S.influx.tagAluno = e.target.checked; pintar(); salvar();
    });
    $('ix-janela').addEventListener('change', e => { S.influx.janela = +e.target.value; pintar(); });
    $('ix-13m').addEventListener('click', () => {
      const tem = Math.min(30 * DIA, S.relogio - INICIO);
      $('ix-13m-res').textContent = `Pedido: 395 dias. Devolvido: ${duracao(tem / MIN)}. O bucket guarda no máximo 30 dias, e esta simulação tem ${duracao((S.relogio - INICIO) / MIN)} de dados. A pergunta de 13 meses vai para o Elasticsearch.`;
      S.ms.m7.influx13 = true; salvar();
    });
  }
  pintores.influxdb = () => {
    const ix = S.influx, fim = Math.floor(S.relogio / MIN), W = ix.janela;
    let max = 1;
    const series = REGIOES.map((r, ri) => { const v = []; for (let m = fim - W + 1; m <= fim; m++) { const c = ix.min[ri][m] || 0; if (c > max) max = c; v.push([c, ix.late[ri][m]]); } return v; });
    $('ix-painel').innerHTML = REGIOES.map((r, ri) => {
      const v = series[ri], ult = v.slice(-5).reduce((s, x) => s + x[0], 0) / 5;
      return `<div class="sim-row"><span>${r.id}</span><div class="sim-bars">${v.map(([c, l]) => `<i class="${c ? (l ? 'is-late' : '') : 'is-zero'}" style="height:${Math.round(c / max * 100)}%"></i>`).join('')}</div><span class="num">${fmt1(ult)}/min</span></div>`;
    }).join('');
    $('ix-dispositivos').innerHTML = REGIOES.map(r => {
      let vivos = 0; const tot = r.n * 2;
      for (const a of r.acad) for (const d of DISPOSITIVOS) if (ix.marca - (ix.hbDisp[a.cod + '/' + d] || 0) < 2 * MIN) vivos++;
      return `<div class="sim-row" style="grid-template-columns:120px 1fr 54px"><span>${r.id}</span><div class="sim-meter"><i style="width:${vivos / tot * 100}%"></i></div><span class="num">${vivos}/${tot}</span></div>`;
    }).join('');
    $('ix-linhas').textContent = ix.linhas.length ? ix.linhas.join('\n') : '// sem pontos ainda';
    $('ix-series').innerHTML = stat([[fmt(nSeries()), 'séries ativas'], [fmt(Object.keys(ix.series).length), 'sem a tag aluno'], [fmt(seriesAluno.size), 'criadas pela tag aluno'], [fmt(ix.pontos), 'pontos gravados']]);
  };

  // --- object storage
  function montarStorage() {
    $('st-lote').value = S.lake.lote; $('st-part').value = S.lake.part;
    $('st-lote').addEventListener('change', e => { lakeConfig('lote', +e.target.value); pintar(); salvar(); });
    $('st-part').addEventListener('change', e => { lakeConfig('part', e.target.value); pintar(); salvar(); });
  }
  pintores.storage = () => {
    const lk = S.lake, r = lakeResumo();
    $('st-stat').innerHTML = stat([[fmt(lk.nObj), 'objetos gravados'], [fmt(lk.eventos), 'eventos lidos'], [`${fmt1(lk.bytes / 1e6)} MB`, 'JSON bruto'], [`${fmt1(lk.bytes / RAZAO_GZIP / 1e6)} MB`, 'em JSONL.gz'], [fmt(r.teorico), 'objetos/dia, mínimo teórico'], [r.observado === null ? '--' : fmt(r.observado), 'objetos/dia, ritmo da última hora'], [r.atraso === null ? '--' : duracao(r.atraso), 'atraso médio até o bucket']]);
    $('st-objetos').innerHTML = '<thead><tr><th>Chave</th><th class="num">Eventos</th><th class="num">gzip</th><th>Fechado em</th></tr></thead><tbody>' +
      (lk.objetos.length ? lk.objetos.slice(0, 14).map(o => `<tr><td><code>${o.chave}</code></td><td class="num">${fmt(o.n)}</td><td class="num">${fmt1(o.gz / 1024)} KB</td><td>${curto(o.fechado)}</td></tr>`).join('') : '<tr><td colspan="4" class="sim-hint">Nenhum lote fechado ainda.</td></tr>') + '</tbody>';
    $('st-previa').textContent = lk.previa.length ? lk.previa.map(e => JSON.stringify(e)).join('\n') : '// nenhum lote fechado';
  };

  // --- elasticsearch
  function camada(nome) {
    const [a, m] = nome.slice(-7).split('.').map(Number), d = new Date(S.relogio);
    const idade = (d.getUTCFullYear() - a) * 12 + (d.getUTCMonth() + 1 - m);
    return idade <= 0 ? 'hot' : idade <= 2 ? 'warm' : idade <= 11 ? 'cold' : 'frozen';
  }
  function buscar() {
    const q = $('es-q').value.trim(), r = bm25(q, S.es.docs);
    S.ms.m7.busca = { q, n: r.res.length };
    $('es-busca-info').textContent = S.es.docs.length
      ? `${fmt(r.N)} documentos com motivo, comprimento médio de ${fmt1(r.avgdl)} termos. ` + r.info.map(x => `"${x.termo}": em ${fmt(x.n)} documentos, IDF ${x.idf.toFixed(3)}`).join('; ') + '. O analisador do simulador não remove acentos: "preco" não encontra "preço".'
      : 'Ainda não há cancelamentos indexados. Registre um na estação Evento, com a simulação rodando, ou carregue o histórico.';
    $('es-resultados').innerHTML = r.res.length ? '<thead><tr><th class="num">BM25</th><th>Motivo</th><th class="num">Termos</th><th>Região</th><th>Academia</th><th>Índice</th></tr></thead><tbody>' +
      r.res.slice(0, 8).map(x => `<tr><td class="num">${x.s.toFixed(3)}</td><td>${esc(x.d.motivo)}</td><td class="num">${x.dl}</td><td>${x.d.regiao}</td><td><code>${x.d.academia}</code></td><td><code>${mesUTC(x.d.t)}</code></td></tr>`).join('') + '</tbody>' : '';
    salvar();
  }
  function montarEs() {
    $('es-p').value = S.es.p;
    $('es-pergunta').innerHTML = PERGUNTAS.map((p, i) => `<option value="${i}">${p}</option>`).join('');
    $('es-p').addEventListener('change', e => { S.es.p = +e.target.value; pintar(); });
    $('es-historico').addEventListener('click', () => { carregarHistorico(); pintarRelatorio(); pintar(); salvar(); });
    $('es-buscar').addEventListener('click', buscar);
    $('es-q').addEventListener('keydown', e => { if (e.key === 'Enter') buscar(); });
    $('es-contexto').addEventListener('click', () => {
      const txt = JSON.stringify(montarContexto(+$('es-pergunta').value), null, 2);
      $('es-ctx').textContent = txt + `\n\n// ${fmt(txt.length)} caracteres, perto de ${fmt(txt.length / 4)} tokens (aproximação de 4 caracteres por token)`;
    });
    pintarRelatorio();
  }
  function pintarRelatorio() {
    const rel = S.es.relatorio;
    if (!rel.length) return;
    const max = Math.max(...rel.map(l => Math.max(l.matriculas, l.cancelamentos)));
    $('es-relatorio').innerHTML = '<div class="sim-scroll"><table class="sim-table"><thead><tr><th>Mês</th><th class="num">Ativos</th><th class="num">Matrículas</th><th style="width:22%"></th><th class="num">Cancelamentos</th><th style="width:22%"></th><th class="num">Saldo</th></tr></thead><tbody>' +
      rel.map(l => `<tr><td><code>${l.mes}</code></td><td class="num">${fmt(l.ativos)}</td><td class="num">${fmt(l.matriculas)}</td><td><div class="sim-meter"><i style="width:${l.matriculas / max * 100}%"></i></div></td><td class="num">${fmt(l.cancelamentos)}</td><td><div class="sim-meter"><i style="width:${l.cancelamentos / max * 100}%"></i></div></td><td class="num">${l.matriculas - l.cancelamentos > 0 ? '+' : ''}${fmt(l.matriculas - l.cancelamentos)}</td></tr>`).join('') + '</tbody></table></div>';
  }
  pintores.elasticsearch = () => {
    const es = S.es, nomes = Object.keys(es.indices).sort().reverse();
    $('es-hist-status').textContent = es.historico ? 'Histórico de outubro de 2025 a outubro de 2026 carregado.' : 'Sem histórico: só o que foi simulado nesta sessão.';
    $('es-historico').disabled = es.historico;
    $('es-indices').innerHTML = '<thead><tr><th>Índice</th><th>Camada</th><th class="num">Documentos</th><th class="num">Shard 0</th><th class="num">Shard 1</th><th class="num">Shard 2</th></tr></thead><tbody>' +
      (nomes.length ? nomes.map(n => { const i = es.indices[n], c = camada(n); return `<tr><td><code>${n}</code></td><td><span class="sim-badge${c === 'hot' ? ' is-on' : c === 'frozen' ? ' is-soft' : ''}">${c}</span></td><td class="num">${fmt(i.docs)}</td>${i.shards.map(s => `<td class="num">${fmt(s)}</td>`).join('')}</tr>`; }).join('') : '<tr><td colspan="6" class="sim-hint">Nenhum documento indexado. O indexador lê o bucket quando um lote fecha.</td></tr>') + '</tbody>';
    const p = es.p, m = 1 << p, est = hllEstimar(p), exato = exatos.size;
    const erro = exato ? (est - exato) / exato * 100 : 0;
    $('es-hll').innerHTML = stat([[fmt(exato), 'contagem exata'], [fmt(est), `HyperLogLog, p=${p}`], [`${erro >= 0 ? '+' : ''}${erro.toFixed(2).replace('.', ',')}%`, 'erro'], [`${(104 / Math.sqrt(m)).toFixed(2).replace('.', ',')}%`, 'erro padrão teórico'], [`${fmt1(m * 6 / 8 / 1024)} KB`, 'memória do HLL'], [`${fmt1(exato * 16 / 1024)} KB`, 'chaves da contagem exata']]);
    if (exato) { const m7 = S.ms.m7; m7.exato = exato; if (p === 8) m7.p8 = Math.round(est); if (p === 14) m7.p14 = Math.round(est); }
  };

  // --- missões
  const MISSOES = [
    { t: 'A chave decide a partição', e: 'Evento e Kafka', passos: ['Na estação Evento, registre um checkin.', 'Copie o event_id e use Localizar event_id na estação Kafka.', 'Registre outro evento da mesma academia e compare a partição.'], q: 'Por que a academia foi escolhida como chave, e o que se perderia com uma chave aleatória?' },
    { t: 'Lag de um consumidor parado', e: 'Kafka', passos: ['Pause o grupo sink-influxdb por 30 minutos simulados.', 'Anote o lag e olhe o painel tático parado na estação InfluxDB.', 'Retome o grupo e meça quanto tempo o lag leva para zerar.'], q: 'A conta lag ÷ (capacidade − chegada) bate com o tempo observado? O CEP e o object storage foram afetados?' },
    { t: 'Falha do cluster da Suécia', e: 'Rede, CEP e InfluxDB', passos: ['Na estação Rede, derrube o cluster eu-estocolmo por 2 horas simuladas.', 'Acompanhe o outbox, o alerta academia_silenciosa e o buraco no painel tático (janela de 3 h).', 'Restaure o cluster e observe os eventos atrasados preenchendo o passado.'], q: 'O que cada destino mostrou durante a falha e depois dela? Que decisão dependeu do tempo do evento?' },
    { t: 'Um padrão de sequência', e: 'Evento e CEP', passos: ['Com a simulação rodando, registre duas cobranca_falhou para o mesmo aluno.', 'Abra o evento complexo cobranca_reincidente e confira os dois eventos simples.', 'Troque a janela da regra e repita com outro aluno.'], q: 'Que estado o CEP precisa guardar para essa regra, e por quanto tempo?' },
    { t: 'Cardinalidade de séries', e: 'InfluxDB', passos: ['Anote o número de séries ativas.', 'Ligue Usar aluno como tag e deixe correr alguns minutos simulados.', 'Desligue e compare: as séries criadas continuam lá.'], q: 'Onde o identificador do aluno deveria ficar, se o painel tático não precisa dele?' },
    { t: 'Tamanho do lote e partição', e: 'Object storage', passos: ['Com lote de 1 minuto, espere uma hora simulada e anote objetos por dia e atraso.', 'Troque para 60 minutos e repita.', 'Com eventos atrasados da missão 3, alterne Particionar por e veja onde os objetos caem.'], q: 'Que intervalo o grupo escolheria para a Rede Tatame, e que partição facilita reprocessar um dia?' },
    { t: 'Busca, estimativa e 13 meses', e: 'Elasticsearch e InfluxDB', passos: ['Carregue o histórico de 13 meses e busque "preço" nos motivos.', 'Compare a contagem exata de alunos únicos com o HyperLogLog em p=8 e p=14.', 'Compare o Relatório de 13 meses com a consulta de 13 meses do InfluxDB.'], q: 'Que perguntas da rede aceitam uma estimativa, e quais exigem a contagem exata?' },
  ];

  function montarMissoes() {
    $('ms-lista').innerHTML = MISSOES.map((m, i) => `
      <div class="sim-mission">
        <div class="n">${i + 1}</div>
        <div>
          <h3>${m.t} <span class="sim-badge is-soft">${m.e}</span></h3>
          <ol>${m.passos.map(p => `<li>${p}</li>`).join('')}</ol>
          <div class="sim-check" id="ms-obs-${i + 1}"></div>
          <p class="sim-hint" style="margin:6px 0 4px">${m.q}</p>
          <textarea data-m="${i + 1}" placeholder="resposta do grupo">${esc(S.respostas[i + 1] || '')}</textarea>
        </div>
      </div>`).join('');
    $('ms-lista').addEventListener('input', e => { if (e.target.dataset.m) S.respostas[e.target.dataset.m] = e.target.value; });
    $('ms-lista').addEventListener('change', salvar);
    $('ms-grupo').value = S.grupo;
    $('ms-grupo').addEventListener('input', e => { S.grupo = e.target.value; });
    $('ms-exportar').addEventListener('click', () => { $('ms-saida').value = evidencia(); salvar(); });
    $('ms-copiar').addEventListener('click', () => { if (!$('ms-saida').value) $('ms-saida').value = evidencia(); $('ms-saida').select(); if (navigator.clipboard) navigator.clipboard.writeText($('ms-saida').value).catch(() => {}); });
    $('ms-baixar').addEventListener('click', () => {
      const txt = $('ms-saida').value || evidencia(); $('ms-saida').value = txt;
      const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([txt], { type: 'text/markdown' })); a.download = 'evidencia_simulador.md'; a.click(); URL.revokeObjectURL(a.href);
    });
  }

  // Cada observação: [rótulo, feito?]
  function observacoes() {
    const ms = S.ms, lk = lakeResumo();
    const nConf = Object.keys(ms.m6.lotes).length;
    return {
      1: [[ms.m1.evId ? `checkin na partição ${ms.m1.part}, offset ${fmt(ms.m1.off)}` : 'checkin registrado', !!ms.m1.evId], ['event_id localizado', ms.m1.localizado], ['segundo evento na mesma partição', ms.m1.mesma]],
      2: [[`pausado por ${duracao(ms.m2.pausadoMin)}`, ms.m2.pausadoMin >= 30], [`lag máximo ${fmt(ms.m2.lagMax)}`, ms.m2.lagMax > 0], [ms.m2.drenagem === null ? 'lag zerado' : `lag zerado em ${duracao(ms.m2.drenagem)}`, ms.m2.drenagem !== null]],
      3: [[`cluster fora por ${duracao(ms.m3.foraMin)}`, ms.m3.foraMin >= 120], [`outbox máximo ${fmt(ms.m3.outboxMax)}`, ms.m3.outboxMax > 0], ['alerta academia_silenciosa', ms.m3.silencio], [ms.m3.escoou === null ? 'outbox escoado' : `outbox escoado em ${duracao(ms.m3.escoou)}`, ms.m3.escoou !== null], [`${fmt(ms.m3.atrasados)} eventos atrasados lidos pelo CEP`, ms.m3.atrasados > 0]],
      4: [['alerta com evento registrado à mão', ms.m4.alerta], [`janelas testadas: ${ms.m4.janelas.join(', ') || 'nenhuma'}`, ms.m4.janelas.length >= 2]],
      5: [[`séries antes: ${ms.m5.antes === null ? '--' : fmt(ms.m5.antes)}`, ms.m5.antes !== null], [`máximo com a tag: ${fmt(ms.m5.max)}`, ms.m5.max > (ms.m5.antes || 0)], ['tag desligada', ms.m5.desligou]],
      6: [[`configurações medidas: ${nConf}`, nConf >= 2], ['partição alternada', ms.m6.trocouPart], [`agora: ${lk.observado === null ? fmt(lk.teorico) + ' objetos/dia (teórico)' : fmt(lk.observado) + ' objetos/dia'}`, true]],
      7: [['histórico carregado', ms.m7.historico], [ms.m7.busca ? `busca "${ms.m7.busca.q}": ${fmt(ms.m7.busca.n)} resultados` : 'busca feita', !!ms.m7.busca], [`p=8: ${ms.m7.p8 === null ? '--' : fmt(ms.m7.p8)}; p=14: ${ms.m7.p14 === null ? '--' : fmt(ms.m7.p14)}; exato: ${ms.m7.exato === null ? '--' : fmt(ms.m7.exato)}`, ms.m7.p8 !== null && ms.m7.p14 !== null], ['consulta de 13 meses no InfluxDB', ms.m7.influx13]],
    };
  }

  pintores.missoes = () => {
    const obs = observacoes();
    for (let i = 1; i <= 7; i++) $('ms-obs-' + i).innerHTML = obs[i].map(([txt, ok]) => `<span class="sim-badge${ok ? ' is-on' : ' is-soft'}">${ok ? 'feito' : 'pendente'} · ${esc(txt)}</span>`).join('');
  };

  function evidencia() {
    const obs = observacoes(), L = [];
    L.push('# Evidência do simulador da Aula 06', '');
    L.push(`- Grupo: ${S.grupo || '(preencher)'}`);
    L.push(`- Exportado em: ${new Date().toLocaleString('pt-BR')}`);
    L.push(`- Relógio simulado: ${curto(S.relogio)} UTC, dia ${Math.floor((S.relogio - INICIO) / DIA) + 1} da simulação`);
    L.push(`- Totais: ${fmt(S.total.gerados)} eventos gerados, ${fmt(S.total.kafka)} publicados no Kafka, ${fmt(S.cep.n)} eventos complexos, ${fmt(S.influx.pontos)} pontos no InfluxDB, ${fmt(S.lake.nObj)} objetos no bucket, ${fmt(S.es.nDocs)} documentos no Elasticsearch`, '');
    MISSOES.forEach((m, i) => {
      L.push(`## Missão ${i + 1}. ${m.t}`, '');
      for (const [txt, ok] of obs[i + 1]) L.push(`- [${ok ? 'x' : ' '}] ${txt}`);
      if (i === 5) for (const [k, v] of Object.entries(S.ms.m6.lotes)) L.push(`- lote de ${k}: ${fmt(v.obj)} objetos por dia, atraso médio de ${v.atraso === null ? 'não medido' : duracao(v.atraso)}`);
      L.push('', `Pergunta: ${m.q}`, '', `Resposta do grupo: ${(S.respostas[i + 1] || '(preencher)').trim()}`, '');
    });
    return L.join('\n');
  }

  // ------------------------------------------------------------ abas e início
  function trocarAba() {
    const h = location.hash.slice(1);
    aba = $('v-' + h) ? h : 'rede';
    document.querySelectorAll('.sim-view').forEach(v => v.classList.toggle('is-active', v.id === 'v-' + aba));
    document.querySelectorAll('#abas a').forEach(a => a.classList.toggle('is-active', a.getAttribute('href') === '#' + aba));
    assinaturaAlertas = '';
    pintar();
    window.scrollTo(0, 0);
  }

  function iniciar() {
    carregar();
    montarRede(); montarEvento(); montarKafka(); montarCep(); montarInflux(); montarStorage(); montarEs(); montarMissoes();
    $('velocidade').value = S.vel;
    $('velocidade').addEventListener('change', e => { S.vel = +e.target.value; salvar(); });
    $('btn-rodar').addEventListener('click', () => rodar(!S.rodando));
    $('btn-reiniciar').addEventListener('click', () => {
      if (!window.confirm('Apagar a simulação, as missões e as respostas guardadas neste navegador?')) return;
      rodar(false);
      try { localStorage.removeItem(CHAVE); } catch (e) { /* sem storage */ }
      location.reload();
    });
    window.addEventListener('hashchange', trocarAba);
    window.addEventListener('pagehide', salvar);
    trocarAba();
    window.__sim = { estado: () => S, passo, salvar, lagDe, hllEstimar, exatos: () => exatos, nSeries };
  }

  document.addEventListener('DOMContentLoaded', iniciar);
})();
