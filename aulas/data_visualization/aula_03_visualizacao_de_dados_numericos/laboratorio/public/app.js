const state = {};
const formatNumber = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });
const formatCurrency = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 });

function setText(id, value) { document.getElementById(id).textContent = value; }

async function getJson(url, options) {
  const response = await fetch(url, { credentials: 'omit', ...options });
  if (!response.ok) throw new Error('request_failed');
  return response.json();
}

function chartFrame(id) {
  const node = document.getElementById(`${id}-chart`);
  node.replaceChildren();
  const width = 900, height = 340;
  const margin = { top: 18, right: 28, bottom: 50, left: id === 'magnitude' ? 190 : 64 };
  const svg = d3.select(node).append('svg').attr('viewBox', `0 0 ${width} ${height}`)
    .attr('aria-hidden', 'true');
  return { svg, width, height, margin, innerWidth: width - margin.left - margin.right, innerHeight: height - margin.top - margin.bottom };
}

function renderEmpty(id) {
  const node = document.getElementById(`${id}-chart`);
  node.replaceChildren();
  const message = document.createElement('p');
  message.className = 'empty-state';
  message.textContent = 'Nenhuma observação disponível para esta combinação. Ajuste o controle ou use a fonte local.';
  node.append(message);
  setText(`${id}-description`, 'A consulta retornou uma amostra vazia; nenhuma conclusão pode ser formulada.');
  metadata(id, [['Unidade', '—'], ['Agregação', '—'], ['Escala', '—'], ['Amostra', '0'], ['Limitação', 'sem observações']]);
}

function metadata(id, entries) {
  const dl = document.getElementById(`${id}-meta`);
  dl.replaceChildren();
  entries.forEach(([term, description]) => {
    const wrapper = document.createElement('div');
    const dt = document.createElement('dt');
    const dd = document.createElement('dd');
    dt.textContent = term;
    dd.textContent = description;
    wrapper.append(dt, dd);
    dl.append(wrapper);
  });
}

function sourceLabel(source) { return source === 'railway' ? 'PostgreSQL Railway' : 'amostra local'; }

function updateKpi(id, value) { setText(`kpi-${id}`, value); }

async function renderEvolution() {
  const grain = document.getElementById('evolution-grain').value;
  const payload = await getJson(`/api/datasets/evolution?grain=${grain}`);
  state.evolution = payload;
  const data = payload.data.map((row) => ({ date: new Date(`${row.period}T00:00:00`), value: Number(row.value) }));
  if (!data.length) return renderEmpty('evolution');
  const frame = chartFrame('evolution');
  const x = d3.scaleTime().domain(d3.extent(data, (d) => d.date)).range([0, frame.innerWidth]);
  const y = d3.scaleLinear().domain([0, d3.max(data, (d) => d.value)]).nice().range([frame.innerHeight, 0]);
  const g = frame.svg.append('g').attr('transform', `translate(${frame.margin.left},${frame.margin.top})`);
  g.append('g').attr('class', 'axis').attr('transform', `translate(0,${frame.innerHeight})`).call(d3.axisBottom(x).ticks(7));
  g.append('g').attr('class', 'axis').call(d3.axisLeft(y).ticks(5));
  g.append('path').datum(data).attr('fill', 'none').attr('stroke', '#0f0f0f').attr('stroke-width', 2.5)
    .attr('d', d3.line().x((d) => x(d.date)).y((d) => y(d.value)));
  setText('evolution-description', `${data.length} períodos. Maior valor: ${formatNumber.format(d3.max(data, (d) => d.value))} pedidos.`);
  metadata('evolution', [['Unidade', 'pedidos'], ['Agregação', 'contagem'], ['Escala', 'linear / tempo'], ['Fonte', sourceLabel(payload.source)], ['Limitação', 'pontas podem estar incompletas']]);
  updateKpi('evolution', `${formatNumber.format(d3.max(data, (d) => d.value))} pedidos`);
}

