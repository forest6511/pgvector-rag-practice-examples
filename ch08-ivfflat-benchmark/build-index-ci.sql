-- ch08-ivfflat-benchmark/build-index-ci.sql
-- CI 用の最小 IVFFlat ビルド(lists=10、1000 件用)。本格版は build-index.sql。

\set ON_ERROR_STOP on

SET maintenance_work_mem = '256MB';

DROP INDEX IF EXISTS items_embedding_ivfflat_idx;

CREATE INDEX items_embedding_ivfflat_idx
    ON items
    USING ivfflat (embedding vector_l2_ops)
    WITH (lists = 10);

ANALYZE items;

SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes WHERE indexrelname = 'items_embedding_ivfflat_idx';
