const evolutionMonthly = [
  ['2017-01-01', 245], ['2017-02-01', 552], ['2017-03-01', 907],
  ['2017-04-01', 789], ['2017-05-01', 1130], ['2017-06-01', 1014],
  ['2017-07-01', 1242], ['2017-08-01', 1358], ['2017-09-01', 1301],
  ['2017-10-01', 1457], ['2017-11-01', 2387], ['2017-12-01', 1732],
  ['2018-01-01', 2254], ['2018-02-01', 2112], ['2018-03-01', 2182],
  ['2018-04-01', 2059], ['2018-05-01', 2091], ['2018-06-01', 1993]
].map(([period, value]) => ({ period, value }));

const prices = [
  12, 18, 21, 24, 28, 31, 35, 39, 42, 44, 48, 52, 55, 58, 61, 65, 68,
  72, 75, 79, 83, 87, 92, 98, 105, 112, 120, 131, 145, 160, 182, 210,
  245, 290, 360, 480, 690, 980, 1350
];

const magnitude = [
  ['cama_mesa_banho', 1712553], ['beleza_saude', 1258681],
  ['relogios_presentes', 1205005], ['esporte_lazer', 988049],
  ['informatica_acessorios', 911954], ['moveis_decoracao', 729762],
  ['utilidades_domesticas', 632248], ['cool_stuff', 635291],
  ['automotivo', 592721], ['ferramentas_jardim', 485256],
  ['brinquedos', 483947], ['bebes', 411764]
].map(([category, value]) => ({ category, value }));

const relation = Array.from({ length: 120 }, (_, index) => {
  const price = 15 + ((index * 37) % 430);
  const freight = 8 + price * 0.075 + ((index * 13) % 24);
  return { price, freight: Number(freight.toFixed(2)) };
});

export const fallback = Object.freeze({ evolutionMonthly, prices, magnitude, relation });

export function aggregateFallbackEvolution(grain) {
  if (grain === 'month') return evolutionMonthly;
  const multiplier = grain === 'week' ? 4 : 28;
  return evolutionMonthly.flatMap((row, monthIndex) =>
    Array.from({ length: multiplier }, (_, index) => ({
      period: new Date(Date.parse(row.period) + index * (grain === 'week' ? 604800000 : 86400000))
        .toISOString()
        .slice(0, 10),
      value: Math.max(1, Math.round(row.value / multiplier + ((index + monthIndex) % 7) - 3))
    }))
  );
}
