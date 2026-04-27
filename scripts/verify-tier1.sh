#!/usr/bin/env bash
# scripts/verify-tier1.sh
# 公開リポのサンプルを Tier 1 (API キー不要 / 短時間) で検証する。
# Ch03-12 + 付録 A/C の SQL/Python/シェルを順次実走し、PASS/FAIL を集計する。
#
# 前提:
#   - リポジトリルートで実行(scripts/verify-tier1.sh ではなく ./scripts/verify-tier1.sh)
#   - docker compose up -d が完了しヘルシー
#   - python3 が PATH 上にある
#
# 使い方:
#   bash scripts/verify-tier1.sh
#   bash scripts/verify-tier1.sh --skip-build      # Docker build をスキップ
#   bash scripts/verify-tier1.sh --only ch07,ch08  # 特定の章のみ
#
# 終了コード: 0 (全 PASS / SKIP のみ) / 1 (1 つでも FAIL)

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$ROOT"

# ---------- options ----------
SKIP_BUILD=0
SKIP_PGVS=0
ONLY_FILTER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)         SKIP_BUILD=1 ;;
    --skip-pgvectorscale) SKIP_PGVS=1 ;;
    --only=*)             ONLY_FILTER="${1#--only=}" ;;
    --only)               shift; ONLY_FILTER="${1:-}" ;;
    -h|--help)            sed -n '2,17p' "$0"; exit 0 ;;
  esac
  shift
done

# Mac arm64 では timescale/timescaledb-ha:pg17 に postgresql-17-pgvectorscale の
# arm64 パッケージが無いため、ローカルでは自動でスキップする。
if [[ "$SKIP_PGVS" -ne 1 ]] && [[ "$(uname -m)" == "arm64" ]] && [[ -z "${CI:-}" ]]; then
  SKIP_PGVS=1
  echo "Note: arm64 detected — pgvectorscale build will be auto-skipped (Linux x86_64 / CI で実走)"
fi

# ---------- helpers ----------
PG_CONTAINER=${PG_CONTAINER:-pgvector-rag-postgres}
PG_USER=${PG_USER:-rag}
PG_DB=${PG_DB:-ragdb}
PG_PASS=${PG_PASS:-ragpass}
PG_DSN="postgresql://${PG_USER}:${PG_PASS}@localhost:5432/${PG_DB}"

# macOS の externally-managed-environment 対策
export PIP_BREAK_SYSTEM_PACKAGES=1
PIP_INSTALL="python3 -m pip install -q"

declare -a RESULTS=()  # "name|status|note"

run_step() {
  # run_step <name> <command...>
  local name="$1"; shift
  if [[ -n "$ONLY_FILTER" ]]; then
    case ",$ONLY_FILTER," in
      *",${name%%::*},"*) ;;
      *) return 0 ;;
    esac
  fi
  printf "\n──────────────────────────────────────\n"
  printf "▶ %s\n" "$name"
  printf "──────────────────────────────────────\n"
  local out err rc
  out=$(mktemp); err=$(mktemp)
  if "$@" >"$out" 2>"$err"; then
    tail -3 "$out" || true
    RESULTS+=("$name|PASS|$(tail -1 "$out" | tr -d '\n' | cut -c1-60)")
  else
    rc=$?
    echo "--- stdout ---"; tail -20 "$out"
    echo "--- stderr ---"; tail -20 "$err"
    RESULTS+=("$name|FAIL|exit=$rc")
  fi
  rm -f "$out" "$err"
  return 0
}

psql_exec() {
  # psql_exec <sql-file>
  docker exec -i -e PGPASSWORD="$PG_PASS" "$PG_CONTAINER" \
    psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -f - < "$1"
}

psql_cmd() {
  # psql_cmd "SQL"
  docker exec -e PGPASSWORD="$PG_PASS" "$PG_CONTAINER" \
    psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -c "$1"
}

