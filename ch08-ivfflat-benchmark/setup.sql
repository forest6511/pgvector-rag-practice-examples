-- ch08-ivfflat-benchmark/setup.sql
-- IVFFlat チューニング計測用のテーブルとテストデータを用意する。
-- 前提: docker compose up -d で rag/ragdb/ragpass が起動していること。
-- 注意: IVFFlat はデータ投入後に CREATE INDEX する(k-means に実データが必要)。

\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS items;

CREATE TABLE items (
    id          bigserial PRIMARY KEY,
    embedding   vector(1536) NOT NULL,
    category    text         NOT NULL,
    created_at  timestamptz  NOT NULL DEFAULT now()
);

-- 10 万件のランダムベクトル。Ch07 と同じ次元(1536)・行数でそろえる。
-- 実コーパスでは事前に埋め込みを計算して COPY で流し込む。
INSERT INTO items (embedding, category)
SELECT
    (SELECT array_agg(random()::real - 0.5)::vector(1536)
       FROM generate_series(1, 1536)),
    (ARRAY['docs', 'blog', 'faq', 'wiki'])[1 + (i % 4)]
FROM generate_series(1, 100000) AS i;

ANALYZE items;

SELECT count(*) AS row_count,
       pg_size_pretty(pg_total_relation_size('items')) AS size
FROM items;
