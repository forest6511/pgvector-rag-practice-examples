"""Ch06: 文境界(句点・疑問符・感嘆符)で区切る分割。

固定長より意味的まとまりを保つが、1 文が長い場合(論文引用・ソースコード)は
別途サイズ上限でさらに分ける必要がある。
"""

from __future__ import annotations

import re

SENTENCE_BOUNDARY = re.compile(r"(?<=[。!?!?])")


def split_sentences(text: str) -> list[str]:
    """日本語の文境界で分割。句点・感嘆符・疑問符の後で切る。"""
    return [s.strip() for s in SENTENCE_BOUNDARY.split(text) if s.strip()]


def sentence_chunk(text: str, max_chars: int = 400) -> list[str]:
    """文境界で分割してから、max_chars を超えないように詰め合わせる。"""
    sentences = split_sentences(text)
    chunks: list[str] = []
    buf: list[str] = []
    buf_len = 0
    for s in sentences:
        if buf_len + len(s) > max_chars and buf:
            chunks.append("".join(buf))
            buf = []
            buf_len = 0
        buf.append(s)
        buf_len += len(s)
    if buf:
        chunks.append("".join(buf))
    return chunks


if __name__ == "__main__":
    text = "pgvector は PostgreSQL の拡張です。ベクトル類似検索を提供します。HNSW と IVFFlat が使えます。"
    print(split_sentences(text))
    print(sentence_chunk(text, max_chars=30))
