-- rrf-hybrid: 両方の top 20 から RRF で top 10
-- $1 = クエリ埋め込み(vector), $2 = クエリ文字列(text), $3 = RRF定数 k(=60)
WITH vec AS (
    SELECT id,
           ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) AS rnk
    FROM docs
    ORDER BY embedding <=> $1::vector
    LIMIT 20
),
kw AS (
    SELECT id,
           ROW_NUMBER() OVER (ORDER BY pgroonga_score(tableoid, ctid) DESC) AS rnk
    FROM docs
    WHERE content &@~ $2
    LIMIT 20
),
unioned AS (
    SELECT id, rnk FROM vec
    UNION ALL
    SELECT id, rnk FROM kw
)
SELECT id, SUM(1.0 / ($3::int + rnk)) AS rrf_score
FROM unioned
GROUP BY id
ORDER BY rrf_score DESC
LIMIT 10;
