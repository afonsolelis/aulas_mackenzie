"""Motor da bancada da Aula 07: roda o pytest de verdade, no navegador (Pyodide) ou no terminal.

O mesmo arquivo serve aos dois lados. No navegador, bancada_aula_07.js grava os
arquivos do exercício no sistema de arquivos do Pyodide e chama rodar() e avaliar().
No terminal, `python bancada.py <exercicio>` avalia os arquivos originais, para o
professor conferir o manifesto antes da aula.
"""

import contextlib
import io
import json
import os
import shutil
import sys
import time

import pytest

sys.dont_write_bytecode = True
_contador = [0]


class _Coletor:
    def __init__(self):
        self.aprovados, self.reprovados, self.erros = [], [], []

    def pytest_runtest_logreport(self, report):
        if report.when == "call" or (report.when == "setup" and report.outcome != "passed"):
            nome = report.nodeid.split("::", 1)[-1]
            if report.passed and report.when == "call":
                self.aprovados.append(nome)
            elif report.failed:
                (self.reprovados if report.when == "call" else self.erros).append(nome)

    def pytest_collectreport(self, report):
        if report.failed:
            self.erros.append(report.nodeid or "coleta")


def _limpar_modulos(pasta):
    for nome, modulo in list(sys.modules.items()):
        arquivo = getattr(modulo, "__file__", None) or ""
        if arquivo.startswith(pasta):
            del sys.modules[nome]


def _sleep_bloqueado(segundos):
    raise RuntimeError(
        "time.sleep(%s) travaria a página: no navegador a espera é de verdade. "
        "Injete esperar no teste, por exemplo esperar=esperas.append." % segundos)


def rodar(arquivos, testes=None, verboso=True):
    """Grava `arquivos` ({nome: conteúdo}) numa pasta nova e roda o pytest nela."""
    _contador[0] += 1
    base = os.path.join(os.environ.get("BANCADA_TMP", "/tmp"), "bancada_run_%d" % _contador[0])
    shutil.rmtree(base, ignore_errors=True)
    os.makedirs(base)
    for nome, conteudo in arquivos.items():
        with open(os.path.join(base, nome), "w", encoding="utf-8") as f:
            f.write(conteudo)
    alvos = [t for t in (testes or sorted(n for n in arquivos if n.startswith("test_")))]
    coletor = _Coletor()
    saida = io.StringIO()
    args = ["-p", "no:cacheprovider", "--rootdir", base, "--import-mode=importlib",
            "--color=no", "--tb=short", "-q" if not verboso else "-v", "-W", "ignore::DeprecationWarning"]
    sys.path.insert(0, base)
    anterior = os.getcwd()
    os.chdir(base)
    inicio = time.perf_counter()
    sleep_original = time.sleep
    if sys.platform == "emscripten":
        # No Pyodide o sleep para a thread da página (e os slides junto).
        time.sleep = _sleep_bloqueado
    try:
        with contextlib.redirect_stdout(saida), contextlib.redirect_stderr(saida):
            codigo = pytest.main(args + alvos, plugins=[coletor])
    finally:
        time.sleep = sleep_original
        os.chdir(anterior)
        sys.path.remove(base)
        _limpar_modulos(base)
        shutil.rmtree(base, ignore_errors=True)
    texto = saida.getvalue().replace(base + os.sep, "").replace(base, ".")
    return {"codigo": int(codigo), "saida": texto, "aprovados": coletor.aprovados,
            "reprovados": coletor.reprovados, "erros": coletor.erros,
            "ms": round((time.perf_counter() - inicio) * 1000)}


def _aplicar(conteudo, mutante):
    if mutante["de"] not in conteudo:
        raise ValueError("mutante %s não se aplica: trecho não encontrado" % mutante["id"])
    return conteudo.replace(mutante["de"], mutante["para"], 1)


