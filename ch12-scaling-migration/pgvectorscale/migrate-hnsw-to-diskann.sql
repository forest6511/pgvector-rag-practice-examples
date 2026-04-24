-- 第12章: HNSW から DiskANN への段階的移行
-- 1. 新 index を CONCURRENTLY 構築(Ch11 の注意点を守る)
CREATE INDEX CONCURRENTLY docs_embedding_diskann
  ON docs USING diskann (embedding vector_cosine_ops);

-- 2. 両者が張られた状態で EXPLAIN を取り、プランナ選択を観察
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM docs
ORDER BY embedding <=> $1::vector
LIMIT 10;

-- 3. diskann 側に寄ったことを確認したら HNSW を DROP
DROP INDEX docs_embedding_hnsw;

-- 移行期間中のフィードバック用: index ごとの呼び出し回数を観察
SELECT indexrelid::regclass AS index_name,
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'docs'
ORDER BY idx_scan DESC;
