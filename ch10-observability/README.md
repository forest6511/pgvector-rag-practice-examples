# ch10-observability

第 10 章「可観測性 ― pg_stat_statements / Grafana / recall CI」のサンプル。

## 前提

本ディレクトリは **独立した docker-compose スタック** を持つ(ルートの compose とは別)。
PostgreSQL + postgres_exporter + Prometheus + Grafana + pgbouncer の 5 サービス構成。

ポート衝突を避けるため、ルート compose を停止してから起動する:

```bash
# ルート compose を停止
docker compose down

# Ch10 スタック起動
cd ch10-observability
docker compose up -d
```

## 構成

```
ch10-observability/
├── README.md
├── docker-compose.yaml    PG + postgres_exporter + Prometheus + Grafana + pgbouncer
├── prometheus.yml         Prometheus scrape 設定(postgres_exporter のみ)
├── prometheus/
│   └── alerts.yml         アラートルール例
├── setup.sql              pg_stat_statements 拡張の有効化
├── queries/
│   ├── slow-queries.sql       pg_stat_statements で重いクエリ列挙
│   ├── index-usage.sql        インデックス使用率(idx_scan / idx_tup_read|fetch)
│   ├── buffer-status.sql      shared_buffers ヒット率
│   ├── recall-ci.sql          ground truth 用の seq scan クエリ生成
│   └── mrr.sql                MRR (Mean Reciprocal Rank) 計算
└── scripts/
    ├── recall-ci.sh           recall を週次で計測する CI スクリプト
    └── dynamic_ef.py          負荷状況に応じて hnsw.ef_search を動的調整
```

## ポート

| サービス | ポート |
|---------|--------|
| PostgreSQL | 5432 |
| postgres_exporter | 9187 |
| Prometheus | 9090 |
| Grafana | 3002 (内部 3000) |
| pgbouncer | 6432 |

## Grafana 初期設定

1. http://localhost:3002 にアクセス(admin / admin)
2. Connections > Add new data source > Prometheus
   - URL: `http://prometheus:9090`(docker network 内)
3. Dashboards > New > Import > 9628(Postgres Database)

詳細は本書 Ch10 本文の「監視ダッシュボード設計」節を参照。

## 動作確認

```bash
# Prometheus が pg_up を取得できるか
curl 'http://localhost:9090/api/v1/query?query=pg_up'

# Grafana ヘルスチェック
curl 'http://localhost:3002/api/health'
```

## クリーンアップ

```bash
cd ch10-observability
docker compose down -v
```
