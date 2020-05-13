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
,
code(ordinal_position,code) AS (
SELECT
  ordinal_position
, CASE row_number() OVER (PARTITION BY table_schema,table_name ORDER BY ordinal_position)
    WHEN 1 THEN 'COPY '||table_schema||'.'||table_name||' ('||CHR(10)||'  '
    ELSE        ', '
  END
||column_name
||CASE WHEN 
    LEAD(column_name) OVER (PARTITION BY table_schema,table_name ORDER BY ordinal_position)
    IS NOT NULL 
    THEN ''
    ELSE 
      CHR(10)||')'
    ||CHR(10)||'FROM ''/data_dir/'||table_name||'.csv'''
    ||CHR(10)||'-- ON '||(SELECT NODE_NAME FROM current_session)
    ||CHR(10)||'-- ON ANY NODE'
    ||CHR(10)||'DELIMITER ''|'' ENCLOSED BY ''"'''
    ||CHR(10)||'DIRECT'
    ||CHR(10)||'REJECTED DATA ''/data_dir/'||table_name||'.bad'' EXCEPTIONS ''/data_dir/'||table_name||'.log'''
    ||CHR(10)||'REJECTMAX 50 -- comment this line out for apportioned load'
    ||CHR(10)||'-- ABORT ON ERROR'
    ||CHR(10)||';'
  END
FROM columns
CROSS
JOIN maxln
JOIN srch
   ON sc=table_schema
  AND tb=table_name
)
SELECT code FROM code ORDER BY ordinal_position
;
