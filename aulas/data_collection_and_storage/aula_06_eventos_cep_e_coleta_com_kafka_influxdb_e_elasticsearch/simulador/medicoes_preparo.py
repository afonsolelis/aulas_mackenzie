"""Medições de preparo da Aula 06 (Data Collection and Storage).

Gera eventos sintéticos da Rede Tatame (rede fictícia de academias) e mede os
números citados no slide e no material: tamanho do evento em JSON, compressão
de um lote JSONL com gzip, erro do HyperLogLog na contagem de alunos únicos e
pontuação BM25 numa busca sobre motivos de cancelamento.

Uso: python3 medicoes_preparo.py
Só biblioteca padrão. A semente é fixa, então os números se repetem.
"""

import gzip
import hashlib
import json
import math
import random
import uuid
from datetime import datetime, timedelta, timezone

random.seed(20261114)

REGIOES = {
    "sa-saopaulo": ("BR-SAO", 96),
    "us-virginia": ("US-VIR", 72),
    "eu-estocolmo": ("SE-STO", 48),
    "ap-sydney": ("AU-SYD", 24),
}
ALUNOS_POR_ACADEMIA = 150
TURMAS = ["adulto-fundamentos", "adulto-avancado", "kids-4-6", "kids-7-10", "juvenil", "feminino"]
FAIXAS = ["branca", "azul", "roxa", "marrom", "preta"]

# Proporção dos eventos de aluno (soma 100). O simulador usa taxas menores para
# os eventos raros (cancelamento, matrícula, aula experimental e graduação), para
# que as regras de CEP não disparem o tempo todo; cobranca_falhou é igual: 0,3%.
PESOS_ALUNO = {
    "app_aberto": 54.0,
    "video_assistido": 30.0,
    "reserva_aula": 8.0,
    "checkin": 4.0,
    "cobranca_aprovada": 2.0,
    "aula_experimental": 0.6,
    "matricula": 0.4,
    "cancelamento": 0.4,
    "cobranca_falhou": 0.3,
    "graduacao": 0.3,
}
MOTIVOS = [
    "mudou de cidade e não há academia da rede perto",
    "achou o preço da mensalidade alto depois do reajuste",
    "lesão no joelho, médico pediu pausa",
    "horário das turmas não encaixa no trabalho",
    "preço alto e pouca turma no horário da noite",
    "trocou por outra modalidade",
]


def aluno_hash(academia: str, n: int) -> str:
    return hashlib.sha256(f"{academia}:{n}".encode()).hexdigest()[:16]


def evento_aluno(tipo: str, quando: datetime) -> dict:
    regiao = random.choices(list(REGIOES), weights=[v[1] for v in REGIOES.values()])[0]
    prefixo, n_acad = REGIOES[regiao]
    academia = f"{prefixo}-{random.randint(1, n_acad):03d}"
    ev = {
        "event_id": str(uuid.uuid4()),
        "tipo": tipo,
        "ocorrido_em": quando.isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "regiao": regiao,
        "academia": academia,
        "aluno": aluno_hash(academia, random.randint(1, ALUNOS_POR_ACADEMIA)),
        "turma": random.choice(TURMAS),
        "faixa": random.choices(FAIXAS, weights=[55, 25, 12, 5, 3])[0],
        "origem": "catraca" if tipo == "checkin" else ("gestao" if tipo.startswith(("cobranca", "matricula", "cancel", "gradu")) else "app"),
    }
    if tipo == "cancelamento":
        ev["motivo"] = random.choice(MOTIVOS)
    if tipo.startswith("cobranca"):
        ev["faixa_valor"] = random.choice(["ate-50", "50-100", "100-150"])
    return ev


