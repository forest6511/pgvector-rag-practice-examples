"""Ch06: Sudachi の A/B/C 分割モード比較。

Mode A(最短): 国家 / 公務 / 員
Mode B(中間): 国家 / 公務員
Mode C(最長): 国家公務員(1 語)

chunk 境界としては Mode C が扱いやすい(固有名詞を 1 語で保持)。
"""

from __future__ import annotations

from sudachipy import tokenizer, dictionary

TOKENIZER = dictionary.Dictionary().create()


def tokenize(text: str, mode: str = "C") -> list[str]:
    split_mode = {
        "A": tokenizer.Tokenizer.SplitMode.A,
        "B": tokenizer.Tokenizer.SplitMode.B,
        "C": tokenizer.Tokenizer.SplitMode.C,
    }[mode]
    return [m.surface() for m in TOKENIZER.tokenize(text, split_mode)]


if __name__ == "__main__":
    text = "国家公務員は毎年試験がある。pgvector は PostgreSQL の拡張です。"
    for mode in ("A", "B", "C"):
        print(f"Mode {mode}: {tokenize(text, mode)}")
