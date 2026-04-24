#!/usr/bin/env bash
# ch07-hnsw-benchmark/scripts/monitor-build.sh
# pg_stat_progress_create_index を 5 秒おきに watch し、
# HNSW の phase(initializing / loading tuples)と進捗率を表示する。
#
# 使い方:
#   bash scripts/monitor-build.sh
#   (別ターミナルで build-index.sql を実行しておく)

set -euo pipefail

PSQL=${PSQL:-docker compose exec -T postgres psql -U rag -d ragdb -A -t}

while true; do
    $PSQL -c "
        SELECT
            pid,
            phase,
            round(100.0 * blocks_done / NULLIF(blocks_total, 0), 1) AS percent,
            tuples_done,
            tuples_total
        FROM pg_stat_progress_create_index;
    " | sed 's/|/ /g'
    echo "---"
    sleep 5
done