async function renderDistribution() {
  const bins = document.getElementById('distribution-bins').value;
  setText('distribution-bins-value', bins);
  const payload = await getJson(`/api/datasets/distribution?bins=${bins}`);
  state.distribution = payload;
  const data = payload.data;
  if (!data.length) return renderEmpty('distribution');
  const frame = chartFrame('distribution');
  const x = d3.scaleLinear().domain([d3.min(data, (d) => d.x0), d3.max(data, (d) => d.x1)]).range([0, frame.innerWidth]);
  const y = d3.scaleLinear().domain([0, d3.max(data, (d) => d.count)]).nice().range([frame.innerHeight, 0]);
  const g = frame.svg.append('g').attr('transform', `translate(${frame.margin.left},${frame.margin.top})`);
  g.append('g').attr('class', 'axis').attr('transform', `translate(0,${frame.innerHeight})`).call(d3.axisBottom(x).ticks(7));
  g.append('g').attr('class', 'axis').call(d3.axisLeft(y).ticks(5));
  g.selectAll('rect').data(data).join('rect').attr('x', (d) => x(d.x0) + 1).attr('y', (d) => y(d.count))
    .attr('width', (d) => Math.max(1, x(d.x1) - x(d.x0) - 2)).attr('height', (d) => frame.innerHeight - y(d.count)).attr('fill', '#0f0f0f');
  setText('distribution-description', `${payload.meta.sampleSize} preços distribuídos em ${payload.meta.bins} intervalos.`);
  metadata('distribution', [['Unidade', 'R$'], ['Agregação', 'frequência'], ['Escala', 'linear'], ['Fonte', sourceLabel(payload.source)], ['Limitação', 'amostra limitada pela API']]);
  const weightedValues = data.flatMap((bin) => Array(bin.count).fill((bin.x0 + bin.x1) / 2));
  updateKpi('distribution', formatCurrency.format(d3.median(weightedValues) ?? 0));
}

async function renderMagnitude() {
  const top = document.getElementById('magnitude-top').value;
  const payload = await getJson(`/api/datasets/magnitude?top=${top}`);
  state.magnitude = payload;
  const data = payload.data.map((row) => ({ category: row.category, value: Number(row.value) }));
  if (!data.length) return renderEmpty('magnitude');
  const frame = chartFrame('magnitude');
  const x = d3.scaleLinear().domain([0, d3.max(data, (d) => d.value)]).nice().range([0, frame.innerWidth]);
  const y = d3.scaleBand().domain(data.map((d) => d.category)).range([0, frame.innerHeight]).padding(.18);
  const g = frame.svg.append('g').attr('transform', `translate(${frame.margin.left},${frame.margin.top})`);
  g.append('g').attr('class', 'axis').attr('transform', `translate(0,${frame.innerHeight})`).call(d3.axisBottom(x).ticks(5).tickFormat(d3.format('.2s')));
  g.append('g').attr('class', 'axis').call(d3.axisLeft(y));
  g.selectAll('rect').data(data).join('rect').attr('x', 0).attr('y', (d) => y(d.category))
    .attr('width', (d) => x(d.value)).attr('height', y.bandwidth()).attr('fill', (_, index) => index === 0 ? '#0f0f0f' : '#696969');
  setText('magnitude-description', `${data.length} categorias; líder: ${data[0]?.category ?? 'sem dados'} (${formatCurrency.format(data[0]?.value ?? 0)}).`);
  metadata('magnitude', [['Unidade', 'R$'], ['Agregação', 'soma'], ['Escala', 'linear'], ['Fonte', sourceLabel(payload.source)], ['Limitação', `categorias fora do Top ${top}`]]);
  updateKpi('magnitude', data[0]?.category ?? 'Sem dados');
}