def evento_dispositivo(quando: datetime) -> dict:
    regiao = random.choices(list(REGIOES), weights=[v[1] for v in REGIOES.values()])[0]
    prefixo, n_acad = REGIOES[regiao]
    academia = f"{prefixo}-{random.randint(1, n_acad):03d}"
    return {
        "event_id": str(uuid.uuid4()),
        "tipo": "heartbeat",
        "ocorrido_em": quando.isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "regiao": regiao,
        "academia": academia,
        "dispositivo": random.choice(["catraca-1", "leitor-facial-1"]),
        "origem": "dispositivo",
        "latencia_ms": random.randint(8, 240),
    }


def tamanho(ev: dict) -> int:
    return len(json.dumps(ev, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))


# ---------------------------------------------------------------- volume
ALUNOS = 36_000
ACADEMIAS = sum(v[1] for v in REGIOES.values())
EV_ALUNO_DIA = 10
DISPOSITIVOS_POR_ACADEMIA = 2
HEARTBEATS_DIA = 24 * 60 * 2  # um a cada 30 s

ev_alunos_dia = ALUNOS * EV_ALUNO_DIA
ev_disp_dia = ACADEMIAS * DISPOSITIVOS_POR_ACADEMIA * HEARTBEATS_DIA
total_dia = ev_alunos_dia + ev_disp_dia
print("== Volume (hipóteses declaradas) ==")
print(f"academias={ACADEMIAS} alunos={ALUNOS}")
print(f"eventos de aluno/dia={ev_alunos_dia:,}  heartbeats/dia={ev_disp_dia:,}  total/dia={total_dia:,}")
print(f"média={total_dia / 86400:.1f} ev/s")

# ---------------------------------------------------------------- tamanho
base = datetime(2026, 11, 14, 11, 0, tzinfo=timezone.utc)
tipos = list(PESOS_ALUNO)
amostra = []
for i in range(100_000):
    quando = base + timedelta(milliseconds=37 * i)
    if random.random() < ev_disp_dia / total_dia:
        amostra.append(evento_dispositivo(quando))
    else:
        tipo = random.choices(tipos, weights=list(PESOS_ALUNO.values()))[0]
        amostra.append(evento_aluno(tipo, quando))

tam = [tamanho(e) for e in amostra]
media = sum(tam) / len(tam)
print("\n== Tamanho do evento (JSON compacto, UTF-8), 100.000 eventos ==")
print(f"média={media:.0f} B  mín={min(tam)} B  máx={max(tam)} B")
por_tipo = {}
for e, t in zip(amostra, tam):
    por_tipo.setdefault(e["tipo"], []).append(t)
for tipo in ("heartbeat", "checkin", "cancelamento"):
    v = por_tipo[tipo]
    print(f"  {tipo}: média {sum(v) / len(v):.0f} B em {len(v)} eventos")

jsonl = ("\n".join(json.dumps(e, ensure_ascii=False, separators=(",", ":")) for e in amostra) + "\n").encode()
gz = gzip.compress(jsonl, compresslevel=6)
print(f"JSONL={len(jsonl) / 1e6:.2f} MB  gzip-6={len(gz) / 1e6:.2f} MB  razão={len(jsonl) / len(gz):.1f}x")
dia_bruto = total_dia * media
dia_gz = dia_bruto * len(gz) / len(jsonl)
print(f"um dia: {dia_bruto / 1e6:.0f} MB em JSON, {dia_gz / 1e6:.0f} MB em JSONL.gz")
print(f"um ano: {dia_bruto * 365 / 1e9:.1f} GB em JSON, {dia_gz * 365 / 1e9:.1f} GB em JSONL.gz")
print(f"Kafka 7 dias, RF 3, sem compressão: {dia_bruto * 7 * 3 / 1e9:.1f} GB")

