"""Ch06: ハイブリッド分割(見出し優先 + 固定長フォールバック)。

1. Markdown 見出しで大きく区切る
2. 各セクションが長すぎる(例: 800 文字超)場合、文境界で再分割
3. それでも長い場合は固定長でさらに刻む
"""

from __future__ import annotations

from dataclasses import dataclass

from .heading_based import HeadingChunk, split_by_headings
from .sentence_boundary import sentence_chunk


MAX_CHARS = 400
OVERLAP = 80


def hybrid_chunk(markdown: str) -> list[Chunk]:
    out: list[Chunk] = []
    section_chunks = split_by_headings(markdown)
    ordinal = 0
    for sc in section_chunks:
        if len(sc.content) <= MAX_CHARS:
            out.append(Chunk(sc.section_path, ordinal, sc.content))
            ordinal += 1
            continue
        sub_chunks = sentence_chunk(sc.content, max_chars=MAX_CHARS)
        for piece in sub_chunks:
            out.append(Chunk(sc.section_path, ordinal, piece))
            ordinal += 1
    return out


@dataclass
class Chunk:
    section_path: list[str]
    ordinal: int
    content: str


if __name__ == "__main__":
    md = "# 入門\n\n" + ("これは長い説明文です。" * 60)
    for c in hybrid_chunk(md):
        print(c.ordinal, c.section_path, len(c.content))
