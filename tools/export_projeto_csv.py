#!/usr/bin/env python3
"""Exporta o recorte pseudonimizado do projeto do módulo para CSVs publicáveis.

Origem: data/pbl_modulo2.sqlite (dados reais e identificados, nunca versionado).
Saída: CSVs sem nome, e-mail ou username de aluno, prontos para download na página
do projeto. A instituição de origem é substituída por um nome fictício.

Pseudonimização:
  - cada pessoa recebe um código estável por grupo (G01-A01, G01-A02, ...);
  - o mapa username/e-mail/nome -> código é reaplicado em todos os campos de autoria;
  - o texto livre passa por scrub de e-mails, URLs institucionais, menções e tokens,
    e pelas ocorrências literais dos nomes reais dos membros.

Modo --completo: exporta as 15 turmas. Cada linha ganha a coluna turma, o código da
pessoa passa a levar a turma (T28-G01-A01) e a autoria é resolvida dentro do próprio
repositório, porque a mesma pessoa pode ser membro de vários grupos. A saída fica em
dados/projeto_pbl_completo/, ignorada pelo Git: o repositório é público e esse recorte
circula só no canal da turma.

Uso:
    python3 tools/export_projeto_csv.py --out dados/projeto_pbl
    python3 tools/export_projeto_csv.py --completo --out dados/projeto_pbl_completo
"""
import argparse
import csv
import json
import os
import re
import sqlite3
import unicodedata
from collections import defaultdict

TURMA = "t28"
GRUPOS = ("g01", "g02", "g03")
INSTITUICAO_FICTICIA = "Instituto Ápice"
DOMINIO_FICTICIO = "apice.edu.br"

# Padrões de reidentificação removidos do texto livre.
# O nome da instituição aparece colado a outras palavras (Intelihub, estude_no_inteli),
# então o padrão consome o sufixo — mas precisa poupar "inteligente" e "inteligência".
SCRUB = [
    (re.compile(r"[\w.\-+]+@[\w\-]+\.\w{2,}"), "[email]"),
    (re.compile(r"https?://[^\s)>\]]*inteli\.edu\.br[^\s)>\]]*", re.I), "[url-institucional]"),
    (re.compile(r"\binteli\.edu\.br\b", re.I), DOMINIO_FICTICIO),
    (re.compile(r"intel[ií](?!g[eêé]n)\w*", re.I), "Apice"),
    (re.compile(r"(?:glpat|ghp|gho|github_pat|sk-|AKIA)[\w\-]{8,}"), "[token-removido]"),
]
MENCAO = re.compile(r"(?<![\w.])@([\w.\-]{3,})")
# Handles de plataforma. Restrito a estas duas formas: um "from X/" genérico casaria
# com nomes de branch legítimos como "feature/login".
HANDLE = [
    (re.compile(r"(?i)(pull request #\d+\s+from\s+)([\w.\-]{3,})/"), 2),
    (re.compile(r"(?i)((?:github|gitlab)\.com/)([\w.\-]{3,})/"), 2),
]
# Prefixos curtos viram apelido ("Leonardo" -> "leo"), mas estes colidem com texto comum.
STOPWORDS = {
    "mar", "ana", "sol", "luz", "ver", "ler", "add", "fix", "doc", "api", "app", "dev",
    "sql", "css", "log", "req", "res", "url", "src", "lib", "bug", "job", "run", "get",
    "set", "new", "old", "the", "and", "for", "not", "com", "por", "que", "uma", "dos",
    "das", "seu", "sua", "seg", "min", "max", "sim", "nao", "seo", "pix", "cor", "rev",
    # conta administrativa da instância, homônima de termo técnico ("repo root")
    "root",
    # parte de nome indexada que colide com GitLab, GitIgnore, GitHub em camelCase
    "git",
    # palavras comuns que também aparecem como parte de nome ou de autoria git
    "hub", "projeto", "nascimento",
    # recorte completo: contas de teste e partes de nome que, no texto das 15 turmas,
    # aparecem quase sempre como vocabulário ("campos do formulário", "de forma clara")
    "teste", "test", "user", "ser", "campos", "mais", "nome", "clara", "art", "durante",
    "use", "mer", "passos", "chaves", "sup", "pessoa", "ponderada", "gera", "dias", "boas",
    "pro", "step", "int", "adr", "tom", "adm", "tree", "mil", "mes", "can", "brasil",
    "brand", "edu", "anti", "math", "aaa", "vscode", "github", "pulse", "pulse mais",
    "g04", "g06", "***", "fez", "car", "cai", "cad", "macos", "cherry", "will", "super",
    "ouro", "preto", "unknown", "dom", "mat", "lor", "val", "aaaa", "anac",
}


