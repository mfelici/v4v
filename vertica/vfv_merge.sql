\a
\t
\set sc_tb '''':arg''''
CREATE LOCAL TEMPORARY TABLE
srch(sc,tb) 
ON COMMIT PRESERVE ROWS AS 
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
;

-- establish schema and table to generate the statement 
-- for and get the length of the longest column name 
-- for alignment in the generated code
\o /dev/null
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS
search(table_schema,table_name,maxln) 
ON COMMIT PRESERVE ROWS AS
SELECT
  table_schema
, table_name
, MAX(char_length(column_name))
FROM columns 
JOIN srch
   ON sc=table_schema
  AND tb=table_name
GROUP BY
  table_schema
, table_name
UNSEGMENTED ALL NODES;

CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS worktab (
  phase INT NOT NULL
, seq   INT NOT NULL
, line  VARCHAR(256)
)
ON COMMIT PRESERVE ROWS
UNSEGMENTED ALL NODES;

-- MERGE statement head, INTO, USING and ON clause
INSERT /*+DIRECT */ INTO worktab
SELECT
  1
, ROW_NUMBER() OVER(ORDER BY c.ordinal_position)
, CASE ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
   WHEN 1 THEN   'MERGE /*+DIRECT*/'
      ||CHR(10)||'INTO  '||c.table_schema||'.'||c.table_name||' t'
      ||CHR(10)||'USING '||c.table_schema||'.stg_'||c.table_name||' s'
      ||CHR(10)||' ON '
   ELSE 'AND '
  END
||'s.'||c.column_name
||repeat(' ',maxln-char_length(c.column_name)) -- alignment space
||' = t.'||c.column_name
FROM search s
NATURAL
JOIN columns c
NATURAL
JOIN constraint_columns cc
WHERE cc.constraint_type='p'
;

-- WHEN MATCHED THEN UPDATE clause
INSERT /*+DIRECT */ INTO worktab
SELECT
  2
, ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
, CASE ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
    WHEN 1 THEN 'WHEN MATCHED THEN UPDATE SET   '||CHR(10)||'  '
    ELSE ', '
  END
||column_name
||repeat(' ',maxln-char_length(c.column_name)) -- alignment space
||' = s.'||column_name
FROM search s
NATURAL
JOIN columns c
;

-- WHEN NOT MATCHED THEN INSERT clause part with column list
INSERT /*+DIRECT */ INTO worktab
SELECT
  3
, ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
, CASE ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
    WHEN 1 THEN 'WHEN NOT MATCHED THEN INSERT (   '||CHR(10)||'  '
    ELSE ', '
  END
||column_name
FROM search s
NATURAL
JOIN columns c
;

-- WHEN NOT MATCHED THEN INSERT clause, the VALUES() sub clause,
-- and closing bracket and final semicolon
INSERT /*+DIRECT */ INTO worktab
SELECT
  4
, ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
, CASE ROW_NUMBER() OVER (ORDER BY c.ordinal_position)
    WHEN 1 THEN ') VALUES ('||CHR(10)||'  s.'
    ELSE ', s.'
  END
||column_name
||CASE 
   WHEN LEAD(c.column_name) OVER (ORDER BY c.ordinal_position) IS NULL
     THEN CHR(10)||');'
     ELSE ''
   END
FROM search s
NATURAL
JOIN columns c
;

\o
SELECT
  line AS "-- optimised MERGE statement"
FROM worktab
ORDER BY
  phase
, seq
;
