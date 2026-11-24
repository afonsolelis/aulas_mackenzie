"""Verificação do professor: roda sobre a limpeza_livros.py do aluno."""

from decimal import Decimal

import pytest

from limpeza_livros import nota_em_estrelas, preco_em_libras, unidades_em_estoque


@pytest.mark.parametrize("texto, esperado", [
    ("£51.77", Decimal("51.77")), ("Â£51.77", Decimal("51.77")), (" Â£13.99 ", Decimal("13.99")),
])
def test_preco(texto, esperado):
    valor = preco_em_libras(texto)
    assert isinstance(valor, Decimal) and valor == esperado


@pytest.mark.parametrize("texto", ["51.77", "", "£", "R$ 51,77"])
def test_preco_invalido_levanta_valueerror(texto):
    with pytest.raises(ValueError):
        preco_em_libras(texto)


@pytest.mark.parametrize("texto, esperado", [
    ("In stock (22 available)", 22), ("In stock (1 available)", 1), ("Out of stock", 0),
])
def test_estoque(texto, esperado):
    assert unidades_em_estoque(texto) == esperado


def test_estoque_invalido_levanta_valueerror():
    with pytest.raises(ValueError):
        unidades_em_estoque("Available soon")


@pytest.mark.parametrize("texto, esperado", [("One", 1), ("Three", 3), ("Five", 5)])
def test_nota(texto, esperado):
    assert nota_em_estrelas(texto) == esperado


@pytest.mark.parametrize("texto", ["Zero", "Six", ""])
def test_nota_invalida_levanta_valueerror(texto):
    with pytest.raises(ValueError):
        nota_em_estrelas(texto)