# O acento aparece de um lado só: "Thais" no cadastro, "Thaís" no texto do cartão —
# ou o inverso. O padrão de busca aceita as duas grafias para cada vogal.
VARIANTES = {"a": "aàáâãä", "e": "eèéêë", "i": "iìíîï", "o": "oòóôõö",
             "u": "uùúûü", "c": "cç", "n": "nñ"}


def padrao_tolerante(termo):
    """Regex que casa o termo com ou sem acento, em qualquer caixa."""
    saida = []
    for ch in norm(termo):
        grupo = VARIANTES.get(ch)
        saida.append(f"[{grupo}]" if grupo else re.escape(ch))
    return "".join(saida)


def norm(s):
    """Chave de comparação: sem acento, sem caixa, sem pontuação de borda."""
    if not s:
        return ""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return s.strip().lower()


class Pseudonimizador:
    """Mapa estável pessoa -> código, alimentado pelos membros de cada projeto."""

    def __init__(self, por_projeto=False):
        self.por_projeto = por_projeto
        self.por_chave = {}          # username/e-mail/nome normalizado -> código
        self.do_projeto = {}         # (projeto, chave) -> código, no modo por_projeto
        self.nomes_reais = []        # nomes literais, para scrub no texto livre
        self.registro = []           # linhas de pessoas.csv

    def carregar(self, con, projetos, rotulo=None):
        """rotulo(pid) devolve o prefixo do código; por padrão, o grupo."""
        for pid, grupo in projetos:
            prefixo = rotulo(pid) if rotulo else grupo.upper()
            membros = con.execute(
                "SELECT user_id, username, name, email, access_level, state "
                "FROM member WHERE project_id=? ORDER BY user_id", (pid,)).fetchall()
            for i, (uid, username, nome, email, nivel, estado) in enumerate(membros, 1):
                codigo = f"{prefixo}-A{i:02d}"
                for chave in (username, email, nome):
                    if chave:
                        self.por_chave[norm(chave)] = codigo
                        self.do_projeto[(pid, norm(chave))] = codigo
                if email and "@" in email:
                    # o local-part costuma ser o nome do aluno em commits git
                    self.por_chave.setdefault(norm(email.split("@")[0]), codigo)
                    self.do_projeto.setdefault((pid, norm(email.split("@")[0])), codigo)
                self._indexar_nome(nome)
                self.registro.append({
                    "projeto_id": pid, "grupo": grupo.upper(), "pessoa_id": codigo,
                    "papel": {50: "owner", 40: "maintainer", 30: "developer",
                              20: "reporter", 10: "guest"}.get(nivel, str(nivel)),
                    "situacao": estado or "",
                })
        # Quem aparece no rastro sem constar como membro (autoria de commit, evento de
        # cartão) também precisa entrar no dicionário de scrub.
        ph = ",".join("?" * len(projetos))
        pids = [pid for pid, _ in projetos]
        for consulta in (
                f"SELECT DISTINCT author_name FROM commit_ WHERE project_id IN ({ph})",
                f"SELECT DISTINCT committer_name FROM commit_ WHERE project_id IN ({ph})",
                f"SELECT DISTINCT user_name FROM issue_label_event WHERE project_id IN ({ph})"):
            for (valor,) in con.execute(consulta, pids):
                self._indexar_nome(valor)

        # nomes mais longos primeiro, para não deixar sobra de sobrenome
        self.nomes_reais = sorted(set(self.nomes_reais), key=len, reverse=True)
        # Bordas de palavra: sem elas "Maria" casaria dentro de "chave primária" e
        # "Erica" dentro de "genérica". \b não serve, porque trata o sublinhado como
        # letra e deixa passar o itálico do Markdown (_Fulana Silva_). A borda também
        # aceita a virada de minúscula para maiúscula, para alcançar nomes em camelCase
        # dentro de branches (feat/comp-JoseHenrique). Só o nome é insensível à caixa;
        # a borda precisa enxergar a caixa real.
        inicio = r"(?:(?<![^\W_])|(?<=[a-zà-ÿ])(?=[A-ZÀ-Þ]))"
        fim = r"(?:(?![^\W_])|(?<=[a-zà-ÿ])(?=[A-ZÀ-Þ]))"
        self._rx_nomes = (
            re.compile(inicio + r"(?i:" + "|".join(padrao_tolerante(n) for n in self.nomes_reais)
                       + r")" + fim)
            if self.nomes_reais else None)

    def _indexar_nome(self, nome):
        """Registra o nome completo, cada parte e o apelido curto, para o scrub."""
        if not nome or len(nome) < 3:
            return

        def registrar(termo):
            # padrao_tolerante já cobre as duas grafias, então basta a forma normalizada
            if len(termo) >= 3 and norm(termo) not in STOPWORDS:
                self.nomes_reais.append(norm(termo))

        registrar(nome)
        for parte in nome.split():
            registrar(parte)
        primeiro = nome.split()[0] if nome.split() else ""
        # "Leonardo" também aparece como "leo" no texto dos cartões
        for corte in (3, 4):
            if len(primeiro) > corte:
                registrar(primeiro[:corte])

    def pessoa(self, *valores, pid=None):
        """Código da pessoa a partir do primeiro identificador que resolver.

        A API do GitLab não devolve o e-mail dos membros para quem não é admin, então
        o e-mail do commit nunca casa inteiro. O que casa é o local-part contra o
        username: "fulano.silva@gmail.com" -> "fulano.silva".
        """
        for valor in valores:
            if not valor:
                continue
            candidatos = [norm(valor)]
            if "@" in valor:
                candidatos.append(norm(valor.split("@")[0]))
            for c in candidatos:
                if self.por_projeto:
                    achado = self.do_projeto.get((pid, c))
                else:
                    achado = self.por_chave.get(c)
                if achado:
                    return achado
        alvo = norm(next((v for v in valores if v), ""))
        if not alvo:
            return ""
        if "bot" in alvo or "ghost" in alvo or "noreply" in alvo:
            return "[bot]"
        return "[externo]"

    def lista(self, valor_json, pid=None):
        try:
            itens = json.loads(valor_json) if valor_json else []
        except (ValueError, TypeError):
            return ""
        return ";".join(self.pessoa(x, pid=pid) for x in itens if x)

    def texto(self, valor, pid=None):
        """Scrub do texto livre: padrões sensíveis e nomes reais dos membros."""
        if not valor:
            return ""
        t = valor
        for rx, sub in SCRUB:
            t = rx.sub(sub, t)
        # handles de plataforma antes dos nomes: "from fulanosobrenome/patch-1" é um
        # token único, que a busca por palavra inteira não alcançaria
        for rx, grupo in HANDLE:
            t = rx.sub(lambda m: f"{m.group(1)}{self.pessoa(m.group(grupo), pid=pid) or '[pessoa]'}/", t)
        if self._rx_nomes:
            t = self._rx_nomes.sub(lambda m: self.pessoa(m.group(0), pid=pid) or "[pessoa]", t)
        t = MENCAO.sub(lambda m: self.pessoa(m.group(1), pid=pid) or "[pessoa]", t)
        return t


