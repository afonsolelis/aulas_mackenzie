#!/usr/bin/env python3
"""Extrai o rastro de trabalho dos grupos PBL do GitLab institucional para SQLite.

Recorte: repositórios de grupo em graduacao/<ciclo>/<turma>/<grupo>.
Canal: estado (API REST). O movimento de cartão fica em extract_kanban_events.py.

Uso:
    python3 tools/extract_gitlab_pbl.py --ciclo 2026-1b --out data/pbl_modulo2.sqlite
"""
import argparse
import json
import re
import sqlite3
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

import requests

ENV_PATH = "/home/afonsolelis/repos/gitlab-admin/.env"
GROUP_PROJECT_RE = r"^graduacao/{ciclo}/(t\d+)/(g\d+)$"


def load_env(path):
    env = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env


class GitLab:
    """Cliente REST com paginação, retry e contador de requisições."""

    def __init__(self, url, token, workers=8):
        self.base = url.rstrip("/") + "/api/v4"
        self.local = threading.local()
        self.token = token
        self.workers = workers
        self.calls = 0
        self._lock = threading.Lock()

    @property
    def session(self):
        if not hasattr(self.local, "s"):
            s = requests.Session()
            s.headers.update({"PRIVATE-TOKEN": self.token})
            self.local.s = s
        return self.local.s

    def get_all(self, path, params=None):
        params = dict(params or {})
        params.setdefault("per_page", 100)
        out, url = [], f"{self.base}{path}"
        while url:
            for attempt in range(5):
                try:
                    r = self.session.get(url, params=params if "?" not in url else None, timeout=90)
                except requests.RequestException:
                    time.sleep(2 * (attempt + 1))
                    continue
                if r.status_code == 429:
                    time.sleep(int(r.headers.get("Retry-After", 5)))
                    continue
                if r.status_code in (404, 403):
                    return out
                if r.status_code >= 500:
                    time.sleep(2 * (attempt + 1))
                    continue
                break
            else:
                return out
            with self._lock:
                self.calls += 1
            try:
                body = r.json()
            except ValueError:
                return out
            if isinstance(body, dict):
                return [body]
            out.extend(body)
            nxt = r.links.get("next", {}).get("url")
            url, params = nxt, None
        return out

    def map(self, fn, items):
        with ThreadPoolExecutor(max_workers=self.workers) as ex:
            futs = {ex.submit(fn, it): it for it in items}
            for f in as_completed(futs):
                yield f.result()


SCHEMA = """
PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS extraction (
  id INTEGER PRIMARY KEY, ciclo TEXT, gitlab_url TEXT, extracted_at TEXT,
  extracted_by TEXT, projects INTEGER, api_calls INTEGER, scope TEXT);

CREATE TABLE IF NOT EXISTS project (
  project_id INTEGER PRIMARY KEY, path TEXT, ciclo TEXT, turma TEXT, grupo TEXT,
  name TEXT, default_branch TEXT, created_at TEXT, last_activity_at TEXT, web_url TEXT);

CREATE TABLE IF NOT EXISTS member (
  project_id INTEGER, user_id INTEGER, username TEXT, name TEXT, email TEXT,
  access_level INTEGER, state TEXT, membership_source TEXT,
  PRIMARY KEY (project_id, user_id));

CREATE TABLE IF NOT EXISTS branch (
  project_id INTEGER, name TEXT, is_default INTEGER, merged INTEGER, protected INTEGER,
  commit_sha TEXT, commit_date TEXT, commit_author TEXT,
  PRIMARY KEY (project_id, name));

CREATE TABLE IF NOT EXISTS milestone (
  project_id INTEGER, iid INTEGER, title TEXT, state TEXT,
  start_date TEXT, due_date TEXT, created_at TEXT,
  PRIMARY KEY (project_id, iid));

CREATE TABLE IF NOT EXISTS board (
  board_id INTEGER PRIMARY KEY, project_id INTEGER, name TEXT);

CREATE TABLE IF NOT EXISTS board_list (
  board_id INTEGER, list_id INTEGER, position INTEGER, list_type TEXT, label_name TEXT,
  PRIMARY KEY (board_id, list_id));

CREATE TABLE IF NOT EXISTS commit_ (
  project_id INTEGER, sha TEXT, short_id TEXT, title TEXT, message TEXT,
  author_name TEXT, author_email TEXT, authored_date TEXT,
  committer_name TEXT, committer_email TEXT, committed_date TEXT, created_at TEXT,
  parent_count INTEGER, is_merge INTEGER,
  additions INTEGER, deletions INTEGER, total INTEGER, web_url TEXT,
  PRIMARY KEY (project_id, sha));

CREATE TABLE IF NOT EXISTS merge_request (
  project_id INTEGER, iid INTEGER, title TEXT, description TEXT, state TEXT,
  created_at TEXT, updated_at TEXT, merged_at TEXT, closed_at TEXT,
  source_branch TEXT, target_branch TEXT, author_username TEXT,
  merged_by_username TEXT, merge_commit_sha TEXT, sha TEXT, draft INTEGER,
  user_notes_count INTEGER, upvotes INTEGER, downvotes INTEGER,
  milestone_title TEXT, labels TEXT, assignees TEXT, reviewers TEXT, web_url TEXT,
  PRIMARY KEY (project_id, iid));

CREATE TABLE IF NOT EXISTS issue (
  project_id INTEGER, iid INTEGER, title TEXT, description TEXT, state TEXT,
  created_at TEXT, updated_at TEXT, closed_at TEXT, due_date TEXT,
  author_username TEXT, closed_by_username TEXT, assignees TEXT, labels TEXT,
  milestone_title TEXT, weight INTEGER, user_notes_count INTEGER,
  time_estimate INTEGER, time_spent INTEGER, web_url TEXT,
  PRIMARY KEY (project_id, iid));

CREATE TABLE IF NOT EXISTS issue_label_event (
  event_id INTEGER PRIMARY KEY, project_id INTEGER, issue_iid INTEGER,
  action TEXT, label_name TEXT, label_color TEXT,
  user_username TEXT, user_name TEXT, created_at TEXT);

CREATE INDEX IF NOT EXISTS ix_commit_proj ON commit_(project_id, committed_date);
CREATE INDEX IF NOT EXISTS ix_commit_author ON commit_(author_email);
CREATE INDEX IF NOT EXISTS ix_mr_proj ON merge_request(project_id, created_at);
CREATE INDEX IF NOT EXISTS ix_issue_proj ON issue(project_id, created_at);
CREATE INDEX IF NOT EXISTS ix_label_ev ON issue_label_event(project_id, issue_iid, created_at);
"""


