"""Verificação do professor: roda sobre a ptax_vigente.py do aluno."""

from datetime import date
from decimal import Decimal

import pytest

from ptax_vigente import BOLETINS, SemCotacao, cotacao_vigente


@pytest.mark.parametrize("hoje, esperado", [
    (date(2026, 11, 19), (date(2026, 11, 19), Decimal("5.8889"))),
    (date(2026, 11, 20), (date(2026, 11, 19), Decimal("5.8889"))),
    (date(2026, 11, 22), (date(2026, 11, 19), Decimal("5.8889"))),
    (date(2026, 11, 23), (date(2026, 11, 23), Decimal("5.9708"))),
    (date(2026, 11, 29), (date(2026, 11, 24), Decimal("5.8573"))),
])
def test_cotacao_vigente(hoje, esperado):
    assert cotacao_vigente(BOLETINS, hoje) == esperado


@pytest.mark.parametrize("hoje", [date(2026, 11, 30), date(2026, 11, 12)])
def test_sem_boletim_na_janela(hoje):
    with pytest.raises(SemCotacao):
        cotacao_vigente(BOLETINS, hoje)


def test_hoje_e_parametro_obrigatorio():
    with pytest.raises(TypeError):
        cotacao_vigente(BOLETINS)
