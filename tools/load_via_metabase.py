#!/usr/bin/env python3
"""Carrega o SQLite do módulo PBL no Postgres lido pelo Metabase.

Esse Postgres fica na rede interna do Railway e não é alcançável por psql daqui,
mas o endpoint /api/dataset do Metabase executa SQL nativo contra ele. O DDL e os
INSERT são enviados por ali, em lotes. O Metabase devolve HTTP 400 para comandos
que não produzem ResultSet — o comando é executado mesmo assim, então esse erro
específico é tratado como sucesso e qualquer outro é propagado.

A senha do Metabase é a credencial compartilhada da turma, a mesma publicada na
home da disciplina; passe --password para usar outra.

Uso: python3 tools/load_via_metabase.py --db data/pbl_modulo2.sqlite
"""
import argparse
import json
import sqlite3
import time
import urllib.error
import urllib.request

MB = "https://metabase-production-76b0.up.railway.app"
DB_ID = 2
SCHEMA = "pbl"
NO_RESULTSET = "did not produce a ResultSet"

# Nome no Postgres -> (tabela no SQLite, DDL, linhas por lote)
TABLES = [
    ("extracao", "extraction", """
        id int primary key, ciclo text, gitlab_url text, extraido_em text,
        extraido_por text, projetos int, chamadas_api int, escopo text""", 500),
    ("projeto", "project", """
        project_id bigint primary key, path text, ciclo text, turma text, grupo text,
        name text, default_branch text, created_at timestamptz,
        last_activity_at timestamptz, web_url text""", 500),
    ("membro", "member", """
        project_id bigint, user_id bigint, username text, name text, email text,
        access_level int, state text, membership_source text,
        primary key (project_id, user_id)""", 500),
    ("branch", "branch", """
        project_id bigint, name text, is_default int, merged int, protected int,
        commit_sha text, commit_date timestamptz, commit_author text,
        primary key (project_id, name)""", 500),
    ("sprint", "milestone", """
        project_id bigint, iid int, title text, state text,
        start_date date, due_date date, created_at timestamptz,
        primary key (project_id, iid)""", 500),
    ("quadro", "board", """
        board_id bigint primary key, project_id bigint, name text""", 500),
    ("quadro_coluna", "board_list", """
        board_id bigint, list_id bigint, position int, list_type text, label_name text,
        primary key (board_id, list_id)""", 500),
    ("commit", "commit_", """
        project_id bigint, sha text, short_id text, title text, message text,
        author_name text, author_email text, authored_date timestamptz,
        committer_name text, committer_email text, committed_date timestamptz,
        created_at timestamptz, parent_count int, is_merge int,
        additions int, deletions int, total int, web_url text,
        primary key (project_id, sha)""", 200),
    ("merge_request", "merge_request", """
        project_id bigint, iid int, title text, description text, state text,
        created_at timestamptz, updated_at timestamptz, merged_at timestamptz,
        closed_at timestamptz, source_branch text, target_branch text,
        author_username text, merged_by_username text, merge_commit_sha text, sha text,
        draft int, user_notes_count int, upvotes int, downvotes int,
        milestone_title text, labels text, assignees text, reviewers text, web_url text,
        primary key (project_id, iid)""", 100),
    ("cartao", "issue", """
        project_id bigint, iid int, title text, description text, state text,
        created_at timestamptz, updated_at timestamptz, closed_at timestamptz,
        due_date date, author_username text, closed_by_username text, assignees text,
        labels text, milestone_title text, weight int, user_notes_count int,
        time_estimate int, time_spent int, web_url text,
        primary key (project_id, iid)""", 100),
    ("cartao_movimento", "issue_label_event", """
        event_id bigint primary key, project_id bigint, issue_iid int,
        action text, label_name text, label_color text,
        user_username text, user_name text, created_at timestamptz""", 500),
]

INDEXES = [
    f"create index if not exists ix_commit_proj on {SCHEMA}.commit (project_id, committed_date)",
    f"create index if not exists ix_commit_autor on {SCHEMA}.commit (author_email)",
    f"create index if not exists ix_mr_proj on {SCHEMA}.merge_request (project_id, created_at)",
    f"create index if not exists ix_cartao_proj on {SCHEMA}.cartao (project_id, created_at)",
    f"create index if not exists ix_mov on {SCHEMA}.cartao_movimento (project_id, issue_iid, created_at)",
]


def login(user, password):
    body = json.dumps({"username": user, "password": password}).encode()
    req = urllib.request.Request(MB + "/api/session", data=body, method="POST",
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())["id"]


def run(token, sql, retries=3):
    """Executa SQL nativo. Retorna as linhas, ou None quando não há ResultSet."""
    body = json.dumps({"database": DB_ID, "type": "native",
                       "native": {"query": sql}}).encode()
    for attempt in range(retries):
        req = urllib.request.Request(MB + "/api/dataset", data=body, method="POST",
                                     headers={"Content-Type": "application/json",
                                              "X-Metabase-Session": token})
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                d = json.loads(r.read())
            if d.get("error"):
                raise RuntimeError(d["error"][:400])
            return d["data"]["rows"]
        except urllib.error.HTTPError as e:
            detail = e.read().decode()
            if NO_RESULTSET in detail:
                return None
            if attempt == retries - 1:
                raise RuntimeError(f"HTTP {e.code}: {detail[:400]}")
            time.sleep(3 * (attempt + 1))
        except urllib.error.URLError:
            if attempt == retries - 1:
                raise
            time.sleep(3 * (attempt + 1))


def lit(v):
    """Literal SQL. Remove NUL, que o Postgres rejeita em text."""
    if v is None:
        return "null"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).replace("\x00", "")
    return "'" + s.replace("'", "''") + "'"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default="data/pbl_modulo2.sqlite")
    ap.add_argument("--user", default="alunos@aula.local")
    ap.add_argument("--password", default="OlistAula2026!")
    ap.add_argument("--only", nargs="*")
    args = ap.parse_args()

    token = login(args.user, args.password)
    con = sqlite3.connect(args.db)
    run(token, f"create schema if not exists {SCHEMA}")

    for pg_name, sqlite_name, ddl, chunk in TABLES:
        if args.only and pg_name not in args.only:
            continue
        total = con.execute(f'SELECT COUNT(*) FROM "{sqlite_name}"').fetchone()[0]
        run(token, f'drop table if exists {SCHEMA}."{pg_name}" cascade')
        run(token, f'create table {SCHEMA}."{pg_name}" ({ddl})')

        cur = con.execute(f'SELECT * FROM "{sqlite_name}"')
        sent, t0 = 0, time.time()
        while True:
            rows = cur.fetchmany(chunk)
            if not rows:
                break
            values = ",".join("(" + ",".join(lit(v) for v in r) + ")" for r in rows)
            run(token, f'insert into {SCHEMA}."{pg_name}" values {values}')
            sent += len(rows)
            if sent % (chunk * 20) == 0 or sent == total:
                print(f"  {pg_name:18s} {sent:>7d}/{total} "
                      f"({time.time() - t0:.0f}s)", flush=True)
        print(f"  {pg_name:18s} concluída: {sent} linhas", flush=True)

    if not args.only:
        for ix in INDEXES:
            run(token, ix)
    con.close()

    print("\n=== conferência no Postgres do Metabase ===")
    rows = run(token, f"""
        select table_name, (xpath('/row/c/text()',
               query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name),
               false, true, '')))[1]::text::bigint as linhas
        from information_schema.tables where table_schema='{SCHEMA}' order by 1""")
    for name, n in rows:
        print(f"  {name:20s} {n:>8}")


if __name__ == "__main__":
    main()
