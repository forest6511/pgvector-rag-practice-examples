# ch09-hybrid-search

第 9 章「ハイブリッド検索 ― pgvector × PGroonga × tsvector RRF」のサンプル。

## 前提

ルートの `docker compose up -d` で PostgreSQL 17 + pgvector 0.8.2 + PGroonga 4.0.6 が起動していること。

## 構成

```
ch09-hybrid-search/
├── README.md
├── setup.sql              docs テーブル + HNSW + PGroonga インデックス
├── seed.py                10 万件のダミー文書を投入(本番ベンチ用)
├── seed-ci.py             100 件版(CI / smoke 用)
├── queries/
│   ├── vector-only.sql        ベクトル単体の top-k
│   ├── pgroonga-only.sql      キーワード単体の top-k
│   ├── rrf-hybrid.sql         RRF (Reciprocal Rank Fusion) ハイブリッド
│   ├── rrf-with-filter.sql    RRF + WHERE 絞り込み
│   ├── weighted-hybrid.sql    重み付きハイブリッド
│   └── query-expand.sql       クエリ展開(同義語・部分一致)
└── scripts/
    ├── hybrid_py.py           Python から RRF を実行
    └── measure-hybrid.py      vector-only / keyword-only / hybrid-RRF の recall@10 と p95 比較
```

## 手順

```bash
# 1. テーブル + インデックス作成
docker compose exec -T postgres psql -U rag -d ragdb -f - < ch09-hybrid-search/setup.sql

# 2. データ投入(CI 版: 100 件)
DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
  python ch09-hybrid-search/seed-ci.py

# 3. 各方式のクエリを EXPLAIN で確認
docker compose exec -T postgres psql -U rag -d ragdb \
  -f - < ch09-hybrid-search/queries/rrf-hybrid.sql

# 4. recall@10 と p95 を 3 方式で計測(本格ベンチ)
DATABASE_URL=postgresql://rag:ragpass@localhost:5432/ragdb \
  python ch09-hybrid-search/scripts/measure-hybrid.py --queries queries.jsonl
```

`measure-hybrid.py` の入力 `queries.jsonl` は `{qvec, qtext, truth_ids}` 形式。本格的な評価では JMTEB の Retrieval タスクから流用する。
