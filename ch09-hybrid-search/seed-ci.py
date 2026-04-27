"""ch09-hybrid-search/seed-ci.py

CI / smoke 検証専用の最小版。本格版は seed.py(100k 件)を使う。
100 件のランダム文書を投入する。

使い方:
    DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
        python seed-ci.py
"""

import os
import random

import psycopg

ROWS = int(os.environ.get("ROWS", "100"))

POOL = [
    "PostgreSQLのベクトル拡張pgvectorは、HNSWとIVFFlatの2種類のインデックスを提供する。",
    "PGroongaはGroongaベースの全文検索拡張で、日本語tokenizeに強い。",
    "Reciprocal Rank Fusionは複数ランキングを統合する軽量アルゴリズムで、k=60が定番。",
]


def main():
    dsn = os.environ["DATABASE_URL"]
    with psycopg.connect(dsn, autocommit=False) as conn, conn.cursor() as cur:
        rows = []
        for i in range(ROWS):
            base = random.choice(POOL)
            title = f"文書{i:06d}"
            content = f"{base} 補足情報 {i}"
            vec = "[" + ",".join(f"{random.random()-0.5:.4f}" for _ in range(1536)) + "]"
            rows.append((title, content, vec))
        cur.executemany(
            "INSERT INTO docs (title, content, embedding) VALUES (%s, %s, %s)",
            rows,
        )
        conn.commit()
    print(f"inserted {ROWS} docs")


if __name__ == "__main__":
    main()
