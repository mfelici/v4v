# -----------------------------------------------------------------------
#!/bin/bash
# Executed by Vim For SQL to extract profile info - Version 0.1
# -----------------------------------------------------------------------

# Check script to be executed:
SCRIPT="${HOME}/._vfv.sql"
test -r ${SCRIPT} || { echo "$0 Error: Script ${SCRIPT} is not readable" ; exit 1 ; }

# Run the query and get Transaction/Statement IDs:
echo "Running query result set redirected to /dev/null)..."
trxst=$(sed "1s/^/PROFILE /" ${SCRIPT} | 
	vsql -XAnq -f - -o /dev/null 2>&1 | 
	sed -n 's/^HINT:.*=\([0-9]*\).*=\([0-9]*\);$/\1,\2/p')
if [ -z "${trxst}" ] ; then
    echo "[qprof] No Transaction/Statement ID retrieved. Check your SQL"
    exit 2
fi
TID=${trxst%,*}
SID=${trxst#*,}

echo "# -----------------------------------------------------------------"
echo "# Query Execution Steps"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v tid=${TID} -v sid=${SID} -f - <<-EOF
    SELECT
		statement_id as sid,
        execution_step, 
        MAX(completion_time - time) AS elapsed
    FROM 
        v_internal.dc_query_executions 
    WHERE 
        transaction_id=:tid
    GROUP BY 
        1, 2
    ORDER BY
		1, 3 DESC
    ;
EOF

echo "# -----------------------------------------------------------------"
echo "# Resource Acquisition"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v tid=${TID} -v sid=${SID} -f - <<-EOF
    SELECT
		a.statement_id AS sid,
        a.node_name,
        a.queue_entry_timestamp,
        a.acquisition_timestamp,
        ( a.acquisition_timestamp - a.queue_entry_timestamp ) AS queue_wait_time,
        a.pool_name
    FROM 
        v_monitor.resource_acquisitions a
        INNER JOIN query_profiles b
            ON a.transaction_id = b.transaction_id
    WHERE 
        a.transaction_id=:tid
    ORDER BY
        1, 2
    ;
EOF

echo "# -----------------------------------------------------------------"
echo "# Query Consumption"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v tid=${TID} -v sid=${SID} -f - <<-EOF
    \pset expanded
    SELECT
		*
    FROM 
        v_monitor.query_consumption
    WHERE 
        transaction_id=:tid
    ORDER BY
        statement_id
    ;
EOF

echo "# -----------------------------------------------------------------"
echo "# Query Events"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v tid=${TID} -v sid=${SID} -f - <<-EOF
    \pset expanded
    \echo '    Step 8: Query events'
    \qecho >>> Step 8: Query events
    SELECT 
		statement_id AS sid,
        event_timestamp, 
        node_name, 
        event_category, 
        event_type, 
        event_description, 
        operator_name, 
        path_id,
        event_details, 
        suggested_action 
    FROM 
        v_monitor.query_events 
    WHERE 
        transaction_id=:tid
    ORDER BY 
        1, 2
    ;
EOF

echo "# -----------------------------------------------------------------"
echo "# High Level Plan Profile"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v tid=${TID} -v sid=${SID} -f - <<-EOF
	SELECT
		statement_id AS sid,
		running_time,
		memory_allocated_bytes//(1024*1024) AS mem_MB,
		read_from_disk_bytes//(1024*104) AS disk_read_MB,
		received_bytes//(1024*1024) AS net_rec_MB,
		sent_bytes//(1024*1024) AS net_sent_MB,
		path_line
	FROM
		v_monitor.query_plan_profiles
	WHERE
		transaction_id = :tid
	ORDER BY
		statement_id, path_id, path_line_index
;
EOF

echo "# -----------------------------------------------------------------"
echo "# More Detailed Execution Profile"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v tid=${TID} -v sid=${SID} -f - <<-EOF
    SELECT
		statement_id as sid,
        node_name, 
        path_id,
        operator_name, 
        activity_id::VARCHAR || ',' || baseplan_id::VARCHAR || ',' || localplan_id::VARCHAR AS abl_id,
        COUNT(DISTINCT(operator_id)) AS '#Threads'
    FROM 
        v_monitor.execution_engine_profiles 
    WHERE 
        transaction_id=:tid
    GROUP BY 
        1, 2, 3, 4, 5
    ORDER BY
        1, 2, 3, 4;
    \qecho Please Note:
    \qecho abl_id = activity_id,baseplan_id,localplan_id

	SELECT
		statement_id AS sid,
		node_name ,
		operator_name,
		path_id,
		ROUND(SUM(CASE counter_name WHEN 'execution time (us)' THEN
		counter_value ELSE NULL END)/1000,3.0) AS exec_time_ms,
		SUM(CASE counter_name WHEN 'estimated rows produced' THEN
		counter_value ELSE NULL END ) AS est_rows,
		SUM ( CASE counter_name WHEN 'rows processed' THEN
		counter_value ELSE NULL END ) AS proc_rows,
		SUM ( CASE counter_name WHEN 'rows produced' THEN
		counter_value ELSE NULL END ) AS prod_rows,
		SUM ( CASE counter_name WHEN 'rle rows produced' THEN
		counter_value ELSE NULL END ) AS rle_prod_rows,
		SUM ( CASE counter_name WHEN 'consumer stall (us)' THEN
		counter_value ELSE NULL END ) AS cstall_us,
		SUM ( CASE counter_name WHEN 'producer stall (us)' THEN
		counter_value ELSE NULL END ) AS pstall_us,
		ROUND(SUM(CASE counter_name WHEN 'memory reserved (bytes)' THEN
		counter_value ELSE NULL END)/1000000,1.0) AS mem_res_mb,
		ROUND(SUM(CASE counter_name WHEN 'memory allocated (bytes)' THEN 
		counter_value ELSE NULL END )/1000000,1.0) AS mem_all_mb
    FROM
		v_monitor.execution_engine_profiles
    WHERE
		transaction_id = :tid AND
		counter_value/1000000 > 0
    GROUP BY
		1, 2, 3, 4
    ORDER BY
		-- NULL values at the end...
		CASE WHEN SUM(CASE counter_name WHEN 'execution time (us)' THEN
		counter_value ELSE NULL END) IS NULL THEN 1 ELSE 0 END asc ,
		5 DESC
    ;
EOF
