"""Cotação vigente do dólar para converter os preços da gold.

Boletins de fechamento (venda) da PTAX, publicados pelo Banco Central de
13/11 a 24/11/2026. Não há boletim em 14, 15, 21 e 22/11 (fins de semana)
nem em 20/11 (feriado nacional da Consciência Negra).
"""

from datetime import date
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


def cotacao_vigente(boletins=BOLETINS):
    """Devolve (data do boletim, cotação) que vale para hoje."""
    hoje = date.today()
    return hoje, boletins[hoje]
