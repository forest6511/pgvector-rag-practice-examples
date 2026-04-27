"""クエリ文字列を embedding 化し、docs から類似検索で上位 K 件を返す。"""
import os
from functools import lru_cache

import psycopg
from openai import OpenAI
from pgvector.psycopg import register_vector


DSN   = os.environ.get("DATABASE_URL", "postgresql://rag:ragpass@localhost:5432/ragdb")
MODEL = "text-embedding-3-small"


@lru_cache(maxsize=1)
def _client() -> OpenAI:
    return OpenAI()


def embed(text: str) -> list[float]:
    return _client().embeddings.create(model=MODEL, input=text).data[0].embedding


def search(query: str, top_k: int = 20) -> list[dict]:
    qvec = embed(query)
    with psycopg.connect(DSN) as conn:
        register_vector(conn)
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, title, body, metadata,
                       1 - (embedding <=> %s::vector) AS similarity
                FROM   docs
                ORDER  BY embedding <=> %s::vector
                LIMIT  %s
                """,
                (qvec, qvec, top_k),
            )
            rows = cur.fetchall()
    return [
        {
            "id":         r[0],
            "title":      r[1],
            "body":       r[2],
            "metadata":   r[3],
            "similarity": float(r[4]),
        }
        for r in rows
    ]


if __name__ == "__main__":
    import sys

    q    = sys.argv[1]
    hits = search(q, top_k=10)
    for h in hits:
        print(f"[{h['id']}] sim={h['similarity']:.3f}  {h['title']}")
        print(f"    {h['body'][:80].replace(chr(10), ' ')}")
