-- 第11章: CPU / IO ボトルネックの切り分け
-- 現在のクエリ活動(CPU 使用の手掛かり)
SELECT pid, state, wait_event_type, wait_event,
       now() - query_start AS duration,
       substr(query, 1, 60) AS query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY query_start;

-- shared_buffers ヒット率(メモリ圧の手掛かり)
SELECT sum(heap_blks_hit)::float
       / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0) AS hit_ratio
FROM pg_statio_user_tables;

-- インデックス側のヒット率も併せて確認
SELECT sum(idx_blks_hit)::float
       / nullif(sum(idx_blks_hit) + sum(idx_blks_read), 0) AS idx_hit_ratio
FROM pg_statio_user_indexes;

-- ディスク読み込みの絶対量
SELECT relname, heap_blks_read, heap_blks_hit, idx_blks_read, idx_blks_hit
FROM pg_statio_user_tables
ORDER BY heap_blks_read DESC
LIMIT 10;
