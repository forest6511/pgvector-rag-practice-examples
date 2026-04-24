"""Ch05: OpenAI Embeddings のバッチ処理とレート制限対応。

tenacity で指数バックオフ。OpenAI は RPM / TPM の両方に制限があるため、
どちらを超えても 429 が返る。retry_if_exception_type でハンドル。
"""

from __future__ import annotations

import os
from typing import Iterable

from openai import OpenAI, RateLimitError, APIConnectionError
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

MAX_BATCH = 256


@retry(
    retry=retry_if_exception_type((RateLimitError, APIConnectionError)),
    wait=wait_exponential(multiplier=2, min=1, max=60),
    stop=stop_after_attempt(6),
)
def _embed_batch(batch: list[str], model: str) -> list[list[float]]:
    resp = client.embeddings.create(model=model, input=batch)
    return [d.embedding for d in resp.data]


def embed_all(
    texts: list[str], model: str = "text-embedding-3-small"
) -> list[list[float]]:
    """入力が MAX_BATCH を超える場合は分割し、すべて埋め込んで連結する。"""
    result: list[list[float]] = []
    for i in range(0, len(texts), MAX_BATCH):
        batch = texts[i : i + MAX_BATCH]
        result.extend(_embed_batch(batch, model))
        print(f"embedded {i + len(batch)}/{len(texts)}")
    return result


if __name__ == "__main__":
    texts = [f"サンプル文 {i}" for i in range(1000)]
    vecs = embed_all(texts)
    print(f"embedded {len(vecs)} texts, dim={len(vecs[0])}")
