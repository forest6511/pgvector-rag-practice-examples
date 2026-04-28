# pgvector-rag-practice-examples

書籍 **『pgvectorで作る実務ベクトル検索 ― PostgreSQL 1台で始めるRAGデータ基盤』**(森川 陽介 / KDP)のサンプルコード。

- Amazon: [pgvectorで作る実務ベクトル検索](https://www.amazon.co.jp/s?k=pgvector%E3%81%A7%E4%BD%9C%E3%82%8B%E5%AE%9F%E5%8B%99%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E6%A4%9C%E7%B4%A2&i=stripbooks)
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
| `ch07-hnsw-benchmark/` | 第 7 章 | HNSW チューニング実測(setup → build-index → ground-truth → measure-recall) |
| `ch08-ivfflat-benchmark/` | 第 8 章 | IVFFlat チューニング実測(同上) |
| `ch09-hybrid-search/` | 第 9 章 | pgvector × PGroonga × tsvector RRF |
| `ch10-observability/` | 第 10 章 | Grafana / Prometheus / pg_stat_statements |
| `ch11-production-pitfalls/` | 第 11 章 | VACUUM / CONCURRENTLY / ポストフィルタ |
| `ch12-scaling-migration/` | 第 12 章 | pgvectorscale 比較・Pinecone 移行 |
| `appendix-a-frameworks/` | 付録 A | Rails / Django / FastAPI / Next.js |
| `appendix-c-raw-sql-rag/` | 付録 C | LangChain 非依存の素 SQL RAG |

各章ディレクトリには独立した `README.md` と実行手順がある。

## CI

GitHub Actions で 3 段階の自動検証を回す。

### docker-compose-smoke (毎 push, 約 1 分)

- Docker image build
- `docker compose up -d` が healthy になるまで起動
- `psql \dx` で pgvector / PGroonga が両方存在
- HNSW と PGroonga の index が index scan で使われる smoke test

### samples-tier1 (毎 push, 約 15 分, API キー不要)

`scripts/verify-tier1.sh` を実行。Ch03-12 + 付録 A/C のサンプルを順次検証:

- Ch04 の全 6 パターン DDL + migrations
- Ch06 chunking 4 種(固定長/文境界/見出し/ハイブリッド)
- **Ch07 HNSW: setup → build-index → ground-truth → measure-recall まで実走**(1000 件版で recall 計測)
- **Ch08 IVFFlat: 同等の実測フロー**
- Ch09 ハイブリッド検索の seed + 6 SQL 構文
- Ch10 の SQL 5 種 + pg_stat_statements 拡張
- Ch11 の 11 SQL(構文 + 一部実走)
- Ch12 pgvectorscale Dockerfile の構文 + 関連 SQL 構文(実 build は samples-tier3 で自動検証)
- 付録 A 4 フレームワークの schema + コード構文
- 付録 C 全スクリプト構文

### samples-tier2 (週次 / 手動, 約 15 分, OPENAI_API_KEY 必要)

`scripts/verify-tier2.sh` を実行(GitHub Secrets に `OPENAI_API_KEY` 必須):

- Ch05 OpenAI / multilingual-e5 / Voyage の埋め込み実走(1 件のみ、コスト < $0.001)
- Ch05 JMTEB-mini 縮小実測
- 付録 C ingest → search → rag end-to-end

### samples-tier3 (週次 / 手動, 約 5-10 分)

`scripts/verify-tier3.sh` を実行。Tier 1/2 で自動化できなかった検証を統合:

- **T3.1** 付録 A 4 フレームワーク (Rails / Django / FastAPI / Next.js) の **依存 install + import 確認**
  - `bundle install` / `pip install` / `npm install` の通過と main module の import 成立まで
  - 起動 + `POST /docs` + `GET /search` の curl 動作は `docs/manual-verification.md` で手動
- **T3.2** Ch10 Grafana スタック (Prometheus + postgres_exporter + Grafana) で `pg_up` メトリクス取得 + Datasource 追加 + クエリ動作
- **T3.3** Ch12 pgvectorscale (`Dockerfile.ci`) build + DiskANN index 作成 + EXPLAIN 動作
- **T3.4** Ch11 Logical Replication (publisher / subscriber 2 インスタンス) で row 同期動作

T3.2/3/4 はローカルでも実走可能 (`bash scripts/verify-tier3.sh --only=t32` 等)。
T3.1 install もローカル可能だが Ruby 3.3 / Node 22 / Python 3.12 が必要。

### ローカル全実走

```bash
# Tier 1 のみ(API キー不要)
bash scripts/verify-all-samples.sh --tier 1

# Tier 1 + Tier 2(OPENAI_API_KEY 環境変数必要)
bash scripts/verify-all-samples.sh

# 個別オプション
bash scripts/verify-tier1.sh --skip-pgvectorscale  # Mac arm64 で自動 skip
bash scripts/verify-tier2.sh --skip-e5              # 2.2GB ダウンロードを回避
```

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
