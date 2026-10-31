import clickhouse_connect
from src.config import env


class TabelaIngestao:
    COLUNAS = ["timestamp", "data_json", "data_tag"]

    def __init__(self):
        self.cli = clickhouse_connect.get_client(
            host=env("CLICKHOUSE_HOST", "localhost"), port=int(env("CLICKHOUSE_HTTP_PORT", "8123")),
            username=env("CLICKHOUSE_USER"), password=env("CLICKHOUSE_PASSWORD"),
            database=env("CLICKHOUSE_DATABASE", "ingestao"),
            # O ClickHouse 26.8 liga async_insert por padrão: o servidor junta INSERTs pequenos
            # e segura cada um por 50 a 200 ms. O consumidor já faz o lote, então desligamos.
            settings={"async_insert": int(env("CLICKHOUSE_ASYNC_INSERT", "0"))})
        self.tabela = env("CLICKHOUSE_TABELA", "db_ingestion")

    def inserir(self, linhas: list[tuple[int, str, str]]) -> None:
        """Um INSERT por lote: cada INSERT cria uma parte no MergeTree."""
        self.cli.insert(self.tabela, linhas, column_names=self.COLUNAS)
