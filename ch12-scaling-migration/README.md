# ch12-scaling-migration

第 12 章「スケール戦略」のサンプル。

## 前提

pgvectorscale を使う章のサンプルは `pgvectorscale/Dockerfile` をビルドしたイメージ、もしくは TimescaleDB HA イメージ + `CREATE EXTENSION vectorscale CASCADE` で起動する。pgbouncer の設定とストリーミングレプリケーションの conf は実機クラスタでの適用例。

## ディレクトリ

| パス | 内容 |
|------|------|
| `pgvectorscale/Dockerfile` | pgvectorscale 同梱 PG17 イメージ |
| `pgvectorscale/setup.sql` | vectorscale 有効化と diskann index 作成 |
| `pgvectorscale/query-tuning.sql` | query_search_list_size / rescore / ラベルフィルタ |
| `pgvectorscale/migrate-hnsw-to-diskann.sql` | HNSW 併存 → 切替 → DROP の段階移行 |
| `pinecone-migration/export.py` | Pinecone fetch API をバッチ化して CSV 出力 |
| `pinecone-migration/import.sql` | CSV から pgvector への `\COPY` と index 作成 |
| `replica/standby.conf` | standby 側 postgresql.conf の要点 |
| `pgbouncer/pgbouncer.ini` | transaction mode での接続プール設定 |

## 実行例

```bash
# pgvectorscale を含む独自イメージをビルド
docker build -t pgvector-rag-pgvs ch12-scaling-migration/pgvectorscale

# Pinecone エクスポート(all_ids はアプリ側で用意)
python ch12-scaling-migration/pinecone-migration/export.py

# CSV 投入
docker compose exec -T postgres psql -U rag -d ragdb \
  -f ch12-scaling-migration/pinecone-migration/import.sql
```

## 注意

- pgvectorscale の macOS Intel ビルドは未サポート。ARM / Linux / Docker を使うこと
- pgbouncer transaction mode では `SET` セッション変数が次のトランザクションに持ち越されない
- Pinecone fetch API は rate limit があるため、バッチ間に適切な sleep を入れること
