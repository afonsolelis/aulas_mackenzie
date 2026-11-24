"""Contrato da leitura do sensor de estufa (Aula 06), simplificado para a bancada.

Regras da spec do grupo (hipóteses de faixa, a confirmar com o agrônomo):
- device_id no formato estufa-a-01 ... estufa-c-99 ou germinacao-01 ... germinacao-99;
- temperatura em C ou F, aceita de -10 °C a 60 °C, limites incluídos, depois de converter;
- umidade relativa de 0 % a 100 %, limites incluídos;
- campo desconhecido é recusado.
"""

from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, ValidationError, model_validator
from pydantic_core import PydanticCustomError

FAIXA_C = (-10.0, 60.0)

DeviceId = Annotated[str, Field(pattern=r"^(estufa-[a-c]|germinacao)-[0-9]{2}$")]


class Leitura(BaseModel):
    model_config = ConfigDict(extra="forbid")

    device_id: DeviceId
    temperatura: float = Field(allow_inf_nan=False)
    unidade: Literal["C", "F"]
    umidade: float = Field(ge=0, le=100, allow_inf_nan=False)

    @property
    def temperatura_c(self) -> float:
        if self.unidade == "F":
            return round((self.temperatura - 32) * 5 / 9, 2)
        return self.temperatura

    @model_validator(mode="after")
    def temperatura_na_faixa(self) -> "Leitura":
        if not FAIXA_C[0] <= self.temperatura_c <= FAIXA_C[1]:
            raise PydanticCustomError(
                "temperatura_fora_da_faixa", "temperatura {c} °C fora da faixa", {"c": self.temperatura_c}
            )
        return self


def motivo_de_rejeicao(dados: dict) -> str | None:
    """None quando a leitura entra; senão, o código do motivo que vai para a quarentena."""
    try:
        Leitura.model_validate(dados)
    except ValidationError as erro:
        primeiro = erro.errors()[0]
        tipo = primeiro["type"]
        campo = primeiro["loc"][0] if primeiro["loc"] else None
        if tipo == "temperatura_fora_da_faixa":
            return tipo
        if tipo == "missing":
            return "campo_ausente"
        if tipo == "extra_forbidden":
            return "campo_desconhecido"
        if campo == "umidade" and tipo in ("greater_than_equal", "less_than_equal", "greater_than", "less_than"):
            return "umidade_fora_da_faixa"
        if campo == "unidade":
            return "unidade_desconhecida"
        if campo == "device_id" and tipo == "string_pattern_mismatch":
            return "sensor_invalido"
        return "tipo_invalido"
    return None
