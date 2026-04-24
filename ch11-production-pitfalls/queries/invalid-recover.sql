-- INVALID 状態からの復旧手順
-- パターン A: DROP して作り直す(シンプル、ダウンタイムは短い)
DROP INDEX docs_embedding_hnsw;
CREATE INDEX CONCURRENTLY docs_embedding_hnsw
  ON docs USING hnsw (embedding vector_cosine_ops);

-- パターン B: REINDEX INDEX CONCURRENTLY(INVALID 対応可)
REINDEX INDEX CONCURRENTLY docs_embedding_hnsw;

-- REINDEX CONCURRENTLY が途中で失敗した場合、_ccnew / _ccold が INVALID で残る
-- 両方とも DROP してから再実行する
DROP INDEX IF EXISTS docs_embedding_hnsw_ccnew;
DROP INDEX IF EXISTS docs_embedding_hnsw_ccold;
REINDEX INDEX CONCURRENTLY docs_embedding_hnsw;
