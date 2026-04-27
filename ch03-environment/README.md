# Ch03 環境構築

第 3 章「環境構築 ― Docker Compose / AWS RDS / Supabase / Neon」のサンプル。
本章のメインコンテンツは Docker Compose スタックそのもの(リポジトリルートの
`docker-compose.yaml` と `docker/Dockerfile.postgres` / `docker/init.sql` /
`docker/postgresql.conf`)で、本ディレクトリには動作確認用の `verify.sql` が入る。

## 動作確認

```bash
# リポジトリルートから
docker compose up -d
docker compose exec postgres psql -U rag -d ragdb -f /sql/ch03-environment/verify.sql
```

`verify.sql` は次を順に確認する:

1. `\dx` で pgvector / pgroonga / plpgsql の 3 拡張が存在
2. smoke_test テーブルへの INSERT と HNSW + PGroonga の index scan
3. pgvector の距離演算子(`<->`、`<#>`、`<=>`)の動作

CI(`.github/workflows/samples-tier1.yml`)が同じスクリプトを毎 push で実行する。

## ファイル

- `verify.sql` — 上記 3 項目の検証クエリ
- ルート `docker/Dockerfile.postgres` — PostgreSQL 17 + pgvector 0.8.2 + PGroonga 4.0.6 ビルド
- ルート `docker/init.sql` — 初回起動時の拡張作成
- ルート `docker/postgresql.conf` — `shared_buffers` / `work_mem` 等の本書推奨値
