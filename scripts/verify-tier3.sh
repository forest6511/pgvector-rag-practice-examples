#!/usr/bin/env bash
# scripts/verify-tier3.sh
# 公開リポのサンプルを Tier 3 (環境依存 / 複数インスタンス) で検証する。
# T3.1: 付録 A 4 フレームワーク起動 + curl 動作確認
# T3.2: Ch10 Grafana + Prometheus + postgres_exporter スタック動作確認 (curl)
# T3.3: Ch12 pgvectorscale Dockerfile.ci の build と DiskANN 動作
# T3.4: Ch11 Logical Replication の 2 インスタンス検証
#
# 必要な環境変数:
#   OPENAI_API_KEY (T3.1 のフレームワーク起動で使用)
#
# 前提:
#   - リポジトリルートで実行
#   - docker / python3 / ruby / node が PATH 上にある
#
# 使い方:
#   bash scripts/verify-tier3.sh
#   bash scripts/verify-tier3.sh --only=t31  # 特定の T3 項目のみ

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$ROOT"

ONLY=""
SKIP_FRAMEWORKS=""
for arg in "$@"; do
  case "$arg" in
    --only=*)              ONLY="${arg#--only=}" ;;
    --skip-frameworks=*)   SKIP_FRAMEWORKS="${arg#--skip-frameworks=}" ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
  esac
done

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

skip_step() {
  local name="$1"; local reason="$2"
  echo "[skip] $name ($reason)"
  RESULTS+=("$name|SKIP|$reason")
}

is_enabled() {
  local kind="$1"
  if [[ -z "$ONLY" ]]; then return 0; fi
  case ",$ONLY," in
    *",$kind,"*) return 0 ;;
    *) return 1 ;;
  esac
}

framework_skipped() {
  local fw="$1"
  case ",$SKIP_FRAMEWORKS," in
    *",$fw,"*) return 0 ;;
    *) return 1 ;;
  esac
}

curl_check() {
  # curl_check <name> <url> [data]
  local name="$1" url="$2"
  if [[ "$#" -ge 3 ]]; then
    curl -sf -m 15 -X POST "$url" \
      -H 'content-type: application/json' \
      -d "$3" -o /dev/null && echo "POST $url 200 OK"
  else
    curl -sf -m 15 "$url" -o /dev/null && echo "GET $url 200 OK"
  fi
}

# ---------- preflight ----------
echo "════════════════════════════════════════"
echo " Tier 3 verification — pgvector-rag-practice-examples"
echo "════════════════════════════════════════"

if ! docker ps --format '{{.Names}}' | grep -q pgvector-rag-postgres 2>/dev/null; then
  run_step "preflight::compose-up" \
    bash -c "docker compose up -d --wait"
fi

# 共通 schema(付録 A 用)
run_step "preflight::appendix-a-schema" bash -c "
  docker exec -i -e PGPASSWORD=$PG_PASS pgvector-rag-postgres \
    psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -f - < appendix-a-frameworks/setup.sql
"

