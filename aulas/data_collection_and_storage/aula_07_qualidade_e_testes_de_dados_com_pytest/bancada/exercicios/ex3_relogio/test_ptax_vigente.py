from datetime import date
from decimal import Decimal

import pytest

from ptax_vigente import BOLETINS, cotacao_vigente


def test_existe_cotacao_para_hoje():
    # Este teste passava quando foi escrito, numa terça-feira. Rode agora.
    data, valor = cotacao_vigente(BOLETINS)
    assert valor > 0


# Depois de injetar o relógio, os testes passam a escolher o dia:
# def test_dia_util_usa_o_proprio_boletim():
#     assert cotacao_vigente(BOLETINS, date(2026, 11, 19)) == (date(2026, 11, 19), Decimal("5.8889"))
