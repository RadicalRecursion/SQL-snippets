/****** Object:  StoredProcedure [Shared].[Generate_NCC_Fiscal_Calendar]    Script Date: 17/01/2024 18:05:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [Shared].[Generate_NCC_Fiscal_Calendar] AS

-- DROP TEMP TABLE IF EXISTS
IF OBJECT_ID('temp.NCC_Fiscal_Calendar') IS NOT NULL
	DROP TABLE temp.[NCC_Fiscal_Calendar];

-- Recreate table with select statement


/*_______________________________________________________________ 
|\ ____________________________________________________________ /| 
| |          [Shared].[Generate_NCC_Fiscal_Calendar]           | | 
| |                     -.-                           -.-      | | 
| |    -.-                                  ___                | | 
| |            -.-                        _(   )      ___      | | 
| |             ___                      (___)__)   _(   )     | | 
| |           _(   )        ___               _    (___)__)    | | 
| |          (___)__)     _(   )             /|\               | | 
| |     ___              (___)__)   ___     / | \              | | 
| |   _(   )                      _(   )   /__|__\             | | 
| |  (___)__)                    (___)__) ____|____            | | 
| |-~~~~~~~~~~~~~-~~~~~~~~~~~~~~~~~~~~~~~~\_______/~~~~~~~~~~~~| | 
| |                                                            | | 
| |   Author:       James Fearnley							   | | 
| |	  Create date:  ca. June 2022							   | | 
| |   Description:  SP calendar object with fiscal months      | | 
| |			                                                   | | 
| |   **WARNING - Calendar will break on 16th October 2273**   | | 
| |											                   | | 
| |____________________________________________________________| | 
|/______________________________________________________________*/ 


/**** CTE Ten - Buid a column with ten rows by unioning the value 1 ten times ****/

WITH Ten(N) AS 
(
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),   


/**** CTE Calendar - Join to the above and convert the row number in to a date starting at 2000-01-01 and adding one day per row ****/

cte_calendar(dt) as 
(
-- This "TOP" function sets the maximum number of rows, in this case days between 2000-01-01 and 5 years after today
	SELECT TOP (DATEDIFF(DAY, '2000-01-01',DATEADD(yy,5,getdate())) + 1)
-- This line is creating the date - we take the row number (minus 1 to start at 0) and add that in days to the start date, set at 2000-01-01
				CONVERT(DATE, DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, '2000-01-01'))
	FROM Ten T10
-- This cross join multiplies the total number of rows in the array, by cross joining to the "Ten" cte. Each cross join multiplies the number of rows in the array by 10.
	CROSS JOIN Ten T100
	CROSS JOIN Ten T1000
	CROSS JOIN Ten T10000
	CROSS JOIN Ten T100000

)

,

/**** CTE fisc_cal -  We've now created a single column with one day per row, starting at 2020-01-01 and ending at today plus 5 years. ****/
/****		 The final CTE uses this column to build the calendar object. New columns should normally be added within this CTE		   ****/

