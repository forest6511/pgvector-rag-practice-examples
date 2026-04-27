-- ch07-hnsw-benchmark/build-index-ci.sql
-- CI 用の最小 HNSW ビルド。本格版は build-index.sql(maintenance_work_mem 2GB)を使う。

\set ON_ERROR_STOP on

SET maintenance_work_mem = '256MB';

DROP INDEX IF EXISTS items_embedding_hnsw_idx;

CREATE INDEX items_embedding_hnsw_idx
    ON items
    USING hnsw (embedding vector_l2_ops)
    WITH (m = 16, ef_construction = 64);

ANALYZE items;

SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes WHERE indexrelname = 'items_embedding_hnsw_idx';
