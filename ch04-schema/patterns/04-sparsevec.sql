-- Ch04: sparsevec を使った SPLADE / BM25 ハイブリッド想定スキーマ
-- sparsevec は非ゼロ要素だけを {index:value}/dim 形式で保持する。
-- 16,000 非ゼロまでストレージ可能、indexing は 1,000 非ゼロまで。
-- index は 1-origin。

DROP TABLE IF EXISTS chunks_sparse CASCADE;

CREATE TABLE chunks_sparse (
    id              bigserial PRIMARY KEY,
    content         text              NOT NULL,
    sparse_embedding sparsevec(10000) NOT NULL,
    created_at      timestamptz       NOT NULL DEFAULT now()
);

CREATE INDEX chunks_sparse_idx
    ON chunks_sparse
    USING hnsw (sparse_embedding sparsevec_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- INSERT 例(index 1, 42, 1337 の 3 要素だけ非ゼロ)
INSERT INTO chunks_sparse (content, sparse_embedding) VALUES
    ('pgvector は PostgreSQL 拡張です',  '{1:0.8,42:0.3,1337:0.1}/10000'),
    ('ベクトル検索は距離関数で行います', '{1:0.7,100:0.5,2048:0.2}/10000');

-- 検索例(同じリテラル形式でクエリ)
-- SELECT id, content FROM chunks_sparse
-- ORDER BY sparse_embedding <=> '{1:0.9,42:0.1}/10000' LIMIT 5;
