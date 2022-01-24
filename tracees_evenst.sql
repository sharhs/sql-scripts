SELECT t.id,
       t.is_default,
       t.[path],
       t.start_time,
       t.stop_time,
       t.[status],
       t.last_event_time,
       t.event_count,
       t.dropped_event_count,
       t.max_size  AS max_size_mb,
       t.max_files,
       t.buffer_count,
       t.buffer_size,
       t.reader_spid,
       te.trace_event_id,
       te.name,
       STUFF(
           (
               SELECT N', ' + tc.name + N' (' +
                      STUFF(
                          (
                              SELECT N', ' +
                                     COALESCE(
                                         CASE tgfi.logical_operator
                                              WHEN 0 THEN N'AND'
                                              WHEN 1 THEN N'OR'
                                         END + N' ',
                                         N''
                                     ) +
                                     COALESCE(
                                         CASE tgfi.comparison_operator
                                              WHEN 0 THEN '='
                                              WHEN 1 THEN '<>'
                                              WHEN 2 THEN '>'
                                              WHEN 3 THEN '<'
                                              WHEN 4 THEN '>='
                                              WHEN 5 THEN '<='
                                              WHEN 6 THEN 'LIKE'
                                              WHEN 7 THEN 'NOT LIKE'
                                         END + N' ',
                                         N''
                                     ) +
                                     COALESCE(CONVERT(NVARCHAR(MAX), tgfi.value), '')
                              FROM   fn_trace_getfilterinfo(t.id) AS tgfi
                              WHERE  tgfi.columnid = tc.trace_column_id
                                     FOR XML PATH(''), TYPE
                          ).value('.', 'NVARCHAR(MAX)'),
                          1,
                          2,
                          ''
                      ) + N')'
               FROM   fn_trace_geteventinfo(t.id) AS ftg
                      INNER JOIN sys.trace_columns AS tc
                           ON  ftg.columnid = tc.trace_column_id
               WHERE  ftg.eventid = te.trace_event_id
               ORDER BY
                      NAME
                      FOR XML PATH(''),
                      TYPE
           ).value('.', 'NVARCHAR(MAX)'),
           1,
           2,
           ''
       )           AS [column]
FROM   sys.traces  AS t
       OUTER APPLY (
    SELECT DISTINCT te.trace_event_id,
           te.name
    FROM   fn_trace_geteventinfo(t.id)  AS ftg
           INNER JOIN sys.trace_events  AS te
                ON  ftg.eventid = te.trace_event_id
)                     te

WHERE reader_spid IS NOT NULL
ORDER BY
       t.id;
GO
