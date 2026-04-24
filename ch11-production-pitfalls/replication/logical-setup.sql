-- 第11章: 論理レプリケーションの最小セットアップ
-- publisher 側
CREATE EXTENSION vector;
CREATE PUBLICATION docs_pub FOR TABLE docs;

-- subscriber 側(両方に vector 拡張が必要)
CREATE EXTENSION vector;
CREATE TABLE docs (LIKE /* publisher 側と同じ定義 */);
CREATE SUBSCRIPTION docs_sub
  CONNECTION 'host=publisher port=5432 user=repl dbname=ragdb'
  PUBLICATION docs_pub;

-- 初期同期後、subscriber 側で手動インデックス構築
CREATE INDEX CONCURRENTLY docs_embedding_hnsw
  ON docs USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- 状態確認
SELECT subname, subenabled, subconninfo
FROM pg_subscription;

SELECT * FROM pg_stat_subscription;