def j(v):
    return json.dumps(v, ensure_ascii=False) if v else None


def names(lst, key="username"):
    return j([x.get(key) for x in (lst or []) if isinstance(x, dict)])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ciclo", default="2026-1b")
    ap.add_argument("--out", default="data/pbl_modulo2.sqlite")
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()

    env = load_env(ENV_PATH)
    gl = GitLab(env["GITLAB_URL"], env["GITLAB_PAT"], args.workers)

    # 1. Localiza o grupo raiz do ciclo e os repositórios de grupo PBL.
    roots = gl.get_all("/groups", {"search": args.ciclo})
    root = next((g for g in roots if g["full_path"] == f"graduacao/{args.ciclo}"), None)
    if not root:
        sys.exit(f"grupo graduacao/{args.ciclo} não encontrado")

    print(f"[1/8] grupo raiz: {root['full_path']} (id {root['id']})", flush=True)
    allp = gl.get_all(f"/groups/{root['id']}/projects",
                      {"include_subgroups": "true", "archived": "false"})
    rx = re.compile(GROUP_PROJECT_RE.format(ciclo=re.escape(args.ciclo)))
    projects = []
    for p in allp:
        m = rx.match(p["path_with_namespace"])
        if m:
            projects.append((p, m.group(1), m.group(2)))
    print(f"      {len(allp)} projetos no ciclo, {len(projects)} são repositórios de grupo PBL",
          flush=True)

    con = sqlite3.connect(args.out)
    con.executescript(SCHEMA)

    con.executemany(
        "INSERT OR REPLACE INTO project VALUES (?,?,?,?,?,?,?,?,?,?)",
        [(p["id"], p["path_with_namespace"], args.ciclo, turma, grupo, p["name"],
          p.get("default_branch"), p.get("created_at"), p.get("last_activity_at"),
          p.get("web_url")) for p, turma, grupo in projects])
    con.commit()
    ids = [p["id"] for p, _, _ in projects]

    def stage(n, label, path_fn, params_fn=None):
        print(f"[{n}/8] {label}...", end=" ", flush=True)
        res = {}
        for pid, rows in gl.map(
                lambda pid: (pid, gl.get_all(path_fn(pid), params_fn(pid) if params_fn else None)),
                ids):
            res[pid] = rows
        print(f"{sum(len(v) for v in res.values())} registros", flush=True)
        return res

    # 2. Membros
    mem = stage(2, "membros", lambda pid: f"/projects/{pid}/members/all")
    con.executemany("INSERT OR REPLACE INTO member VALUES (?,?,?,?,?,?,?,?)",
                    [(pid, m["id"], m.get("username"), m.get("name"), m.get("email"),
                      m.get("access_level"), m.get("state"), m.get("membership_state"))
                     for pid, rows in mem.items() for m in rows])

    # 3. Branches
    br = stage(3, "branches", lambda pid: f"/projects/{pid}/repository/branches")
    con.executemany("INSERT OR REPLACE INTO branch VALUES (?,?,?,?,?,?,?,?)",
                    [(pid, b["name"], int(bool(b.get("default"))), int(bool(b.get("merged"))),
                      int(bool(b.get("protected"))), (b.get("commit") or {}).get("id"),
                      (b.get("commit") or {}).get("committed_date"),
                      (b.get("commit") or {}).get("author_name"))
                     for pid, rows in br.items() for b in rows])

    # 4. Milestones (sprints)
    ms = stage(4, "milestones", lambda pid: f"/projects/{pid}/milestones")
    con.executemany("INSERT OR REPLACE INTO milestone VALUES (?,?,?,?,?,?,?)",
                    [(pid, m["iid"], m.get("title"), m.get("state"), m.get("start_date"),
                      m.get("due_date"), m.get("created_at"))
                     for pid, rows in ms.items() for m in rows])

    # 5. Boards e colunas
    bd = stage(5, "boards", lambda pid: f"/projects/{pid}/boards")
    for pid, rows in bd.items():
        for b in rows:
            con.execute("INSERT OR REPLACE INTO board VALUES (?,?,?)",
                        (b["id"], pid, b.get("name")))
            con.executemany("INSERT OR REPLACE INTO board_list VALUES (?,?,?,?,?)",
                            [(b["id"], l["id"], l.get("position"), l.get("list_type"),
                              (l.get("label") or {}).get("name")) for l in b.get("lists", [])])

    # 6. Commits com estatísticas de linhas
    cm = stage(6, "commits", lambda pid: f"/projects/{pid}/repository/commits",
               lambda pid: {"all": "true", "with_stats": "true"})
    con.executemany("INSERT OR REPLACE INTO commit_ VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    [(pid, c["id"], c.get("short_id"), c.get("title"), c.get("message"),
                      c.get("author_name"), c.get("author_email"), c.get("authored_date"),
                      c.get("committer_name"), c.get("committer_email"), c.get("committed_date"),
                      c.get("created_at"), len(c.get("parent_ids") or []),
                      int(len(c.get("parent_ids") or []) > 1),
                      (c.get("stats") or {}).get("additions"),
                      (c.get("stats") or {}).get("deletions"),
                      (c.get("stats") or {}).get("total"), c.get("web_url"))
                     for pid, rows in cm.items() for c in rows])

    # 7. Merge requests
    mr = stage(7, "merge requests", lambda pid: f"/projects/{pid}/merge_requests",
               lambda pid: {"state": "all", "scope": "all"})
    con.executemany(
        "INSERT OR REPLACE INTO merge_request VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        [(pid, m["iid"], m.get("title"), m.get("description"), m.get("state"),
          m.get("created_at"), m.get("updated_at"), m.get("merged_at"), m.get("closed_at"),
          m.get("source_branch"), m.get("target_branch"),
          (m.get("author") or {}).get("username"), (m.get("merged_by") or {}).get("username"),
          m.get("merge_commit_sha"), m.get("sha"), int(bool(m.get("draft"))),
          m.get("user_notes_count"), m.get("upvotes"), m.get("downvotes"),
          (m.get("milestone") or {}).get("title"), j(m.get("labels")),
          names(m.get("assignees")), names(m.get("reviewers")), m.get("web_url"))
         for pid, rows in mr.items() for m in rows])

    # 8. Issues (cartões do quadro)
    iss = stage(8, "issues", lambda pid: f"/projects/{pid}/issues",
                lambda pid: {"state": "all", "scope": "all"})
    con.executemany(
        "INSERT OR REPLACE INTO issue VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        [(pid, i["iid"], i.get("title"), i.get("description"), i.get("state"),
          i.get("created_at"), i.get("updated_at"), i.get("closed_at"), i.get("due_date"),
          (i.get("author") or {}).get("username"), (i.get("closed_by") or {}).get("username"),
          names(i.get("assignees")), j(i.get("labels")),
          (i.get("milestone") or {}).get("title"), i.get("weight"), i.get("user_notes_count"),
          (i.get("time_stats") or {}).get("time_estimate"),
          (i.get("time_stats") or {}).get("total_time_spent"), i.get("web_url"))
         for pid, rows in iss.items() for i in rows])
    con.commit()

    con.execute("DELETE FROM extraction")
    con.execute("INSERT INTO extraction VALUES (1,?,?,?,?,?,?,?)",
                (args.ciclo, env["GITLAB_URL"], datetime.now(timezone.utc).isoformat(),
                 "afonso.brandao", len(projects), gl.calls,
                 "repositorios de grupo PBL: graduacao/<ciclo>/<turma>/<grupo>; "
                 "canal de estado (API REST) + movimento de cartao (resource_label_events); "
                 "sem diff por commit e sem comentarios"))
    con.commit()

    print("\n=== resumo ===")
    for t in ("project", "member", "branch", "milestone", "board", "board_list",
              "commit_", "merge_request", "issue", "issue_label_event"):
        n = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        print(f"  {t:20s} {n:>8d}")
    print(f"  {'chamadas à API':20s} {gl.calls:>8d}")
    con.close()


if __name__ == "__main__":
    main()
