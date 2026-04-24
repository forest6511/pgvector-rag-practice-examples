"""Ch06: fugashi(MeCab 互換 Cython wrapper)での形態素解析。

高速(MeCab と同等)で、辞書は unidic-lite(50MB)を別 install。
"""

from __future__ import annotations

from fugashi import Tagger

TAGGER = Tagger()


def tokenize_with_pos(text: str) -> list[tuple[str, str]]:
    return [(token.surface, token.feature.pos1) for token in TAGGER(text)]


def tokenize(text: str) -> list[str]:
    return [token.surface for token in TAGGER(text)]


if __name__ == "__main__":
    text = "pgvector は PostgreSQL のベクトル拡張です。"
    print("surface:", tokenize(text))
    print("with pos:", tokenize_with_pos(text))