fisc_cal as
(
   SELECT
        [ID]						= cast(DATEDIFF(DAY, '2000-01-01', c.dt) + 1 as int),
		[Date Key]					= DATEDIFF(DD,0,c.dt),
		[Date]						= CAST(c.dt as date),
        [Calendar Year]				= YEAR(c.dt),
		[Calendar Month]			= DATENAME(MM,c.dt),
		[Calendar Month Short]		= FORMAT(c.dt,'MMM'),
		--[Day]						= DAY(c.dt),
		[Day of Week]				= DATENAME(WEEKDAY,c.dt),
		[Weekend]					= CASE WHEN DATENAME(WEEKDAY,c.dt) IN ('Saturday','Sunday') THEN 1 ELSE 0 END,
		[Week Number]				= DATEPART(WW,c.dt),
		--[Month Year]				= CONCAT(FORMAT(c.dt,'MMM'),' ',YEAR(c.dt)),
        [Fiscal Period]				= CONCAT('P',FORMAT(case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end,'00')),
		[Fiscal Quarter]			= CONCAT('Q',case when month(c.dt) > 5 then datepart(qq,(dateadd(mm,-5,c.dt))) else datepart(qq,(dateadd(mm,7,c.dt))) end),
		[Fiscal Year]				= CASE WHEN MONTH(c.dt) > 5 THEN CONCAT('FY',right(year(c.dt) + 1,2)) ELSE CONCAT('FY',right(year(c.dt),2)) END,
		[Fiscal Year Month]			= CONCAT(case when month(c.dt) > 5 then concat('FY',right(year(c.dt) + 1,2)) else concat('FY',right(year(c.dt),2)) end,'-',FORMAT(c.dt,'MMM')),
	    [Fiscal Year Period]		= CONCAT(case when month(c.dt) > 5 then concat('FY',right(year(c.dt) + 1,2)) else concat('FY',right(year(c.dt),2)) end,'-','P',FORMAT(case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end,'00')),
	    [Fiscal Date]				= CONCAT(case when month(c.dt) > 5 then concat('FY',right(year(c.dt) + 1,2)) else concat('FY',right(year(c.dt),2)) end,'-','P',FORMAT(case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end,'00'),'-',FORMAT(c.dt,'MMM')),
		[Fiscal Year Quarter]		= CONCAT(case when month(c.dt) > 5 then concat('FY',right(year(c.dt) + 1,2)) else concat('FY',right(year(c.dt),2)) end,'-','Q',case when month(c.dt) > 5 then datepart(qq,(dateadd(mm,-5,c.dt))) else datepart(qq,(dateadd(mm,7,c.dt))) end),
        [Fiscal Year Half]			= CONCAT(case when month(c.dt) > 5 then concat('FY',right(year(c.dt) + 1,2)) else concat('FY',right(year(c.dt),2)) end,'-',CASE WHEN DATENAME(MM,c.dt) IN ('JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER') THEN 'H1' ELSE 'H2' END),
		[Fiscal Month & Month Name] = CONCAT('P',FORMAT(case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end,'00'),' ', FORMAT(c.dt,'MMM')),
		[Fiscal Year Dimension]		= CASE (CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END)
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END) THEN 'Current Fiscal Year'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END) +1 THEN 'Next Fiscal Year'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END) -1 THEN 'Prior Fiscal Year'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END) -2 THEN 'Prior Fiscal Year -1'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END) -3 THEN 'Prior Fiscal Year -2'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END)  +2 THEN 'All Other Future Fiscal Years'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END)  +3 THEN 'All Other Future Fiscal Years'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END)  +4 THEN 'All Other Future Fiscal Years'
									  WHEN (CASE WHEN MONTH(GETDATE()) > 5 THEN year(GETDATE()) + 1 ELSE year(GETDATE()) END)  +5 THEN 'All Other Future Fiscal Years'
									  ELSE 'All Other Prior Fiscal Years'
									  END,
		[Fiscal Quarter Dimension]	= CASE (CASE WHEN month(c.dt) > 5 THEN datepart(qq,(dateadd(mm,-5,c.dt))) ELSE datepart(qq,(dateadd(mm,7,c.dt))) end)
									  WHEN (CASE WHEN month(GETDATE()) > 5 THEN datepart(qq,(dateadd(mm,-5,GETDATE()))) ELSE datepart(qq,(dateadd(mm,7,GETDATE()))) end) THEN 'Current Fiscal Quarter'
									  WHEN (CASE WHEN month(GETDATE()) > 5 THEN datepart(qq,(dateadd(mm,-8,GETDATE()))) ELSE datepart(qq,(dateadd(mm,4,GETDATE()))) end) THEN 'Prior Fiscal Quarter'
									  WHEN (CASE WHEN month(GETDATE()) > 5 THEN datepart(qq,(dateadd(mm,-2,GETDATE()))) ELSE datepart(qq,(dateadd(mm,10,GETDATE()))) end) THEN 'Next Fiscal Quarter'
									  ELSE 'Other Fiscal Quarters'
									  END,
		[Fiscal Month Dimension]	= CASE MONTH(c.dt)
									  WHEN MONTH(GETDATE()) THEN 'Current Month'
									  WHEN MONTH(GETDATE()) + 1 THEN 'Next Month'
									  WHEN MONTH(GETDATE()) - 1 THEN 'Prior Month'
									  WHEN MONTH(GETDATE()) - 11 THEN 'Next Month'
									  WHEN MONTH(GETDATE()) + 11 THEN 'Prior Month'
									  ELSE 'All Other Months'
									  END,
		[Year to Date]				= CASE 
									  WHEN case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end < case when MONTH(GETDATE()) > 5 then MONTH(GETDATE()) -5 else MONTH (GETDATE()) + 7 end
									  OR (MONTH(C.DT) = MONTH(GETDATE()) AND DAY(C.DT) <= DAY(GETDATE()))
									  THEN 'Year-to-Date'
									  ELSE ''
									  END,
		[Year to Date (Full Month)]	= CASE 
									  WHEN case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end < case when MONTH(GETDATE()) > 5 then MONTH(GETDATE()) -5 else MONTH (GETDATE()) + 7 end
									  OR (MONTH(C.DT) = MONTH(GETDATE()))
									  THEN 'Year-to-Date'
									  ELSE ''
									  END,
		[Quarter to Date]			= CASE
									  WHEN case when month(c.dt) > 5 then datepart(qq,(dateadd(mm,-5,c.dt))) else datepart(qq,(dateadd(mm,7,c.dt))) end
										=  case when month(getdate()) > 5 then datepart(qq,(dateadd(mm,-5,getdate()))) else datepart(qq,(dateadd(mm,7,getdate()))) end
									  AND ((MONTH(C.DT) < MONTH(GETDATE()) or (MONTH(C.DT) = MONTH(GETDATE()) AND DAY(C.DT) <= DAY(GETDATE()))))
									  THEN 'Quarter-to-Date'
									  ELSE ''
									  END,
		[Month to Date]				= CASE 
									  WHEN (MONTH(C.DT) = MONTH(GETDATE()) AND DAY(C.DT) <= DAY(GETDATE()))
									  THEN 'Month-to-Date'
									  ELSE ''
									  END,
		[Half Year]			        = CASE 
									  WHEN DATENAME(MM,c.dt) IN ('JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER') THEN 'H1'
									  ELSE 'H2' END,

