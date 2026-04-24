-- ch07-hnsw-benchmark/queries/bench.sql
-- pgbench カスタムクエリ。ef_search を環境変数で可変にする。
-- 使い方:
--   EF=40  pgbench -f queries/bench.sql -T 60 -c 8 -j 2 -P 10 -r -U rag ragdb
--   EF=100 pgbench ...
--
-- :query_vec は `\set query_vec` で pgbench 起動時に渡す想定。
-- 実運用では別コーパスのクエリ embedding を random にロードする。

\set ef random(40, 40)

SET hnsw.ef_search = :ef;

SELECT id
FROM items
ORDER BY embedding <-> (
    SELECT embedding FROM items WHERE id = 1 + (random() * 99999)::int LIMIT 1
)
LIMIT 10;
