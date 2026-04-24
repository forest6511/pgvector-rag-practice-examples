-- 想定: tenant_id = 7 のドキュメントを類似度で 10 件取得
SELECT id, content
FROM docs
WHERE tenant_id = 7
ORDER BY embedding <=> $1::vector
LIMIT 10;
