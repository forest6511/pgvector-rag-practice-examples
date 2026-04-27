# Manual Verification (Tier 3)

`scripts/verify-all-samples.sh` で自動化できない検証を、本書出版前に手元で 1 周しておくための手順書。

## カバレッジ全体像

| Tier | 内容 | 自動化 | 所要時間 |
|------|------|------|---------|
| 1 | Ch03-12 + 付録 A/C の SQL/Python/シェル(API キー不要) | ✅ `verify-tier1.sh` + `samples-tier1.yml` | 約 15-20 分 |
| 2 | OpenAI/Voyage/e5 embedding + 付録 C end-to-end | ✅ `verify-tier2.sh` + `samples-tier2.yml` | 約 10-15 分 |
| **3** | **付録 A 4 フレームワーク起動 / Grafana / pgvectorscale 実機 / レプリケーション** | **❌ 本ドキュメントで手動** | **1-2 時間** |

Tier 3 は環境依存(Ruby/Node ランタイム / 2 インスタンスのレプリケーション環境 / GPU / Grafana ブラウザ操作)が大きく、ローカル PC で 1 度通すのが現実的。

---

## 前提環境

```bash
# リポジトリ
cd ~/Workspace/pgvector-rag-practice-examples

# ベース PG/pgvector/PGroonga 起動
docker compose up -d --wait
```

各検証は 1 章ずつ独立して実施可能。途中で停止して再開しても OK。

---

## T3.1 付録 A: 4 フレームワーク起動と API 動作確認

各フレームワークで `POST /docs` と `GET /search` の最小機能を実装している。
4 つすべて動かす必要はないが、本書で扱った言語のうち**自分が普段触らない 2 つ以上**は通しておく。

### 共通準備

```bash
# 共通スキーマ作成
docker exec -i -e PGPASSWORD=ragpass pgvector-rag-postgres \
  psql -U rag -d ragdb -f - < appendix-a-frameworks/setup.sql

# OpenAI キー(全フレームワーク共通)
export OPENAI_API_KEY=sk-...
```

### Rails (port 3001)

前提: Ruby 3.3 / Bundler

```bash
cd appendix-a-frameworks/rails

# 初回のみ
bundle install
bin/rails db:migrate

# 起動
DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
  OPENAI_API_KEY=$OPENAI_API_KEY \
  bin/rails server -p 3001 &

# 動作確認
curl -X POST http://localhost:3001/docs \
  -H 'content-type: application/json' \
  -d '{"title":"pgvector","body":"PostgreSQLのベクトル検索拡張"}'
# 期待: HTTP 201 + 投入された id

curl 'http://localhost:3001/search?q=ベクトル+DB'
# 期待: 投入文書を含む JSON 配列

# 停止
kill %1
```

合格基準: 投入レスポンスが 201、検索が 0 件以上を返す。

### Django (port 8001)

前提: Python 3.12

```bash
cd appendix-a-frameworks/django
pip install -r requirements.txt
python manage.py migrate

DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
  OPENAI_API_KEY=$OPENAI_API_KEY \
  python manage.py runserver 8001 &

curl -X POST http://localhost:8001/docs \
  -H 'content-type: application/json' \
  -d '{"title":"Django RAG","body":"Django から pgvector を使う最小サンプル"}'

curl 'http://localhost:8001/search?q=Django'

kill %1
```

### FastAPI (port 8000)

```bash
cd appendix-a-frameworks/fastapi
pip install -r requirements.txt

DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
  OPENAI_API_KEY=$OPENAI_API_KEY \
  uvicorn main:app --port 8000 --reload &

curl -X POST http://localhost:8000/docs \
  -H 'content-type: application/json' \
  -d '{"title":"FastAPI","body":"非同期 ORM 経由の pgvector 検索"}'

curl 'http://localhost:8000/search?q=非同期'

# OpenAPI ドキュメントが正常に表示されるか
open http://localhost:8000/docs

kill %1
```

### Next.js (port 3000)

前提: Node.js 22 LTS

```bash
cd appendix-a-frameworks/nextjs
npm install

# Drizzle で migration(必要なら)
npx drizzle-kit push

DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
  OPENAI_API_KEY=$OPENAI_API_KEY \
  npm run dev &

curl -X POST http://localhost:3000/api/docs \
  -H 'content-type: application/json' \
  -d '{"title":"Next.js","body":"App Router + Drizzle"}'

curl 'http://localhost:3000/api/search?q=Next.js'

kill %1
```

### トラブルシュート

