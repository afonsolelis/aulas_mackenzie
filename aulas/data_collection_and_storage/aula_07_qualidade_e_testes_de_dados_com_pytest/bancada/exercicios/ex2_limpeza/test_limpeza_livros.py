from decimal import Decimal

import pytest

from limpeza_livros import nota_em_estrelas, preco_em_libras, unidades_em_estoque


def test_preco_com_libra_vira_decimal():
    assert preco_em_libras("£51.77") == Decimal("51.77")


# Ciclo 1 (vermelho): o preço como ele chega de verdade na bronze.
# def test_preco_da_bronze_com_mojibake():
#     assert preco_em_libras("Â£51.77") == Decimal("51.77")

# Ciclo 2: unidades_em_estoque("In stock (22 available)") == 22, e "Out of stock"?
# Ciclo 3: nota_em_estrelas("Three") == 3, e um texto que não é nota?
# Ciclo 4: o que acontece com "51.77" sem a libra, ou "£51.7"? Decida e teste.
