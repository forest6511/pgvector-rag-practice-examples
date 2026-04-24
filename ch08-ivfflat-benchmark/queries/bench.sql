-- ch08-ivfflat-benchmark/queries/bench.sql
-- pgbench カスタムクエリ。probes を random(n, n) で固定値にする。
-- 使い方:
--   pgbench -f queries/bench.sql -T 60 -c 8 -j 2 -P 10 -r -U rag ragdb
--   probes を変えるたびに下の random(1, 1) を (10, 10) などに書き換える。

\set probes random(1, 1)

SET ivfflat.probes = :probes;

SELECT id
FROM items
ORDER BY embedding <-> (
    SELECT embedding FROM items WHERE id = 1 + (random() * 99999)::int LIMIT 1
)
LIMIT 10;
