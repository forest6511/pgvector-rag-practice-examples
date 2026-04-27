"""Ch05: OpenAI text-embedding-3-small / text-embedding-3-large による埋め込み生成。

Matryoshka(dimensions パラメータ)対応。レート制限対応は batch/rate-limit.py 側。
"""

from __future__ import annotations

import os
from functools import lru_cache
from typing import Iterable

from openai import OpenAI


@lru_cache(maxsize=1)
def _client() -> OpenAI:
    return OpenAI(api_key=os.environ["OPENAI_API_KEY"])


def embed_small(texts: list[str], dimensions: int | None = None) -> list[list[float]]:
    """text-embedding-3-small。dimensions 省略時は 1536。"""
    kwargs: dict = {"model": "text-embedding-3-small", "input": texts}
    if dimensions is not None:
        kwargs["dimensions"] = dimensions
    resp = _client().embeddings.create(**kwargs)
    return [d.embedding for d in resp.data]


def embed_large(texts: list[str], dimensions: int | None = None) -> list[list[float]]:
    """text-embedding-3-large。dimensions 省略時は 3072(halfvec 推奨)。"""
    kwargs: dict = {"model": "text-embedding-3-large", "input": texts}
    if dimensions is not None:
        kwargs["dimensions"] = dimensions
    resp = _client().embeddings.create(**kwargs)
    return [d.embedding for d in resp.data]


if __name__ == "__main__":
    sample = ["pgvector は PostgreSQL のベクトル拡張です", "RAG の基盤として使える"]
    vecs = embed_small(sample)
    print(f"small default dim: {len(vecs[0])}")

    vecs_768 = embed_small(sample, dimensions=768)
    print(f"small with dimensions=768: {len(vecs_768[0])}")
