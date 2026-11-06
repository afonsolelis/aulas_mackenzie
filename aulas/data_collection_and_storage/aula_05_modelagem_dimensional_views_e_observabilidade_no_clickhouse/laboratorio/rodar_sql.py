"""Roda um arquivo .sql no ClickHouse da turma pela interface HTTPS, um comando por vez.

A interface HTTP do ClickHouse aceita um comando por requisição. Este script separa o arquivo
nos ";" que estão fora de texto e de comentário, troca o prefixo g00_ pelo do grupo e envia
cada comando na mesma sessão (um SET vale para os comandos seguintes).

Uso (na pasta que tem o .env):
    python rodar_sql.py sql/001_dimensoes_e_fatos.sql
    python rodar_sql.py -q "SELECT data_tag, count() FROM mackenzie.db_ingestion GROUP BY data_tag"

Só biblioteca padrão: roda no Codespace sem pip install.
"""
import argparse
import base64
import os
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid


def ler_env(caminho: pathlib.Path) -> None:
    """Carrega CHAVE=valor do .env sem sobrescrever o que já está no ambiente."""
    if not caminho.exists():
        return
    for linha in caminho.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if linha and not linha.startswith("#") and "=" in linha:
            chave, valor = linha.split("=", 1)
            os.environ.setdefault(chave.strip(), valor.strip())


def separar(sql: str) -> list[str]:
    """Divide nos ';' fora de 'texto', de "identificador" e de comentários -- e /* */."""
    comandos, atual, i, n = [], [], 0, len(sql)
    while i < n:
        c = sql[i]
        if c == "-" and sql.startswith("--", i):
            fim = sql.find("\n", i)
            i = n if fim < 0 else fim
            continue
        if c == "/" and sql.startswith("/*", i):
            fim = sql.find("*/", i + 2)
            i = n if fim < 0 else fim + 2
            continue
        if c in "'\"`":
            j = i + 1
            while j < n and sql[j] != c:
                j += 2 if sql[j] == "\\" else 1
            atual.append(sql[i:j + 1])
            i = j + 1
            continue
        if c == ";":
            comandos.append("".join(atual).strip())
            atual = []
        else:
            atual.append(c)
        i += 1
    comandos.append("".join(atual).strip())
    return [c for c in comandos if c]


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("arquivo", nargs="?", help="arquivo .sql")
    p.add_argument("-q", "--query", help="um comando direto, em vez de arquivo")
    p.add_argument("--env", default=".env")
    a = p.parse_args()
    ler_env(pathlib.Path(a.env))

    url = os.environ.get("CLICKHOUSE_URL", "https://clickhouse.afonsolelis.tech")
    usuario = os.environ.get("CLICKHOUSE_USER", "turma")
    senha = os.environ.get("CLICKHOUSE_PASSWORD")
    grupo = os.environ.get("GRUPO", "g00").strip().lower()
    if not senha:
        sys.exit("Defina CLICKHOUSE_PASSWORD no .env (a senha está no slide da aula).")
    if not (len(grupo) == 3 and grupo[0] == "g" and grupo[1:].isdigit()):
        sys.exit(f"GRUPO={grupo!r}: use g seguido de dois dígitos, por exemplo g07.")

    if a.query:
        texto = a.query
    elif a.arquivo:
        texto = pathlib.Path(a.arquivo).read_text(encoding="utf-8")
    else:
        sys.exit("Informe um arquivo .sql ou -q \"comando\".")

    auth = base64.b64encode(f"{usuario}:{senha}".encode()).decode()
    sessao = f"{grupo}-{uuid.uuid4().hex[:8]}"
    for k, comando in enumerate(separar(texto.replace("g00_", f"{grupo}_")), start=1):
        params = urllib.parse.urlencode({"session_id": sessao, "default_format": "PrettyCompactNoEscapes"})
        req = urllib.request.Request(f"{url}/?{params}", data=comando.encode("utf-8"),
                                     headers={"Authorization": f"Basic {auth}"})
        resumo = " ".join(comando.split())[:90]
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                saida = r.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            print(f"[{k}] ERRO em: {resumo}\n{e.read().decode('utf-8', 'replace')}", file=sys.stderr)
            sys.exit(1)
        print(f"[{k}] ok: {resumo}")
        if saida.strip():
            print(saida.rstrip())


if __name__ == "__main__":
    main()
