"""Ch06: Janome(Pure Python、辞書内包)での形態素解析。

C 拡張や外部辞書のダウンロードが不要。CI や小規模環境で使いやすい。
MeCab / fugashi の約 10 倍遅いため、大量処理には不向き。
"""

from __future__ import annotations

from janome.tokenizer import Tokenizer

TOKENIZER = Tokenizer()


def tokenize_with_pos(text: str) -> list[tuple[str, str]]:
    return [(token.surface, token.part_of_speech.split(",")[0]) for token in TOKENIZER.tokenize(text)]


def tokenize(text: str) -> list[str]:
    return [token.surface for token in TOKENIZER.tokenize(text)]


if __name__ == "__main__":
    text = "pgvector は PostgreSQL のベクトル拡張です。"
    print("surface:", tokenize(text))
    print("with pos:", tokenize_with_pos(text))
