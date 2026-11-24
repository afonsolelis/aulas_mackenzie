"""Limpeza dos campos de texto que o scraper da Aula 03 grava na bronze.

Valores reais da bronze, coletados de books.toscrape.com com requests:
    preço:      "Â£51.77"   (o servidor não declara charset e o requests decodifica como ISO-8859-1)
    estoque:    "In stock (22 available)"  ou  "Out of stock"
    nota:       "Three"     (vem da classe CSS star-rating Three)
"""

from decimal import Decimal


def preco_em_libras(texto: str) -> Decimal:
    return Decimal(texto.replace("£", ""))


def unidades_em_estoque(texto: str) -> int:
    raise NotImplementedError("escreva o teste primeiro")


def nota_em_estrelas(texto: str) -> int:
    raise NotImplementedError("escreva o teste primeiro")
