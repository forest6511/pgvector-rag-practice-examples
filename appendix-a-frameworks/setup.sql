-- 付録A 共通スキーマ
-- 4 フレームワーク(Rails / Django / FastAPI / Next.js)のサンプルで共有する。

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS docs (
    id         bigserial PRIMARY KEY,
    title      text NOT NULL,
    body       text NOT NULL,
    embedding  vector(1536) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS docs_embedding_hnsw
    ON docs USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
