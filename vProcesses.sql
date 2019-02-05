/*
SQL Stats query/view
*/
USE master
GO
IF EXISTS (SELECT NULL FROM sys.views WHERE NAME ='vProcesses') 
	DROP VIEW dbo.vProcesses
GO

DECLARE @SQL NVARCHAR(MAX)


IF (select SUBSTRING(CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion')),0,CHARINDEX('.',CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion'),0)))) >= 11
BEGIN
	PRINT 'Creating view for SQL 2012 and up.'
	/* for SQL 2012 and up 
	 Earlier versions of SQL server doesn't have database_id in sys.dm_exec_sessions
	*/
	SET @SQL = '
	CREATE VIEW dbo.vProcesses
	AS 
		SELECT
		s.session_id,
		r.request_id,
		s.login_time,
		s.[host_name],
		s.[program_name],
		s.client_interface_name,
		s.login_name,
		r.status,
		r.percent_complete,
		r.blocking_session_id,
		r.wait_type,
		r.last_wait_type,		
		r.command,
		s.database_id,
		sd.name,
		s.cpu_time,
		s.memory_usage,
		r.sql_handle,
		qs.execution_count,
		qs.last_execution_time,
		qs.last_worker_time,
		qs.last_physical_reads,
		qs.last_logical_reads,
		qs.last_logical_writes,
		qs.last_elapsed_time,
		r.plan_handle,
		t.text AS SQLText,
		p.query_plan AS QueryPlanXML
	FROM sys.dm_exec_sessions AS s
	LEFT JOIN sys.databases AS sd
		ON sd.database_id = s.database_id
	LEFT JOIN sys.dm_exec_requests AS r
		ON r.session_id = s.session_id
	LEFT JOIN sys.dm_exec_query_stats AS qs
		ON qs.plan_handle = r.plan_handle
	OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
	OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS p'
END
ELSE
BEGIN
	PRINT 'Creating view for SQL 2008 R2, or older.'
/* For older SQL versions (2008R2 and older) */
	SET @SQL = '
		CREATE VIEW dbo.vProcesses
		AS 
		SELECT
			s.session_id,
		r.request_id,			
			s.login_time,
			s.[host_name],
			s.[program_name],
			s.client_interface_name,
			s.login_name,
			r.status,
			r.percent_complete,
			r.blocking_session_id,
			r.wait_type,
			r.last_wait_type,
			r.command,
			r.database_id,
			sd.name,
			s.cpu_time,
			s.memory_usage,
			r.sql_handle,
			t.text AS SQLText,
			p.query_plan AS QueryPlanXML
		FROM sys.dm_exec_sessions AS s
		LEFT JOIN sys.dm_exec_requests AS r
			ON r.session_id = s.session_id
		LEFT JOIN sys.databases AS sd
			ON sd.database_id = r.database_id
		OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
		OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS p'
END

EXEC sp_executeSQL @SQL