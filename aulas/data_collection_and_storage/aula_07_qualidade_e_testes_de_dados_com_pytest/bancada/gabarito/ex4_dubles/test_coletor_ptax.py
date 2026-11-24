import json
from datetime import date
from decimal import Decimal
from pathlib import Path

import pytest

from coletor_ptax import ErroColeta, coletar

BOLETIM = json.loads((Path(__file__).parent / "boletim_ptax.json").read_text(encoding="utf-8"))
INICIO, FIM = date(2026, 11, 13), date(2026, 11, 24)


class Espiao:
    def __init__(self, *respostas):
        self.respostas = list(respostas)
        self.urls = []

    def __call__(self, url):
        self.urls.append(url)
        return self.respostas.pop(0)


def test_venda_exata_de_19_11():
    cotacoes = coletar(Espiao((200, BOLETIM)), INICIO, FIM, esperar=lambda s: None)
    dia = next(c for c in cotacoes if c["data"] == date(2026, 11, 19))
    assert dia["venda"] == Decimal("5.8889")
    assert dia["compra"] == Decimal("5.8883")


def test_url_com_datas_mm_dd_aaaa():
    espiao = Espiao((200, BOLETIM))
    coletar(espiao, INICIO, FIM, esperar=lambda s: None)
    assert "@dataInicial='11-13-2026'" in espiao.urls[0]
    assert "@dataFinalCotacao='11-24-2026'" in espiao.urls[0]


def test_feriado_devolve_lista_vazia():
    assert coletar(Espiao((200, {"value": []})), date(2026, 11, 20), date(2026, 11, 20), esperar=lambda s: None) == []


def test_503_depois_200():
    espiao, esperas = Espiao((503, {}), (200, BOLETIM)), []
    assert len(coletar(espiao, INICIO, FIM, esperar=esperas.append)) == 7
    assert len(espiao.urls) == 2 and esperas == [1]


def test_503_tres_vezes():
    espiao, esperas = Espiao((503, {}), (503, {}), (503, {})), []
    with pytest.raises(ErroColeta):
        coletar(espiao, INICIO, FIM, esperar=esperas.append)
    assert len(espiao.urls) == 3 and esperas == [1, 2]


def test_404_nao_repete():
    espiao, esperas = Espiao((404, {})), []
    with pytest.raises(ErroColeta):
        coletar(espiao, INICIO, FIM, esperar=esperas.append)
    assert len(espiao.urls) == 1 and esperas == []
