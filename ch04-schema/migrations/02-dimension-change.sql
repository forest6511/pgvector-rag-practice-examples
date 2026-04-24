-- Ch04: 既存カラムの次元変更(単一テーブル RAG)
-- pgvector の vector 型は ALTER TABLE ... TYPE で次元を変えても
-- 既存データのキャストはされない。現実的な手順は以下:
--   1. 新カラムを追加(新次元)
--   2. 再埋め込みで populate
--   3. 新しいインデックスを張る
--   4. アプリ側の参照を切り替え
--   5. 旧カラム削除

-- Step 1: 新カラム追加 / Step 2: populate / Step 3: halfvec+index
-- Step 4: アプリ参照切り替え / Step 5: 旧カラム削除(参照無くなってから)

ALTER TABLE chunks
    ADD COLUMN embedding_v2 vector(3072);

ALTER TABLE chunks
    ADD COLUMN embedding_v2_half halfvec(3072)
    GENERATED ALWAYS AS (embedding_v2::halfvec(3072)) STORED;

CREATE INDEX chunks_embedding_v2_half_idx
    ON chunks
    USING hnsw (embedding_v2_half halfvec_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- UPDATE chunks SET embedding_v2 = $1 WHERE id = $2;   -- 再埋め込みで populate
-- ALTER TABLE chunks DROP COLUMN embedding;            -- 最後に旧カラム削除
