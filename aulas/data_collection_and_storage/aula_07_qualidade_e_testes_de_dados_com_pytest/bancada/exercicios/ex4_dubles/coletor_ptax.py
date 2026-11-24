"""Coletor do boletim PTAX (Aula 03), com o HTTP e a espera injetados.

http_get(url) devolve (status, corpo), com o corpo já convertido de JSON em dict.
No código de produção ele é uma função pequena sobre requests.get; no teste é um dublê.
"""

import time
from datetime import date, datetime
from decimal import Decimal

BASE = ("https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/"
        "CotacaoDolarPeriodo(dataInicial=@dataInicial,dataFinalCotacao=@dataFinalCotacao)")


class ErroColeta(RuntimeError):
    pass


def montar_url(inicio: date, fim: date) -> str:
    # A API do Banco Central espera as datas como MM-DD-AAAA, entre aspas simples.
    return f"{BASE}?@dataInicial='{inicio:%m-%d-%Y}'&@dataFinalCotacao='{fim:%m-%d-%Y}'&$format=json"


def interpretar(item: dict) -> dict:
    momento = datetime.strptime(item["dataHoraCotacao"], "%Y-%m-%d %H:%M:%S.%f")
    return {
        "data": momento.date(),
        "compra": Decimal(str(item["cotacaoCompra"])),
        "venda": Decimal(str(item["cotacaoVenda"])),
    }


def coletar(http_get, inicio: date, fim: date, tentativas: int = 3, esperar=time.sleep) -> list[dict]:
    url = montar_url(inicio, fim)
    for tentativa in range(1, tentativas + 1):
        status, corpo = http_get(url)
        if status == 200:
            return [interpretar(item) for item in corpo["value"]]
        if status < 500:
            # Erro do pedido (400, 404): repetir a mesma URL não muda a resposta.
            raise ErroColeta(f"HTTP {status} em {url}")
        if tentativa < tentativas:
            esperar(2 ** (tentativa - 1))  # 1 s, depois 2 s
    raise ErroColeta(f"HTTP {status} depois de {tentativas} tentativas")
