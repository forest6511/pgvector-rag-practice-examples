#!/usr/bin/env bash
# セッション A: 長時間トランザクションを開始
psql -U rag -d ragdb -c "BEGIN; SELECT pg_sleep(600);" &
LONG_TX_PID=$!

# セッション B: CONCURRENTLY 構築(セッション A の COMMIT 待ちで停滞)
psql -U rag -d ragdb \
  -c "CREATE INDEX CONCURRENTLY docs_embedding_hnsw
      ON docs USING hnsw (embedding vector_cosine_ops);"

wait $LONG_TX_PID
