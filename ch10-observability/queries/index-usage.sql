-- pgvector / PGroonga 関連の index 使用状況
SELECT
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname LIKE '%hnsw%'
   OR indexrelname LIKE '%ivfflat%'
   OR indexrelname LIKE '%pgroonga%'
ORDER BY idx_scan DESC;
