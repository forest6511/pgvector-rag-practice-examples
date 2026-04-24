"""Ch05: Voyage AI voyage-3 系 / voyage-4 系での埋め込み生成。

本書執筆時点(2026-04)で voyage-4-lite が多言語向けの最新安定。
voyage-multilingual-2 は旧世代扱い。詳細は https://docs.voyageai.com/docs/embeddings 参照。
"""

from __future__ import annotations

import os

import voyageai

client = voyageai.Client(api_key=os.environ["VOYAGE_API_KEY"])


def embed(texts: list[str], model: str = "voyage-4-lite") -> list[list[float]]:
    resp = client.embed(texts, model=model, input_type="document")
    return resp.embeddings


def embed_query(texts: list[str], model: str = "voyage-4-lite") -> list[list[float]]:
    resp = client.embed(texts, model=model, input_type="query")
    return resp.embeddings


if __name__ == "__main__":
    sample = ["pgvector は PostgreSQL のベクトル拡張です"]
    vecs = embed(sample)
    print(f"voyage-4-lite dim: {len(vecs[0])}")  # 1024 default
