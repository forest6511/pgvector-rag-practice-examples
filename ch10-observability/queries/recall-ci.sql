-- seq scan で真の最近傍を 1,000 クエリ分生成
-- 出力先: temp table eval_ground_truth
\set ON_ERROR_STOP on

SET enable_indexscan = off;
SET enable_bitmapscan = off;
SET enable_indexonlyscan = off;

DROP TABLE IF EXISTS eval_queries;

CREATE TEMP TABLE eval_queries AS
SELECT id AS query_id, embedding AS query_vec
FROM docs ORDER BY random() LIMIT 1000;

DROP TABLE IF EXISTS eval_ground_truth;

CREATE TEMP TABLE eval_ground_truth AS
SELECT q.query_id,
       ARRAY_AGG(d.id ORDER BY d.embedding <=> q.query_vec) AS gt_ids
FROM eval_queries q
CROSS JOIN LATERAL (
    SELECT id, embedding FROM docs
    ORDER BY embedding <=> q.query_vec
    LIMIT 10
) d
GROUP BY q.query_id;
