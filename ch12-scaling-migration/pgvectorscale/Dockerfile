FROM timescale/timescaledb-ha:pg17
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-17-pgvectorscale && \
    rm -rf /var/lib/apt/lists/*
