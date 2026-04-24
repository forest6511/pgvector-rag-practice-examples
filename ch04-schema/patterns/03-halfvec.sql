-- Ch04: halfvec による 50% ストレージ削減
-- OpenAI text-embedding-3-large(3072 次元)を扱う場合、
-- vector(3072) は INSERT 可能だが HNSW/IVFFlat index が 2000 次元上限に抵触する。
-- halfvec(3072) なら indexing 上限 4000 次元以内で index も張れる。

DROP TABLE IF EXISTS chunks_large_halfvec CASCADE;

CREATE TABLE chunks_large_halfvec (
    id           bigserial PRIMARY KEY,
    source_url   text         NOT NULL,
    content      text         NOT NULL,
    -- text-embedding-3-large 3072 次元を半精度で保持
    embedding    halfvec(3072) NOT NULL,
    created_at   timestamptz  NOT NULL DEFAULT now()
);

-- halfvec 用の距離演算子は vector と同じ(<->, <=>, <#>, <+>)
-- opclass だけ halfvec_* に置き換える
CREATE INDEX chunks_large_halfvec_embedding_idx
    ON chunks_large_halfvec
    USING hnsw (embedding halfvec_cosine_ops)
    WITH (m = 16, ef_construction = 64);

COMMENT ON TABLE chunks_large_halfvec IS
    'text-embedding-3-large(3072)を halfvec で格納する構成';
