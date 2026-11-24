import json
from collections import Counter
from decimal import ROUND_HALF_EVEN, Decimal
from pathlib import Path

import pytest

from pipeline_livros import processar

BRONZE = json.loads((Path(__file__).parent / "lote_bronze.json").read_text(encoding="utf-8"))


@pytest.fixture
def lote():
    return processar(BRONZE)


def test_unicidade_do_upc(lote):
    repetidos = [u for u, n in Counter(l["upc"] for l in lote["silver"]).items() if n > 1]
    assert repetidos == []


def test_reconciliacao(lote):
    assert len(BRONZE) == len(lote["silver"]) + len(lote["quarentena"]) + len(lote["duplicadas"])


def test_quarentena_tem_motivo(lote):
    assert all(item["motivo"] for item in lote["quarentena"])


def test_categorias_sem_espaco(lote):
    assert all(c == c.strip() for c in lote["gold"])


def test_gold_recalculada(lote):
    for categoria, linha in lote["gold"].items():
        itens = [l for l in lote["silver"] if l["categoria"] == categoria]
        media = (sum(l["preco_gbp"] for l in itens) / len(itens)).quantize(Decimal("0.01"), rounding=ROUND_HALF_EVEN)
        assert linha["livros"] == len(itens)
        assert linha["preco_medio_gbp"] == media
