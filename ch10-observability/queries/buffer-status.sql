-- shared_buffers のヒット率(pgvector のインデックスが cache に乗っているかの指標)
SELECT datname,
       blks_hit,
       blks_read,
       round(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS hit_ratio
FROM pg_stat_database
WHERE datname = 'ragdb';

-- 特定インデックスのサイズと buffer 使用率
SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size,
       (SELECT buffers_backend FROM pg_stat_bgwriter) AS backend_buffers
FROM pg_stat_user_indexes
WHERE indexrelname = 'docs_embedding_hnsw';
