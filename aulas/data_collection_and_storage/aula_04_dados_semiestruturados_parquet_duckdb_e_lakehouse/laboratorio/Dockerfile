# Dockerfile modelo do job do lakehouse (Aula 04).
# O job roda, processa a data pedida e termina: requisito do cron do Railway.
# Ajuste o módulo de entrada (CMD) ao nome definido em specs/tasks.md.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN useradd --create-home job
WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

USER job
# Instala a extensão httpfs na imagem para o job não depender de download a cada execução.
RUN python -c "import duckdb; duckdb.sql('INSTALL httpfs'); print('httpfs ok')"

COPY --chown=job:job src/ src/
COPY --chown=job:job sql/ sql/

CMD ["python", "-m", "src.job_lakehouse"]
