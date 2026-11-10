/* Simulador da Aula 07 — Data Collection and Storage.
 * Roda inteiro no navegador. O estado fica em localStorage.
 * A Rede Tatame, as academias, os alunos e os números são inventados para a aula. */
(function () {
  'use strict';

  const CHAVE = 'dcs_aula07_simulador_v1';
  const MIN = 60000, HORA = 3600000, DIA = 86400000;
  const INICIO = Date.UTC(2026, 10, 28, 11, 30); // 8h30 em São Paulo
  const TICK_MS = 250;
  const ALUNOS_POR = 150;
  const LIMITE_PARTES = 300;
  const MERGES_POR_MIN = 2, PARTES_POR_MERGE = 10;
  const TEMPO_LOTE = 5;           // minutos simulados até fechar o lote pelo tempo
  const FILA_MAX = 20000;         // eventos que o tópico segura para o sink
  const TAXA_DEFEITO = 0.02, TAXA_DUP = 0.01;
  const ORCAMENTO = 400;          // tokens do contexto
  const N_HIST = 800, VIVOS_MAX = 400, M_GRAFO = 6, DIM = 16;

  const REGIOES = [
    { id: 'sa-saopaulo', pre: 'BR-SAO', n: 10, fuso: -3, cidade: 'São Paulo' },
    { id: 'us-virginia', pre: 'US-VIR', n: 7, fuso: -5, cidade: 'Virgínia' },
    { id: 'eu-estocolmo', pre: 'SE-STO', n: 5, fuso: 1, cidade: 'Estocolmo' },
    { id: 'ap-sydney', pre: 'AU-SYD', n: 2, fuso: 11, cidade: 'Sydney' },
  ];
  const REG_IDX = Object.fromEntries(REGIOES.map((r, i) => [r.id, i]));

  // Proporção dos eventos de aluno. O simulador usa mais check-ins e cancelamentos
  // que a hipótese do material, para que o painel e a busca tenham o que mostrar.
  const TIPOS = [['app_aberto', 46], ['video_assistido', 24], ['checkin', 16], ['reserva_aula', 8], ['cobranca_aprovada', 2], ['cancelamento', 2], ['aula_experimental', .6], ['matricula', .5], ['cobranca_falhou', .5], ['graduacao', .4]];
  const TIPOS_VALIDOS = TIPOS.map(t => t[0]).concat('heartbeat');
  const ORIGENS = ['app', 'catraca', 'gestao', 'dispositivo'];
  const ORIGEM = { checkin: 'catraca', cobranca_aprovada: 'gestao', cobranca_falhou: 'gestao', matricula: 'gestao', cancelamento: 'gestao', graduacao: 'gestao' };

  const CURVA = (() => {
    const c = [.1, .1, .1, .1, .1, .2, 1.2, 1.3, 1.1, .8, .8, .8, 1, 1, .7, .7, .8, 2.4, 2.8, 2.8, 2.4, 1.6, .6, .4];
    const m = c.reduce((a, b) => a + b, 0) / 24;
    return c.map(x => x / m);
  })();

  // ------------------------------------------------------------ motivos e conceitos
  const CONCEITOS = ['preço', 'horário', 'distância', 'mudança de cidade', 'saúde', 'clima', 'professor', 'lotação', 'crianças', 'cobrança', 'concorrência', 'outra modalidade', 'viagem e trabalho', 'rotina', 'atendimento', 'motivação'];
  const DIC = (() => {
    const grupos = [
      'preço preços cara caro caros caras valor valores mensalidade mensalidades reajuste aumento orçamento custo custos dinheiro pesado pesou barato desconto',
      'horário horários hora noite manhã cedo tarde grade agenda encaixa turno',
      'longe distância deslocamento trânsito metrô ônibus perto caminho trajeto estacionamento',
      'mudou mudança mudar cidade bairro país transferido mudando',
      'lesão joelho ombro coluna médico cirurgia dor saúde fisioterapia machucou gravidez',
      'inverno frio escuro neve chuva calor clima verão',
      'professor professora instrutor aula aulas didática ritmo método ensino',
      'cheia lotada lotação espaço tatame fila vaga vagas apertado',
      'kids filho filha criança crianças infantil escola',
      'cobrança cartão pagamento boleto falhou estorno fatura cobrado duplicidade',
      'concorrente concorrência outra rival abriu',
      'musculação crossfit natação corrida modalidade pilates boxe',
      'viagem trabalho emprego plantão viajando escala',
      'tempo rotina correria cansaço cansado estudos faculdade prova',
      'atendimento recepção resposta suporte reclamação aplicativo app',
      'interesse desanimou motivação vontade evolução graduação faixa parou',
    ];
    const d = {};
    grupos.forEach((g, i) => g.split(' ').forEach(p => { (d[p] = d[p] || []).push(i); }));
    return d;
  })();

  // Texto do motivo e peso por região (SP, VA, STO, SYD).
  const BASES = [
    ['achou o preço alto depois do reajuste', [5, 3, 2, 2]],
    ['o valor ficou pesado no orçamento da família', [4, 3, 1, 2]],
    ['mensalidade subiu e não coube mais', [3, 2, 1, 1]],
    ['plano caro para treinar só duas vezes na semana', [3, 2, 1, 2]],
    ['pediu desconto e não conseguiu', [2, 1, 0, 1]],
    ['horário das turmas não encaixa no trabalho', [3, 3, 2, 2]],
    ['só consegue treinar cedo e não há turma de manhã', [2, 2, 1, 1]],
    ['a grade da noite mudou e ficou tarde demais', [2, 1, 1, 1]],
    ['mudou de cidade e não há academia da rede perto', [2, 3, 2, 3]],
    ['foi transferido para outro país', [1, 2, 1, 2]],
    ['mudou de bairro e a academia ficou longe', [3, 2, 1, 1]],
    ['trânsito pesado, o trajeto leva mais de uma hora', [4, 2, 0, 1]],
    ['deslocamento longo, a academia fica longe do metrô', [1, 0, 4, 0]],
    ['sem estacionamento perto da unidade', [1, 3, 0, 1]],
    ['lesão no joelho, médico pediu pausa de seis meses', [2, 2, 2, 2]],
    ['cirurgia no ombro marcada', [1, 1, 1, 1]],
    ['dor na coluna, está em fisioterapia', [2, 1, 1, 1]],
    ['inverno escuro e frio, parou de sair de casa', [0, 1, 6, 0]],
    ['muita neve no caminho durante o inverno', [0, 1, 4, 0]],
    ['calor forte no tatame durante o verão', [2, 0, 0, 3]],
    ['professor da turma mudou e a aula perdeu o ritmo', [1, 2, 1, 1]],
    ['não se adaptou à didática do novo instrutor', [1, 1, 1, 1]],
    ['turma cheia, pouco espaço no tatame', [3, 1, 1, 1]],
    ['fila de espera para a vaga do horário que queria', [2, 1, 0, 1]],
    ['a turma kids ficou cheia e o filho perdeu o interesse', [2, 2, 1, 2]],
    ['a criança trocou de escola e os horários bateram', [1, 2, 1, 1]],
    ['cobrança falhou três vezes e a matrícula foi encerrada', [2, 2, 1, 1]],
    ['foi cobrado em duplicidade no cartão', [1, 1, 0, 1]],
    ['boleto não chegou e a fatura venceu', [2, 0, 0, 0]],
    ['academia concorrente abriu mais perto de casa', [2, 1, 0, 2]],
    ['trocou por outra modalidade, foi para a musculação', [2, 2, 1, 1]],
    ['passou a fazer natação com a família', [1, 1, 1, 2]],
    ['viagem longa a trabalho, volta no ano que vem', [1, 1, 1, 2]],
    ['novo emprego com plantão em escala', [1, 2, 1, 1]],
    ['rotina de estudos na faculdade, sem tempo', [2, 1, 1, 1]],
    ['correria e cansaço no fim do dia', [2, 2, 1, 1]],
    ['atendimento da recepção não resolveu a reclamação', [1, 1, 0, 1]],
    ['o aplicativo de reservas falha toda semana', [1, 1, 1, 0]],
    ['desanimou por não ver evolução na faixa', [1, 1, 1, 1]],
    ['perdeu a vontade depois da graduação', [1, 1, 1, 1]],
  ];
  const COMPLEMENTOS = ['', '', '', ', e o preço pesou', ', e o horário não ajudava', ', e a unidade fica longe', ', pretende voltar', ', avisou pelo aplicativo', ', depois de dois anos de treino', ', junto com um colega da turma', ', sem reclamação do professor', ', e o trabalho aumentou'];
  const PERGUNTAS = [
    'Por que os alunos estão cancelando por causa do preço?',
    'O que tem levado ao cancelamento durante o inverno?',
    'Quais reclamações envolvem cobrança e pagamento?',
    'Problemas com horário e deslocamento até a academia',
  ];

  // ------------------------------------------------------------ utilidades
  const $ = id => document.getElementById(id);
  const fmt = n => Math.round(n).toLocaleString('pt-BR');
  const fmt1 = n => n.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const fmt3 = n => n.toLocaleString('pt-BR', { minimumFractionDigits: 3, maximumFractionDigits: 3 });
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const p2 = n => String(n).padStart(2, '0');
  const curto = t => { const d = new Date(t); return `${p2(d.getUTCDate())}/${p2(d.getUTCMonth() + 1)} ${p2(d.getUTCHours())}:${p2(d.getUTCMinutes())}`; };
  const isoMs = t => new Date(t).toISOString();
  const minDe = t => Math.floor((t - INICIO) / MIN);
  const stat = pares => pares.map(([v, r]) => `<div><b>${v}</b><span>${r}</span></div>`).join('');

  function mix(h) { h ^= h >>> 16; h = Math.imul(h, 0x85ebca6b); h ^= h >>> 13; h = Math.imul(h, 0xc2b2ae35); h ^= h >>> 16; return h >>> 0; }
  function fnv(s, sem) { let h = (0x811c9dc5 ^ sem) >>> 0; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193); } return mix(h); }
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
  const tokenizar = s => s.toLowerCase().replace(/[^\p{L}\p{N}\s]/gu, ' ').split(/\s+/).filter(Boolean);
  const academia = (ri, rnd = Math.random) => `${REGIOES[ri].pre}-${String(1 + Math.floor(rnd() * REGIOES[ri].n)).padStart(3, '0')}`;

  // ------------------------------------------------------------ estado
  let S;
  function novoEstado() {
    return {
      v: 1, relogio: INICIO, vel: 1, rodando: false, grupo: '', respostas: {},
      cfg: { modo: 'strict', extra: 'forbid', lote: 1000, async: false, token: false, distinto: false },
      total: { gerados: 0, aceitos: 0, quarentena: 0, salvosLax: 0, salvosIgnore: 0 },
      taxa: [0, 0, 0, 0],
      ct: { erros: {}, ultimos: [] },
      ig: { fila: [], filaDesde: null, perdidos: 0, partes: [], inserts: 0, recusados: 0, bloqueado: false, asyncBuf: [], ultimo: null, tokens: [], log: [], atraso: 0, partesMax: 0, fusoes: 0 },
      mv: { min: {}, linhasView: 0 },
      vt: { historico: false, vivos: [], proxId: 1, ultima: null },
      ts: { defeitos: {}, ultima: null },
      ms: {
        m1: { presets: [], lax: false, ignore: false },
        m2: { estourou: false, lotes: [], semToken: false, comToken: false },
        m3: { consulta: null, distinto: false },
        m4: { busca: null, efs: {} },
        m5: { pos: null, pre: null },
        m6: { rodadas: {} },
      },
    };
  }
  let ultimoSalvo = 0, tamanhoSalvo = 0;
  function salvar() {
    try {
      const txt = JSON.stringify(Object.assign({}, S, { rodando: false }));
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
          for (const k of ['cfg', 'total', 'ct', 'ig', 'mv', 'vt', 'ts']) S[k] = Object.assign(novoEstado()[k], d[k]);
          for (const m of Object.keys(base.ms)) S.ms[m] = Object.assign(novoEstado().ms[m], d.ms && d.ms[m]);
          tamanhoSalvo = txt.length;
        }
      }
    } catch (e) { S = novoEstado(); }
    S.rodando = false;
  }

  // ------------------------------------------------------------ contrato
  // Erros no formato de ValidationError.errors() do Pydantic v2.
  const RE_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const CAMPOS = ['event_id', 'tipo', 'ocorrido_em', 'regiao', 'academia', 'aluno', 'origem', 'motivo', 'dispositivo', 'latencia_ms'];

  function validar(o, cfg, agora) {
    const er = [], E = (type, loc, msg, input) => er.push({ type, loc: [loc], msg, input });
    if (o === null || typeof o !== 'object' || Array.isArray(o)) { er.push({ type: 'model_type', loc: [], msg: 'Input should be an object', input: o }); return er; }
    const texto = (c, obrig) => {
      if (o[c] === undefined) { if (obrig) E('missing', c, 'Field required', o); return false; }
      if (typeof o[c] !== 'string') { E('string_type', c, 'Input should be a valid string', o[c]); return false; }
      return true;
    };
    if (texto('event_id', true) && !RE_UUID.test(o.event_id)) E('uuid_parsing', 'event_id', 'Input should be a valid UUID', o.event_id);
    const temTipo = texto('tipo', true);
    if (temTipo && !TIPOS_VALIDOS.includes(o.tipo)) E('literal_error', 'tipo', 'Input should be ' + TIPOS_VALIDOS.map(t => `'${t}'`).join(', '), o.tipo);
    if (texto('ocorrido_em', true)) {
      const t = Date.parse(o.ocorrido_em);
      if (isNaN(t)) E('datetime_from_date_parsing', 'ocorrido_em', 'Input should be a valid datetime', o.ocorrido_em);
      else if (t > agora + 5 * MIN) E('value_error', 'ocorrido_em', 'Value error, ocorrido_em está mais de 5 minutos à frente do relógio do consumidor', o.ocorrido_em);
    }
    const temReg = texto('regiao', true) && (REG_IDX[o.regiao] !== undefined || (E('literal_error', 'regiao', 'Input should be ' + REGIOES.map(r => `'${r.id}'`).join(', '), o.regiao), false));
    const temAcad = texto('academia', true) && (/^[A-Z]{2}-[A-Z]{3}-\d{3}$/.test(o.academia) || (E('string_pattern_mismatch', 'academia', "String should match pattern '^[A-Z]{2}-[A-Z]{3}-\\d{3}$'", o.academia), false));
    if (texto('origem', true) && !ORIGENS.includes(o.origem)) E('literal_error', 'origem', 'Input should be ' + ORIGENS.map(t => `'${t}'`).join(', '), o.origem);
    const hb = o.tipo === 'heartbeat';
    if (texto('aluno', false) && !/^[0-9a-f]{16}$/.test(o.aluno)) E('string_pattern_mismatch', 'aluno', "String should match pattern '^[0-9a-f]{16}$'", o.aluno);
    if (texto('motivo', false) && o.motivo.length > 280) E('string_too_long', 'motivo', 'String should have at most 280 characters', o.motivo);
    texto('dispositivo', false);
    if (o.latencia_ms !== undefined) {
      let v = o.latencia_ms;
      if (typeof v === 'string') {
        if (cfg.modo === 'strict') { E('int_type', 'latencia_ms', 'Input should be a valid integer', v); v = null; }
        else if (/^-?\d+$/.test(v.trim())) v = parseInt(v, 10);
        else { E('int_parsing', 'latencia_ms', 'Input should be a valid integer, unable to parse string as an integer', v); v = null; }
      } else if (typeof v !== 'number' || !Number.isInteger(v)) { E('int_type', 'latencia_ms', 'Input should be a valid integer', v); v = null; }
      if (v !== null && v < 0) E('greater_than_equal', 'latencia_ms', 'Input should be greater than or equal to 0', v);
      if (v !== null && v > 60000) E('less_than_equal', 'latencia_ms', 'Input should be less than or equal to 60000', v);
    }
    if (cfg.extra === 'forbid') for (const k of Object.keys(o)) if (!CAMPOS.includes(k)) E('extra_forbidden', k, 'Extra inputs are not permitted', o[k]);
    // validadores de modelo: só rodam quando os campos passaram, como no Pydantic
    if (!er.length) {
      const M = msg => er.push({ type: 'value_error', loc: [], msg: 'Value error, ' + msg, input: o });
      if (temReg && temAcad && !o.academia.startsWith(REGIOES[REG_IDX[o.regiao]].pre)) M(`a academia ${o.academia} não pertence à região ${o.regiao}`);
      if (temTipo && hb && (o.dispositivo === undefined || o.latencia_ms === undefined)) M('heartbeat exige dispositivo e latencia_ms');
      if (temTipo && !hb && o.aluno === undefined) M(`o evento ${o.tipo} exige o campo aluno`);
      if (o.tipo === 'cancelamento' && !(o.motivo && o.motivo.trim())) M('cancelamento exige motivo preenchido');
    }
    return er;
  }

  const DEFEITOS_EV = [
    ['inteiro_como_texto', 30, 'latencia_ms chega como texto ("120")'],
    ['campo_extra', 30, 'firmware novo manda versao_fw'],
    ['tipo_desconhecido', 8, 'tipo fora da lista'],
    ['campo_ausente', 8, 'check-in sem aluno'],
    ['data_futura', 8, 'relógio do dispositivo adiantado'],
    ['cancelamento_sem_motivo', 8, 'cancelamento sem motivo'],
    ['regiao_incoerente', 8, 'academia de outra região'],
  ];
  function eventoBase(ri, tipo, t) {
    const ac = academia(ri);
    if (tipo === 'heartbeat') return { event_id: uuid(), tipo, ocorrido_em: isoMs(t), regiao: REGIOES[ri].id, academia: ac, dispositivo: Math.random() < .5 ? 'catraca-1' : 'leitor-facial-1', origem: 'dispositivo', latencia_ms: 8 + Math.floor(Math.random() * 230) };
    const e = { event_id: uuid(), tipo, ocorrido_em: isoMs(t), regiao: REGIOES[ri].id, academia: ac, aluno: hash16(`${ac}:${1 + Math.floor(Math.random() * ALUNOS_POR)}`), origem: ORIGEM[tipo] || 'app' };
    if (tipo === 'cancelamento') e.motivo = textoMotivo(sortearMotivo(ri, Math.random));
    return e;
  }
  function estragar(defeito, ri, t) {
    let e;
    switch (defeito) {
      case 'inteiro_como_texto': e = eventoBase(ri, 'heartbeat', t); e.latencia_ms = String(e.latencia_ms); break;
      case 'campo_extra': e = eventoBase(ri, 'heartbeat', t); e.versao_fw = '2.4.1'; break;
      case 'tipo_desconhecido': e = eventoBase(ri, 'checkin', t); e.tipo = 'check-in'; break;
      case 'campo_ausente': e = eventoBase(ri, 'checkin', t); delete e.aluno; break;
      case 'data_futura': e = eventoBase(ri, 'checkin', t + 3 * HORA); break;
      case 'cancelamento_sem_motivo': e = eventoBase(ri, 'cancelamento', t); e.motivo = ''; break;
      case 'regiao_incoerente': e = eventoBase(ri, 'checkin', t); e.regiao = REGIOES[(ri + 1) % 4].id; break;
      default: e = eventoBase(ri, 'checkin', t);
    }
    return e;
  }

  // ------------------------------------------------------------ geração
  // Linha na fila do sink: [minuto, região, é check-in, é cópia]
  function gerarMinuto(t0, fracao) {
    const m = minDe(t0);
    REGIOES.forEach((r, ri) => {
      const horaLocal = ((new Date(t0).getUTCHours() + r.fuso) % 24 + 24) % 24;
      const nAluno = poisson(r.n * ALUNOS_POR * 10 / 1440 * CURVA[horaLocal] * fracao);
      const nHb = poisson(r.n * 2 * 2 * fracao);
      S.taxa[ri] = S.taxa[ri] * .8 + (nAluno + nHb) / fracao * .2;
      for (let i = 0; i < nAluno + nHb; i++) {
        const hb = i >= nAluno, t = t0 + Math.random() * fracao * MIN;
        S.total.gerados++;
        let ev, defeito = null;
        if (Math.random() < TAXA_DEFEITO) { defeito = sorteio(DEFEITOS_EV); ev = estragar(defeito, ri, t); }
        else ev = eventoBase(ri, hb ? 'heartbeat' : sorteio(TIPOS), t);
        const er = validar(ev, S.cfg, S.relogio + fracao * MIN);
        if (er.length) {
          S.total.quarentena++;
          const chave = er[0].type + (er[0].loc.length ? ' em ' + er[0].loc[0] : ' no modelo');
          S.ct.erros[chave] = (S.ct.erros[chave] || 0) + 1;
          S.ct.ultimos.unshift({ t, tipo: ev.tipo, reg: ev.regiao, erro: er[0].msg, loc: er[0].loc[0] || '(modelo)' });
          if (S.ct.ultimos.length > 12) S.ct.ultimos.length = 12;
          continue;
        }
        if (defeito === 'inteiro_como_texto') S.total.salvosLax++;
        if (defeito === 'campo_extra') S.total.salvosIgnore++;
        S.total.aceitos++;
        const ck = ev.tipo === 'checkin' ? 1 : 0;
        enfileirar([m, ri, ck, 0]);
        if (Math.random() < TAXA_DUP) enfileirar([m, ri, ck, 1]); // entrega pelo menos uma vez
        if (ev.tipo === 'cancelamento') novoMotivoVivo(ri, ev.motivo);
      }
    });
  }
  function enfileirar(l) {
    const ig = S.ig;
    if (!ig.fila.length) ig.filaDesde = S.relogio;
    ig.fila.push(l);
    if (ig.fila.length > FILA_MAX) { ig.fila.shift(); ig.perdidos++; }
  }

  // ------------------------------------------------------------ ingestão
  function logar(txt) { const ig = S.ig; ig.log.unshift(`${curto(S.relogio)}  ${txt}`); if (ig.log.length > 8) ig.log.length = 8; }

  function aplicarNasViews(linhas) {
    const mv = S.mv;
    for (const [m, ri, ck, dup] of linhas) {
      let x = mv.min[m];
      if (!x) x = mv.min[m] = { v: [0, 0, 0, 0], r: [0, 0, 0, 0], b: [0, 0, 0, 0], n: 0 };
      x.n++;
      if (!ck) continue;
      x.b[ri]++;
      if (!dup) x.r[ri]++;
      if (!dup || !S.cfg.distinto) x.v[ri]++;
    }
  }
  function criarParte(linhas) {
    const ig = S.ig;
    ig.partes.push({ n: linhas.length, d: linhas.reduce((s, l) => s + l[3], 0) });
    if (ig.partes.length > ig.partesMax) ig.partesMax = ig.partes.length;
    aplicarNasViews(linhas);
  }
  // Um INSERT: devolve false quando o servidor recusa por excesso de partes.
  function inserir(linhas, token) {
    const ig = S.ig;
    if (ig.partes.length >= LIMITE_PARTES) { ig.recusados++; ig.bloqueado = true; S.ms.m2.estourou = true; return false; }
    ig.bloqueado = false;
    if (token && ig.tokens.includes(token)) { logar(`INSERT de ${fmt(linhas.length)} linhas ignorado: token ${token} já visto`); return true; }
    if (token) { ig.tokens.push(token); if (ig.tokens.length > 100) ig.tokens.shift(); }
    ig.inserts++;
    if (S.cfg.async) ig.asyncBuf.push(...linhas);
    else criarParte(linhas);
    return true;
  }
  function sink(final) {
    const ig = S.ig, lote = S.cfg.lote;
    let guarda = 0;
    while (ig.fila.length && guarda++ < 4000) {
      const cheio = ig.fila.length >= lote;
      const venceu = ig.filaDesde !== null && S.relogio - ig.filaDesde >= TEMPO_LOTE * MIN;
      if (!cheio && !venceu && !final) break;
      const linhas = ig.fila.slice(0, lote);
      const token = S.cfg.token ? 'lote-' + (ig.inserts + 1) : null;
      if (!inserir(linhas, token)) break;
      ig.fila.splice(0, linhas.length);
      ig.ultimo = { linhas, token };
      ig.filaDesde = ig.fila.length ? S.relogio : null;
      if (!S.ms.m2.lotes.includes(lote)) S.ms.m2.lotes.push(lote);
    }
  }
  function descarregarAsync() {
    const ig = S.ig;
    if (!ig.asyncBuf.length || ig.partes.length >= LIMITE_PARTES) return;
    criarParte(ig.asyncBuf); ig.asyncBuf = [];
  }
  function fundir(dtMin) {
    const ig = S.ig;
    ig._credito = (ig._credito || 0) + MERGES_POR_MIN * dtMin;
    while (ig._credito >= 1 && ig.partes.length > 1) {
      ig._credito--;
      // junta as menores partes; as cópias que estavam nelas somem
      const ordem = ig.partes.map((p, i) => [p.n, i]).sort((a, b) => a[0] - b[0]).slice(0, PARTES_POR_MERGE);
      if (ig.partes.length < 6) break; // a fusão espera juntar algumas partes
      const idx = new Set(ordem.map(o => o[1]));
      let n = 0;
      for (const i of idx) n += ig.partes[i].n - ig.partes[i].d;
      ig.partes = ig.partes.filter((_, i) => !idx.has(i));
      ig.partes.push({ n, d: 0 });
      ig.fusoes++;
    }
    if (ig._credito > MERGES_POR_MIN * 2) ig._credito = MERGES_POR_MIN * 2;
  }
  const linhasTabela = () => S.ig.partes.reduce((s, p) => s + p.n, 0);
  const linhasFinal = () => S.ig.partes.reduce((s, p) => s + p.n - p.d, 0);

  function reenviar() {
    const ig = S.ig;
    if (!ig.ultimo) { logar('nenhum lote para reenviar'); return; }
    const copias = ig.ultimo.linhas.map(l => [l[0], l[1], l[2], 1]);
    const token = S.cfg.token ? (ig.ultimo.token || 'lote-' + ig.inserts) : null;
    if (token && !ig.tokens.includes(token)) ig.tokens.push(token); // o lote original passa a ter token
    const antes = linhasTabela();
    if (!inserir(copias, token)) { logar('reenvio recusado: partes demais'); return; }
    if (S.cfg.async) descarregarAsync();
    const depois = linhasTabela();
    if (token) S.ms.m2.comToken = true;
    else { S.ms.m2.semToken = true; logar(`reenvio de ${fmt(copias.length)} linhas sem token: tabela foi de ${fmt(antes)} para ${fmt(depois)} linhas`); }
  }

  // ------------------------------------------------------------ vetores
  let docs = [];        // { id, ri, texto, vet }
  let grafo = [];       // vizinhos por posição
  const sortearMotivo = (ri, rnd) => [sorteio(BASES.map((b, i) => [i, b[1][ri]]), rnd), Math.floor(rnd() * COMPLEMENTOS.length), Math.floor(rnd() * 1e6)];
  const textoMotivo = ([b, c]) => BASES[b][0] + COMPLEMENTOS[c];

  function embutir(texto, ruido) {
    const v = new Array(DIM).fill(0);
    let achou = 0;
    for (const p of tokenizar(texto)) { const cs = DIC[p]; if (cs) { achou++; for (const c of cs) v[c] += 1; } }
    if (!achou) return null;
    if (ruido !== undefined) { const rnd = semente(ruido); for (let i = 0; i < DIM; i++) v[i] += (rnd() - .5) * .5; }
    let n = 0; for (const x of v) n += x * x; n = Math.sqrt(n) || 1;
    return v.map(x => x / n);
  }
  const dist = (a, b) => { let s = 0; for (let i = 0; i < DIM; i++) s += a[i] * b[i]; return 1 - s; };

  function adicionarDoc(id, ri, texto, ruido) {
    const vet = embutir(texto, ruido);
    if (!vet) return;
    const pos = docs.length;
    // grafo de uma camada, construído na inserção: liga aos M vizinhos mais próximos já presentes
    const viz = docs.map((d, i) => [dist(vet, d.vet), i]).sort((a, b) => a[0] - b[0]).slice(0, M_GRAFO).map(x => x[1]);
    docs.push({ id, ri, texto, vet });
    grafo.push(viz.slice());
    for (const i of viz) grafo[i].push(pos);
  }
  function reconstruirDocs() {
    docs = []; grafo = [];
    if (S.vt.historico) {
      const rnd = semente(20261128);
      for (let i = 0; i < N_HIST; i++) {
        const ri = sorteio([[0, 96], [1, 72], [2, 48], [3, 24]], rnd);
        const m = sortearMotivo(ri, rnd);
        adicionarDoc('h' + (i + 1), ri, textoMotivo(m), m[2]);
      }
    }
    for (const [id, ri, texto, ruido] of S.vt.vivos) adicionarDoc('s' + id, ri, texto, ruido);
  }
  function novoMotivoVivo(ri, texto) {
    const vt = S.vt;
    if (vt.vivos.length >= VIVOS_MAX) return;
    const reg = [vt.proxId++, ri, texto, Math.floor(Math.random() * 1e6)];
    vt.vivos.push(reg);
    adicionarDoc('s' + reg[0], ri, texto, reg[3]);
  }

  function buscaExata(q, k, ri) {
    let comp = 0; const r = [];
    docs.forEach((d, i) => { if (ri >= 0 && d.ri !== ri) return; comp++; r.push([dist(q, d.vet), i]); });
    r.sort((a, b) => a[0] - b[0]);
    return { res: r.slice(0, k), comp };
  }
  // Busca gulosa no grafo: expande no máximo `ef` nós, a partir de um ponto de entrada fixo.
  function buscaAprox(q, k, ef) {
    if (!docs.length) return { res: [], comp: 0 };
    const visto = new Map(); let comp = 0;
    const ver = i => { if (!visto.has(i)) { visto.set(i, dist(q, docs[i].vet)); comp++; } };
    ver(0);
    const expandido = new Set();
    for (let passo = 0; passo < ef; passo++) {
      let melhor = -1, dm = Infinity;
      for (const [i, d] of visto) if (!expandido.has(i) && d < dm) { dm = d; melhor = i; }
      if (melhor < 0) break;
      expandido.add(melhor);
      for (const v of grafo[melhor]) ver(v);
    }
    const res = [...visto].map(([i, d]) => [d, i]).sort((a, b) => a[0] - b[0]).slice(0, k);
    return { res, comp };
  }
  function bm25(consulta, k, ri) {
    const k1 = 1.2, b = 0.75, termos = tokenizar(consulta);
    const base = docs.filter(d => ri < 0 || d.ri === ri);
    const toks = base.map(d => tokenizar(d.texto));
    const N = base.length, avgdl = N ? toks.reduce((s, t) => s + t.length, 0) / N : 0;
    const info = termos.map(termo => { const n = toks.filter(t => t.includes(termo)).length; return { termo, n, idf: Math.log(1 + (N - n + .5) / (n + .5)) }; });
    const res = [];
    base.forEach((d, i) => {
      let s = 0;
      for (const x of info) { if (!x.n) continue; const f = toks[i].filter(t => t === x.termo).length; if (f) s += x.idf * f * (k1 + 1) / (f + k1 * (1 - b + b * toks[i].length / avgdl)); }
      if (s > 0) res.push({ d, s });
    });
    res.sort((a, b2) => b2.s - a.s);
    return { res: res.slice(0, k), total: res.length, info };
  }
  // Busca completa, como a estação e o contexto usam.
  function buscar(texto, k, ef, ri, filtro) {
    const q = embutir(texto);
    if (!q) return { q: null };
    const exata = buscaExata(q, k, ri);
    let res, comp;
    if (ri >= 0 && filtro === 'pre') { res = exata.res; comp = exata.comp; }
    else { const a = buscaAprox(q, k, ef); comp = a.comp; res = ri >= 0 ? a.res.filter(([, i]) => docs[i].ri === ri) : a.res; }
    const certos = new Set(exata.res.map(x => x[1]));
    const acerto = res.filter(x => certos.has(x[1])).length;
    return { q, res, comp, exata, acerto, alvo: exata.res.length, certos };
  }

  // ------------------------------------------------------------ contexto
  const tokens = s => Math.ceil(s.length / 4);
  function checkinsHora() {
    const fim = minDe(S.relogio), tot = [0, 0, 0, 0];
    for (let m = fim - 60; m < fim; m++) { const x = S.mv.min[m]; if (x) for (let i = 0; i < 4; i++) tot[i] += x.v[i]; }
    return tot;
  }
  function montarContexto(pergunta, ri, k, filtro) {
    const b = buscar(pergunta, k, 32, ri, filtro);
    if (!b.q) return { texto: '// nenhuma palavra da pergunta está no dicionário de conceitos do simulador', n: 0, tok: 0 };
    const ck = checkinsHora(), canc = [0, 0, 0, 0];
    docs.forEach(d => { canc[d.ri]++; });
    const L = [];
    L.push('Você responde ao time de retenção da Rede Tatame. Use só o que está abaixo e cite o id de cada motivo usado.', '');
    L.push(`Pergunta: ${pergunta}`);
    L.push(`Recorte: ${ri >= 0 ? REGIOES[ri].id : 'todas as regiões'}`, '');
    L.push('Números (views materializadas do ClickHouse):');
    REGIOES.forEach((r, i) => { if (ri < 0 || ri === i) L.push(`- ${r.id}: ${fmt(ck[i])} check-ins na última hora; ${fmt(canc[i])} cancelamentos com motivo registrado`); });
    L.push('', `Motivos recuperados por similaridade (${filtro === 'pre' && ri >= 0 ? 'pré-filtro' : 'pós-filtro'}, k=${k}):`);
    let usados = 0, cortados = 0;
    const cab = L.join('\n');
    let tot = tokens(cab);
    for (const [d, i] of b.res) {
      const linha = `- [${docs[i].id}] ${docs[i].regiao || REGIOES[docs[i].ri].id} · distância ${fmt3(d)} · ${docs[i].texto}`;
      if (tot + tokens(linha) > ORCAMENTO) { cortados++; continue; }
      L.push(linha); tot += tokens(linha); usados++;
    }
    if (!b.res.length) L.push('- nenhum motivo sobrou depois do filtro de região');
    if (cortados) L.push(`(${cortados} motivos ficaram de fora pelo limite de ${ORCAMENTO} tokens)`);
    return { texto: L.join('\n'), n: usados, tok: tot, pedidos: k, devolvidos: b.res.length };
  }

  // ------------------------------------------------------------ testes
  const DEFEITOS = [
    ['d1', 'O contrato aceita ocorrido_em no futuro'],
    ['d2', 'A montagem do contexto passa do limite de tokens'],
    ['d3', 'A DDL cria MergeTree no lugar de ReplacingMergeTree'],
    ['d4', 'A view foi criada depois da carga e ficou sem o passado'],
    ['d5', 'A consulta ordena por L2Distance e o índice é de cosineDistance'],
    ['d6', 'A coluna do vetor recebe 768 dimensões e o índice espera 384'],
    ['d7', 'O sink não reenvia o lote depois de um timeout de rede'],
  ];
  // [nome, camada, defeito que o teste pega, duração em s]
  const TESTES = [
    ['test_contrato_aceita_evento_valido', 'uni', null, .02],
    ['test_contrato_recusa_data_futura', 'uni', 'd1', .02],
    ['test_contrato_cancelamento_exige_motivo', 'uni', null, .02],
    ['test_contexto_respeita_limite_de_tokens', 'uni', 'd2', .03],
    ['test_contexto_cita_o_id_dos_motivos', 'uni', null, .02],
    ['test_ddl_aplica_sem_erro', 'int', 'd6', .3],
    ['test_duplicata_some_com_final', 'int', 'd3', .5],
    ['test_view_bate_com_a_tabela_bruta', 'int', 'd4', .6],
    ['test_busca_usa_o_indice_vetorial', 'int', 'd5', .4],
    ['test_insert_de_vetor_com_384_dimensoes', 'int', 'd6', .3],
    ['test_pipeline_do_topico_ao_contexto', 'e2e', 'd4', 9],
    ['test_sink_reenvia_depois_de_timeout', 'e2e', 'd7', 12],
  ];
  const CAMADA = { uni: 'unidade', int: 'integração', e2e: 'ponta a ponta' };
  function rodarSuite(camadas, modo) {
    const ativos = DEFEITOS.filter(d => S.ts.defeitos[d[0]]).map(d => d[0]);
    let tempo = 0; const linhas = [], pegos = new Set();
    if (camadas.int) tempo += modo === 'real' ? 5.9 : 0.1;
    if (camadas.e2e) tempo += 40;
    for (const [nome, cam, def, dur] of TESTES) {
      if (!camadas[cam]) { linhas.push([nome, cam, 'não executado', 0]); continue; }
      const d = cam === 'int' && modo === 'duble' ? .05 : dur;
      const enxerga = !(cam === 'int' && modo === 'duble'); // o dublê não tem motor, fusão, view nem índice
      const falhou = def && ativos.includes(def) && enxerga;
      if (falhou) pegos.add(def);
      tempo += d;
      linhas.push([nome, cam, falhou ? 'falhou' : 'passou', d]);
    }
    const escaparam = ativos.filter(d => !pegos.has(d));
    return { linhas, tempo, ativos, pegos: [...pegos], escaparam, camadas, modo };
  }

  // ------------------------------------------------------------ laço
  function passo(dtMin) {
    let resta = dtMin;
    while (resta > 1e-9) {
      const ateVirar = 1 - ((S.relogio - INICIO) / MIN % 1);
      const f = Math.min(resta, ateVirar < 1e-9 ? 1 : ateVirar);
      gerarMinuto(S.relogio, f);
      const antes = minDe(S.relogio);
      S.relogio += f * MIN;
      resta -= f;
      sink(false);
      if (minDe(S.relogio) !== antes) descarregarAsync();
      fundir(f);
    }
    // a view guarda um dia de minutos
    const corte = minDe(S.relogio) - 1440;
    if (S.mv.min[corte - 1]) for (const k of Object.keys(S.mv.min)) if (+k < corte) delete S.mv.min[k];
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
  const opcoesRegiao = () => '<option value="-1">todas</option>' + REGIOES.map((r, i) => `<option value="${i}">${r.id}</option>`).join('');

  // --- visão geral
  function montarRede() {
    $('rede-regioes').innerHTML = '<div class="sim-grid">' + REGIOES.map((r, i) => `
      <div class="sim-panel sim-col-3 sim-region">
        <h3>${r.id}</h3>
        <p class="sim-hint">${r.n} academias · ${fmt(r.n * ALUNOS_POR)} alunos</p>
        <div class="sim-stat"><div><b id="rg-tx-${i}">0</b><span>eventos/min</span></div></div>
      </div>`).join('') + '</div>';
  }
  pintores.rede = () => {
    $('rede-fluxo').innerHTML = stat([[fmt(S.total.gerados), 'eventos lidos do tópico'], [fmt(S.total.quarentena), 'em quarentena'], [fmt(linhasTabela()), 'linhas no ClickHouse'], [fmt(S.ig.partes.length), 'partes ativas'], [fmt(Object.keys(S.mv.min).length * 4), 'linhas na view'], [fmt(docs.length), 'motivos com vetor']]);
    S.taxa.forEach((t, i) => { $('rg-tx-' + i).textContent = fmt(t); });
    $('rede-storage').textContent = tamanhoSalvo < 0
      ? 'O navegador recusou a gravação em localStorage. A simulação segue em memória e se perde ao recarregar.'
      : `Estado salvo na chave ${CHAVE}: ${fmt(tamanhoSalvo / 1024)} KB. Ficam guardados o relógio, as configurações, a fila do sink, a lista de partes, os minutos da view, os motivos de cancelamento, as missões e as respostas. Os vetores e o grafo de vizinhos são recalculados ao abrir a página.`;
  };

  // --- contrato
  const PRESETS = [['valido', 'evento válido'], ...DEFEITOS_EV.map(d => [d[0], d[2]])];
  function montarContrato() {
    $('ct-preset').innerHTML = PRESETS.map(([v, r]) => `<option value="${v}">${r}</option>`).join('');
    const carregarPreset = () => { const p = $('ct-preset').value; $('ct-json').value = JSON.stringify(p === 'valido' ? eventoBase(2, 'checkin', S.relogio) : estragar(p, 2, S.relogio), null, 2); };
    $('ct-preset').addEventListener('change', carregarPreset);
    carregarPreset();
    $('ct-modo').value = S.cfg.modo; $('ct-extra').value = S.cfg.extra;
    $('ct-modo').addEventListener('change', e => { S.cfg.modo = e.target.value; if (S.cfg.modo === 'lax') S.ms.m1.lax = true; salvar(); pintar(); });
    $('ct-extra').addEventListener('change', e => { S.cfg.extra = e.target.value; if (S.cfg.extra === 'ignore') S.ms.m1.ignore = true; salvar(); pintar(); });
    $('ct-validar').addEventListener('click', () => {
      let o;
      try { o = JSON.parse($('ct-json').value); }
      catch (e) { $('ct-veredito').textContent = 'JSON inválido'; $('ct-saida').textContent = JSON.stringify([{ type: 'json_invalid', loc: [], msg: 'Invalid JSON: ' + e.message, input: $('ct-json').value.slice(0, 60) }], null, 2); return; }
      const er = validar(o, S.cfg, S.relogio);
      const p = $('ct-preset').value;
      if (!S.ms.m1.presets.includes(p)) S.ms.m1.presets.push(p);
      $('ct-veredito').textContent = er.length ? `recusado com ${er.length} erro${er.length > 1 ? 's' : ''}: vai para a quarentena` : 'aceito: segue para o ClickHouse';
      $('ct-saida').textContent = er.length
        ? `# ValidationError.errors()  (modo ${S.cfg.modo}, extra=${S.cfg.extra})\n` + JSON.stringify(er.map(x => Object.assign({}, x, { input: typeof x.input === 'object' ? '(o evento inteiro)' : x.input })), null, 2)
        : `# evento aceito  (modo ${S.cfg.modo}, extra=${S.cfg.extra})\n` + JSON.stringify(Object.fromEntries(Object.entries(o).filter(([k]) => CAMPOS.includes(k)).map(([k, v]) => [k, k === 'latencia_ms' && typeof v === 'string' ? parseInt(v, 10) : v])), null, 2);
      salvar();
    });
  }
  pintores.contrato = () => {
    const t = S.total;
    $('ct-stat').innerHTML = stat([[fmt(t.gerados), 'eventos lidos'], [fmt(t.aceitos), 'aceitos'], [fmt(t.quarentena), 'em quarentena'], [t.gerados ? fmt1(t.quarentena / t.gerados * 100) + ' %' : '--', 'taxa de rejeição'], [fmt(t.salvosLax), 'aceitos por causa do lax'], [fmt(t.salvosIgnore), 'aceitos por causa do ignore']]);
    const er = Object.entries(S.ct.erros).sort((a, b) => b[1] - a[1]);
    const max = er.length ? er[0][1] : 1;
    $('ct-erros').innerHTML = '<thead><tr><th>Erro</th><th class="num">Eventos</th><th style="width:35%"></th></tr></thead><tbody>' + (er.map(([k, n]) => `<tr><td><code>${esc(k)}</code></td><td class="num">${fmt(n)}</td><td><div class="sim-meter"><i style="width:${n / max * 100}%"></i></div></td></tr>`).join('') || '<tr><td colspan="3">nenhum evento em quarentena ainda</td></tr>') + '</tbody>';
    $('ct-ultimos').innerHTML = '<thead><tr><th>Hora</th><th>Tipo</th><th>Campo</th><th>Mensagem</th></tr></thead><tbody>' + (S.ct.ultimos.map(u => `<tr><td><code>${curto(u.t).slice(6)}</code></td><td><code>${esc(u.tipo || '')}</code></td><td><code>${esc(u.loc)}</code></td><td>${esc(u.erro)}</td></tr>`).join('') || '<tr><td colspan="4">inicie a simulação</td></tr>') + '</tbody>';
  };

  // --- ingestão
  function montarIngestao() {
    $('ig-lote').value = S.cfg.lote; $('ig-async').checked = S.cfg.async; $('ig-token').checked = S.cfg.token;
    $('ig-lote').addEventListener('change', e => { S.cfg.lote = +e.target.value; salvar(); });
    $('ig-async').addEventListener('change', e => { S.cfg.async = e.target.checked; if (!S.cfg.async) descarregarAsync(); salvar(); });
    $('ig-token').addEventListener('change', e => { S.cfg.token = e.target.checked; salvar(); });
    $('ig-reenviar').addEventListener('click', () => { reenviar(); pintar(); salvar(); });
  }
  pintores.ingestao = () => {
    const ig = S.ig, n = linhasTabela(), f = linhasFinal();
    const espera = ig.filaDesde === null ? 0 : (S.relogio - ig.filaDesde) / MIN;
    $('ig-stat').innerHTML = stat([[fmt(ig.fila.length), 'eventos esperando no sink'], [fmt1(espera) + ' min', 'idade do lote aberto'], [fmt(ig.inserts), 'INSERTs aceitos'], [fmt(ig.recusados), 'INSERTs recusados'], [fmt(ig.partes.length), 'partes ativas'], [fmt(ig.partesMax), 'máximo de partes'], [fmt(ig.fusoes), 'fusões'], [fmt(ig.perdidos), 'perdidos por retenção']]);
    $('ig-aviso').innerHTML = ig.bloqueado ? `<div class="sim-note">DB::Exception: Too many parts (${ig.partes.length}). Merges are processing significantly slower than inserts. O sink não confirma o offset e o lag cresce no tópico. Aumente o lote ou ligue o async_insert.</div>` : '';
    const max = Math.log(Math.max(2, ...ig.partes.map(p => p.n)) + 1);
    $('ig-partes').innerHTML = ig.partes.map(p => `<i style="height:${Math.max(4, Math.round(Math.log(p.n + 1) / max * 100))}%"></i>`).join('');
    $('ig-final').innerHTML = stat([[fmt(n), 'count()'], [fmt(f), 'count() FINAL'], [fmt(n - f), 'cópias ainda no disco']]);
    $('ig-log').textContent = ig.log.length ? ig.log.join('\n') : '// reenvie um lote para ver o efeito do token';
  };

  // --- views
  function serieView() {
    const fim = minDe(S.relogio), v = [];
    for (let m = fim - 60; m < fim; m++) { const x = S.mv.min[m]; v.push(x ? x.v.reduce((a, b) => a + b, 0) : 0); }
    return v;
  }
  function consultarViews() {
    const fim = minDe(S.relogio); let lidas = 0, bruto = 0, real = 0, view = 0, linhasView = 0;
    for (let m = fim - 60; m < fim; m++) {
      const x = S.mv.min[m]; if (!x) continue;
      lidas += x.n;
      for (let i = 0; i < 4; i++) { bruto += x.b[i]; real += x.r[i]; view += x.v[i]; if (x.v[i]) linhasView++; }
    }
    return { lidas, bruto, real, view, linhasView };
  }
  function montarViews() {
    $('vw-distinto').checked = S.cfg.distinto;
    $('vw-distinto').addEventListener('change', e => { S.cfg.distinto = e.target.checked; if (S.cfg.distinto) S.ms.m3.distinto = true; salvar(); });
    $('vw-consultar').addEventListener('click', () => {
      const c = consultarViews(); S.ms.m3.consulta = c; salvar();
      $('vw-comparacao').innerHTML = '<thead><tr><th>Consulta</th><th class="num">Linhas lidas</th><th class="num">Check-ins</th><th>Observação</th></tr></thead><tbody>' +
        `<tr><td><code>SELECT count() FROM tatame.eventos WHERE tipo = 'checkin'</code></td><td class="num">${fmt(c.lidas)}</td><td class="num">${fmt(c.bruto)}</td><td>conta as cópias que ainda não foram fundidas</td></tr>` +
        `<tr><td><code>SELECT count() FROM tatame.eventos FINAL WHERE tipo = 'checkin'</code></td><td class="num">${fmt(c.lidas)}</td><td class="num">${fmt(c.real)}</td><td>resposta correta, com o custo de deduplicar na leitura</td></tr>` +
        `<tr><td><code>SELECT countMerge(eventos) FROM tatame.checkins_por_minuto</code></td><td class="num">${fmt(c.linhasView)}</td><td class="num">${fmt(c.view)}</td><td>${c.view === c.real ? 'igual à resposta correta' : `diferença de ${fmt(c.view - c.real)} em relação à resposta correta`}</td></tr></tbody>`;
    });
  }
  pintores.views = () => {
    const v = serieView(), max = Math.max(1, ...v), c = consultarViews();
    $('vw-painel').innerHTML = `<div class="sim-bars" style="height:90px">${v.map(x => `<i class="${x ? '' : 'is-zero'}" style="height:${Math.round(x / max * 100)}%"></i>`).join('')}</div><p class="sim-hint" style="margin-top:8px">Os minutos mais recentes ficam vazios enquanto o lote não é inserido: a view só enxerga o que já entrou na tabela. Lote aberto há ${fmt1(S.ig.filaDesde === null ? 0 : (S.relogio - S.ig.filaDesde) / MIN)} min, com ${fmt(S.ig.fila.length)} eventos.</p>`;
    $('vw-stat').innerHTML = stat([[fmt(c.view), 'check-ins na view, 60 min'], [fmt(c.real), 'check-ins distintos'], [fmt(c.view - c.real), 'diferença']]);
  };

  // --- busca vetorial
  function pintarBusca() {
    const texto = $('vt-q').value.trim(), k = +$('vt-k').value, ef = +$('vt-ef').value, ri = +$('vt-regiao').value, filtro = $('vt-filtro').value;
    if (!docs.length) { $('vt-stat').innerHTML = '<span class="sim-hint">Nenhum motivo ainda. Carregue o histórico ou deixe a simulação correr.</span>'; return; }
    const b = buscar(texto, k, ef, ri, filtro), bm = bm25(texto, k, ri);
    $('vt-bm25').innerHTML = '<thead><tr><th>#</th><th>Motivo</th><th>Região</th><th class="num">BM25</th></tr></thead><tbody>' + (bm.res.map((r, i) => `<tr><td>${i + 1}</td><td>${esc(r.d.texto)}</td><td><code>${REGIOES[r.d.ri].id}</code></td><td class="num">${fmt3(r.s)}</td></tr>`).join('') || '<tr><td colspan="4">nenhum motivo contém as palavras da consulta</td></tr>') + '</tbody>';
    if (!b.q) {
      $('vt-emb').textContent = '// nenhuma palavra da consulta está no dicionário de conceitos do simulador; um modelo de embeddings geraria um vetor mesmo assim';
      $('vt-vetor').innerHTML = '<tbody><tr><td>sem vetor para a consulta</td></tr></tbody>'; $('vt-stat').innerHTML = ''; return;
    }
    const pre = ri >= 0 && filtro === 'pre';
    $('vt-stat').innerHTML = stat([[fmt(b.exata.comp), 'comparações na busca exata'], [fmt(b.comp), pre ? 'comparações com pré-filtro' : 'comparações na aproximada'], [`${b.acerto} de ${b.alvo}`, 'vizinhos exatos encontrados'], [`${b.res.length} de ${k}`, 'resultados devolvidos'], [fmt(docs.length), 'motivos na tabela']]);
    $('vt-vetor').innerHTML = '<thead><tr><th>#</th><th>Motivo</th><th>Região</th><th class="num">Distância</th><th>Na exata</th></tr></thead><tbody>' + (b.res.map(([d, i], n) => `<tr><td>${n + 1}</td><td>${esc(docs[i].texto)}</td><td><code>${REGIOES[docs[i].ri].id}</code></td><td class="num">${fmt3(d)}</td><td>${b.certos.has(i) ? 'sim' : 'não'}</td></tr>`).join('') || '<tr><td colspan="5">o filtro de região descartou todos os vizinhos devolvidos pelo índice</td></tr>') + '</tbody>';
    $('vt-emb').textContent = `[${b.q.map(x => x.toFixed(2)).join(', ')}]\n\n` + b.q.map((x, i) => x > 0.01 ? `${CONCEITOS[i]}: ${x.toFixed(2)}` : null).filter(Boolean).join(' · ');
    S.ms.m4.busca = { q: texto, bm: bm.total };
    if (!pre) S.ms.m4.efs[ef] = { acerto: b.acerto, alvo: b.alvo, comp: b.comp };
    S.vt.ultima = { q: texto, k, ef, ri, filtro };
    salvar();
  }
  function montarVetores() {
    $('vt-regiao').innerHTML = opcoesRegiao();
    $('vt-historico').addEventListener('click', () => { S.vt.historico = true; reconstruirDocs(); salvar(); pintar(); });
    $('vt-buscar').addEventListener('click', pintarBusca);
    $('vt-q').addEventListener('keydown', e => { if (e.key === 'Enter') pintarBusca(); });
  }
  pintores.vetores = () => {
    $('vt-historico').disabled = S.vt.historico;
    $('vt-status').textContent = `${fmt(docs.length)} motivos com vetor: ${S.vt.historico ? fmt(N_HIST) + ' do histórico e ' : ''}${fmt(S.vt.vivos.length)} desta simulação.`;
  };

  // --- contexto
  function montarCx() {
    $('cx-pronta').innerHTML = PERGUNTAS.map((p, i) => `<option value="${i}">${p}</option>`).join('');
    $('cx-regiao').innerHTML = opcoesRegiao();
    $('cx-q').value = PERGUNTAS[0];
    $('cx-pronta').addEventListener('change', e => { $('cx-q').value = PERGUNTAS[+e.target.value]; });
    $('cx-montar').addEventListener('click', () => {
      if (!docs.length) { $('cx-saida').textContent = '// nenhum motivo com vetor: carregue o histórico na estação 4'; return; }
      const ri = +$('cx-regiao').value, k = +$('cx-k').value, filtro = $('cx-filtro').value;
      const c = montarContexto($('cx-q').value.trim(), ri, k, filtro);
      $('cx-saida').textContent = c.texto;
      $('cx-info').textContent = c.tok ? `${c.n} de ${k} motivos pedidos · cerca de ${fmt(c.tok)} de ${ORCAMENTO} tokens` : '';
      if (ri >= 0 && c.tok) S.ms.m5[filtro] = { n: c.devolvidos, k, reg: REGIOES[ri].id };
      salvar();
    });
  }

  // --- testes
  function montarTestes() {
    $('ts-defeitos').innerHTML = DEFEITOS.map(([id, txt]) => `<div class="sim-inline" style="margin-bottom:8px"><label><input type="checkbox" data-def="${id}"${S.ts.defeitos[id] ? ' checked' : ''}> ${txt}</label></div>`).join('');
    $('ts-defeitos').addEventListener('change', e => { const d = e.target.dataset.def; if (d) { S.ts.defeitos[d] = e.target.checked; salvar(); } });
    $('ts-rodar').addEventListener('click', () => {
      const camadas = { uni: $('ts-uni').checked, int: $('ts-int').checked, e2e: $('ts-e2e').checked }, modo = $('ts-modo').value;
      const r = rodarSuite(camadas, modo);
      S.ts.ultima = r;
      const chave = (camadas.e2e ? 'ponta a ponta' : camadas.int ? (modo === 'real' ? 'integração real' : 'integração com dublê') : camadas.uni ? 'só unidade' : 'nada');
      S.ms.m6.rodadas[chave] = { ativos: r.ativos.length, escaparam: r.escaparam.length, tempo: r.tempo };
      salvar(); pintar();
    });
  }
  pintores.testes = () => {
    const r = S.ts.ultima;
    if (!r) { $('ts-stat').innerHTML = ''; $('ts-escaparam').innerHTML = ''; $('ts-resultado').innerHTML = '<tbody><tr><td>ligue alguns defeitos e execute a suíte</td></tr></tbody>'; return; }
    const exec = r.linhas.filter(l => l[2] !== 'não executado'), falhas = exec.filter(l => l[2] === 'falhou').length;
    $('ts-stat').innerHTML = stat([[fmt(exec.length), 'testes executados'], [fmt(falhas), 'falharam'], [fmt(r.ativos.length), 'defeitos ligados'], [fmt(r.escaparam.length), 'defeitos que escaparam'], [fmt1(r.tempo) + ' s', 'tempo da suíte']]);
    const nome = id => DEFEITOS.find(d => d[0] === id)[1];
    $('ts-escaparam').innerHTML = r.escaparam.length ? `<div class="sim-note">Suíte ${falhas ? 'vermelha' : 'verde'}, e estes defeitos seguiriam para produção: ${r.escaparam.map(nome).map(esc).join('; ')}.</div>` : (r.ativos.length ? '<div class="sim-note">Todos os defeitos ligados fizeram algum teste falhar.</div>' : '');
    $('ts-resultado').innerHTML = '<thead><tr><th>Teste</th><th>Camada</th><th>Resultado</th><th class="num">Duração</th></tr></thead><tbody>' + r.linhas.map(([n, c, res, d]) => `<tr><td><code>${n}</code></td><td>${CAMADA[c]}</td><td><span class="sim-badge${res === 'falhou' ? ' is-on' : ' is-soft'}">${res}</span></td><td class="num">${res === 'não executado' ? '--' : d.toLocaleString('pt-BR') + ' s'}</td></tr>`).join('') + '</tbody>';
  };

  // --- missões
  const MISSOES = [
    { t: 'Contrato na entrada', e: 'Contrato', passos: ['Valide pelo menos três eventos com defeito e leia a lista de erros.', 'Troque strict por lax e veja o que deixa de ir para a quarentena.', 'Troque forbid por ignore e repita.'], q: 'Que configuração o grupo usaria para um produtor que a rede controla, como a catraca, e para um de terceiros, como o gateway de pagamento?' },
    { t: 'Lote, partes e duplicatas', e: 'Ingestão', passos: ['Com 1 linha por INSERT, deixe correr até o erro de partes demais.', 'Volte para 1.000 linhas e acompanhe as fusões.', 'Reenvie o último lote sem token e depois com token, comparando count() e FINAL.'], q: 'Que tamanho de lote e que atraso o painel tático aceita? O token resolve a cópia de 1 em cada 100 eventos?' },
    { t: 'A view e a tabela bruta', e: 'Views', passos: ['Consulte os check-ins dos últimos 60 minutos e compare as linhas lidas.', 'Anote a diferença entre a view e a resposta correta.', 'Ligue a contagem por event_id distinto e consulte de novo depois de uma hora simulada.'], q: 'Por que a view não recalcula o passado, e o que isso exige no dia em que ela é criada ou alterada?' },
    { t: 'Palavra e sentido', e: 'Busca vetorial', passos: ['Carregue o histórico e busque "mensalidade cara".', 'Compare a lista por palavras com a lista por vetor.', 'Repita com 2 e com 128 candidatos e anote o acerto e as comparações.'], q: 'Quanto acerto o caso de uso do time de retenção exige, e quanto custa em comparações?' },
    { t: 'Filtro antes ou depois', e: 'Contexto para IA', passos: ['Monte o contexto para ap-sydney com pós-filtro.', 'Monte de novo com pré-filtro e compare quantos motivos chegaram.', 'Leia o contexto e marque o que veio das views.'], q: 'O que precisa entrar no contexto além dos textos, e o que não deveria ser enviado ao modelo?' },
    { t: 'O que cada camada pega', e: 'Testes', passos: ['Ligue todos os defeitos e execute só os testes de unidade.', 'Execute a integração com dublê em memória.', 'Execute a integração com ClickHouse real e compare o que escapou e o tempo.'], q: 'Quais testes o grupo roda a cada commit e quais deixa para o CI?' },
  ];
  function observacoes() {
    const ms = S.ms, ig = S.ig;
    const efs = Object.entries(ms.m4.efs).map(([ef, r]) => `ef ${ef}: ${r.acerto} de ${r.alvo} com ${r.comp} comparações`).join('; ');
    const rod = Object.entries(ms.m6.rodadas);
    return {
      1: [[`presets validados: ${ms.m1.presets.length}`, ms.m1.presets.length >= 3], ['modo lax testado', ms.m1.lax], ['extra ignore testado', ms.m1.ignore], [`${fmt(S.total.quarentena)} eventos em quarentena`, S.total.quarentena > 0]],
      2: [[`máximo de ${fmt(ig.partesMax)} partes`, ms.m2.estourou], [`lotes usados: ${ms.m2.lotes.map(fmt).join(', ') || 'nenhum'}`, ms.m2.lotes.length >= 2], ['reenvio sem token', ms.m2.semToken], ['reenvio com token', ms.m2.comToken], [`count() ${fmt(linhasTabela())}, FINAL ${fmt(linhasFinal())}`, true]],
      3: [[ms.m3.consulta ? `bruta leu ${fmt(ms.m3.consulta.lidas)} linhas, view leu ${fmt(ms.m3.consulta.linhasView)}` : 'consulta comparada', !!ms.m3.consulta], [ms.m3.consulta ? `view ${fmt(ms.m3.consulta.view)}, correto ${fmt(ms.m3.consulta.real)}` : 'diferença anotada', !!ms.m3.consulta], ['contagem por event_id distinto ligada', ms.m3.distinto]],
      4: [['histórico carregado', S.vt.historico], [ms.m4.busca ? `busca "${ms.m4.busca.q}": ${fmt(ms.m4.busca.bm)} motivos por palavras` : 'busca feita', !!ms.m4.busca], [efs || 'dois valores de candidatos testados', Object.keys(ms.m4.efs).length >= 2]],
      5: [[ms.m5.pos ? `pós-filtro em ${ms.m5.pos.reg}: ${ms.m5.pos.n} de ${ms.m5.pos.k} motivos` : 'contexto com pós-filtro numa região', !!ms.m5.pos], [ms.m5.pre ? `pré-filtro em ${ms.m5.pre.reg}: ${ms.m5.pre.n} de ${ms.m5.pre.k} motivos` : 'contexto com pré-filtro numa região', !!ms.m5.pre]],
      6: rod.length ? rod.map(([k, r]) => [`${k}: ${r.escaparam} de ${r.ativos} defeitos escaparam, ${fmt1(r.tempo)} s`, true]).concat([['três configurações executadas', rod.length >= 3]]) : [['suíte executada', false]],
    };
  }
  function evidencia() {
    const obs = observacoes(), L = [];
    L.push('# Evidência do simulador da Aula 07', '');
    L.push(`- Grupo: ${S.grupo || '(preencher)'}`);
    L.push(`- Exportado em: ${new Date().toLocaleString('pt-BR')}`);
    L.push(`- Relógio simulado: ${curto(S.relogio)} UTC, dia ${Math.floor((S.relogio - INICIO) / DIA) + 1} da simulação`);
    L.push(`- Configuração: contrato ${S.cfg.modo} com extra=${S.cfg.extra}; ${fmt(S.cfg.lote)} linhas por INSERT; async_insert ${S.cfg.async ? 'ligado' : 'desligado'}; token ${S.cfg.token ? 'ligado' : 'desligado'}`);
    L.push(`- Totais: ${fmt(S.total.gerados)} eventos lidos, ${fmt(S.total.quarentena)} em quarentena, ${fmt(linhasTabela())} linhas no ClickHouse em ${fmt(S.ig.partes.length)} partes, ${fmt(docs.length)} motivos com vetor`, '');
    MISSOES.forEach((m, i) => {
      L.push(`## Missão ${i + 1}. ${m.t}`, '');
      for (const [txt, ok] of obs[i + 1]) L.push(`- [${ok ? 'x' : ' '}] ${txt}`);
      L.push('', `Pergunta: ${m.q}`, '', `Resposta do grupo: ${(S.respostas[i + 1] || '(preencher)').trim()}`, '');
    });
    return L.join('\n');
  }
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
  pintores.missoes = () => {
    const obs = observacoes();
    for (let i = 1; i <= MISSOES.length; i++) $('ms-obs-' + i).innerHTML = obs[i].map(([txt, ok]) => `<span class="sim-badge${ok ? ' is-on' : ' is-soft'}">${ok ? 'feito' : 'pendente'} · ${esc(txt)}</span>`).join('');
  };

  // ------------------------------------------------------------ abas e início
  function trocarAba() {
    const h = location.hash.slice(1);
    aba = $('v-' + h) ? h : 'rede';
    document.querySelectorAll('.sim-view').forEach(v => v.classList.toggle('is-active', v.id === 'v-' + aba));
    document.querySelectorAll('#abas a').forEach(a => a.classList.toggle('is-active', a.getAttribute('href') === '#' + aba));
    pintar();
    window.scrollTo(0, 0);
  }
  function iniciar() {
    carregar();
    reconstruirDocs();
    montarRede(); montarContrato(); montarIngestao(); montarViews(); montarVetores(); montarCx(); montarTestes(); montarMissoes();
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
    window.__sim = { estado: () => S, passo, salvar, docs: () => docs, buscar, rodarSuite, linhasTabela, linhasFinal, validar };
  }
  document.addEventListener('DOMContentLoaded', iniciar);
})();
