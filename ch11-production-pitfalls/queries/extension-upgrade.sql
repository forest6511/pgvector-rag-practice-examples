-- 現在のバージョン確認
SELECT extname, extversion
FROM pg_extension
WHERE extname = 'vector';

-- 最新版へ更新(control file の default version へ)
ALTER EXTENSION vector UPDATE;

-- 特定バージョン指定も可
ALTER EXTENSION vector UPDATE TO '0.8.2';
