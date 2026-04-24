-- Ch04: 単一テーブル RAG(最短パス)
-- chunks テーブルに embedding を直接持つ構成。
-- 単一の埋め込みモデルで運用する前提、PoC/検証向け。

DROP TABLE IF EXISTS chunks CASCADE;

CREATE TABLE chunks (
    id           bigserial PRIMARY KEY,
    source_url   text        NOT NULL,
    section      text,
    language     text        NOT NULL DEFAULT 'ja',
    content      text        NOT NULL,
    -- OpenAI text-embedding-3-small を想定(1536 次元)
    embedding    vector(1536) NOT NULL,
    metadata     jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);

-- メタデータで絞り込む用の B-tree(必要に応じて)
CREATE INDEX chunks_source_url_idx ON chunks (source_url);
CREATE INDEX chunks_language_idx   ON chunks (language);

COMMENT ON TABLE  chunks IS '単一テーブル RAG: 1 行 = 1 chunk + embedding';
COMMENT ON COLUMN chunks.embedding IS 'OpenAI text-embedding-3-small 前提、cosine 距離で検索';
