import json
from datetime import date
from decimal import Decimal
from pathlib import Path

import pytest

from coletor_ptax import ErroColeta, coletar

# Resposta real da API, gravada em 24/11/2026 (o mesmo papel de um cassete do VCR).
BOLETIM = json.loads((Path(__file__).parent / "boletim_ptax.json").read_text(encoding="utf-8"))

INICIO, FIM = date(2026, 11, 13), date(2026, 11, 24)


def stub_ok(url):
    """Stub: devolve sempre a mesma resposta, sem rede."""
    return 200, BOLETIM


def test_boletim_real_tem_sete_dias_uteis():
    cotacoes = coletar(stub_ok, INICIO, FIM, esperar=lambda s: None)
    assert len(cotacoes) == 7


class Espiao:
    """Spy: responde com uma fila de respostas e guarda as URLs que recebeu."""

    def __init__(self, *respostas):
        self.respostas = list(respostas)
        self.urls = []

    def __call__(self, url):
        self.urls.append(url)
        return self.respostas.pop(0)


# Sua vez. Ideias de testes, um por comportamento:
# - a venda de 19/11/2026 é exatamente Decimal("5.8889");
# - a URL leva as datas no formato MM-DD-AAAA ('11-13-2026');
# - feriado ou fim de semana: {"value": []} vira lista vazia, sem erro;
# - 503 e depois 200: duas chamadas e uma espera de 1 s (troque esperar por uma lista);
# - 503 três vezes: ErroColeta, três chamadas, esperas [1, 2];
# - 404: ErroColeta na primeira chamada, nenhuma espera.
