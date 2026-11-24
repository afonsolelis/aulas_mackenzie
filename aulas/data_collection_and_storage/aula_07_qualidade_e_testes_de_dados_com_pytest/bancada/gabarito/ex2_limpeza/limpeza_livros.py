"""Referência do professor para a limpeza dos livros."""

import re
from decimal import Decimal

_PRECO = re.compile(r"^(?:Â)?£\s*(\d+\.\d{2})$")
_ESTOQUE = re.compile(r"^In stock \((\d+) available\)$")
_NOTAS = {"One": 1, "Two": 2, "Three": 3, "Four": 4, "Five": 5}


def preco_em_libras(texto: str) -> Decimal:
    achado = _PRECO.match(texto.strip())
    if not achado:
        raise ValueError(f"preço fora do formato: {texto!r}")
    return Decimal(achado.group(1))


def unidades_em_estoque(texto: str) -> int:
    limpo = texto.strip()
    if limpo == "Out of stock":
        return 0
    achado = _ESTOQUE.match(limpo)
    if not achado:
        raise ValueError(f"estoque fora do formato: {texto!r}")
    return int(achado.group(1))


def nota_em_estrelas(texto: str) -> int:
    try:
        return _NOTAS[texto.strip()]
    except KeyError:
        raise ValueError(f"nota desconhecida: {texto!r}") from None
