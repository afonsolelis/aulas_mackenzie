import pytest

from contrato_sensor import motivo_de_rejeicao

VALIDA = {"device_id": "estufa-a-03", "temperatura": 24.6, "unidade": "C", "umidade": 61.2}


def leitura(**alteracoes):
    return {**VALIDA, **alteracoes}


@pytest.mark.parametrize("dados, esperado", [
    (leitura(), None),
    (leitura(temperatura=77.0, unidade="F"), None),
    (leitura(temperatura=200.0), "temperatura_fora_da_faixa"),
    (leitura(umidade=150.0), "umidade_fora_da_faixa"),
    (leitura(unidade="K"), "unidade_desconhecida"),
    (leitura(device_id="sala"), "sensor_invalido"),
    (leitura(bateria=87), "campo_desconhecido"),
    ({"device_id": "estufa-a-03"}, "campo_ausente"),
    (leitura(temperatura="quente"), "tipo_invalido"),
])
def test_um_caso_por_motivo(dados, esperado):
    assert motivo_de_rejeicao(dados) == esperado
