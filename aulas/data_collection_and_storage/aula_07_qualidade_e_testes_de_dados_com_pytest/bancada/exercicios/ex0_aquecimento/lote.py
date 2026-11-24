"""Aquecimento: uma função pequena do coletor da Aula 03."""


def total_de_linhas(arquivos: list[dict]) -> int:
    """Soma as linhas de todos os arquivos que o coletor gravou na bronze."""
    return sum(arquivo["linhas"] for arquivo in arquivos)