/* The following columns are intended to be used within measures and should be hidden in the data model */

		[Current or Prior FM]		= CASE WHEN c.dt <= EOMONTH(GETDATE()) THEN 'Yes' ELSE 'No' END,		
		[Sequential FY Key]			= CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END,
		[Sequential FQ Key]			= (CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END *4) + case when month(c.dt) > 5 then datepart(qq,(dateadd(mm,-5,c.dt))) else datepart(qq,(dateadd(mm,7,c.dt))) end,
		[Sequential FM Key]			= ((CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END) * 12) + ((case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end)),
		[FY Number]					= CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END,
		[FQ Number]					= case when month(c.dt) > 5 then datepart(qq,(dateadd(mm,-5,c.dt))) else datepart(qq,(dateadd(mm,7,c.dt))) end,
		[FM Number]					= case when MONTH(c.dt) > 5 then MONTH(c.dt) -5 else MONTH (c.dt) + 7 end,
		[First Day of FY]			= DATEFROMPARTS((CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END)-1,'6','1'),
		[First Day of FQ]			= CASE
										WHEN MONTH(C.DT) < 3  THEN DATEFROMPARTS(YEAR(C.DT)-1,12,1)
										WHEN MONTH(C.DT) BETWEEN 3 AND 5 THEN DATEFROMPARTS(YEAR(C.DT),3,1)
										WHEN MONTH(C.DT) BETWEEN 6 AND 8 THEN DATEFROMPARTS(YEAR(C.DT),6,1)
										WHEN MONTH(C.DT) BETWEEN 9 AND 11 THEN DATEFROMPARTS(YEAR(C.DT),9,1)
										WHEN MONTH(C.DT) = 12 THEN DATEFROMPARTS(YEAR(C.DT),12,1)
										END,
		[Day of FY]					= DATEDIFF(day,DATEFROMPARTS((CASE WHEN MONTH(c.dt) > 5 THEN year(c.dt) + 1 ELSE year(c.dt) END)-1,'6','1'),C.DT)+1,
		[Day of FQ]					= DATEDIFF(DAY,
												CASE
													WHEN MONTH(C.DT) < 3  THEN DATEFROMPARTS(YEAR(C.DT)-1,12,1)
													WHEN MONTH(C.DT) BETWEEN 3 AND 5 THEN DATEFROMPARTS(YEAR(C.DT),3,1)
													WHEN MONTH(C.DT) BETWEEN 6 AND 8 THEN DATEFROMPARTS(YEAR(C.DT),6,1)
													WHEN MONTH(C.DT) BETWEEN 9 AND 11 THEN DATEFROMPARTS(YEAR(C.DT),9,1)
													WHEN MONTH(C.DT) = 12 THEN DATEFROMPARTS(YEAR(C.DT),12,1)
													END, C.DT)+1,		
		[Day of Month]				= DAY(C.DT),
		[Month of FQ]				= CASE
										WHEN MONTH(C.DT) IN (6,9,12,3) THEN 1
										WHEN MONTH(C.DT) IN (7,10,1,4) THEN 2
										WHEN MONTH(C.DT) IN (8,11,2,5) THEN 3
										END

	FROM
        cte_Calendar c
)
	
	
	
