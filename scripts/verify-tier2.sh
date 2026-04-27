#!/usr/bin/env bash
# scripts/verify-tier2.sh
# 公開リポのサンプルを Tier 2 (API キー必要 / やや重い) で検証する。
#
# 必要な環境変数:
#   OPENAI_API_KEY (必須)
#   VOYAGE_API_KEY (任意。未設定なら voyage は自動スキップ)
#
# 前提:
#   - リポジトリルートで実行
#   - docker compose up -d が完了しヘルシー
#   - python3 + pip
#
# 使い方:
#   bash scripts/verify-tier2.sh
#   bash scripts/verify-tier2.sh --skip-e5     # e5 (2.2GB DL) をスキップ
#
# 終了コード: 0 (全 PASS) / 1 (1 つでも FAIL)

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$ROOT"

SKIP_E5=0
for arg in "$@"; do
  case "$arg" in
    --skip-e5) SKIP_E5=1 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
  esac
done

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "ERROR: OPENAI_API_KEY is not set." >&2
  echo "       Tier 2 requires OpenAI API access." >&2
  exit 2
fi

PG_USER=${PG_USER:-rag}
PG_DB=${PG_DB:-ragdb}
PG_PASS=${PG_PASS:-ragpass}
PG_DSN="postgresql://${PG_USER}:${PG_PASS}@localhost:5432/${PG_DB}"

# macOS の externally-managed-environment 対策
export PIP_BREAK_SYSTEM_PACKAGES=1

declare -a RESULTS=()

run_step() {
  local name="$1"; shift
  printf "\n──────────────────────────────────────\n"
  printf "▶ %s\n" "$name"
  printf "──────────────────────────────────────\n"
  local out err rc
  out=$(mktemp); err=$(mktemp)
  if "$@" >"$out" 2>"$err"; then
    rc=0
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

# ---------- ch05 OpenAI ----------
run_step "ch05::openai-embed" bash -c "
  cd ch05-embeddings/openai && \
  python3 -m pip install -q -r requirements.txt && \
  OPENAI_API_KEY=$OPENAI_API_KEY python3 embed.py
"

# ---------- ch05 e5 (2.2GB DL) ----------
if [[ "$SKIP_E5" -eq 0 ]]; then
  run_step "ch05::e5-embed" bash -c "
    cd ch05-embeddings/e5 && \
    python3 -m pip install -q -r requirements.txt && \
    python3 embed.py
  "
else
  echo "[skip] ch05::e5-embed (--skip-e5)"
fi

# ---------- ch05 Voyage ----------
if [[ -n "${VOYAGE_API_KEY:-}" ]]; then
  run_step "ch05::voyage-embed" bash -c "
    cd ch05-embeddings/voyage && \
    python3 -m pip install -q -r requirements.txt && \
    VOYAGE_API_KEY=$VOYAGE_API_KEY python3 embed.py
  "
else
  echo "[skip] ch05::voyage-embed (VOYAGE_API_KEY not set)"
  RESULTS+=("ch05::voyage-embed|SKIP|VOYAGE_API_KEY not set")
fi

# ---------- ch05 jmteb-mini ----------
run_step "ch05::jmteb-mini" bash -c "
  cd ch05-embeddings/jmteb-mini && \
  python3 -m pip install -q -r requirements.txt && \
  OPENAI_API_KEY=$OPENAI_API_KEY python3 run.py
"

# ---------- 付録 C: end-to-end RAG ----------
# Tier 1 で他章の docs テーブルが作られている可能性があるため、
# 付録 C 専用スキーマで再作成してから ingest する。
run_step "appendix-c::reset-schema" bash -c "
  docker exec -i -e PGPASSWORD=$PG_PASS pgvector-rag-postgres \
    psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -f - < appendix-c-raw-sql-rag/setup.sql
"

run_step "appendix-c::ingest" bash -c "
  cd appendix-c-raw-sql-rag && \
  python3 -m pip install -q --upgrade -r requirements.txt && \
  echo 'pgvector は PostgreSQL のベクトル検索拡張です。HNSW インデックスを使うと高速に類似検索できます。' > /tmp/appendix-c-test.md && \
  DATABASE_URL=$PG_DSN OPENAI_API_KEY=$OPENAI_API_KEY \
    python3 ingest.py /tmp/appendix-c-test.md --title 'テスト文書'
"

run_step "appendix-c::search" bash -c "
  cd appendix-c-raw-sql-rag && \
  DATABASE_URL=$PG_DSN OPENAI_API_KEY=$OPENAI_API_KEY \
    python3 search.py 'pgvectorとは何ですか' | head -5
"

run_step "appendix-c::rag-end-to-end" bash -c "
  cd appendix-c-raw-sql-rag && \
  DATABASE_URL=$PG_DSN OPENAI_API_KEY=$OPENAI_API_KEY \
    python3 rag.py 'pgvectorはどんな用途に向いていますか'
"

# ---------- summary ----------
printf "\n════════════════════════════════════════\n"
printf " Tier 2 — Summary\n"
printf "════════════════════════════════════════\n"

pass=0; fail=0; skip=0
printf "%-40s | %-6s | %s\n" "step" "status" "note"
printf "%s\n" "$(printf -- '─%.0s' {1..80})"
for r in "${RESULTS[@]}"; do
  IFS='|' read -r name status note <<< "$r"
  printf "%-40s | %-6s | %s\n" "$name" "$status" "$note"
  case "$status" in
    PASS) ((pass++)) ;;
    FAIL) ((fail++)) ;;
    SKIP) ((skip++)) ;;
  esac
done
printf "%s\n" "$(printf -- '─%.0s' {1..80})"
printf "Total: %d  PASS: %d  FAIL: %d  SKIP: %d\n" "$((pass+fail+skip))" "$pass" "$fail" "$skip"

[[ "$fail" -eq 0 ]] && exit 0 || exit 1