# ============================================================
# T3.1: 付録 A 4 フレームワーク起動 + curl 動作確認
# ============================================================
if is_enabled t31; then
  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    skip_step "t3.1::all-frameworks" "OPENAI_API_KEY not set"
  else
    # ----- FastAPI (port 8000) -----
    if framework_skipped fastapi; then
      skip_step "t3.1::fastapi" "--skip-frameworks"
    else
      run_step "t3.1::fastapi-install" bash -c "
        cd appendix-a-frameworks/fastapi && \
        python3 -m pip install -q -r requirements.txt
      "
      ( cd appendix-a-frameworks/fastapi && \
        DATABASE_URL=$PG_DSN OPENAI_API_KEY="$OPENAI_API_KEY" \
        nohup python3 -m uvicorn main:app --port 8000 \
        > /tmp/fastapi.log 2>&1 & echo $! > /tmp/fastapi.pid )
      sleep 6
      run_step "t3.1::fastapi-post-docs" \
        curl_check fastapi-post http://localhost:8000/docs \
        '{"title":"pgvector","body":"PostgreSQLのベクトル検索拡張"}'
      run_step "t3.1::fastapi-get-search" \
        curl_check fastapi-get 'http://localhost:8000/search?q=ベクトル'
      kill "$(cat /tmp/fastapi.pid)" 2>/dev/null || true
      sleep 2
    fi

    # ----- Django (port 8001) -----
    if framework_skipped django; then
      skip_step "t3.1::django" "--skip-frameworks"
    else
      run_step "t3.1::django-install" bash -c "
        cd appendix-a-frameworks/django && \
        python3 -m pip install -q -r requirements.txt
      "
      ( cd appendix-a-frameworks/django && \
        DATABASE_URL=$PG_DSN OPENAI_API_KEY="$OPENAI_API_KEY" \
        nohup python3 manage.py runserver 8001 \
        > /tmp/django.log 2>&1 & echo $! > /tmp/django.pid )
      sleep 6
      run_step "t3.1::django-post-docs" \
        curl_check django-post http://localhost:8001/docs \
        '{"title":"Django RAG","body":"Django から pgvector"}'
      run_step "t3.1::django-get-search" \
        curl_check django-get 'http://localhost:8001/search?q=Django'
      kill "$(cat /tmp/django.pid)" 2>/dev/null || true
      sleep 2
    fi

    # ----- Rails (port 3001) -----
    if framework_skipped rails; then
      skip_step "t3.1::rails" "--skip-frameworks"
    else
      run_step "t3.1::rails-bundle" bash -c "
        cd appendix-a-frameworks/rails && \
        bundle install --quiet
      "
      ( cd appendix-a-frameworks/rails && \
        DATABASE_URL=$PG_DSN OPENAI_API_KEY="$OPENAI_API_KEY" \
        DATABASE_HOST=localhost DATABASE_PORT=5432 \
        DATABASE_USER=$PG_USER DATABASE_PASSWORD=$PG_PASS \
        SECRET_KEY_BASE=ci-only-key-not-for-production \
        nohup bin/rails server -p 3001 \
        > /tmp/rails.log 2>&1 & echo $! > /tmp/rails.pid )
      sleep 12
      run_step "t3.1::rails-post-docs" \
        curl_check rails-post http://localhost:3001/docs \
        '{"title":"Rails","body":"Rails から pgvector"}'
      run_step "t3.1::rails-get-search" \
        curl_check rails-get 'http://localhost:3001/search?q=Rails'
      kill "$(cat /tmp/rails.pid)" 2>/dev/null || true
      sleep 2
    fi

    # ----- Next.js (port 3000) -----
    if framework_skipped nextjs; then
      skip_step "t3.1::nextjs" "--skip-frameworks"
    else
      run_step "t3.1::nextjs-install" bash -c "
        cd appendix-a-frameworks/nextjs && \
        npm install --no-audit --no-fund --silent
      "
      ( cd appendix-a-frameworks/nextjs && \
        DATABASE_URL=$PG_DSN OPENAI_API_KEY="$OPENAI_API_KEY" \
        nohup npm run dev \
        > /tmp/nextjs.log 2>&1 & echo $! > /tmp/nextjs.pid )
      sleep 15
      run_step "t3.1::nextjs-post-docs" \
        curl_check nextjs-post http://localhost:3000/api/docs \
        '{"title":"Next.js","body":"Next.js App Router"}'
      run_step "t3.1::nextjs-get-search" \
        curl_check nextjs-get 'http://localhost:3000/api/search?q=Next.js'
      kill "$(cat /tmp/nextjs.pid)" 2>/dev/null || true
      sleep 2
    fi
  fi
fi

