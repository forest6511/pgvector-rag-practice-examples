-- ch07-hnsw-benchmark/build-index.sql
-- HNSW インデックスを構築する標準手順。
-- m / ef_construction / maintenance_work_mem の 3 点をセッションで明示する。

\set ON_ERROR_STOP on

SET maintenance_work_mem = '2GB';
SET max_parallel_maintenance_workers = 3;

DROP INDEX IF EXISTS items_embedding_hnsw_idx;

CREATE INDEX items_embedding_hnsw_idx
    ON items
    USING hnsw (embedding vector_l2_ops)
    WITH (m = 16, ef_construction = 64);

ANALYZE items;

SELECT
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE indexrelname = 'items_embedding_hnsw_idx';
