USE master
GO
CREATE VIEW dbo.vTransactions 
AS
/* 
	View to see currently open transactions.
	Use DatabaseName as filter.

	ORDER BY act.transaction_begin_time,st.session_id
*/
SELECT
	st.session_id,
	s.login_name,
	s.host_name,
	s.program_name,
	s.status,
	act.transaction_begin_time,
	DATEDIFF(MINUTE, act.transaction_begin_time, GETDATE()) AS TranOpenTime,
	r.blocking_session_id,
	r.start_time,
	s.last_request_end_time,
	d.name AS DatabaseName,
	r.wait_type,
	r.last_wait_type,
	s.lock_timeout,
	st.open_transaction_count,
	c.most_recent_sql_handle,
	sqltext.text

FROM sys.dm_tran_session_transactions AS st
JOIN sys.dm_tran_active_transactions AS act
	ON act.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions AS s
	ON s.session_id = st.session_id
JOIN sys.dm_exec_connections AS c
	ON c.session_id = st.session_id
JOIN sys.databases AS d
	ON d.database_id = s.database_id
LEFT JOIN sys.dm_exec_requests AS r
	ON r.session_id = st.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS sqltext
WHERE st.open_transaction_count > 0
--

