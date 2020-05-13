\a
\t
\set sc_tb '''':arg''''
WITH 
arg(arg) AS (
SELECT :sc_tb
)
,
i(i) AS (SELECT  1 
    UNION ALL SELECT  2
    UNION ALL SELECT  3
    UNION ALL SELECT  4
    UNION ALL SELECT  5
    UNION ALL SELECT  6
    UNION ALL SELECT  7
    UNION ALL SELECT  8
    UNION ALL SELECT  9
    UNION ALL SELECT 10
)
,
path(path) AS (
SELECT search_path
FROM query_requests
JOIN current_session USING(session_id)
ORDER BY start_timestamp DESC LIMIT 1
)
,
p AS (
SELECT
  i
, REPLACE(SPLIT_PART(path,', ',i)::VARCHAR(128),'"$user"',user) AS table_schema
FROM path CROSS JOIN i
WHERE SPLIT_PART(path,', ',i) <>''
)
,
srch(sc,tb) AS (
  SELECT
    SPLIT_PART(arg,'.',1)
  , SPLIT_PART(arg,'.',2)
  FROM arg
  WHERE INSTR(arg,'.') > 0
  UNION ALL
  SELECT * FROM (
    SELECT
      tables.table_schema
    , tables.table_name
    FROM tables
    JOIN arg ON table_name=arg
    JOIN p   USING(table_schema)
    ORDER BY i LIMIT 1 
    ) foo
)
,
maxln AS (
SELECT                                    -- need this to align
  MAX(CHAR_LENGTH(column_name)) AS maxln  -- need this to align
FROM columns                              -- need this to align
JOIN srch
   ON sc=table_schema
  AND tb=table_name
)
SELECT
  CASE row_number() OVER (PARTITION BY table_schema,table_name ORDER BY ordinal_position)
    WHEN 1 THEN 'SELECT'||CHR(10)||'  '
    ELSE        ', '
  END
||column_name||REPEAT(' ',maxln - CHAR_LENGTH(column_name))||' AS '||column_name
||CASE WHEN 
    LEAD(column_name) OVER (PARTITION BY table_schema,table_name ORDER BY ordinal_position)
    IS NOT NULL 
    THEN ''
    ELSE CHR(10)||'FROM '||table_schema||'.'||table_name||';'
  END
FROM columns
CROSS JOIN maxln
JOIN srch
   ON sc=table_schema
  AND tb=table_name
;
