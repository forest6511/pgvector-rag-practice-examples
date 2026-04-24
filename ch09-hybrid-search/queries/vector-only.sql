-- vector-only: embedding 距離だけで top 10
-- $1 はクエリ埋め込み(1536次元のvector)
SELECT id, title
FROM docs
ORDER BY embedding <=> $1::vector
LIMIT 10;
