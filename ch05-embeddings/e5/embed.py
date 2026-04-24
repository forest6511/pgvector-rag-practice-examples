"""Ch05: multilingual-e5-large(intfloat/multilingual-e5-large)での埋め込み生成。

重要: 入力に 'query: ' または 'passage: ' のプレフィックスが必須。
忘れると recall が大きく下がる(公式モデルカードで明示)。
"""

from __future__ import annotations

from sentence_transformers import SentenceTransformer

MODEL_NAME = "intfloat/multilingual-e5-large"
MODEL = SentenceTransformer(MODEL_NAME)


def embed_queries(queries: list[str]) -> list[list[float]]:
    """検索クエリ用。'query: ' プレフィックスを付与して埋め込む。"""
    prefixed = [f"query: {q}" for q in queries]
    vecs = MODEL.encode(prefixed, normalize_embeddings=True)
    return vecs.tolist()


def embed_passages(passages: list[str]) -> list[list[float]]:
    """検索対象の文書用。'passage: ' プレフィックスを付与して埋め込む。"""
    prefixed = [f"passage: {p}" for p in passages]
    vecs = MODEL.encode(prefixed, normalize_embeddings=True)
    return vecs.tolist()


if __name__ == "__main__":
    queries = ["pgvector とは何ですか?"]
    passages = [
        "pgvector は PostgreSQL の拡張で、ベクトル類似検索を提供します。",
        "Docker Compose で pgvector を起動できます。",
    ]

    q_vecs = embed_queries(queries)
    p_vecs = embed_passages(passages)

    print(f"query dim: {len(q_vecs[0])}")      # 1024
    print(f"passage dim: {len(p_vecs[0])}")    # 1024
