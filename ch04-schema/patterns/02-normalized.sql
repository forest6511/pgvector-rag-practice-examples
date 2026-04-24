-- Ch04: 正規化 RAG(複数モデル・複数次元対応)
-- documents / chunks / embeddings の 3 テーブル構成。
-- 複数の埋め込みモデルを併存させる前提、本番運用向け。

DROP TABLE IF EXISTS embeddings CASCADE;
DROP TABLE IF EXISTS chunks     CASCADE;
DROP TABLE IF EXISTS documents  CASCADE;

CREATE TABLE documents (
    id           bigserial PRIMARY KEY,
    source_url   text        NOT NULL UNIQUE,
    title        text        NOT NULL,
    language     text        NOT NULL DEFAULT 'ja',
    metadata     jsonb       NOT NULL DEFAULT '{}'::jsonb,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE chunks (
    id             bigserial PRIMARY KEY,
    document_id    bigint      NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    ordinal        int         NOT NULL,
    section        text,
    content        text        NOT NULL,
    content_tokens int,
    created_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (document_id, ordinal)
);

CREATE INDEX chunks_document_id_idx ON chunks (document_id);

CREATE TABLE embeddings (
    id            bigserial PRIMARY KEY,
    chunk_id      bigint       NOT NULL REFERENCES chunks(id) ON DELETE CASCADE,
    model_name    text         NOT NULL,
    model_version text         NOT NULL,
    dim           int          NOT NULL,
    -- 複数モデル併存のため汎用 vector 型。次元は CHECK で model ごとに保証
    embedding     vector       NOT NULL,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    UNIQUE (chunk_id, model_name, model_version),
    CHECK (dim > 0 AND dim <= 16000)
);

CREATE INDEX embeddings_chunk_id_idx ON embeddings (chunk_id);
CREATE INDEX embeddings_model_idx    ON embeddings (model_name, model_version);

COMMENT ON TABLE documents  IS '文書単位(source_url でユニーク)';
COMMENT ON TABLE chunks     IS '文書を分割したテキスト単位。embedding は別テーブル';
COMMENT ON TABLE embeddings IS 'chunk と埋め込みモデルの直積。モデル差し替えも追加可能';
