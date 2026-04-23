# pgvector-rag-practice-examples

書籍 **『pgvectorで作る実務ベクトル検索 ― PostgreSQL 1台で始めるRAGデータ基盤』**(森川 陽介 / KDP)のサンプルコード。

- 書籍リンク: 出版後に追記
- Kindle 価格: ¥1,480(Kindle Unlimited 対応)
- 著者: 森川 陽介(もりかわ ようすけ)
- ライセンス: MIT

## 動作スタック

本リポジトリ全体で以下のバージョンを前提にする。

| 対象 | バージョン | 備考 |
|------|-----------|------|
| PostgreSQL | 17.9 | Debian trixie(pgvector 公式 image ベース) |
| pgvector | 0.8.2 | HNSW / IVFFlat / halfvec / sparsevec / bit |
| PGroonga | 4.0.6 | 日本語全文検索 + TokenMecab |
| Docker Compose | v2.x | |

## クイックスタート

```bash
git clone git@github.com:forest6511/pgvector-rag-practice-examples.git
cd pgvector-rag-practice-examples
docker compose up -d

# 接続確認
docker compose exec postgres psql -U rag -d ragdb -c "\dx"
# 期待: pgvector 0.8.2 + pgroonga 4.0.6 + plpgsql が一覧に出る

# 片付け
docker compose down -v
```

接続情報(ローカル):

- host: `localhost`
- port: `5432`
- db: `ragdb`
- user: `rag` / password: `ragpass`

## ディレクトリ構成

| ディレクトリ | 対応章 | 内容 |
|------------|-------|------|
| `docker/` | 共通 | Dockerfile / init.sql / postgresql.conf |
| `ch03-environment/` | 第 3 章 | 環境構築の確認スクリプト |
| `ch04-schema/` | 第 4 章 | テーブル設計・DDL |
| `ch05-embeddings/` | 第 5 章 | 埋め込みモデル比較(OpenAI / multilingual-e5 / Voyage) |
| `ch06-chunking/` | 第 6 章 | 日本語 chunk 分割(MeCab / Sudachi / Janome) |
| `ch07-hnsw-benchmark/` | 第 7 章 | HNSW チューニング実測(step-NN 構造) |
| `ch08-ivfflat-benchmark/` | 第 8 章 | IVFFlat チューニング実測(step-NN 構造) |
| `ch09-hybrid-search/` | 第 9 章 | pgvector × PGroonga × tsvector RRF |
| `ch10-observability/` | 第 10 章 | Grafana / Prometheus / pg_stat_statements |
| `ch11-production-pitfalls/` | 第 11 章 | VACUUM / CONCURRENTLY / ポストフィルタ |
| `ch12-scaling-migration/` | 第 12 章 | pgvectorscale 比較・Pinecone 移行 |
| `appendix-a-frameworks/` | 付録 A | Rails / Django / FastAPI / Next.js |
| `appendix-c-raw-sql-rag/` | 付録 C | LangChain 非依存の素 SQL RAG |

各章ディレクトリには独立した `README.md` と実行手順がある(Phase 2 以降順次追加)。

## CI

GitHub Actions で以下を検証する(`.github/workflows/`):

- Docker image build
- `docker compose up -d` が healthy になるまで起動
- `psql \dx` で pgvector / PGroonga が両方存在
- HNSW と PGroonga の index が実際に index scan で使われる(smoke test)

章別サンプルの build/test も順次 CI matrix に追加予定。

## ベンチマーク環境(本書の実測値の前提)

本書の実測値(Ch07 の HNSW チューニング、Ch08 IVFFlat、Ch09 ハイブリッド)はすべて以下の環境で計測:

- AWS EC2 `c6i.xlarge`(4 vCPU Intel Xeon / 8 GB RAM)
- gp3 SSD 100 GB(3000 IOPS / 125 MB/s)
- Ubuntu 24.04 LTS(x86_64)
- ap-northeast-1(東京)

手元の Mac / ARM 環境でも同じ compose が動くが、測定値は参考値扱い。詳細は書籍本文と `docs/benchmark-policy.md`(書籍パッケージ側)。

## 本書とこのリポジトリの関係

本書のコードブロックは**すべて本リポジトリの実ファイルと完全一致**する(機械検証済み)。書籍を読みながら該当章のディレクトリに `cd` して動作を確認できる。

書籍本文に「ファイル: \`path/to/file.sql\`」とキャプションがあるコードは、このリポの該当パスに必ず存在する。乖離があれば issue でお知らせください。

## ライセンス

MIT License(`LICENSE` 参照)。

書籍本文の著作権は著者(森川 陽介)に帰属。サンプルコードは MIT ライセンスで自由に利用可能。
