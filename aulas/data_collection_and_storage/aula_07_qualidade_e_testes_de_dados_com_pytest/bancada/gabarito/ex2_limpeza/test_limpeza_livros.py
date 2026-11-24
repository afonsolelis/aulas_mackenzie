from decimal import Decimal

import pytest

from limpeza_livros import nota_em_estrelas, preco_em_libras, unidades_em_estoque


@pytest.mark.parametrize("texto", ["£51.77", "Â£51.77"])
def test_preco_vira_decimal_exato(texto):
    valor = preco_em_libras(texto)
    assert isinstance(valor, Decimal)
    assert valor == Decimal("51.77")


@pytest.mark.parametrize("texto", ["51.77", "£51.7", ""])
def test_preco_fora_do_formato(texto):
    with pytest.raises(ValueError):
        preco_em_libras(texto)


@pytest.mark.parametrize("texto, esperado", [("In stock (22 available)", 22), ("In stock (1 available)", 1), ("Out of stock", 0)])
def test_estoque(texto, esperado):
    assert unidades_em_estoque(texto) == esperado


@pytest.mark.parametrize("texto, esperado", [("One", 1), ("Two", 2), ("Three", 3), ("Four", 4), ("Five", 5)])
def test_nota(texto, esperado):
    assert nota_em_estrelas(texto) == esperado


def test_nota_desconhecida():
    with pytest.raises(ValueError):
        nota_em_estrelas("Zero")
