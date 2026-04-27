-- ch08-ivfflat-benchmark/setup-ci.sql
-- CI / smoke 検証専用の最小版。本格ベンチは setup.sql(100k 件)を使う。
-- 1,000 件投入 → IVFFlat ビルド → recall 計測まで 60 秒以内に終わるサイズ。
-- IVFFlat の lists は CI では 10 に縮める(rows / 100)。

\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS items;

CREATE TABLE items (
    id          bigserial PRIMARY KEY,
    embedding   vector(1536) NOT NULL,
    category    text         NOT NULL,
    created_at  timestamptz  NOT NULL DEFAULT now()
);

INSERT INTO items (embedding, category)
SELECT
    (SELECT array_agg(random()::real - 0.5)::vector(1536)
       FROM generate_series(1, 1536)),
    (ARRAY['docs', 'blog', 'faq', 'wiki'])[1 + (i % 4)]
FROM generate_series(1, 1000) AS i;

ANALYZE items;

SELECT count(*) AS row_count FROM items;