# ============================================================
# T3.2: Ch10 Grafana + Prometheus + postgres_exporter スタック動作
# ============================================================
if is_enabled t32; then
  # ベース postgres を一旦止めて 5432 衝突を回避(ch10 compose も 5432 を使う)
  run_step "t3.2::base-compose-down" \
    docker compose down

  run_step "t3.2::ch10-compose-up" bash -c "
    cd ch10-observability && \
    docker compose up -d && \
    sleep 25
  "

  run_step "t3.2::prometheus-health" bash -c "
    curl -sfm 10 'http://localhost:9090/-/healthy' | head -1
  "

  run_step "t3.2::prometheus-pg-up-metric" bash -c "
    for i in 1 2 3 4 5 6 7 8 9 10; do
      result=\$(curl -sfm 5 'http://localhost:9090/api/v1/query?query=pg_up' \
        | python3 -c 'import sys,json;d=json.load(sys.stdin);r=d[\"data\"][\"result\"];print(r[0][\"value\"][1] if r else \"none\")') || result=\"err\"
      echo \"[\$i] pg_up=\$result\"
      if [ \"\$result\" = \"1\" ]; then exit 0; fi
      sleep 4
    done
    exit 1
  "

  run_step "t3.2::grafana-health" bash -c "
    curl -sfm 10 'http://localhost:3002/api/health' | grep -q 'database'
  "

  run_step "t3.2::grafana-add-prometheus-datasource" bash -c "
    curl -sfm 10 -X POST 'http://admin:admin@localhost:3002/api/datasources' \
      -H 'content-type: application/json' \
      -d '{\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"http://prometheus:9090\",\"access\":\"proxy\",\"isDefault\":true}' \
      | grep -E 'Prometheus|already exists'
  "

  run_step "t3.2::grafana-query-via-datasource" bash -c "
    curl -sfm 10 'http://admin:admin@localhost:3002/api/datasources/proxy/1/api/v1/query?query=pg_up' \
      | grep -q '\"status\":\"success\"'
  "

  run_step "t3.2::ch10-compose-down" bash -c "
    cd ch10-observability && docker compose down -v
  "
fi

# ============================================================
# T3.3: Ch12 pgvectorscale Dockerfile.ci build と DiskANN 動作
# ============================================================
if is_enabled t33; then
  run_step "t3.3::pgvectorscale-build" \
    docker build -f ch12-scaling-migration/pgvectorscale/Dockerfile.ci \
      -t pgvector-rag-pgvs-ci \
      ch12-scaling-migration/pgvectorscale

  # 既存 container があれば停止
  docker rm -f pgvs-ci-test 2>/dev/null || true

  run_step "t3.3::pgvectorscale-run" bash -c '
    docker run -d --name pgvs-ci-test \
      -e POSTGRES_USER=rag -e POSTGRES_PASSWORD=ragpass -e POSTGRES_DB=ragdb \
      -p 5433:5432 \
      pgvector-rag-pgvs-ci > /dev/null && \
    sleep 12 && \
    docker exec -e PGPASSWORD=ragpass pgvs-ci-test \
      psql -U rag -d ragdb -c "SELECT version();" | head -3
  '

  run_step "t3.3::pgvectorscale-extension" bash -c "
    docker exec -e PGPASSWORD=ragpass pgvs-ci-test \
      psql -U rag -d ragdb -v ON_ERROR_STOP=1 \
      -c 'CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;' \
      -c \"SELECT extname, extversion FROM pg_extension WHERE extname IN ('vector', 'vectorscale') ORDER BY extname;\"
  "

  run_step "t3.3::pgvectorscale-diskann" bash -c '
    docker exec -e PGPASSWORD=ragpass pgvs-ci-test \
      psql -U rag -d ragdb -v ON_ERROR_STOP=1 <<SQL
CREATE TABLE docs (
    id        bigserial PRIMARY KEY,
    embedding vector(1536) NOT NULL
);
INSERT INTO docs (embedding)
SELECT (SELECT array_agg(random()::real - 0.5)::vector(1536)
        FROM generate_series(1, 1536))
FROM generate_series(1, 500);
CREATE INDEX docs_embedding_diskann
  ON docs USING diskann (embedding vector_cosine_ops);
ANALYZE docs;
EXPLAIN (FORMAT TEXT)
  SELECT id FROM docs
  ORDER BY embedding <=> (SELECT embedding FROM docs WHERE id = 1)
  LIMIT 10;
SQL
  '

  docker rm -f pgvs-ci-test > /dev/null 2>&1 || true
fi

# ============================================================
# T3.4: Ch11 Logical Replication の 2 インスタンス検証
# ============================================================
if is_enabled t34; then
  # 既存 container をクリーンアップ
  docker rm -f pg-pub-test pg-sub-test 2>/dev/null || true
  docker network rm rag-replication-net 2>/dev/null || true

  run_step "t3.4::network-create" \
    docker network create rag-replication-net

  run_step "t3.4::publisher-up" bash -c '
    docker run -d --name pg-pub-test \
      --network rag-replication-net \
      -e POSTGRES_USER=rag -e POSTGRES_PASSWORD=ragpass -e POSTGRES_DB=ragdb \
      -p 5434:5432 \
      pgvector/pgvector:0.8.2-pg17-trixie \
      postgres -c wal_level=logical \
      > /dev/null && sleep 8 && \
    docker exec -e PGPASSWORD=ragpass pg-pub-test \
      psql -U rag -d ragdb -v ON_ERROR_STOP=1 -c "
        CREATE EXTENSION vector;
        CREATE TABLE docs (id bigserial PRIMARY KEY, embedding vector(8) NOT NULL);
        ALTER TABLE docs REPLICA IDENTITY FULL;
        CREATE PUBLICATION docs_pub FOR TABLE docs;
      "
  '

  run_step "t3.4::subscriber-up" bash -c '
    docker run -d --name pg-sub-test \
      --network rag-replication-net \
      -e POSTGRES_USER=rag -e POSTGRES_PASSWORD=ragpass -e POSTGRES_DB=ragdb \
      -p 5435:5432 \
      pgvector/pgvector:0.8.2-pg17-trixie \
      > /dev/null && sleep 8 && \
    docker exec -e PGPASSWORD=ragpass pg-sub-test \
      psql -U rag -d ragdb -v ON_ERROR_STOP=1 \
      -c "CREATE EXTENSION vector;" \
      -c "CREATE TABLE docs (id bigint PRIMARY KEY, embedding vector(8) NOT NULL);" \
      -c "CREATE SUBSCRIPTION docs_sub CONNECTION '"'"'host=pg-pub-test port=5432 user=rag password=ragpass dbname=ragdb'"'"' PUBLICATION docs_pub;"
  '

  run_step "t3.4::insert-and-verify-sync" bash -c '
    docker exec -e PGPASSWORD=ragpass pg-pub-test \
      psql -U rag -d ragdb -v ON_ERROR_STOP=1 -c "
        INSERT INTO docs (embedding)
          SELECT (SELECT array_agg(random()::real)::vector(8)
                  FROM generate_series(1, 8))
          FROM generate_series(1, 5);
      " > /dev/null && \
    sleep 5 && \
    count=$(docker exec -e PGPASSWORD=ragpass pg-sub-test \
      psql -U rag -d ragdb -tAc "SELECT count(*) FROM docs") && \
    echo "subscriber row count: $count" && \
    [ "$count" = "5" ]
  '

  docker rm -f pg-pub-test pg-sub-test > /dev/null 2>&1 || true
  docker network rm rag-replication-net > /dev/null 2>&1 || true
fi

# ============================================================
# Summary
# ============================================================
printf "\n════════════════════════════════════════\n"
printf " Tier 3 — Summary\n"
printf "════════════════════════════════════════\n"

pass=0; fail=0; skip=0
printf "%-40s | %-6s | %s\n" "step" "status" "note"
printf "%s\n" "$(printf -- '─%.0s' {1..80})"
for r in "${RESULTS[@]}"; do
  IFS='|' read -r name status note <<< "$r"
  printf "%-40s | %-6s | %s\n" "$name" "$status" "$note"
  case "$status" in
    PASS) ((pass++)) ;;
    SKIP) ((skip++)) ;;
    *)    ((fail++)) ;;
  esac
done
printf "%s\n" "$(printf -- '─%.0s' {1..80})"
printf "Total: %d  PASS: %d  FAIL: %d  SKIP: %d\n" "$((pass+fail+skip))" "$pass" "$fail" "$skip"

[[ "$fail" -eq 0 ]] && exit 0 || exit 1
