DROP TABLE IF EXISTS chunks_binary CASCADE;

CREATE TABLE chunks_binary (
    id              bigserial PRIMARY KEY,
    content         text        NOT NULL,
    embedding       vector(768) NOT NULL,
    embedding_bin   bit(768)    NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX chunks_binary_bin_idx
    ON chunks_binary
    USING hnsw (embedding_bin bit_hamming_ops);

CREATE OR REPLACE FUNCTION quantize_embedding_to_bin()
RETURNS trigger AS $$
BEGIN
    NEW.embedding_bin := binary_quantize(NEW.embedding)::bit(768);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER chunks_binary_quantize_trg
    BEFORE INSERT OR UPDATE OF embedding ON chunks_binary
    FOR EACH ROW EXECUTE FUNCTION quantize_embedding_to_bin();
