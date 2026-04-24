-- 距離順を厳密に維持しつつ、LIMIT を満たすまで自動的に候補を広げる
SET hnsw.iterative_scan = strict_order;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM docs
WHERE tenant_id = 7
ORDER BY embedding <=> $1::vector
LIMIT 10;

-- 速度優先で順序を緩める(recall は概ね維持)
SET hnsw.iterative_scan = relaxed_order;

-- IVFFlat 用
SET ivfflat.iterative_scan = relaxed_order;

-- 元に戻す(セッション単位なので明示的に OFF)
SET hnsw.iterative_scan = off;
SET ivfflat.iterative_scan = off;
