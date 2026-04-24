-- 1. postgresql.conf または ALTER SYSTEM で 3 行追加
-- shared_preload_libraries = 'pg_stat_statements'
-- compute_query_id = 'auto'
-- pg_stat_statements.track = 'all'

-- 2. サーバを再起動(shared_preload_libraries は reload では反映されない)

-- 3. DB 内で拡張を CREATE
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
