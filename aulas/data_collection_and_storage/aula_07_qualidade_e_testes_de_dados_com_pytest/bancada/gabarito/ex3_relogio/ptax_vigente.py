"""Referência do professor: relógio injetado e janela de busca."""

from datetime import date, timedelta
from decimal import Decimal

BOLETINS = {
    date(2026, 11, 13): Decimal("5.6518"),
    date(2026, 11, 16): Decimal("5.7324"),
    date(2026, 11, 17): Decimal("5.7851"),
    date(2026, 11, 18): Decimal("5.8102"),
    date(2026, 11, 19): Decimal("5.8889"),
    date(2026, 11, 23): Decimal("5.9708"),
    date(2026, 11, 24): Decimal("5.8573"),
}

JANELA_DIAS = 5


class SemCotacao(LookupError):
    """Nenhum boletim na janela: a conversão para e o lote vai para a quarentena."""


def cotacao_vigente(boletins, hoje):
    """Boletim do próprio dia ou do dia mais recente antes dele, até JANELA_DIAS para trás."""
    for atras in range(JANELA_DIAS + 1):
        dia = hoje - timedelta(days=atras)
        if dia in boletins:
            return dia, boletins[dia]
    raise SemCotacao(f"nenhum boletim entre {hoje - timedelta(days=JANELA_DIAS)} e {hoje}")
