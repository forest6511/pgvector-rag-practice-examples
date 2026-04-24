# 付録C: SQL だけで書く RAG 実装 (LangChain 非依存)

LangChain / LlamaIndex を使わず、`psycopg + openai + tiktoken + SQL` だけで RAG の全行程を組む。

## 前提

- ルートの `docker compose up -d` で PostgreSQL + pgvector が起動済み
- `OPENAI_API_KEY` 環境変数が設定済み

## セットアップ

```bash
pip install -r requirements.txt
psql postgresql://rag:ragpass@localhost:5432/ragdb -f setup.sql
```

## 使い方

```bash
# 文書の投入
python ingest.py path/to/doc.md --title "ドキュメント1"

# 検索
python search.py "pgvectorとは何か"

# RAG(検索 + 回答生成)
python rag.py "pgvectorはどんな用途に向いている?"
```

## ファイル構成

- `setup.sql` — `docs` テーブルと HNSW インデックス
- `ingest.py` — chunk 分割 + embedding + INSERT
- `search.py` — クエリ embedding + 類似検索 SQL
- `rerank.py` — 簡易 rerank (embedding + title keyword)
- `generate.py` — OpenAI chat.completions で回答生成
- `rag.py` — 全行程を束ねたエントリポイント
