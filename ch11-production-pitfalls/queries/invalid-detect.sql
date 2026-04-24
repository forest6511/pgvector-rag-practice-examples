-- INVALID 状態のインデックスを列挙
SELECT i.indexrelid::regclass AS index_name,
       c.relname              AS table_name,
       i.indisvalid,
       i.indisready
FROM pg_index i
JOIN pg_class c ON c.oid = i.indrelid
WHERE NOT i.indisvalid
  AND c.relkind = 'r';
