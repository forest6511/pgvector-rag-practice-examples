"""10 万件の日本語ドキュメントを docs テーブルに投入する。

本番の評価では日本語 Wikipedia 等の実コーパスを使うが、CI や初期動作確認用に
ランダムベクトル + 循環テキストの軽量版を提供する。

使い方:
    DATABASE_URL=postgresql://rag:rag@localhost:5432/ragdb \\
        python seed.py
"""

import os, random, psycopg

SYSTEM_PROMPT_POOL = [
    "PostgreSQLのベクトル拡張pgvectorは、HNSWとIVFFlatの2種類のインデックスを提供する。",
    "PGroongaはGroongaベースの全文検索拡張で、日本語tokenizeに強い。",
    "Reciprocal Rank Fusionは複数ランキングを統合する軽量アルゴリズムで、k=60が定番。",
    # ... 本番では Wikipedia 日本語ダンプ等から抽出した多様なテキスト
]

def main():
    dsn = os.environ["DATABASE_URL"]
    with psycopg.connect(dsn, autocommit=False) as conn, conn.cursor() as cur:
        rows = []
        for i in range(100_000):
            base = random.choice(SYSTEM_PROMPT_POOL)
            title = f"文書{i:06d}"
            content = f"{base} 補足情報 {i}"
            vec = "[" + ",".join(f"{random.random()-0.5:.4f}" for _ in range(1536)) + "]"
            rows.append((title, content, vec))
        cur.executemany(
            "INSERT INTO docs (title, content, embedding) VALUES (%s, %s, %s)",
            rows,
        )
        conn.commit()
    print("inserted 100k docs")

if __name__ == "__main__":
    main()
