-- ch08-ivfflat-benchmark/build-index.sql
-- IVFFlat インデックス構築の標準手順。
-- lists は「行数 10 万 / 1000 = 100」を起点にし、ベンチで 100 / 1000 を比較する。
-- maintenance_work_mem は k-means フェーズでは大きな効果は出ないが、
-- loading tuples フェーズで default 64MB を使うと遅くなる。

\set ON_ERROR_STOP on

SET maintenance_work_mem = '1GB';
SET max_parallel_maintenance_workers = 3;

DROP INDEX IF EXISTS items_embedding_ivfflat_idx;

CREATE INDEX items_embedding_ivfflat_idx
    ON items
    USING ivfflat (embedding vector_l2_ops)
    WITH (lists = 100);

ANALYZE items;

SELECT
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE indexrelname = 'items_embedding_ivfflat_idx';
