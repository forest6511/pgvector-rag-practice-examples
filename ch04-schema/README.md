# ch04-schema

第 4 章「テーブル設計とベクトル型 ― vector / halfvec / sparsevec / bit」のサンプル。

## 構成

```
ch04-schema/
├── patterns/              # テーブル設計パターン別 DDL
│   ├── 01-single-table.sql     単一テーブル RAG
│   ├── 02-normalized.sql       正規化 RAG(documents/chunks/embeddings)
│   ├── 03-halfvec.sql          halfvec(3072) の HNSW index
│   ├── 04-sparsevec.sql        sparsevec(10000)
│   ├── 05-bit.sql              bit(768) binary quantize + HNSW Hamming
│   └── 06-partitioned.sql      月次 RANGE パーティション + ATTACH
├── migrations/
│   ├── 01-add-new-model.sql    埋め込みモデル追加の運用
│   └── 02-dimension-change.sql 次元変更のダウンタイム最小手順
└── bulk-load/
    ├── copy-binary.py          psycopg 3 で COPY FORMAT BINARY
    └── requirements.txt
```

## 実行

リポジトリルートで `docker compose up -d` 済みを前提。

```bash
# 単一テーブル RAG を作る
docker compose exec postgres \
    psql -U rag -d ragdb -f /sql/ch04-schema/patterns/01-single-table.sql

# バルクロード(10,000 行)
cd ch04-schema/bulk-load
pip install -r requirements.txt
PG_DSN=postgresql://rag:ragpass@localhost:5432/ragdb python copy-binary.py
```

> Docker コンテナ内から `/sql/ch04-schema/...` にアクセスするには、
> ルートの `docker-compose.yaml` に `./:/sql:ro` のボリュームマウントが必要。
> compose を変更したくない場合は `psql -f ch04-schema/patterns/01-single-table.sql`
> をホスト側の psql で実行しても良い。

## 章構成との対応

本ディレクトリ内のファイルは、書籍本文「ファイル: \`ch04-schema/...\`」
キャプション付きコードブロックと完全一致する(`scripts/verify-code-parity.sh` で機械検証)。
