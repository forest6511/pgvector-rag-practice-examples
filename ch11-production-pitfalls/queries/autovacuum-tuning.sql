-- 埋め込みテーブル向け autovacuum チューニング
ALTER TABLE docs SET (
    autovacuum_vacuum_scale_factor = 0.05,   -- 5% で起動
    autovacuum_vacuum_threshold    = 1000,
    autovacuum_analyze_scale_factor = 0.02,
    autovacuum_vacuum_cost_limit   = 2000,
    autovacuum_vacuum_cost_delay   = 2
);

-- 設定の確認
SELECT relname, reloptions
FROM pg_class
WHERE relname = 'docs';
