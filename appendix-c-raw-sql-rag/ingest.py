"""文書を chunk 分割して embedding 生成し、docs テーブルに INSERT する。

使い方:
    python ingest.py path/to/doc.md --title "ドキュメント名"
"""
import argparse
import os
import sys

import psycopg
import tiktoken
from openai import OpenAI
from pgvector.psycopg import register_vector


DSN   = os.environ.get("DATABASE_URL", "postgresql://rag:ragpass@localhost:5432/ragdb")
MODEL = "text-embedding-3-small"
ENC   = tiktoken.get_encoding("cl100k_base")
OAI   = OpenAI()


def chunk(text: str, target_tokens: int = 400, overlap: int = 50) -> list[str]:
    tokens = ENC.encode(text)
    pieces = []
    i = 0
    while i < len(tokens):
        piece = tokens[i : i + target_tokens]
        pieces.append(ENC.decode(piece))
        i += target_tokens - overlap
    return pieces


def embed_batch(texts: list[str]) -> list[list[float]]:
    resp = OAI.embeddings.create(model=MODEL, input=texts)
    return [d.embedding for d in resp.data]


def ingest(path: str, title: str) -> int:
    with open(path, encoding="utf-8") as f:
        text = f.read()
    pieces = chunk(text)

    inserted = 0
    with psycopg.connect(DSN) as conn:
        register_vector(conn)
        for batch_start in range(0, len(pieces), 64):
            batch  = pieces[batch_start : batch_start + 64]
            vecs   = embed_batch(batch)
            with conn.cursor() as cur:
                for idx, (body, vec) in enumerate(zip(batch, vecs)):
                    cur.execute(
                        """
                        INSERT INTO docs (title, body, embedding, metadata)
                        VALUES (%s, %s, %s, %s)
                        """,
                        (
                            title,
                            body,
                            vec,
                            psycopg.types.json.Jsonb(
                                {"source": path, "chunk": batch_start + idx}
                            ),
                        ),
                    )
                    inserted += 1
            conn.commit()
    return inserted


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("path")
    p.add_argument("--title", required=True)
    args = p.parse_args()

    n = ingest(args.path, args.title)
    print(f"inserted {n} chunks from {args.path}", file=sys.stderr)
