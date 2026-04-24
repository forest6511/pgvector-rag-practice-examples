-- eval_results: 各クエリ × 実際に返ってきた id と rank
-- eval_ground_truth: 各クエリ × 正解 id 配列(gt_ids)
SELECT AVG(1.0 / first_hit) AS mrr
FROM (
    SELECT r.query_id,
           MIN(r.rnk) FILTER (WHERE r.id = ANY(g.gt_ids)) AS first_hit
    FROM eval_results r
    JOIN eval_ground_truth g USING (query_id)
    GROUP BY r.query_id
) s
WHERE first_hit IS NOT NULL;
