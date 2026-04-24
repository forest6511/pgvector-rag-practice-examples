-- ch07-hnsw-benchmark/ground-truth.sql
-- recall 計測用の ground truth(真の近傍)を seq scan で作る。
-- 評価クエリ 1,000 件に対して k=10 の最近傍 id を CSV 出力する。
-- インデックスを使わないよう明示的に無効化する。

\set ON_ERROR_STOP on

SET enable_indexscan = off;
SET enable_bitmapscan = off;
SET enable_indexonlyscan = off;

CREATE TEMP TABLE eval_queries AS
SELECT id AS query_id, embedding AS query_vec
FROM items
ORDER BY random()
LIMIT 1000;

\copy (
  SELECT q.query_id,
         array_agg(t.id ORDER BY t.embedding <-> q.query_vec) AS gt_ids
  FROM eval_queries q,
       LATERAL (
         SELECT id, embedding
         FROM items
         ORDER BY embedding <-> q.query_vec
         LIMIT 10
       ) t
  GROUP BY q.query_id
) TO 'eval/gt.csv' WITH CSV HEADER
