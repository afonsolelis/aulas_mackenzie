"""Carrega mackenzie.db_ingestion com o dados_aula_04.zip, como o servidor de ingestão da Aula 04 gravaria.

Uma linha por objeto: livros um por mensagem, os 40 boletins PTAX numa mensagem só (mesmo timestamp)
e a telemetria uma linha por linha de arquivo, {"arquivo", "numero_linha", "linha"}. A chegada fica
espalhada nos últimos 25 minutos, na ordem do enviar_entrada.py, em INSERTs de 500 linhas (FLUSH_N).
Resultado esperado: livros 1.000, ptax 40, telemetria 31.265 (32.305 linhas).

Uso (professor; serve para recarregar se a turma apagar ou esvaziar a tabela):
    export CLICKHOUSE_INGESTAO_PASSWORD=...      # DCS_CLICKHOUSE_INGESTAO_PASSWORD no .env da raiz
    python carregar_pouso.py                     # lê o zip da Aula 04 sem descompactar
A tabela precisa existir (sql/000_db_ingestion.sql, rodado pelo professor com usuário administrador).
Rodar duas vezes duplica as linhas: esvazie antes se for recarga completa.
"""
import argparse
import base64
import json
import os
import pathlib
import sys
import time
import urllib.parse
import urllib.request
import zipfile

AQUI = pathlib.Path(__file__).resolve().parent
ZIP_PADRAO = AQUI.parents[2] / "aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse/laboratorio/dados/dados_aula_04.zip"


def mensagens(z: zipfile.ZipFile) -> list[tuple[str, list[dict]]]:
    nomes = sorted(z.namelist())
    ler = lambda n: z.read(n).decode("utf-8").splitlines()
    msgs = [("livros", [json.loads(l)]) for n in nomes if n.startswith("entrada/livros/") and n.endswith(".jsonl")
            for l in ler(n) if l.strip()]
    for n in (n for n in nomes if n.startswith("entrada/ptax/") and n.endswith(".jsonl")):
        lista = [json.loads(l) for l in ler(n) if l.strip()]
        if lista:
            msgs.append(("ptax", lista))
    for n in (n for n in nomes if n.startswith("entrada/telemetria/") and n.endswith(".txt")):
        for i, linha in enumerate(ler(n), start=1):
            msgs.append(("telemetria", [{"arquivo": n, "numero_linha": i, "linha": linha}]))
    return msgs


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--zip", default=str(ZIP_PADRAO))
    a = p.parse_args()
    senha = os.environ.get("CLICKHOUSE_INGESTAO_PASSWORD")
    if not senha:
        sys.exit("Defina CLICKHOUSE_INGESTAO_PASSWORD (DCS_CLICKHOUSE_INGESTAO_PASSWORD no .env da raiz).")
    url = os.environ.get("CLICKHOUSE_URL", "https://clickhouse.afonsolelis.tech")

    with zipfile.ZipFile(a.zip) as z:
        msgs = mensagens(z)
    fim = time.time_ns() // 1_000_000
    inicio, passo = fim - 25 * 60 * 1000, 25 * 60 * 1000 / len(msgs)
    linhas = [json.dumps({"timestamp": int(inicio + k * passo), "data_json": o, "data_tag": tag}, ensure_ascii=False)
              for k, (tag, objs) in enumerate(msgs) for o in objs]

    # Mesmos settings do consumidor da Aula 04: datas e horas ficam como texto dentro do JSON.
    # materialized_views_ignore_errors: a view quebrada de um grupo não derruba a carga.
    q = urllib.parse.urlencode({"query": "INSERT INTO mackenzie.db_ingestion FORMAT JSONEachRow", "async_insert": 0,
                                "input_format_try_infer_dates": 0, "input_format_try_infer_datetimes": 0,
                                "materialized_views_ignore_errors": 1})
    auth = base64.b64encode(f"ingestao:{senha}".encode()).decode()
    for b in range(0, len(linhas), 500):
        corpo = ("\n".join(linhas[b:b + 500]) + "\n").encode("utf-8")
        req = urllib.request.Request(f"{url}/?{q}", data=corpo, headers={"Authorization": f"Basic {auth}"})
        urllib.request.urlopen(req, timeout=60).read()
    print(f"mensagens {len(msgs)}, linhas {len(linhas)}, INSERTs {-(-len(linhas) // 500)}")


if __name__ == "__main__":
    main()
