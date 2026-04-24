# ch11-production-pitfalls

第 11 章「本番運用の落とし穴」のサンプル。

## 前提

ルートの `docker compose up -d` で PostgreSQL 17 + pgvector 0.8.2 が起動していること。Ch07 / Ch08 のサンプルでテーブル `docs` と HNSW インデックスを用意しておく。

## 扱うシナリオ

| ファイル | 内容 |
|---------|------|
| `queries/memory-tuning.sql` | work_mem / maintenance_work_mem / hash_mem_multiplier の設定例 |
| `scripts/simulate-long-tx.sh` | CONCURRENTLY をロングトランザクションで停滞させる再現 |
| `queries/long-tx-detect.sql` | 5 分以上走っているトランザクションの検出 |
| `queries/invalid-detect.sql` | INVALID 状態のインデックスを列挙 |
| `queries/invalid-recover.sql` | DROP 再作成と REINDEX CONCURRENTLY による復旧 |
| `queries/post-filter-problem.sql` | ポストフィルタ問題の典型クエリ |
| `queries/iterative-scan.sql` | pgvector 0.8.0+ の Iterative Index Scan |
| `queries/partial-index.sql` | 部分インデックスによるプレフィルタ |
| `queries/autovacuum-tuning.sql` | テーブル単位の autovacuum オーバーライド |
| `queries/extension-upgrade.sql` | ALTER EXTENSION vector UPDATE |
| `replication/logical-setup.sql` | 論理レプリケーションの最小構成 |
| `queries/bottleneck-diagnose.sql` | CPU / IO ボトルネックの切り分け |

## 実行

```bash
# 例: INVALID 状態の検出
docker compose exec -T postgres psql -U rag -d ragdb \
  -f ch11-production-pitfalls/queries/invalid-detect.sql

# 例: CONCURRENTLY 停滞再現
bash ch11-production-pitfalls/scripts/simulate-long-tx.sh
```

## 注意

- 本章のサンプルは破壊的操作(DROP INDEX、REINDEX、ALTER EXTENSION)を含む。本番クラスタに対して実行しないこと
- `replication/logical-setup.sql` は publisher / subscriber 2 インスタンス前提