py_syntax() {
  # py_syntax <file>
  python3 -m py_compile "$1"
}

sql_run() {
  # 実走できる SQL(BEGIN/ROLLBACK で囲んで安全に試す)。
  # パラメータ($1, \copy, CONCURRENTLY 等)を含む SQL は sql_lint を使う。
  local sql_file="$1"
  local content
  content=$(cat "$sql_file")
  docker exec -i -e PGPASSWORD="$PG_PASS" "$PG_CONTAINER" \
    psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 <<EOF
BEGIN;
SET LOCAL statement_timeout = '5s';
$content
ROLLBACK;
EOF
}

sql_lint() {
  # 実走できない SQL (パラメータ・\copy・CONCURRENTLY 等を含む) の最小検証。
  # 1) ファイルが空でない
  # 2) SQL らしいキーワードを 1 個以上含む
  local sql_file="$1"
  if [[ ! -s "$sql_file" ]]; then
    echo "ERROR: $sql_file is empty"; return 1
  fi
  if ! grep -qiE 'SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|EXPLAIN|SET|REINDEX|COPY|VACUUM|ANALYZE' "$sql_file"; then
    echo "ERROR: $sql_file contains no SQL keyword"; return 1
  fi
  echo "lint OK: $(basename "$sql_file") ($(wc -l < "$sql_file") lines)"
}

# ---------- 0. preflight ----------
echo "════════════════════════════════════════"
echo " Tier 1 verification — pgvector-rag-practice-examples"
echo "════════════════════════════════════════"
echo "PG_DSN: $PG_DSN"

if [[ "$SKIP_BUILD" -ne 1 ]]; then
  run_step "preflight::compose-up" \
    bash -c "docker compose up -d --wait"
fi

run_step "preflight::extensions" \
  psql_cmd "SELECT extname, extversion FROM pg_extension WHERE extname IN ('vector','pgroonga') ORDER BY 1;"

# ---------- ch03 ----------
run_step "ch03::verify-sql" \
  psql_exec ch03-environment/verify.sql

