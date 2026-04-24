-- 第11章: メモリ関連パラメータのチューニング
-- RRF を含む複雑クエリ側のセッションで引き上げ
SET work_mem = '64MB';
SET hash_mem_multiplier = 2.0;  -- default 2.0、spill 多発なら 4-8 へ

-- 保守側のセッションで引き上げ
SET maintenance_work_mem = '2GB';
SET max_parallel_maintenance_workers = 4;

-- 現在の設定値を確認
SHOW work_mem;
SHOW maintenance_work_mem;
SHOW max_parallel_maintenance_workers;
SHOW shared_buffers;        -- 再起動必須、ここでは参照のみ
SHOW hash_mem_multiplier;

-- セッション終了時は RESET で元に戻す
RESET work_mem;
RESET maintenance_work_mem;
