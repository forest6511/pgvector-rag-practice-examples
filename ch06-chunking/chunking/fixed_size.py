"""Ch06: 固定長分割(baseline)。

文字数 N とオーバーラップ M で単純にスライス。
日本語の 400 文字 ≒ multilingual-e5 の 512 tokens に収まる。
"""

from __future__ import annotations


def fixed_chunk(text: str, size: int = 400, overlap: int = 80) -> list[str]:
    """size 文字ずつ切り、overlap 文字だけ重ねる。"""
    if size <= 0:
        raise ValueError("size must be positive")
    if overlap >= size:
        raise ValueError("overlap must be less than size")

    chunks: list[str] = []
    step = size - overlap
    for start in range(0, len(text), step):
        end = start + size
        chunks.append(text[start:end])
        if end >= len(text):
            break
    return chunks


if __name__ == "__main__":
    text = "日本語のテスト文章です。" * 100
    out = fixed_chunk(text, size=400, overlap=80)
    print(f"{len(out)} chunks, first chunk {len(out[0])} chars")