# ---------- ch04 ----------
for sql in ch04-schema/patterns/*.sql; do
  name="ch04::$(basename "$sql" .sql)"
  run_step "$name" psql_exec "$sql"
done

run_step "ch04::migrations-01" psql_exec ch04-schema/migrations/01-add-new-model.sql
run_step "ch04::migrations-02" psql_exec ch04-schema/migrations/02-dimension-change.sql
run_step "ch04::copy-binary-syntax" py_syntax ch04-schema/bulk-load/copy-binary.py

# ---------- ch06 ----------
run_step "ch06::tokenizers-syntax" bash -c "
  for f in ch06-chunking/tokenizers/*.py; do python3 -m py_compile \"\$f\"; done
"
run_step "ch06::chunking-fixed-size" python3 ch06-chunking/chunking/fixed_size.py
run_step "ch06::chunking-sentence-boundary" python3 ch06-chunking/chunking/sentence_boundary.py
run_step "ch06::chunking-heading-based" python3 ch06-chunking/chunking/heading_based.py
run_step "ch06::chunking-hybrid" python3 ch06-chunking/chunking/hybrid.py
run_step "ch06::extractors-syntax" bash -c "
  for f in ch06-chunking/extractors/*.py; do python3 -m py_compile \"\$f\"; done
"

# ---------- ch07 (CI 版: 1000 件) ----------
run_step "ch07::setup-ci" psql_exec ch07-hnsw-benchmark/setup-ci.sql
run_step "ch07::build-index-ci" psql_exec ch07-hnsw-benchmark/build-index-ci.sql

# ground-truth: \copy ... TO STDOUT で psql の stdout を host 側 CSV に redirect
ground_truth_ci_for() {
  # ground_truth_ci_for <chapter-dir>
  local dir="$1"
  mkdir -p "$dir/eval"
  # psql は CREATE TABLE の結果として "SELECT 100" 等を stdout に書くため、
  # それらを除去するために grep -E '^[0-9]+,"\{|^query_id' で本文行のみ残す。
  docker exec -i -e PGPASSWORD="$PG_PASS" "$PG_CONTAINER" \
    psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -q -A -t <<'SQL' \
    | grep -E '^(query_id,gt_ids|[0-9]+,"\{)' \
    > "$dir/eval/gt.csv"
CREATE TEMP TABLE q AS
  SELECT id AS query_id, embedding AS qv
  FROM items
  ORDER BY random()
  LIMIT 100;
\copy (SELECT q.query_id, array_agg(t.id ORDER BY t.embedding <-> q.qv) AS gt_ids FROM q, LATERAL (SELECT id, embedding FROM items ORDER BY embedding <-> q.qv LIMIT 10) t GROUP BY q.query_id) TO STDOUT WITH CSV HEADER
SQL
  test -s "$dir/eval/gt.csv"
}

run_step "ch07::ground-truth-ci" ground_truth_ci_for ch07-hnsw-benchmark

run_step "ch07::measure-recall" \
  bash -c "$PIP_INSTALL psycopg && \
    cd ch07-hnsw-benchmark && \
    DSN=$PG_DSN python3 scripts/measure-recall.py --ef 40 --k 10 --gt eval/gt.csv"

# ---------- ch08 (CI 版: 1000 件) ----------
run_step "ch08::setup-ci" psql_exec ch08-ivfflat-benchmark/setup-ci.sql
run_step "ch08::build-index-ci" psql_exec ch08-ivfflat-benchmark/build-index-ci.sql

run_step "ch08::ground-truth-ci" ground_truth_ci_for ch08-ivfflat-benchmark

run_step "ch08::measure-recall" \
  bash -c "$PIP_INSTALL psycopg && \
    cd ch08-ivfflat-benchmark && \
    DSN=$PG_DSN python3 scripts/measure-recall.py --probes 10 --k 10 --gt eval/gt.csv"

# ---------- ch09 (CI 版: 100 件、API キー不要のためダミー埋め込み) ----------
run_step "ch09::setup" psql_exec ch09-hybrid-search/setup.sql
run_step "ch09::seed-ci" \
  bash -c "$PIP_INSTALL psycopg && \
    ROWS=100 DATABASE_URL=$PG_DSN python3 ch09-hybrid-search/seed-ci.py"

# 6 SQL: いずれも $1 パラメータを含むため lint(キーワード確認)のみ
for sql in ch09-hybrid-search/queries/*.sql; do
  name="ch09::$(basename "$sql" .sql)-lint"
  run_step "$name" sql_lint "$sql"
done

# ---------- ch10 (Tier 1 では SQL の lint と extension 動作確認) ----------
# 各 SQL は eval_results / eval_ground_truth など実環境固有テーブル前提があるので lint
for sql in ch10-observability/queries/*.sql; do
  name="ch10::$(basename "$sql" .sql)-lint"
  run_step "$name" sql_lint "$sql"
done
run_step "ch10::pg_stat_statements-extension" \
  psql_cmd "CREATE EXTENSION IF NOT EXISTS pg_stat_statements; SELECT 1;"

# ---------- ch11 ----------
# CONCURRENTLY や $1 を含むものは lint、そうでないものは sql_run
ch11_mode_for() {
  case "$1" in
    autovacuum-tuning|bottleneck-diagnose|extension-upgrade|invalid-detect|long-tx-detect|memory-tuning) echo run ;;
    invalid-recover|iterative-scan|partial-index|post-filter-problem) echo lint ;;
    *) echo lint ;;
  esac
}

for sql in ch11-production-pitfalls/queries/*.sql; do
  base=$(basename "$sql" .sql)
  mode=$(ch11_mode_for "$base")
  name="ch11::${base}-${mode}"
  if [[ "$mode" == "run" ]]; then
    run_step "$name" sql_run "$sql"
  else
    run_step "$name" sql_lint "$sql"
  fi
done

# ---------- ch12 ----------
# pgvectorscale Dockerfile build を実走(USER root 修正済み)
if [[ "$SKIP_PGVS" -eq 1 ]]; then
  RESULTS+=("ch12::pgvectorscale-build|SKIP|arm64 or --skip-pgvectorscale")
  echo "[skip] ch12::pgvectorscale-build"
else
  run_step "ch12::pgvectorscale-build" \
    docker build -t pgvector-rag-pgvs-test ch12-scaling-migration/pgvectorscale
fi

# pgvectorscale 関連 SQL は extension が要るので lint
for sql in ch12-scaling-migration/pgvectorscale/*.sql; do
  name="ch12::pgvectorscale-$(basename "$sql" .sql)-lint"
  run_step "$name" sql_lint "$sql"
done

run_step "ch12::pinecone-export-syntax" py_syntax ch12-scaling-migration/pinecone-migration/export.py
run_step "ch12::pinecone-import-lint" sql_lint ch12-scaling-migration/pinecone-migration/import.sql

# ---------- appendix-a (Tier 1 では SQL とコード構文のみ。フレームワーク起動は Tier 3) ----------
run_step "appendix-a::setup-sql" psql_exec appendix-a-frameworks/setup.sql

run_step "appendix-a::django-syntax" bash -c "
  for f in appendix-a-frameworks/django/rag/*.py appendix-a-frameworks/django/ragproj/*.py; do
    python3 -m py_compile \"\$f\"
  done
"
run_step "appendix-a::fastapi-syntax" bash -c "
  for f in appendix-a-frameworks/fastapi/*.py; do python3 -m py_compile \"\$f\"; done
"
run_step "appendix-a::rails-files-exist" \
  bash -c "test -f appendix-a-frameworks/rails/Gemfile && \
           test -f appendix-a-frameworks/rails/config/database.yml"
run_step "appendix-a::nextjs-files-exist" \
  bash -c "test -f appendix-a-frameworks/nextjs/package.json && \
           test -f appendix-a-frameworks/nextjs/db/schema.ts"

# ---------- appendix-c (構文のみ。OpenAI 実走は Tier 2) ----------
run_step "appendix-c::setup-sql" psql_exec appendix-c-raw-sql-rag/setup.sql
run_step "appendix-c::ingest-syntax" py_syntax appendix-c-raw-sql-rag/ingest.py
run_step "appendix-c::search-syntax" py_syntax appendix-c-raw-sql-rag/search.py
run_step "appendix-c::generate-syntax" py_syntax appendix-c-raw-sql-rag/generate.py
run_step "appendix-c::rerank-syntax" py_syntax appendix-c-raw-sql-rag/rerank.py
run_step "appendix-c::rag-syntax" py_syntax appendix-c-raw-sql-rag/rag.py

# ---------- summary ----------
printf "\n════════════════════════════════════════\n"
printf " Tier 1 — Summary\n"
printf "════════════════════════════════════════\n"

pass=0; fail=0; skip=0
printf "%-50s | %-6s | %s\n" "step" "status" "note"
printf "%s\n" "$(printf -- '─%.0s' {1..90})"
for r in "${RESULTS[@]}"; do
  IFS='|' read -r name status note <<< "$r"
  printf "%-50s | %-6s | %s\n" "$name" "$status" "$note"
  case "$status" in
    PASS) ((pass++)) ;;
    SKIP) ((skip++)) ;;
    *)    ((fail++)) ;;
  esac
done
printf "%s\n" "$(printf -- '─%.0s' {1..90})"
printf "Total: %d  PASS: %d  FAIL: %d  SKIP: %d\n" "$((pass+fail+skip))" "$pass" "$fail" "$skip"

[[ "$fail" -eq 0 ]] && exit 0 || exit 1
