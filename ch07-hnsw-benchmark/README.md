# ch07-hnsw-benchmark

第 7 章「HNSW チューニング」のサンプル。m / ef_construction / ef_search を変えながら recall とレイテンシを実測するためのスクリプト群。

## 前提

ルートで Docker Compose が起動していること。

```bash
docker compose up -d
```

## 実行手順

```bash
# 1. items テーブルと 10 万件のランダムベクトルを投入
docker compose exec -T postgres psql -U rag -d ragdb < setup.sql

# 2. HNSW インデックスを構築(m=16, ef_construction=64)
docker compose exec -T postgres psql -U rag -d ragdb < build-index.sql

# 3. 進捗を別ターミナルで見る(構築中のみ)
bash scripts/monitor-build.sh

# 4. ground truth(真の近傍)を seq scan で作る
mkdir -p eval
docker compose exec -T postgres psql -U rag -d ragdb < ground-truth.sql

# 5. ef_search を変えて recall を計測
pip install psycopg
python scripts/measure-recall.py --ef 40
python scripts/measure-recall.py --ef 100
python scripts/measure-recall.py --ef 200

# 6. pgbench で p95 レイテンシを計測
pgbench -f queries/bench.sql -T 60 -c 8 -j 2 -P 10 -r \
        -h localhost -U rag ragdb
```

## ファイル一覧

| ファイル | 用途 |
|---------|------|
| `setup.sql` | items テーブル作成 + 10 万ベクトル投入 |
| `build-index.sql` | HNSW インデックス構築(m=16, ef_construction=64) |
| `ground-truth.sql` | seq scan で真の近傍 k=10 を CSV 出力 |
| `queries/bench.sql` | pgbench カスタムクエリ |
| `scripts/monitor-build.sh` | pg_stat_progress_create_index を watch |
| `scripts/measure-recall.py` | eval/gt.csv との比較で recall@10 計測 |

## ベンチマーク環境(著者実測値の前提)

- AWS EC2 c6i.xlarge(4 vCPU / 8 GB RAM / gp3 200 IOPS ベース)
- PostgreSQL 17.9 / pgvector 0.8.2
- `maintenance_work_mem = 2GB`
- `shared_buffers = 2GB`

Mac 上の Docker Desktop は参考値として計測可だが、本書本文の数値は EC2 実測値を採用している。
