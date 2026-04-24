-- ch08-ivfflat-benchmark/ground-truth.sql
-- Ch07 と同じ方針。インデックスを無効化した seq scan で
-- 1,000 クエリそれぞれに対する真の top-10 を CSV に書き出す。
-- 出力: eval/gt.csv (既存を上書き)

\set ON_ERROR_STOP on

SET enable_indexscan = off;
SET enable_bitmapscan = off;
SET enable_indexonlyscan = off;

DROP TABLE IF EXISTS eval_queries;

CREATE TEMP TABLE eval_queries AS
SELECT id AS query_id, embedding AS query_vec
FROM items
ORDER BY random()
LIMIT 1000;

\copy (                                                                       \
  SELECT q.query_id,                                                          \
         array_agg(t.id ORDER BY t.embedding <-> q.query_vec) AS gt_ids       \
  FROM eval_queries q,                                                        \
       LATERAL (                                                              \
         SELECT id, embedding                                                 \
         FROM items                                                           \
         ORDER BY embedding <-> q.query_vec                                   \
         LIMIT 10                                                             \
       ) t                                                                    \
  GROUP BY q.query_id                                                         \
) TO 'eval/gt.csv' WITH CSV HEADER
