import pytest

from contrato_sensor import motivo_de_rejeicao

VALIDA = {"device_id": "estufa-a-03", "temperatura": 24.6, "unidade": "C", "umidade": 61.2}


def leitura(**alteracoes):
    return {**VALIDA, **alteracoes}


def test_leitura_tipica_entra():
    assert motivo_de_rejeicao(leitura()) is None


@pytest.mark.parametrize(
    "alteracoes, esperado",
    [
        ({"temperatura": -10.0}, None),
        ({"temperatura": -10.1}, "temperatura_fora_da_faixa"),
        ({"temperatura": 60.0}, None),
        ({"temperatura": 60.1}, "temperatura_fora_da_faixa"),
        ({"umidade": 0.0}, None),
        ({"umidade": -0.1}, "umidade_fora_da_faixa"),
        ({"umidade": 100.0}, None),
        ({"umidade": 100.1}, "umidade_fora_da_faixa"),
        ({"temperatura": 140.0, "unidade": "F"}, None),
        ({"temperatura": 141.0, "unidade": "F"}, "temperatura_fora_da_faixa"),
        ({"unidade": "K"}, "unidade_desconhecida"),
        ({"device_id": "estufa-a-031"}, "sensor_invalido"),
        ({"device_id": "estufa-d-01"}, "sensor_invalido"),
        ({"bateria": 87}, "campo_desconhecido"),
    ],
)
def test_particoes_e_limites(alteracoes, esperado):
    assert motivo_de_rejeicao(leitura(**alteracoes)) == esperado
