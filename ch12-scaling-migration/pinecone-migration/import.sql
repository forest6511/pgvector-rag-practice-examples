-- スキーマ作成(次元は Pinecone index と一致させる)
CREATE TABLE docs (
    id        text PRIMARY KEY,
    embedding vector(1536),
    metadata  jsonb
);

-- CSV 投入(embedding は "[...]" 形式、jsonb は JSON 文字列)
\COPY docs (id, embedding, metadata)
    FROM 'pinecone_export.csv' WITH (FORMAT csv, HEADER true);

-- インデックス構築(Ch07 の CONCURRENTLY 注意点を守る)
SET maintenance_work_mem = '2GB';
CREATE INDEX CONCURRENTLY docs_embedding_hnsw
  ON docs USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
