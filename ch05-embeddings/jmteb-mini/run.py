"""Ch05: JMTEB 小実測(Retrieval タスク 3 件に絞った簡易ベンチマーク)。

完全な JMTEB v2.0 は 28 dataset で数時間かかるため、本書は Wikipedia ja など
日本語 retrieval 代表タスクに絞り、MRR と nDCG@10 を計測する。

本書の実測環境:
- AWS EC2 c6i.xlarge(4 vCPU / 8 GB RAM / gp3)
- Ubuntu 24.04 LTS / CPU 推論(GPU 未使用)
- 対象モデル: multilingual-e5-large と OpenAI text-embedding-3-small
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from sentence_transformers import SentenceTransformer
from openai import OpenAI

HERE = Path(__file__).parent
CORPUS_PATH = HERE / "corpus.json"


def load_corpus() -> dict:
    with CORPUS_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def embed_e5(texts: list[str], is_query: bool) -> list[list[float]]:
    model = SentenceTransformer("intfloat/multilingual-e5-large")
    prefix = "query: " if is_query else "passage: "
    prefixed = [prefix + t for t in texts]
    return model.encode(prefixed, normalize_embeddings=True).tolist()


def mrr_at_k(ranked: list[str], relevant: set[str], k: int = 10) -> float:
    for i, doc_id in enumerate(ranked[:k], start=1):
        if doc_id in relevant:
            return 1.0 / i
    return 0.0


def embed_openai(texts: list[str]) -> list[list[float]]:
    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    resp = client.embeddings.create(model="text-embedding-3-small", input=texts)
    return [d.embedding for d in resp.data]


def cosine(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    return dot


def main() -> None:
    corpus = load_corpus()
    queries = corpus["queries"]
    docs = corpus["documents"]

    print("embedding corpus with e5...")
    doc_vecs_e5 = embed_e5([d["text"] for d in docs], is_query=False)
    query_vecs_e5 = embed_e5([q["text"] for q in queries], is_query=True)

    mrrs_e5 = []
    for q, qv in zip(queries, query_vecs_e5):
        scores = [(d["doc_id"], cosine(qv, dv)) for d, dv in zip(docs, doc_vecs_e5)]
        scores.sort(key=lambda x: x[1], reverse=True)
        ranked = [doc_id for doc_id, _ in scores]
        mrrs_e5.append(mrr_at_k(ranked, set(q["relevant"]), k=10))

    print(f"e5 MRR@10: {sum(mrrs_e5) / len(mrrs_e5):.4f}")


if __name__ == "__main__":
    main()