| 症状 | 対処 |
|------|------|
| `pq: extension "vector" does not exist` | ベース compose を `up -d` していない / 別 DB に接続している |
| Rails `Could not find pg-x.x.x` | `bundle install` 失敗。OS の libpq-dev / postgresql-client を入れる |
| Django `ImproperlyConfigured: settings.DATABASES is improperly configured` | `DATABASE_URL` 環境変数が未設定 |
| Next.js `Error: connect ECONNREFUSED ::1:5432` | `localhost` を `127.0.0.1` に変更(IPv6 解決の問題) |

---

## T3.2 Ch10 Grafana ダッシュボード起動 + ブラウザ確認

Ch10 本文で 6 パネル(レイテンシ/QPS/idx_scan/サイズ/接続数/autovacuum)を扱った。
実画面でこれらが描画されるかをブラウザで確認する。

### 起動

```bash
cd ch10-observability
docker compose up -d
```

起動するもの:
- postgres (port 5432) — Ch10 専用、ベースとは別
- postgres_exporter (port 9187)
- prometheus (port 9090)
- grafana (port 3002)
- pgbouncer (port 6432)

> **Note**: Ch10 compose はベース compose と同時に上げると 5432 が衝突する。先に `docker compose down`(リポジトリルート)してから起動する。

### 動作確認

```bash
# 1. Prometheus が postgres_exporter を scrape できているか
open http://localhost:9090
# Targets ページで postgres_exporter が UP

# 2. Grafana にログイン
open http://localhost:3002
# user: admin / pass: admin
# Data source: Prometheus を追加(URL: http://prometheus:9090)

# 3. PostgreSQL ダッシュボード(ID 9628)を import
#    Dashboard → New → Import → 9628 → Prometheus を選択

# 4. パネルが描画されることを確認
#    最低限「pg_up」「pg_stat_database_xact_commit」が緑で出る
```

### スクショ取得(出版で図を使う場合)

Phase B 5 マーカーは本文から削除済みなので必須ではないが、改訂版で図差し込みする場合の手順:

```bash
# Playwright MCP なら以下のように指示
# 1. browser_navigate http://localhost:3002 → ログイン
# 2. browser_navigate <dashboard URL>
# 3. browser_take_screenshot
```

合格基準: Grafana ダッシュボードで PostgreSQL メトリクスが時系列で描画される。

### Cleanup

```bash
cd ch10-observability
docker compose down -v
```

---

## T3.3 Ch12 pgvectorscale 実機検証

`postgresql-17-pgvectorscale` パッケージは Tigerdata 公式 apt repo にあり、`timescale/timescaledb-ha:pg17` の base image には含まれていない。そのため **Dockerfile に apt repo の追加が必要**。

本書本文の Dockerfile はあくまで「最短の例示」であり、実 build には以下の Dockerfile を使う(または本文の Dockerfile に下記の `RUN` ブロックを追加する)。

### 完全動作する Dockerfile

```dockerfile
FROM timescale/timescaledb-ha:pg17
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl gnupg lsb-release ca-certificates && \
    curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey \
      | gpg --dearmor -o /etc/apt/keyrings/timescaledb.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/timescaledb.gpg] \
      https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/timescaledb.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-17-pgvectorscale && \
    rm -rf /var/lib/apt/lists/*

USER postgres
```

### 手順

```bash
cd ch12-scaling-migration/pgvectorscale
# (上記 Dockerfile を Dockerfile.full として保存し、または既存 Dockerfile を編集)

# 1. 独自イメージビルド(5-10 分、初回は apt update + curl 取得で時間がかかる)
docker build -t pgvector-rag-pgvs .

# 2. 起動
docker run -d --name pgvs-test \
  -e POSTGRES_PASSWORD=ragpass \
  -e POSTGRES_USER=rag \
  -e POSTGRES_DB=ragdb \
  -p 5433:5432 \
  pgvector-rag-pgvs

# 3. extension 有効化と DiskANN index 構築
sleep 10
PGPASSWORD=ragpass psql -h localhost -p 5433 -U rag -d ragdb <<'EOF'
CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;

CREATE TABLE docs (
    id        bigserial PRIMARY KEY,
    embedding vector(1536) NOT NULL
);

INSERT INTO docs (embedding)
SELECT (SELECT array_agg(random()::real - 0.5)::vector(1536)
        FROM generate_series(1,1536))
FROM generate_series(1, 1000);

CREATE INDEX docs_embedding_diskann
  ON docs USING diskann (embedding vector_cosine_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM docs
ORDER BY embedding <=> (SELECT embedding FROM docs WHERE id = 1)
LIMIT 10;
EOF

# 4. クリーンアップ
docker stop pgvs-test && docker rm pgvs-test
```

合格基準: `EXPLAIN ANALYZE` の出力に `Index Scan using docs_embedding_diskann` が含まれる。

---

