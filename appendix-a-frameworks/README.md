# 付録A: Rails / Django / FastAPI / Next.js サンプル

4 フレームワークで同一の最小 RAG 機能(`POST /docs` と `GET /search`)を実装し、pgvector との統合方法を比較する。

## 前提

ルートの `docker compose up -d` で PostgreSQL + pgvector + PGroonga を起動済みであること。

```bash
docker compose up -d
psql postgresql://rag:ragpass@localhost:5432/ragdb -f appendix-a-frameworks/setup.sql
```

## 共通スキーマ

`setup.sql` で `docs` テーブルと HNSW インデックスを作成する。4 フレームワークとも同じスキーマを参照する。

## 各フレームワークの起動手順

| フレームワーク | ポート | 起動コマンド |
|---------------|-------|-------------|
| Rails | 3001 | `cd rails && bundle install && bin/rails s -p 3001` |
| Django | 8001 | `cd django && pip install -r requirements.txt && python manage.py runserver 8001` |
| FastAPI | 8000 | `cd fastapi && pip install -r requirements.txt && uvicorn main:app --port 8000` |
| Next.js | 3000 | `cd nextjs && npm install && npm run dev` |

各フレームワークは `OPENAI_API_KEY` と `DATABASE_URL` を環境変数で読む。

## 動作確認

```bash
# ドキュメント投入
curl -X POST http://localhost:8000/docs \
     -H 'content-type: application/json' \
     -d '{"title":"pgvector","body":"PostgreSQLのベクトル検索拡張"}'

# 類似検索
curl 'http://localhost:8000/search?q=ベクトル+DB'
```