def escrever(caminho, campos, linhas):
    with open(caminho, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=campos, extrasaction="ignore")
        w.writeheader()
        w.writerows(linhas)
    print(f"  {os.path.basename(caminho):28} {len(linhas):>7,} linhas")
    return len(linhas)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default="data/pbl_modulo2.sqlite")
    ap.add_argument("--out", default="dados/projeto_pbl")
    ap.add_argument("--completo", action="store_true",
                    help="exporta as 15 turmas, com a coluna turma e códigos T28-G01-A01")
    args = ap.parse_args()

    con = sqlite3.connect(f"file:{args.db}?mode=ro", uri=True)
    con.row_factory = sqlite3.Row
    os.makedirs(args.out, exist_ok=True)

    if args.completo:
        linhas = con.execute(
            "SELECT project_id, turma, grupo FROM project ORDER BY turma, grupo").fetchall()
    else:
        linhas = con.execute(
            "SELECT project_id, turma, grupo FROM project WHERE turma=? AND grupo IN (?,?,?) "
            "ORDER BY grupo", (TURMA, *GRUPOS)).fetchall()
        if len(linhas) != len(GRUPOS):
            raise SystemExit(f"esperados {len(GRUPOS)} projetos, encontrados {len(linhas)}")
    projetos = [(r["project_id"], r["grupo"]) for r in linhas]
    turma_de = {r["project_id"]: r["turma"].upper() for r in linhas}
    grupo_de = {r["project_id"]: r["grupo"].upper() for r in linhas}
    pids = tuple(grupo_de)
    ph = ",".join("?" * len(pids))

    ps = Pseudonimizador(por_projeto=args.completo)
    ps.carregar(con, projetos,
                rotulo=(lambda pid: f"{turma_de[pid]}-{grupo_de[pid]}") if args.completo else None)
    print(f"pessoas mapeadas: {len(ps.registro)}")

    # No modo completo, toda linha abre com turma e grupo; no recorte T28, só grupo.
    chave = ["turma", "grupo"] if args.completo else ["grupo"]

    def origem(pid):
        return {"turma": turma_de[pid], "grupo": grupo_de[pid]}

    contagens = {}

    # 1. Grupos
    contagens["grupos"] = escrever(
        f"{args.out}/grupos.csv",
        chave + ["branch_padrao", "criado_em", "ultima_atividade_em"],
        [{**origem(r[0]), "branch_padrao": r[1] or "",
          "criado_em": r[2] or "", "ultima_atividade_em": r[3] or ""}
         for r in con.execute(
             f"SELECT project_id, default_branch, created_at, last_activity_at "
             f"FROM project WHERE project_id IN ({ph}) ORDER BY turma, grupo", pids)])

    # 2. Pessoas
    contagens["pessoas"] = escrever(
        f"{args.out}/pessoas.csv", chave + ["pessoa_id", "papel", "situacao"],
        [{**origem(p["projeto_id"]), **p} for p in ps.registro])

    # 3. Sprints
    contagens["sprints"] = escrever(
        f"{args.out}/sprints.csv",
        chave + ["sprint", "situacao", "inicio_em", "prazo_em"],
        [{**origem(r[0]), "sprint": r[1], "situacao": r[2] or "",
          "inicio_em": r[3] or "", "prazo_em": r[4] or ""}
         for r in con.execute(
             f"SELECT project_id, title, state, start_date, due_date FROM milestone "
             f"WHERE project_id IN ({ph}) ORDER BY project_id, title", pids)])

    # 4. Colunas do quadro Kanban
    contagens["quadro_colunas"] = escrever(
        f"{args.out}/quadro_colunas.csv", chave + ["quadro", "posicao", "coluna"],
        [{**origem(r[0]), "quadro": r[1] or "", "posicao": r[2],
          "coluna": r[3] or ""}
         for r in con.execute(
             f"SELECT b.project_id, b.name, bl.position, bl.label_name "
             f"FROM board b JOIN board_list bl ON bl.board_id=b.board_id "
             f"WHERE b.project_id IN ({ph}) ORDER BY b.project_id, bl.position", pids)])

    # 5. Commits
    contagens["commits"] = escrever(
        f"{args.out}/commits.csv",
        chave + ["commit_id", "autor_id", "autorado_em", "commitado_em", "e_merge",
                 "linhas_adicionadas", "linhas_removidas", "linhas_total", "titulo", "mensagem"],
        [{**origem(r["project_id"]), "commit_id": r["short_id"] or r["sha"][:8],
          "autor_id": ps.pessoa(r["author_email"], r["author_name"], pid=r["project_id"]),
          "autorado_em": r["authored_date"] or "", "commitado_em": r["committed_date"] or "",
          "e_merge": r["is_merge"], "linhas_adicionadas": r["additions"],
          "linhas_removidas": r["deletions"], "linhas_total": r["total"],
          "titulo": ps.texto(r["title"], pid=r["project_id"]),
          "mensagem": ps.texto(r["message"], pid=r["project_id"])}
         for r in con.execute(
             f"SELECT * FROM commit_ WHERE project_id IN ({ph}) "
             f"ORDER BY project_id, committed_date", pids)])

    # 6. Merge requests
    contagens["merge_requests"] = escrever(
        f"{args.out}/merge_requests.csv",
        chave + ["mr_numero", "titulo", "descricao", "situacao", "criado_em",
                 "atualizado_em", "merged_em", "fechado_em", "branch_origem", "branch_destino",
                 "autor_id", "merged_por_id", "revisores_ids", "responsaveis_ids",
                 "e_rascunho", "comentarios", "sprint", "rotulos"],
        [{**origem(r["project_id"]), "mr_numero": r["iid"],
          "titulo": ps.texto(r["title"], pid=r["project_id"]),
          "descricao": ps.texto(r["description"], pid=r["project_id"]),
          "situacao": r["state"] or "", "criado_em": r["created_at"] or "",
          "atualizado_em": r["updated_at"] or "", "merged_em": r["merged_at"] or "",
          "fechado_em": r["closed_at"] or "",
          # branches como "paragrafo-escopo-do-fulano" carregam nome de pessoa
          "branch_origem": ps.texto(r["source_branch"], pid=r["project_id"]),
          "branch_destino": ps.texto(r["target_branch"], pid=r["project_id"]),
          "autor_id": ps.pessoa(r["author_username"], pid=r["project_id"]),
          "merged_por_id": ps.pessoa(r["merged_by_username"], pid=r["project_id"]),
          "revisores_ids": ps.lista(r["reviewers"], pid=r["project_id"]),
          "responsaveis_ids": ps.lista(r["assignees"], pid=r["project_id"]),
          "e_rascunho": r["draft"], "comentarios": r["user_notes_count"],
          "sprint": r["milestone_title"] or "",
          "rotulos": ";".join(json.loads(r["labels"]) if r["labels"] else [])}
         for r in con.execute(
             f"SELECT * FROM merge_request WHERE project_id IN ({ph}) "
             f"ORDER BY project_id, iid", pids)])

    # 7. Cartões (issues)
    contagens["cartoes"] = escrever(
        f"{args.out}/cartoes.csv",
        chave + ["cartao_numero", "titulo", "descricao", "situacao", "criado_em",
                 "atualizado_em", "fechado_em", "prazo_em", "autor_id", "fechado_por_id",
                 "responsaveis_ids", "rotulos", "sprint", "peso", "comentarios",
                 "tempo_estimado_s", "tempo_gasto_s"],
        [{**origem(r["project_id"]), "cartao_numero": r["iid"],
          "titulo": ps.texto(r["title"], pid=r["project_id"]),
          "descricao": ps.texto(r["description"], pid=r["project_id"]),
          "situacao": r["state"] or "", "criado_em": r["created_at"] or "",
          "atualizado_em": r["updated_at"] or "", "fechado_em": r["closed_at"] or "",
          "prazo_em": r["due_date"] or "",
          "autor_id": ps.pessoa(r["author_username"], pid=r["project_id"]),
          "fechado_por_id": ps.pessoa(r["closed_by_username"], pid=r["project_id"]),
          "responsaveis_ids": ps.lista(r["assignees"], pid=r["project_id"]),
          "rotulos": ";".join(json.loads(r["labels"]) if r["labels"] else []),
          "sprint": r["milestone_title"] or "", "peso": r["weight"],
          "comentarios": r["user_notes_count"],
          "tempo_estimado_s": r["time_estimate"], "tempo_gasto_s": r["time_spent"]}
         for r in con.execute(
             f"SELECT * FROM issue WHERE project_id IN ({ph}) "
             f"ORDER BY project_id, iid", pids)])

    # 8. Movimento dos cartões pelas colunas do quadro
    contagens["kanban_eventos"] = escrever(
        f"{args.out}/kanban_eventos.csv",
        chave + ["cartao_numero", "acao", "coluna", "pessoa_id", "ocorrido_em"],
        [{**origem(r["project_id"]), "cartao_numero": r["issue_iid"],
          "acao": r["action"] or "", "coluna": r["label_name"] or "",
          "pessoa_id": ps.pessoa(r["user_username"], r["user_name"], pid=r["project_id"]),
          "ocorrido_em": r["created_at"] or ""}
         for r in con.execute(
             f"SELECT * FROM issue_label_event WHERE project_id IN ({ph}) "
             f"ORDER BY project_id, issue_iid, created_at", pids)])

    # 9. Manifesto de proveniência
    extracao = con.execute("SELECT ciclo, extracted_at, scope FROM extraction "
                           "ORDER BY id DESC LIMIT 1").fetchone()
    turmas = sorted(set(turma_de.values()))
    manifesto = {
        "conjunto": "Projeto do módulo — rastro de trabalho PBL",
        "instituicao": INSTITUICAO_FICTICIA,
        "observacao": "Dados reais de projetos acadêmicos, pseudonimizados. "
                      "Instituição, pessoas e endereços foram substituídos.",
        "turma": turmas[0] if len(turmas) == 1 else turmas,
        "grupos": [g.upper() for g in GRUPOS] if not args.completo else len(projetos),
        "ciclo": extracao[0] if extracao else None,
        "extraido_em": extracao[1] if extracao else None,
        "recorte": extracao[2] if extracao else None,
        "pessoas_pseudonimizadas": len(ps.registro),
        "arquivos": {f"{k}.csv": v for k, v in contagens.items()},
    }
    if args.completo:
        manifesto["distribuicao"] = ("Somente no canal da turma. Não publicar em "
                                     "repositório aberto, portfólio ou rede social.")
    with open(f"{args.out}/manifesto.json", "w", encoding="utf-8") as fh:
        json.dump(manifesto, fh, ensure_ascii=False, indent=2)
    print(f"  {'manifesto.json':28} {sum(contagens.values()):>7,} linhas no total")


if __name__ == "__main__":
    main()
