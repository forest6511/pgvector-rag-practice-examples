"""アプリから rrf-hybrid.sql を呼ぶ最小 Python 実装。

使い方:
    with psycopg.connect(DATABASE_URL) as conn:
        ids = hybrid_search(conn, qvec, qtext)
"""

import psycopg
from pathlib import Path

SQL = Path("queries/rrf-hybrid.sql").read_text()

def hybrid_search(conn, qvec, qtext, k_rrf=60, k=10):
    with conn.cursor() as cur:
        cur.execute(SQL, (qvec, qtext, k_rrf))
        return [row[0] for row in cur.fetchmany(k)]
