"""簡易 rerank: embedding similarity に title の部分一致ボーナスを足す。

本格的な rerank は cross-encoder や Ch09 の RRF を参照。
"""


def simple_rerank(hits: list[dict], query: str) -> list[dict]:
    keyword = query.strip()

    for h in hits:
        bonus    = 0.1 if keyword and keyword in h["title"] else 0.0
        h["score"] = h["similarity"] + bonus

    return sorted(hits, key=lambda h: h["score"], reverse=True)
