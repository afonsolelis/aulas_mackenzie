from lote import total_de_linhas


def test_soma_as_linhas_de_tres_arquivos():
    # Arrange: três arquivos que o coletor gravou na bronze
    arquivos = [
        {"chave": "bronze/books_toscrape/pagina_01.json", "linhas": 20},
        {"chave": "bronze/books_toscrape/pagina_02.json", "linhas": 20},
        {"chave": "bronze/books_toscrape/pagina_50.json", "linhas": 20},
    ]
    # Act
    total = total_de_linhas(arquivos)
    # Assert: troque 60 por 61, rode de novo e leia o relatório do pytest
    assert total == 60


def test_lote_vazio_tem_zero_linhas():
    assert total_de_linhas([]) == 0
