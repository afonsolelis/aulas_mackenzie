#!/usr/bin/env python3
"""Coleta o movimento de cartões no quadro (resource_label_events) das issues já extraídas.

Cada coluna do quadro corresponde a um rótulo, então a passagem de um cartão pelas
colunas é reconstruída pareando cada `add` com o `remove` seguinte do mesmo rótulo.

Retomável: só busca issues ainda não visitadas. Uma issue sem nenhum evento também
fica marcada como visitada, para não ser rebuscada a cada execução.

Uso: python3 tools/extract_kanban_events.py --db data/pbl_modulo2.sqlite
"""
import argparse
import sqlite3
import sys

sys.path.insert(0, "tools")
from extract_gitlab_pbl import ENV_PATH, GitLab, load_env  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default="data/pbl_modulo2.sqlite")
    ap.add_argument("--workers", type=int, default=10)
    args = ap.parse_args()

    env = load_env(ENV_PATH)
    gl = GitLab(env["GITLAB_URL"], env["GITLAB_PAT"], args.workers)
    con = sqlite3.connect(args.db, timeout=60)
    con.execute("CREATE TABLE IF NOT EXISTS issue_events_done "
                "(project_id INTEGER, issue_iid INTEGER, n INTEGER, "
                "PRIMARY KEY (project_id, issue_iid))")
    con.commit()

    pending = con.execute(
        "SELECT i.project_id, i.iid FROM issue i "
        "LEFT JOIN issue_events_done d ON d.project_id=i.project_id AND d.issue_iid=i.iid "
        "WHERE d.project_id IS NULL").fetchall()
    print(f"issues pendentes: {len(pending)}", flush=True)

    buf, done_buf, done = [], [], 0
    for (pid, iid), evs in gl.map(
            lambda t: (t, gl.get_all(
                f"/projects/{t[0]}/issues/{t[1]}/resource_label_events")), pending):
        for e in evs:
            buf.append((e["id"], pid, iid, e.get("action"),
                        (e.get("label") or {}).get("name"),
                        (e.get("label") or {}).get("color"),
                        (e.get("user") or {}).get("username"),
                        (e.get("user") or {}).get("name"), e.get("created_at")))
        done_buf.append((pid, iid, len(evs)))
        done += 1
        if done % 400 == 0:
            con.executemany("INSERT OR REPLACE INTO issue_label_event VALUES (?,?,?,?,?,?,?,?,?)", buf)
            con.executemany("INSERT OR REPLACE INTO issue_events_done VALUES (?,?,?)", done_buf)
            con.commit()
            buf, done_buf = [], []
            print(f"  {done}/{len(pending)} issues | {gl.calls} chamadas", flush=True)

    con.executemany("INSERT OR REPLACE INTO issue_label_event VALUES (?,?,?,?,?,?,?,?,?)", buf)
    con.executemany("INSERT OR REPLACE INTO issue_events_done VALUES (?,?,?)", done_buf)
    con.commit()
    n = con.execute("SELECT COUNT(*) FROM issue_label_event").fetchone()[0]
    print(f"\nconcluído: {n} eventos de rótulo | {gl.calls} chamadas")
    con.close()


if __name__ == "__main__":
    main()
