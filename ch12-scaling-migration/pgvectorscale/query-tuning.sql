-- 候補検索数(default 100)
SET diskann.query_search_list_size = 100;

-- 再スコア候補数(default 50、0 で無効)
SET diskann.query_rescore = 50;

-- ラベルフィルタ付き検索(labels は SMALLINT[] である必要あり)
SELECT id, content
FROM docs
WHERE labels && ARRAY[1, 3]::smallint[]
ORDER BY embedding <=> $1::vector
LIMIT 10;
