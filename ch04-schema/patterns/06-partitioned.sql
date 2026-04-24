-- Ch04: 時系列パーティション
-- 社内ドキュメントを月単位で切る構成。古い月はアーカイブ・削除が容易。
-- RANGE パーティションは FROM inclusive, TO exclusive。

DROP TABLE IF EXISTS chunks_partitioned CASCADE;

CREATE TABLE chunks_partitioned (
    id           bigint       GENERATED ALWAYS AS IDENTITY,
    document_id  bigint       NOT NULL,
    content      text         NOT NULL,
    embedding    vector(1536) NOT NULL,
    created_at   timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE TABLE chunks_p_y2026m03 PARTITION OF chunks_partitioned
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE chunks_p_y2026m04 PARTITION OF chunks_partitioned
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE chunks_p_y2026m05 PARTITION OF chunks_partitioned
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- 親テーブルで ONLY + invalid index を作る(パーティション親は
-- CREATE INDEX CONCURRENTLY 不可のため、この迂回が定石)
CREATE INDEX chunks_partitioned_embedding_idx
    ON ONLY chunks_partitioned
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

CREATE INDEX CONCURRENTLY chunks_p_y2026m03_emb_idx
    ON chunks_p_y2026m03
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

ALTER INDEX chunks_partitioned_embedding_idx
    ATTACH PARTITION chunks_p_y2026m03_emb_idx;

CREATE INDEX CONCURRENTLY chunks_p_y2026m04_emb_idx
    ON chunks_p_y2026m04
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

ALTER INDEX chunks_partitioned_embedding_idx
    ATTACH PARTITION chunks_p_y2026m04_emb_idx;

CREATE INDEX CONCURRENTLY chunks_p_y2026m05_emb_idx
    ON chunks_p_y2026m05
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

ALTER INDEX chunks_partitioned_embedding_idx
    ATTACH PARTITION chunks_p_y2026m05_emb_idx;