async function renderRelation() {
  const trim = document.getElementById('relation-trim').checked;
  const payload = await getJson(`/api/datasets/relation?limit=200&trimOutliers=${trim}`);
  state.relation = payload;
  const data = payload.data;
  if (!data.length) return renderEmpty('relation');
  const frame = chartFrame('relation');
  const x = d3.scaleLinear().domain([0, d3.max(data, (d) => d.price)]).nice().range([0, frame.innerWidth]);
  const y = d3.scaleLinear().domain([0, d3.max(data, (d) => d.freight)]).nice().range([frame.innerHeight, 0]);
  const g = frame.svg.append('g').attr('transform', `translate(${frame.margin.left},${frame.margin.top})`);
  g.append('g').attr('class', 'axis').attr('transform', `translate(0,${frame.innerHeight})`).call(d3.axisBottom(x).ticks(7));
  g.append('g').attr('class', 'axis').call(d3.axisLeft(y).ticks(5));
  g.selectAll('circle').data(data).join('circle').attr('cx', (d) => x(d.price)).attr('cy', (d) => y(d.freight))
    .attr('r', 3.5).attr('fill', '#0f0f0f').attr('fill-opacity', .48);
  setText('relation-description', `${data.length} itens. A associação visual não demonstra causalidade.`);
  metadata('relation', [['Unidade', 'R$ × R$'], ['Agregação', 'item'], ['Escala', 'linear'], ['Fonte', sourceLabel(payload.source)], ['Limitação', trim ? 'valores acima do P95 removidos' : 'sobreposição e extremos']]);
  updateKpi('relation', `${data.length} itens`);
}

function summarize(chartId) {
  const payload = state[chartId];
  const values = chartId === 'relation' ? payload.data.map((d) => Number(d.price))
    : chartId === 'magnitude' ? payload.data.map((d) => Number(d.value))
    : chartId === 'distribution' ? payload.data.flatMap((d) => Array(d.count).fill((d.x0 + d.x1) / 2))
    : payload.data.map((d) => Number(d.value));
  const sorted = values.toSorted((a, b) => a - b);
  return { sampleSize: values.length, min: d3.min(values), max: d3.max(values), mean: d3.mean(values), median: d3.median(sorted) };
}

async function requestCritique(chartId, button) {
  button.disabled = true;
  const target = document.getElementById(`${chartId}-agent`);
  target.textContent = 'Analisando a decisão…';
  try {
    const result = await getJson('/api/agent', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ chartId, decision: document.getElementById(`${chartId}-decision`).value, summary: summarize(chartId) })
    });
    target.replaceChildren();
    [['Observação', result.observation], ['Cuidado', result.caution], ['Sugestão', result.suggestion]].forEach(([label, text]) => {
      const paragraph = document.createElement('p');
      const strong = document.createElement('strong');
      strong.textContent = `${label}: `;
      paragraph.append(strong, document.createTextNode(text));
      target.append(paragraph);
    });
    const mode = document.createElement('p');
    mode.textContent = `Modo: ${result.mode}. Recomendação revisável; nenhuma alteração foi aplicada.`;
    target.append(mode);
  } catch { target.textContent = 'Não foi possível obter a crítica. Use o roteiro local: compare uma alternativa, declare a limitação e evite linguagem causal.'; }
  finally { button.disabled = false; }
}

async function health() {
  try {
    const result = await getJson('/api/health');
    setText('app-status', `API: ${result.app}`); setText('data-status', `Dados: ${result.database}`); setText('ai-status', `IA: ${result.ai}`);
  } catch { setText('app-status', 'API: indisponível'); }
}

document.getElementById('evolution-grain').addEventListener('change', renderEvolution);
document.getElementById('distribution-bins').addEventListener('input', renderDistribution);
document.getElementById('magnitude-top').addEventListener('change', renderMagnitude);
document.getElementById('relation-trim').addEventListener('change', renderRelation);
document.querySelectorAll('[data-agent]').forEach((button) => button.addEventListener('click', () => requestCritique(button.dataset.agent, button)));

await health();
await Promise.all([renderEvolution(), renderDistribution(), renderMagnitude(), renderRelation()]);
