"""Reenvia telemetria para mackenzie.db_ingestion durante a aula, com o horário de agora.

As views em janela (últimos 5 ou 15 minutos) só mostram algo se chegar dado novo. Este script
copia, a cada intervalo, um bloco de linhas de telemetria que já estão na tabela de pouso para ela mesma,
com timestamp = agora. Cada bloco é um INSERT: dispara as views materializadas de todos
os grupos, como um lote do servidor da Aula 04.

A reentrega repete (caminhao, instante) já existentes: nos fatos com ReplacingMergeTree, o FINAL
continua devolvendo uma linha por chave do grão; nos contadores por minuto, a chegada aparece.

Uso (professor, com a senha do usuário ingestao no ambiente; só biblioteca padrão):
    export CLICKHOUSE_INGESTAO_PASSWORD=...      # .env da raiz do repositório
    python reenviar_ao_vivo.py                   # 40 linhas a cada 5 s, até Ctrl+C
    python reenviar_ao_vivo.py --linhas 100 --intervalo 2
"""
import argparse
import base64
import os
import sys
import time
import urllib.parse
import urllib.request

URL = os.environ.get("CLICKHOUSE_URL", "https://clickhouse.afonsolelis.tech")


def consultar(sql: str, auth: str) -> str:
    # materialized_views_ignore_errors: a view quebrada de um grupo não derruba o INSERT da turma inteira.
    params = {"query": sql, "materialized_views_ignore_errors": 1}
    req = urllib.request.Request(f"{URL}/?{urllib.parse.urlencode(params)}", data=b"",
                                 headers={"Authorization": f"Basic {auth}"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8").strip()


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--linhas", type=int, default=40, help="linhas por INSERT")
    p.add_argument("--intervalo", type=float, default=5.0, help="segundos entre INSERTs")
    a = p.parse_args()
    senha = os.environ.get("CLICKHOUSE_INGESTAO_PASSWORD")
    if not senha:
        sys.exit("Defina CLICKHOUSE_INGESTAO_PASSWORD (DCS_CLICKHOUSE_INGESTAO_PASSWORD no .env da raiz).")
    auth = base64.b64encode(f"ingestao:{senha}".encode()).decode()

    # Entra no rodízio o que já estava na tabela na partida: os reenvios desta execução ficam de fora.
    limite = int(consultar("SELECT max(timestamp) FROM mackenzie.db_ingestion WHERE data_tag = 'telemetria'", auth) or 0)
    total = int(consultar(f"SELECT count() FROM mackenzie.db_ingestion WHERE data_tag = 'telemetria' AND timestamp <= {limite}", auth) or 0)
    if total == 0:
        sys.exit("Sem telemetria em db_ingestion. Rode carregar_pouso.py antes.")
    print(f"{total} linhas de telemetria no rodízio; {a.linhas} a cada {a.intervalo:g} s. Ctrl+C para parar.")

    deslocamento = 0
    try:
        while True:
            consultar(f"""INSERT INTO mackenzie.db_ingestion
                SELECT toUInt64(toUnixTimestamp64Milli(now64(3))), data_json, data_tag
                FROM mackenzie.db_ingestion
                WHERE data_tag = 'telemetria' AND timestamp <= {limite}
                ORDER BY timestamp LIMIT {a.linhas} OFFSET {deslocamento}""", auth)
            deslocamento = (deslocamento + a.linhas) % total
            print(f"{time.strftime('%H:%M:%S')} +{a.linhas} linhas (posição {deslocamento}/{total})", flush=True)
            time.sleep(a.intervalo)
    except KeyboardInterrupt:
        print("parado")


if __name__ == "__main__":
    main()
