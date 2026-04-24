-- Ch04: 新しい埋め込みモデルを追加する運用
-- 正規化 RAG(02-normalized.sql)を前提。
-- OpenAI text-embedding-3-small(1536)で運用中に
-- multilingual-e5-large(1024)を追加し、ABテストを行う流れ。

-- 既存モデルのチェック
SELECT model_name, model_version, dim, count(*)
FROM embeddings
GROUP BY 1, 2, 3;

-- 新モデルを INSERT で追加(chunk_id は既存を流用)
INSERT INTO embeddings (chunk_id, model_name, model_version, dim, embedding)
SELECT
    c.id,
    'multilingual-e5-large',
    'v1.0',
    1024,
    array_fill(0::real, ARRAY[1024])::vector
FROM chunks c
WHERE NOT EXISTS (
    SELECT 1 FROM embeddings e
    WHERE e.chunk_id = c.id
      AND e.model_name = 'multilingual-e5-large'
);

-- モデルごとに条件分岐して HNSW index を張る
CREATE INDEX embeddings_e5_idx
    ON embeddings
    USING hnsw ((embedding::vector(1024)) vector_cosine_ops)
    WITH (m = 16, ef_construction = 64)
    WHERE model_name = 'multilingual-e5-large';

-- クエリ時もモデルを明示
-- SELECT chunk_id FROM embeddings
-- WHERE model_name = 'multilingual-e5-large'
-- ORDER BY embedding <=> $1::vector(1024) LIMIT 10;
