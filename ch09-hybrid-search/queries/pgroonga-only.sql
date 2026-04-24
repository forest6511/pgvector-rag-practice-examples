-- pgroonga-only: &@~ のスコアで top 10
-- $1 はクエリ文字列
SELECT id, title, pgroonga_score(tableoid, ctid) AS score
FROM docs
WHERE content &@~ $1
ORDER BY pgroonga_score(tableoid, ctid) DESC
LIMIT 10;
