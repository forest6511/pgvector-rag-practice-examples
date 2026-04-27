FROM timescale/timescaledb-ha:pg17
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-17-pgvectorscale && \
    rm -rf /var/lib/apt/lists/*
USER postgres
