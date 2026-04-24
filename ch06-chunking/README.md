# ch06-chunking

第 6 章「日本語 chunk 分割とメタデータ設計 ― MeCab / Sudachi 活用」のサンプル。

## 構成

```
ch06-chunking/
├── tokenizers/       形態素解析器の使い分け(Sudachi / fugashi / Janome)
├── chunking/         分割方式の実装(固定長・文境界・見出し・ハイブリッド)
├── extractors/       PDF / HTML からの本文抽出
└── eval/             chunk サイズと recall の関係(Ch05 eval 流用)
```

## 実行

```bash
cd tokenizers
pip install -r requirements.txt
python sudachi_example.py
python fugashi_example.py
python janome_example.py
```

chunking は stdlib のみで動作するため install 不要。

```bash
cd ../chunking
python fixed_size.py
python sentence_boundary.py
python heading_based.py
python hybrid.py
```

PDF / HTML 抽出:

```bash
cd ../extractors
pip install -r requirements.txt
python pdf_extract.py path/to/document.pdf
```
