# ch08-ivfflat-benchmark

第 8 章「IVFFlat チューニング」のサンプル。

## 前提

ルートの `docker compose up -d` で PostgreSQL 17 + pgvector 0.8.2 が起動していること。

## 手順

```bash
# 1. テーブル作成と 10 万件投入
docker compose exec -T postgres psql -U rag -d ragdb -f ch08-ivfflat-benchmark/setup.sql

# 2. ground truth 生成(インデックス無効の seq scan、1,000 クエリ × top-10)
mkdir -p ch08-ivfflat-benchmark/eval
docker compose exec -T postgres psql -U rag -d ragdb \
    -f ch08-ivfflat-benchmark/ground-truth.sql

# 3. IVFFlat インデックス構築(lists=100 がデフォルト、書き換えて lists=1000 も試す)
docker compose exec -T postgres psql -U rag -d ragdb -f ch08-ivfflat-benchmark/build-index.sql

# 4. probes を変えながら recall@10 を計測
python ch08-ivfflat-benchmark/scripts/measure-recall.py --probes 1
python ch08-ivfflat-benchmark/scripts/measure-recall.py --probes 10
python ch08-ivfflat-benchmark/scripts/measure-recall.py --probes 100

# 5. pgbench で p95 レイテンシを測る(queries/bench.sql の random(n,n) を書き換える)
pgbench -f ch08-ivfflat-benchmark/queries/bench.sql \
        -T 60 -c 8 -j 2 -P 10 -r -U rag ragdb

# 6. 構築中の監視(別ターミナル)
bash ch08-ivfflat-benchmark/scripts/monitor-build.sh
```

## ディレクトリ構成

```
ch08-ivfflat-benchmark/
├── README.md
├── setup.sql              items テーブル + 10 万件 INSERT
├── build-index.sql        IVFFlat インデックス(lists=100 の標準形)
├── ground-truth.sql       seq scan による真の top-10
├── queries/bench.sql      pgbench カスタムクエリ(probes 可変)
└── scripts/
    ├── measure-recall.py  probes ごとの recall@10
    └── monitor-build.sh   pg_stat_progress_create_index 監視(4 フェーズ)
```
