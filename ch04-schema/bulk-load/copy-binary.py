"""Ch04: psycopg 3 + pgvector-python で COPY FORMAT BINARY バルクロード。

INSERT ... VALUES より 10-50 倍高速。初回ロード時は必ず COPY を使う。
前提: `ch04-schema/patterns/01-single-table.sql` で chunks を作成済み。
"""

from __future__ import annotations

import os
import time

import numpy as np
import psycopg
from pgvector.psycopg import register_vector

ROWS = 10_000
DIMS = 1536


def generate_rows(n: int, dim: int):
    """擬似データ生成。実運用では埋め込み API の出力を渡す。"""
    rng = np.random.default_rng(seed=42)
    for i in range(n):
        vec = rng.standard_normal(dim).astype(np.float32)
        vec /= np.linalg.norm(vec) + 1e-12
        yield (
            f"https://example.com/doc/{i}",
            f"doc-{i}",
            f"これは {i} 番目のサンプル文書です。pgvector のバルクロード検証用。",
            vec,
        )


def main() -> None:
    dsn = os.environ.get(
        "PG_DSN", "postgresql://rag:ragpass@localhost:5432/ragdb"
    )
    with psycopg.connect(dsn, autocommit=True) as conn:
        register_vector(conn)

        start = time.perf_counter()
        with conn.cursor().copy(
            "COPY chunks (source_url, section, content, embedding) "
            "FROM STDIN WITH (FORMAT BINARY)"
        ) as copy:
            copy.set_types(["text", "text", "text", "vector"])
            for source_url, section, content, embedding in generate_rows(
                ROWS, DIMS
            ):
                copy.write_row([source_url, section, content, embedding])
        elapsed = time.perf_counter() - start
        print(f"loaded {ROWS} rows in {elapsed:.2f}s "
              f"({ROWS / elapsed:.0f} rows/s)")

        conn.execute("SET maintenance_work_mem = '1GB'")
        conn.execute("SET max_parallel_maintenance_workers = 4")
        conn.execute(
            "CREATE INDEX IF NOT EXISTS chunks_embedding_idx "
            "ON chunks USING hnsw (embedding vector_cosine_ops) "
            "WITH (m = 16, ef_construction = 64)"
        )
        conn.execute("ANALYZE chunks")

        count = conn.execute("SELECT count(*) FROM chunks").fetchone()[0]
        print(f"rows in chunks: {count}")


if __name__ == "__main__":
    main()
