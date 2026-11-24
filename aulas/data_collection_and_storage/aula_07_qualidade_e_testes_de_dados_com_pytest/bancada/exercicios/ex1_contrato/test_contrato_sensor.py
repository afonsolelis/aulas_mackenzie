import pytest

from contrato_sensor import motivo_de_rejeicao

VALIDA = {"device_id": "estufa-a-03", "temperatura": 24.6, "unidade": "C", "umidade": 61.2}


def leitura(**alteracoes):
    return {**VALIDA, **alteracoes}


def test_leitura_tipica_entra():
    assert motivo_de_rejeicao(leitura()) is None


def test_umidade_absurda_vai_para_a_quarentena():
    assert motivo_de_rejeicao(leitura(umidade=150.0)) == "umidade_fora_da_faixa"


# Sua vez: partições e valores-limite.
# Complete a tabela abaixo com os limites de cada faixa (o valor no limite e o
# vizinho de fora), a conversão de Fahrenheit e os campos de formato.
@pytest.mark.parametrize(
    "alteracoes, esperado",
    [
        ({"temperatura": 60.0}, None),
        # ({"temperatura": 60.1}, "temperatura_fora_da_faixa"),
    ],
)
def test_particoes_e_limites(alteracoes, esperado):
    assert motivo_de_rejeicao(leitura(**alteracoes)) == esperado
