"""高精度検索のデモ: SET LOCAL で ef_search を一時的に引き上げる。"""

import psycopg


def search_high_precision(conn, qvec, ef_search=200, k=10):
    with conn.transaction(), conn.cursor() as cur:
        cur.execute(f"SET LOCAL hnsw.ef_search = {ef_search}")
        cur.execute(
            "SELECT id FROM docs ORDER BY embedding <=> %s::vector LIMIT %s",
            (qvec, k),
        )
        return [row[0] for row in cur.fetchall()]
