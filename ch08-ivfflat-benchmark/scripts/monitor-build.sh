#!/usr/bin/env bash
# ch08-ivfflat-benchmark/scripts/monitor-build.sh
# pg_stat_progress_create_index を 5 秒おきに watch し、
# IVFFlat の 4 フェーズと進捗率を表示する。
#
# IVFFlat の phase(pgvector 0.8.x 公式):
#   1. initializing
#   2. performing k-means
#   3. assigning tuples
#   4. loading tuples  ← この段階でだけ tuples_done/tuples_total が更新される
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
            round(100.0 * tuples_done / NULLIF(tuples_total, 0), 1) AS percent,
            tuples_done,
            tuples_total
        FROM pg_stat_progress_create_index;
    " | sed 's/|/ /g'
    echo "---"
    sleep 5
done