SELECT TOP 100000		-- The "TOP" function here just enables the use of ORDER BY at the end of the statement. Max rows is 100,000 so has no impact 

A.[ID] AS [ID],
A.[Date Key] AS [Date Key],
A.[Date] AS [Date],
A.[Calendar Year] AS [Calendar Year],
A.[Calendar Month] AS [Calendar Month],
A.[Calendar Month Short] AS [Calendar Month Short],
A.[Day of Week] AS [Day of Week],
A.[Weekend] AS [Weekend],
A.[Week Number] AS [Week Number],
A.[Fiscal Period] AS [Fiscal Period],
A.[Fiscal Quarter] AS [Fiscal Quarter],
A.[Fiscal Year] AS [Fiscal Year],
A.[Fiscal Year Month] AS [Fiscal Year Month],
A.[Fiscal Year Period] AS [Fiscal Year Period],
A.[Fiscal Date] AS [Fiscal Date],
A.[Fiscal Year Quarter] AS [Fiscal Year Quarter],
A.[Fiscal Year Half],
A.[Fiscal Month & Month Name] AS [Fiscal Month & Month Name],
A.[Fiscal Year Dimension] AS [Fiscal Year Dimension],
A.[Fiscal Quarter Dimension] AS [Fiscal Quarter Dimension],
A.[Fiscal Month Dimension] AS [Fiscal Month Dimension],
A.[Year to Date] AS [Year to Date],
A.[Year to Date (Full Month)] AS [Year to Date (Full Month)],
A.[Quarter to Date] AS [Quarter to Date],
A.[Month to Date] AS [Month to Date],
A.[Half Year] AS [Half Year],
A.[Current or Prior FM] AS [Current or Prior FM],
A.[Sequential FY Key] AS [Sequential FY Key],
A.[Sequential FQ Key] AS [Sequential FQ Key],
A.[Sequential FM Key] AS [Sequential FM Key],
A.[FY Number] AS [FY Number],
A.[FQ Number] AS [FQ Number],
A.[FM Number] AS [FM Number],
A.[First Day of FY] AS [First Day of FY],
A.[First Day of FQ] AS [First Day of FQ],
A.[Day of FY] AS [Day of FY],
A.[Day of FQ] AS [Day of FQ],
A.[Day of Month] AS [Day of Month],
A.[Month of FQ] AS [Month of FQ],
CASE WHEN CAST(A.[Week Number] AS VARCHAR(2)) + '. WE: ' + CAST(RIGHT(B.[Date],2) AS varchar(32)) +
'-' + B.[Calendar Month Short] + 
'-' + CAST(RIGHT(B.[Calendar Year],2) AS varchar(32)) IS NULL 
AND A.[Calendar Month] = 'December' THEN
CAST(A.[Week Number] AS VARCHAR(2)) + '. WE: ' + CAST(31 AS varchar(32)) +
'-' + 'Dec' + 
'-' + CAST(RIGHT(A.[Calendar Year],2) AS varchar(32))
ELSE CAST(A.[Week Number] AS VARCHAR(2)) + '. WE: ' + CAST(RIGHT(B.[Date],2) AS varchar(32)) +
'-' + B.[Calendar Month Short] + 
'-' + CAST(RIGHT(B.[Calendar Year],2) AS varchar(32)) END
AS [Week Name]

	into temp.[NCC_Fiscal_Calendar]
from fisc_cal A
LEFT JOIN fisc_cal B ON A.[Week Number]=B.[Week Number]
	AND A.[Calendar Year]=B.[Calendar Year]
	AND B.[Day of Week] = 'Friday'

order by id asc

--Set table refresh date based on the minimum for the given base tables used
exec [app].[SetTableJustRefreshed] -1, 'Shared', 'Shared', 'NCC_Fiscal_Calendar'
GO
