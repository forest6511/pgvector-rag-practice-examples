-- pgvector と vectorscale を両方有効化(CASCADE で依存を解決)
CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;

-- 基本形(cosine)
CREATE INDEX docs_embedding_diskann
  ON docs USING diskann (embedding vector_cosine_ops);

-- パラメータ明示
CREATE INDEX docs_embedding_diskann_tuned
  ON docs USING diskann (embedding vector_cosine_ops)
  WITH (
      num_neighbors   = 50,
      search_list_size = 100,
      max_alpha       = 1.2,
      storage_layout  = 'memory_optimized'
  );
