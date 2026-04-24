-- 付録C 用の docs テーブルと HNSW インデックス

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS docs (
    id         bigserial PRIMARY KEY,
    title      text  NOT NULL,
    body       text  NOT NULL,
    embedding  vector(1536) NOT NULL,
    metadata   jsonb NOT NULL DEFAULT '{}',
    created_at timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS docs_embedding_hnsw
    ON docs USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
