\pset null '(null)'
\x
SELECT
    qr.node_name,
    qr.start_timestamp,
    current_timestamp AS current_timestamp,
    (qr.start_timestamp - current_timestamp) AS running_time,
    qr.user_name,
    qr.session_id,
    qr.transaction_id AS trx_id,
    qr.statement_id AS stm_id,
    qr.request_label,
    LEFT(qr.request, 70) AS request,
    LISTAGG(DISTINCT ra.pool_name) AS 'pool(s)'
FROM 
    v_monitor.query_requests qr
    LEFT OUTER JOIN v_internal.dc_resource_acquisitions ra
        USING(transaction_id, statement_id)
WHERE qr.is_executing
GROUP BY 1,2,3,4,5,6,7,8,9,10
;
