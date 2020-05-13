# -----------------------------------------------------------------------
#!/bin/bash
# Executed by Vim For SQL to extract table info - Version 0.1
# Single argument in input ${1} expected format [schema.]table
# -----------------------------------------------------------------------

test $# -ne 1 && { echo "$0 Error: missing [schema.]table" ; exit 1 ; }

# Check Command line:
arrst=(${1//./ })				# split ${1} into an array on '.'
if [ -z ${arrst[1]} ] ; then	# no schema...
	schema="-"
	table="${arrst[0]}"
else
	schema="${arrst[0]}"
	table="${arrst[1]}"
fi

echo "# -----------------------------------------------------------------"
echo "# Projection Storage by node (SCHEMA=${schema} TABLE=${table})"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v schema=\'${schema}\' -v table=\'${table}\' -f - <<-EOF
	SELECT
		projection_name,
		node_name,
		SUM(row_count) AS row_count, 
		SUM(used_bytes) AS used_bytes,
		SUM(wos_row_count) AS wos_row_count, 
		SUM(wos_used_bytes) AS wos_used_bytes, 
		SUM(ros_row_count) AS ros_row_count, 
		SUM(ros_used_bytes) AS ros_used_bytes,
		SUM(ros_count) AS ros_count
	FROM
		v_monitor.projection_storage 
	WHERE 
		('-' = :schema OR anchor_table_schema = :schema) AND
		anchor_table_name = :table
	GROUP BY 1, 2
	ORDER BY 1, 2
	;
EOF

echo "# -----------------------------------------------------------------"
echo "# Projection Storage by column (SCHEMA=${schema} TABLE=${table})"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v schema=\'${schema}\' -v table=\'${table}\' -f - <<-EOF
	SELECT
		cs.projection_name,
		cs.column_name,
		SUM(cs.row_count) AS row_count, 
		SUM(cs.used_bytes) AS used_bytes,
		MAX(pc.encoding_type) AS encoding_type,
		MAX(pc.statistics_type) AS statistics_type,
		MAX(pc.statistics_updated_timestamp) AS last_updated,
		MAX(cs.encodings) AS encodings,
		MAX(cs.compressions) AS compressions
	FROM
		v_monitor.column_storage cs
		inner join v_catalog.projection_columns pc
		on cs.column_id = pc.column_id 
	WHERE 
		('-' = :schema OR anchor_table_schema = :schema) AND
		anchor_table_name = :table
	GROUP BY 1, 2
	ORDER BY 1, 2
	;
EOF

echo "# -----------------------------------------------------------------"
echo "# Partitions by node (SCHEMA=${schema} TABLE=${table})"
echo "# -----------------------------------------------------------------"
vsql -Xnq -v schema=\'${schema}\' -v table=\'${table}\' -f - <<-EOF
	SELECT
		pa.partition_key,
		pa.node_name,
		SUM(pa.ros_row_count) AS ros_row_count, 
		SUM(pa.ros_size_bytes) AS ros_size_bytes,
		SUM(pa.deleted_row_count) AS deleted_row_count 
	FROM
		v_monitor.partitions pa
		inner join v_monitor.projection_storage ps
		on pa.projection_id = ps.projection_id
	WHERE 
		('-' = :schema OR ps.anchor_table_schema = :schema ) AND
		ps.anchor_table_name = :table
	GROUP BY 1, 2
	ORDER BY 1, 2
	;
EOF
