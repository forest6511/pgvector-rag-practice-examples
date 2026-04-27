-- 付録C 用の docs テーブルと HNSW インデックス
-- 本文 Ch09 や付録 A も同じ DB に docs テーブルを作るため、
-- 本付録専用のスキーマで再作成する(他章のスキーマを破壊しないために必要)。

CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS docs CASCADE;

CREATE TABLE docs (
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