## T3.4 Ch11 Logical Replication の 2 インスタンス検証

Ch11 で扱った `logical-setup.sql` は publisher / subscriber の 2 インスタンスが必要。手動でしか検証できない。

```bash
# publisher
docker run -d --name pg-pub \
  -e POSTGRES_PASSWORD=ragpass -e POSTGRES_USER=rag -e POSTGRES_DB=ragdb \
  -p 5434:5432 \
  -c wal_level=logical \
  pgvector/pgvector:0.8.2-pg17-trixie \
  postgres -c wal_level=logical

# subscriber
docker run -d --name pg-sub \
  -e POSTGRES_PASSWORD=ragpass -e POSTGRES_USER=rag -e POSTGRES_DB=ragdb \
  -p 5435:5432 \
  pgvector/pgvector:0.8.2-pg17-trixie

# 両側に同一スキーマ
for port in 5434 5435; do
  PGPASSWORD=ragpass psql -h localhost -p $port -U rag -d ragdb -c "
    CREATE EXTENSION IF NOT EXISTS vector;
    CREATE TABLE docs (id bigserial PRIMARY KEY, embedding vector(1536) NOT NULL);
  "
done

# publisher 側で publication
PGPASSWORD=ragpass psql -h localhost -p 5434 -U rag -d ragdb \
  -f ch11-production-pitfalls/replication/logical-setup.sql

# subscriber 側で subscription
PGPASSWORD=ragpass psql -h localhost -p 5435 -U rag -d ragdb -c "
  CREATE SUBSCRIPTION docs_sub
    CONNECTION 'host=host.docker.internal port=5434 user=rag password=ragpass dbname=ragdb'
    PUBLICATION docs_pub;
"

# データ投入 → 同期確認
PGPASSWORD=ragpass psql -h localhost -p 5434 -U rag -d ragdb -c "
  INSERT INTO docs (embedding)
  SELECT (SELECT array_agg(random()::real - 0.5)::vector(1536) FROM generate_series(1,1536))
  FROM generate_series(1, 5);
"
sleep 3
PGPASSWORD=ragpass psql -h localhost -p 5435 -U rag -d ragdb -c "SELECT count(*) FROM docs;"
# 期待: 5

# クリーンアップ
docker stop pg-pub pg-sub && docker rm pg-pub pg-sub
```

合格基準: subscriber 側で `count = 5`(またはそれ以上)。

---

## T3.5 Ch07/Ch08 本格ベンチ(10 万件)

CI 版は 1,000 件で短時間に終わる構成だが、**本文に記載されている数値**(recall@10 = 0.93→0.97、p95 50ms など)は 100,000 件 × c6i.xlarge での実測値。出版前に AWS で 1 度回しておくのが理想だが、必須ではない(著者実測済みの値を本文に書いている)。

```bash
# AWS EC2 c6i.xlarge を立てる、または手元で半日空けて
docker exec -i -e PGPASSWORD=ragpass pgvector-rag-postgres \
  psql -U rag -d ragdb -f - < ch07-hnsw-benchmark/setup.sql       # 約 5-10 分
docker exec -i -e PGPASSWORD=ragpass pgvector-rag-postgres \
  psql -U rag -d ragdb -f - < ch07-hnsw-benchmark/build-index.sql # 約 5 分

mkdir -p ch07-hnsw-benchmark/eval
docker exec -i -e PGPASSWORD=ragpass pgvector-rag-postgres \
  psql -U rag -d ragdb -f - < ch07-hnsw-benchmark/ground-truth.sql  # 約 10 分

cd ch07-hnsw-benchmark
for ef in 40 100 200; do
  python3 scripts/measure-recall.py --ef $ef --k 10
done
```

合格基準: 本文記載値と ±0.02 以内で再現する recall@10。

---

## チェックリスト(出版前)

| # | 項目 | 完了 |
|---|------|------|
| 1 | T3.1 Rails 起動 + curl 動作 | ☐ |
| 2 | T3.1 Django 起動 + curl 動作 | ☐ |
| 3 | T3.1 FastAPI 起動 + curl 動作 + /docs OpenAPI | ☐ |
| 4 | T3.1 Next.js 起動 + curl 動作 | ☐ |
| 5 | T3.2 Grafana ダッシュボード描画 | ☐ |
| 6 | T3.3 pgvectorscale DiskANN index 動作 | ☐ |
| 7 | T3.4 Logical replication で行が同期される | ☐ |
| 8 | T3.5 Ch07 本格ベンチ(任意、AWS 必要) | ☐ |
| 9 | T3.5 Ch08 本格ベンチ(任意) | ☐ |

完了したら `docs/manual-verification-results.md` に日付と環境を記録すると改訂時に役立つ。
