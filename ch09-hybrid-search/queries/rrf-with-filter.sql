-- カテゴリ = 'blog' のみ、過去 30 日以内の文書に対するハイブリッド検索
WITH vec AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) AS rnk
    FROM docs
    WHERE category = 'blog' AND created_at > now() - interval '30 days'
    ORDER BY embedding <=> $1::vector
    LIMIT 20
),
kw AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY pgroonga_score(tableoid, ctid) DESC) AS rnk
    FROM docs
    WHERE content &@~ $2
      AND category = 'blog'
      AND created_at > now() - interval '30 days'
    LIMIT 20
)
SELECT id, SUM(1.0 / (60 + rnk)) AS rrf_score
FROM (SELECT id, rnk FROM vec UNION ALL SELECT id, rnk FROM kw) t
GROUP BY id ORDER BY rrf_score DESC LIMIT 10;
