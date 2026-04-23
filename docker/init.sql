-- 初回起動時に実行される SQL。PostgreSQL 公式 image 慣習で
-- /docker-entrypoint-initdb.d/ に配置されたスクリプトが自動実行される。

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgroonga;

-- 動作確認用のサンプル table(Ch03 smoke test で使用)
CREATE TABLE IF NOT EXISTS smoke_test (
    id serial PRIMARY KEY,
    content text NOT NULL,
    embedding vector(3)
);

-- pgvector 動作確認
INSERT INTO smoke_test (content, embedding) VALUES
    ('sample text 1', '[1.0, 0.0, 0.0]'),
    ('sample text 2', '[0.0, 1.0, 0.0]'),
    ('sample text 3', '[0.0, 0.0, 1.0]');

-- PGroonga 動作確認用 index
CREATE INDEX IF NOT EXISTS smoke_test_content_pgroonga
    ON smoke_test USING pgroonga (content);

-- HNSW 動作確認
CREATE INDEX IF NOT EXISTS smoke_test_embedding_hnsw
    ON smoke_test USING hnsw (embedding vector_l2_ops)
    WITH (m = 16, ef_construction = 64);
