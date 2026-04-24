-- Ch03 環境構築確認スクリプト
-- 用途: pgvector と PGroonga が有効化され、HNSW インデックス経由の検索が
--       index scan で実行されることを確認する。
--
-- 実行:
--   docker compose exec postgres psql -U rag -d ragdb -f ch03-environment/verify.sql

-- 1. インストール済み拡張の一覧
SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('vector', 'pgroonga')
ORDER BY extname;

-- 2. vector 型カラムを含むサンプルテーブル smoke_test の存在確認
SELECT table_name, column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'smoke_test'
ORDER BY ordinal_position;

-- 3. HNSW インデックス + pgroonga インデックスの存在確認
SELECT schemaname, indexname, indexdef
FROM pg_indexes
WHERE tablename = 'smoke_test'
ORDER BY indexname;

-- 4. ベクトル類似検索が動作することを確認(L2 距離)
SELECT id, content,
       embedding <-> '[1.0, 0.0, 0.0]' AS l2_distance
FROM smoke_test
ORDER BY embedding <-> '[1.0, 0.0, 0.0]'
LIMIT 3;

-- 5. HNSW インデックスが使われることを EXPLAIN で確認
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, content
FROM smoke_test
ORDER BY embedding <-> '[1.0, 0.0, 0.0]'
LIMIT 1;

-- 6. PGroonga 全文検索が動作することを確認
SELECT id, content
FROM smoke_test
WHERE content &@ 'sample';
