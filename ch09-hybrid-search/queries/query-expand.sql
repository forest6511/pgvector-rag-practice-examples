-- synonyms テーブル: term -> synonyms 配列
CREATE TABLE IF NOT EXISTS synonyms (
    term     text PRIMARY KEY,
    synonyms text[]
);

CREATE INDEX IF NOT EXISTS synonyms_term_pg
    ON synonyms
    USING pgroonga (term pgroonga_text_term_search_ops_v2);

-- 登録例
INSERT INTO synonyms (term, synonyms) VALUES
    ('Mac',    ARRAY['マック', 'macOS', 'OSX']),
    ('AWS',    ARRAY['Amazon Web Services']),
    ('レイテンシ', ARRAY['遅延', '応答時間', 'レスポンス時間'])
ON CONFLICT (term) DO UPDATE SET synonyms = EXCLUDED.synonyms;

-- 検索側: $1 のクエリ文字列を同義語展開してから &@~ に流す
SELECT id, title
FROM docs
WHERE content &@~ pgroonga_query_expand(
    'synonyms', 'term', 'synonyms', $1
)
LIMIT 10;
