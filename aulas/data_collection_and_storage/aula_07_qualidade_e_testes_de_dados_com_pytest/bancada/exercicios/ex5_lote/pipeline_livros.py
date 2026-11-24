"""Bronze -> silver -> gold dos livros (Aulas 03 a 05), em memória, para a bancada.

A silver tem um livro por UPC, com preço, estoque e nota limpos.
A quarentena guarda a linha da bronze que não passou na limpeza, com o motivo.
A gold resume a silver por categoria.
"""

import re
from decimal import ROUND_HALF_EVEN, Decimal

_PRECO = re.compile(r"^(?:Â)?£\s*(\d+\.\d{2})$")
_ESTOQUE = re.compile(r"^In stock \((\d+) available\)$")
_NOTAS = {"One": 1, "Two": 2, "Three": 3, "Four": 4, "Five": 5}


def limpar(linha: dict) -> dict:
    preco = _PRECO.match(linha["preco"].strip())
    if not preco:
        raise ValueError(f"preço fora do formato: {linha['preco']!r}")
    if linha["estoque"].strip() == "Out of stock":
        estoque = 0
    else:
        achado = _ESTOQUE.match(linha["estoque"].strip())
        if not achado:
            raise ValueError(f"estoque fora do formato: {linha['estoque']!r}")
        estoque = int(achado.group(1))
    if linha["nota"].strip() not in _NOTAS:
        raise ValueError(f"nota desconhecida: {linha['nota']!r}")
    return {
        "upc": linha["upc"],
        "titulo": linha["titulo"],
        "categoria": linha["categoria"].strip(),
        "preco_gbp": Decimal(preco.group(1)),
        "estoque": estoque,
        "nota": _NOTAS[linha["nota"].strip()],
    }


def processar(bronze: list[dict]) -> dict:
    silver, quarentena, duplicadas, vistos = [], [], [], set()
    for posicao, linha in enumerate(bronze):
        if linha["upc"] in vistos:
            duplicadas.append({"posicao": posicao, "upc": linha["upc"]})
            continue
        try:
            limpa = limpar(linha)
        except ValueError as erro:
            quarentena.append({"posicao": posicao, "upc": linha["upc"], "motivo": str(erro)})
            continue
        vistos.add(linha["upc"])
        silver.append(limpa)

    gold = {}
    for categoria in sorted({livro["categoria"] for livro in silver}):
        itens = [livro for livro in silver if livro["categoria"] == categoria]
        media = sum(livro["preco_gbp"] for livro in itens) / len(itens)
        gold[categoria] = {
            "livros": len(itens),
            "preco_medio_gbp": media.quantize(Decimal("0.01"), rounding=ROUND_HALF_EVEN),
            "estoque_total": sum(livro["estoque"] for livro in itens),
        }
    return {"silver": silver, "quarentena": quarentena, "duplicadas": duplicadas, "gold": gold}
