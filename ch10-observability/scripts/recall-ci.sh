#!/usr/bin/env bash
set -euo pipefail

THRESHOLD=${RECALL_THRESHOLD:-0.90}
PSQL=${PSQL:-docker compose exec -T postgres psql -U rag -d ragdb -A -t}

# ground truth 生成
$PSQL -f queries/recall-ci.sql

# recall 計測(Python 側)
recall=$(python scripts/measure-recall.py --ef_search 40 --k 10)

echo "measured recall: $recall (threshold: $THRESHOLD)"

python -c "
import sys
r = float('$recall')
t = float('$THRESHOLD')
sys.exit(0 if r >= t else 1)
"
