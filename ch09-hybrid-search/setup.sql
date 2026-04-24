\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgroonga;

DROP TABLE IF EXISTS docs;

CREATE TABLE docs (
    id          bigserial PRIMARY KEY,
    title       text         NOT NULL,
    content     text         NOT NULL,
    embedding   vector(1536) NOT NULL,
    created_at  timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX docs_content_pgroonga
    ON docs
    USING pgroonga (content);

CREATE INDEX docs_embedding_hnsw
    ON docs
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- INSERT 完了後に実行する
ANALYZE docs;

-- PGroonga 側はデータ投入後でも問題ないが、HNSW も同様にデータ投入後構築を推奨
SET maintenance_work_mem = '1GB';
SET max_parallel_maintenance_workers = 3;

REINDEX INDEX docs_embedding_hnsw;
REINDEX INDEX docs_content_pgroonga;
