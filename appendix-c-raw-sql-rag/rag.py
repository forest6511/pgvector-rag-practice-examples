"""RAG エントリポイント: 検索 + rerank + 回答生成。

使い方:
    python rag.py "pgvectorはどんな用途に向いていますか?"
"""
import sys

from search import search
from rerank import simple_rerank
from generate import generate


def rag(query: str) -> str:
    hits    = search(query, top_k=20)
    reranked = simple_rerank(hits, query)
    return generate(query, reranked[:5])


if __name__ == "__main__":
    query = sys.argv[1]
    print(rag(query))
