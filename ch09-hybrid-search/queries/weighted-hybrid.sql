-- weighted-hybrid (前半): vector 距離と pgroonga スコアを min-max 正規化
-- $1 = 埋め込みベクトル, $2 = クエリ文字列
WITH vec AS (
    SELECT id, embedding <=> $1::vector AS dist
    FROM docs
    ORDER BY embedding <=> $1::vector
    LIMIT 20
),
vec_norm AS (
    SELECT id,
           (MAX(dist) OVER () - dist)
         / NULLIF(MAX(dist) OVER () - MIN(dist) OVER (), 0) AS score_v
    FROM vec
),
kw AS (
    SELECT id, pgroonga_score(tableoid, ctid) AS raw_score
    FROM docs
    WHERE content &@~ $2
    LIMIT 20
),
kw_norm AS (
    SELECT id,
           (raw_score - MIN(raw_score) OVER ())
         / NULLIF(MAX(raw_score) OVER () - MIN(raw_score) OVER (), 0) AS score_k
    FROM kw
)
-- weighted-hybrid (後半): 重み付き和で統合
-- $3 = ベクトル重み(例 0.5), $4 = キーワード重み(例 0.5)
, unioned AS (
    SELECT id, score_v AS s, $3::float AS w FROM vec_norm
    UNION ALL
    SELECT id, score_k AS s, $4::float AS w FROM kw_norm
)
SELECT id, SUM(s * w) AS weighted_score
FROM unioned
GROUP BY id
ORDER BY weighted_score DESC
LIMIT 10;
