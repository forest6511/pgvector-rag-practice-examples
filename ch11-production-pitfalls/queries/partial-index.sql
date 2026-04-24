-- 「アクティブかつ優先テナント」に限定した HNSW
CREATE INDEX docs_active_hnsw
  ON docs USING hnsw (embedding vector_cosine_ops)
  WHERE status = 'active' AND tenant_id IN (1, 2, 3);

-- クエリ側も同じ条件を含めることでプランナが選択する
EXPLAIN
SELECT id FROM docs
WHERE status = 'active' AND tenant_id = 2
ORDER BY embedding <=> $1::vector
LIMIT 10;
