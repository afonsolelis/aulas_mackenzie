"""Testes sobre o dado: rodam depois do pipeline e decidem se o lote publica."""

import json
from decimal import Decimal
from pathlib import Path

import pytest

from pipeline_livros import processar

BRONZE = json.loads((Path(__file__).parent / "lote_bronze.json").read_text(encoding="utf-8"))


@pytest.fixture
def lote():
    return processar(BRONZE)


def test_silver_nao_esta_vazia(lote):
    assert len(lote["silver"]) > 0


# Sua vez. Uma dimensão da ISO/IEC 25012 por teste:
# - unicidade: nenhum UPC aparece duas vezes na silver;
# - completude da reconciliação: bronze = silver + quarentena + duplicadas, linha por linha;
# - rastreabilidade: toda linha da quarentena tem motivo;
# - consistência: nenhuma categoria da gold tem espaço sobrando no nome;
# - exatidão da gold: livros por categoria e preço médio recalculados a partir da silver.