# ---------------------------------------------------------------- falha regional
alunos_eu = REGIOES["eu-estocolmo"][1] * ALUNOS_POR_ACADEMIA
taxa_eu = (alunos_eu * EV_ALUNO_DIA + REGIOES["eu-estocolmo"][1] * DISPOSITIVOS_POR_ACADEMIA * HEARTBEATS_DIA) / 86400
parada_s = 2 * 3600
retidos = taxa_eu * parada_s
vazao_replay = 200
print("\n== Falha do cluster eu-estocolmo por 2 h (taxa média da região) ==")
print(f"taxa={taxa_eu:.2f} ev/s  retidos={retidos:,.0f}  drenagem a {vazao_replay} ev/s={retidos / (vazao_replay - taxa_eu):.0f} s")

# ---------------------------------------------------------------- CEP: estado
falhas_dia = ev_alunos_dia * PESOS_ALUNO["cobranca_falhou"] / 100
print("\n== Estado da regra de cobrança (janela de 7 dias) ==")
print(f"cobranca_falhou/dia={falhas_dia:,.0f}  chaves em estado, no máximo={falhas_dia * 7:,.0f} de {ALUNOS:,} alunos")

# ---------------------------------------------------------------- InfluxDB: séries
tipos_total = len(PESOS_ALUNO) + 1
print("\n== Cardinalidade de séries ==")
print(f"tags regiao+academia+tipo: {ACADEMIAS * tipos_total:,} séries")
print(f"com a tag aluno nos {len(PESOS_ALUNO)} tipos de aluno: até {ALUNOS * len(PESOS_ALUNO):,} séries")
print(f"pontos/dia a 1 ponto por série por minuto: {ACADEMIAS * tipos_total * 1440:,}")


# ---------------------------------------------------------------- HyperLogLog
def hll(itens, p):
    m = 1 << p
    reg = [0] * m
    for it in itens:
        h = int.from_bytes(hashlib.sha1(it.encode()).digest()[:8], "big")
        idx = h >> (64 - p)
        resto = h & ((1 << (64 - p)) - 1)
        rank = (64 - p) - resto.bit_length() + 1
        reg[idx] = max(reg[idx], rank)
    alfa = 0.7213 / (1 + 1.079 / m)
    est = alfa * m * m / sum(2.0 ** -r for r in reg)
    zeros = reg.count(0)
    if est <= 2.5 * m and zeros:
        est = m * math.log(m / zeros)
    return est


ids = [aluno_hash("rede", n) for n in range(ALUNOS)]
fluxo = ids * 3  # cada aluno aparece três vezes: a repetição não altera a estimativa
random.shuffle(fluxo)
print("\n== HyperLogLog: alunos únicos (exato = 36.000) ==")
for p in (8, 10, 12, 14):
    est = hll(fluxo, p)
    m = 1 << p
    print(f"p={p:2d} registradores={m:6d} memória≈{m * 6 / 8 / 1024:6.2f} KB  estimativa={est:9.0f}  erro={100 * (est - ALUNOS) / ALUNOS:+.2f}%  erro padrão teórico={104 / math.sqrt(m):.2f}%")
print(f"conjunto exato com 36.000 hashes de 16 caracteres: {ALUNOS * 16 / 1024:.0f} KB só de chaves")

# ---------------------------------------------------------------- BM25
docs = MOTIVOS
tok = [d.replace(",", "").split() for d in docs]
N = len(tok)
avgdl = sum(len(t) for t in tok) / N
k1, b = 1.2, 0.75


def bm25(consulta, i):
    s = 0.0
    for termo in consulta.split():
        n = sum(1 for t in tok if termo in t)
        if not n:
            continue
        idf = math.log(1 + (N - n + 0.5) / (n + 0.5))
        f = tok[i].count(termo)
        s += idf * f * (k1 + 1) / (f + k1 * (1 - b + b * len(tok[i]) / avgdl))
    return s


print("\n== BM25 para a consulta 'preço' (k1=1,2 b=0,75) ==")
print(f"N={N} avgdl={avgdl:.2f}")
for i, d in enumerate(docs):
    s = bm25("preço", i)
    if s:
        print(f"  {s:.3f}  ({len(tok[i])} termos)  {d}")
