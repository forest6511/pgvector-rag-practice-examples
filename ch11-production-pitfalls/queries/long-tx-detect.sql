-- ロングトランザクションの検出
SELECT pid,
       now() - xact_start AS tx_age,
       state,
       wait_event_type,
       wait_event,
       substr(query, 1, 60) AS query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND now() - xact_start > interval '5 minutes'
ORDER BY xact_start;
