from datetime import date
from decimal import Decimal

import pytest

from ptax_vigente import BOLETINS, SemCotacao, cotacao_vigente


@pytest.mark.parametrize("hoje, esperado", [
    (date(2026, 11, 19), date(2026, 11, 19)),   # dia útil
    (date(2026, 11, 20), date(2026, 11, 19)),   # feriado
    (date(2026, 11, 22), date(2026, 11, 19)),   # domingo depois do feriado
    (date(2026, 11, 29), date(2026, 11, 24)),   # último dia da janela
])
def test_data_do_boletim(hoje, esperado):
    assert cotacao_vigente(BOLETINS, hoje)[0] == esperado


def test_valor_do_boletim():
    assert cotacao_vigente(BOLETINS, date(2026, 11, 20)) == (date(2026, 11, 19), Decimal("5.8889"))


def test_fora_da_janela():
    with pytest.raises(SemCotacao):
        cotacao_vigente(BOLETINS, date(2026, 11, 30))
