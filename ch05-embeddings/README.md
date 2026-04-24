# ch05-embeddings

第 5 章「埋め込みモデル選定 ― multilingual-e5 vs OpenAI text-embedding-3(JMTEB 比較)」のサンプル。

## 構成

```
ch05-embeddings/
├── openai/           OpenAI text-embedding-3-small / large(Python)
├── e5/               multilingual-e5-large(sentence-transformers)
├── voyage/           Voyage AI voyage-4-lite
├── batch/            バッチ処理 + レート制限対応(tenacity)
├── jmteb-mini/       JMTEB 縮小版(Retrieval 3 タスク)
├── nodejs/           OpenAI Node.js SDK + TypeScript
└── ruby/             ruby-openai
```

## 実行例

OpenAI:

```bash
cd openai
pip install -r requirements.txt
export OPENAI_API_KEY=sk-...
python embed.py
```

multilingual-e5:

```bash
cd e5
pip install -r requirements.txt
python embed.py   # 初回はモデル DL で数 GB のダウンロード
```

JMTEB 小実測:

```bash
cd jmteb-mini
pip install -r requirements.txt
python run.py
```

## 注意

- OpenAI / Voyage の API キーは `.env` に入れてください(コミットしないこと)
- multilingual-e5 は 2.2 GB 程度のモデルデータを HuggingFace からダウンロードします
- **multilingual-e5 の呼び出し時、`query: ` または `passage: ` のプレフィックスが必須**です。これを忘れると recall が大きく下がります