def avaliar(exercicio, arquivos_aluno, ocultos):
    """Avalia o exercício.

    exercicio: entrada do manifesto.
    arquivos_aluno: {nome: conteúdo} como está no editor.
    ocultos: {nome: conteúdo} dos arquivos de referência e verificação.
    """
    testes = exercicio.get("testes_do_aluno", [])
    resultado = {"principal": rodar(arquivos_aluno, testes, verboso=False)}

    # 1. A implementação do aluno passa na verificação do professor?
    if exercicio.get("verificacao"):
        arquivos = {n: c for n, c in arquivos_aluno.items() if not n.startswith("test_")}
        arquivos["test_verificacao.py"] = ocultos[exercicio["verificacao"]]
        resultado["verificacao"] = rodar(arquivos, ["test_verificacao.py"], verboso=False)

    # 2. Os testes do aluno aprovam a versão correta?
    referencia = dict(arquivos_aluno)
    for nome, oculto in exercicio.get("referencia", {}).items():
        referencia[nome] = ocultos[oculto] if oculto in ocultos else arquivos_aluno[nome]
    resultado["referencia"] = rodar(referencia, testes, verboso=False)

    # 3. Os testes do aluno reprovam cada mutante?
    mutantes = []
    if resultado["referencia"]["codigo"] == 0:
        for mutante in exercicio.get("mutantes", []):
            arquivos = dict(referencia)
            arquivos[mutante["arquivo"]] = _aplicar(arquivos[mutante["arquivo"]], mutante)
            r = rodar(arquivos, testes, verboso=False)
            mutantes.append({"id": mutante["id"], "descricao": mutante["descricao"],
                             "morto": r["codigo"] != 0, "pegou": r["reprovados"] + r["erros"]})
    resultado["mutantes"] = mutantes
    return resultado


def avaliar_json(exercicio_json, aluno_json, ocultos_json):
    return json.dumps(avaliar(json.loads(exercicio_json), json.loads(aluno_json), json.loads(ocultos_json)),
                      ensure_ascii=False)


def rodar_json(aluno_json, testes_json):
    return json.dumps(rodar(json.loads(aluno_json), json.loads(testes_json) or None), ensure_ascii=False)


if __name__ == "__main__":
    # Uso: python bancada.py ex1_contrato [pasta_com_versao_alternativa_dos_testes]
    raiz = os.path.dirname(os.path.abspath(__file__))
    manifesto = json.load(open(os.path.join(raiz, "exercicios", "manifesto.json"), encoding="utf-8"))
    nome = sys.argv[1]
    ex = manifesto[nome]
    pasta = os.path.join(raiz, "exercicios", nome)
    alt = sys.argv[2] if len(sys.argv) > 2 else None
    ler = lambda p: open(p, encoding="utf-8").read()
    aluno = {a["nome"]: ler(os.path.join(alt if alt and os.path.exists(os.path.join(alt, a["nome"])) else pasta, a["nome"]))
             for a in ex["arquivos"]}
    ocultos = {o: ler(os.path.join(pasta, o)) for o in ex.get("ocultos", [])}
    r = avaliar(ex, aluno, ocultos)
    p = r["principal"]
    print("principal: código %d, %d aprovados, %d reprovados, %d erros, %d ms"
          % (p["codigo"], len(p["aprovados"]), len(p["reprovados"]), len(p["erros"]), p["ms"]))
    if "verificacao" in r:
        v = r["verificacao"]
        print("verificação: código %d, %d aprovados, %d reprovados" % (v["codigo"], len(v["aprovados"]), len(v["reprovados"])))
    print("referência: código %d" % r["referencia"]["codigo"])
    if r["referencia"]["codigo"]:
        print(r["referencia"]["saida"][-1500:])
    mortos = sum(m["morto"] for m in r["mutantes"])
    print("mutantes mortos: %d de %d" % (mortos, len(r["mutantes"])))
    for m in r["mutantes"]:
        print("  %s %s  %s" % ("X" if m["morto"] else ".", m["id"], m["descricao"]))
