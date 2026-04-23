# Ch03 環境構築

第 3 章「環境構築 ― Docker Compose / AWS RDS / Supabase / Neon」のサンプル。

## 動作確認

```bash
# リポジトリルートから
docker compose up -d
docker compose exec postgres psql -U rag -d ragdb -f ch03-environment/verify.sql
```

本ディレクトリのサンプルファイルは Phase 2(執筆)で追加予定。現状はスタブ。
