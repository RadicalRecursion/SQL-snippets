declare @startdate date, @enddate date;
set @startdate = '2012-01-01';
set @enddate = '2032-12-31';



WITH Ten(N) AS 
(
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),   


cte_calendar(dt) as  (SELECT TOP (DATEDIFF(DAY, @startdate,@enddate) + 1)
                CONVERT(DATE, DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, '2012-01-01'))
				FROM Ten T10
CROSS JOIN Ten T100
CROSS JOIN Ten T1000
CROSS JOIN Ten T10000
CROSS JOIN Ten T100000)

   SELECT
        [ID] = DATEDIFF(DAY, @startdate, c.dt) + 1,
		[Date] = CAST(c.dt as date),
        [Calendar Year] = YEAR(c.dt),
		[Calendar Month] = DATENAME(MM,c.dt),
		[Day] = DAY(c.dt),
		[Day Name] = DATENAME(WEEKDAY,c.dt),
        [Fiscal Period] = case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end,
		[Fiscal Quarter] = case when month(c.dt) > 5 then datepart(qq,(dateadd(mm,-5,c.dt))) else datepart(qq,(dateadd(mm,7,c.dt))) end,
		[Fiscal Year] = case when month(c.dt) > 5 then concat('FY',right(year(c.dt) + 1,2)) else concat('FY',right(year(c.dt),2)) end
	      
    FROM
        cte_Calendar c;
GO