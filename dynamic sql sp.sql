/****** Object:  StoredProcedure [Shared].[Escrow_KPIs]    Script Date: 17/01/2024 16:32:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [Shared].[Escrow_KPIs] @col_name [NVARCHAR](128) AS
/*									  CREATED BY JF 15.01.24											**
**	 ----------------------------------------------------------------------------------------------		**
**							This SP generates Escode KPIs for use by Excom								**			
**	    The 'col_name' parameter will accept any column name from [Shared].[NCC_Fiscal_Calendar]		**
**		example use:																					**								
**			exec [Shared].[Escrow_KPIs] 'Fiscal Year'		(returns values based on fiscal years)		**
**			exec [Shared].[Escrow_KPIs] 'Fiscal Year Half'	(returns values based on half years)		**
**			exec [Shared].[Escrow_KPIs] 'Fiscal Date'		(returns values based on fiscal months)		*/



-- Dynamic SQL which defines the date period based on the parameter
-- the result is inserted into  temp table, #temp_dates

DECLARE @sql NVARCHAR(MAX);
SET @sql = N'
    Select top 1000000
		min([date]) as [min]
	   ,max([date]) as [max]
	   ,' + QUOTENAME(@col_name) + ' as [Period]
    INTO #temp_dates
    from [Shared].[NCC_Fiscal_Calendar] A
	where date < getdate()
	group by ' + QUOTENAME(@col_name) + '
	order by [min] asc;'
EXEC sp_executesql @sql;

/* Get the list of contracts */
with contract_data as (
SELECT  
 [Account ID]
,[Contract ID]
,[Contract Signed Date]
,CASE 
	WHEN [Contract Status] = 'Approved' 
	THEN NULL
	ELSE [Termination Date] 
 END AS [Termination Date]
FROM [Shared].[Escrow_Contracts] A
  where [contract status] <> 'Cancelled'
  and [is beneficiary] = 'Yes'
  and [account id] <> ''
  and A.[Contract Signed Date] is not null
),


Beneficiaries as
(
select 
count(distinct A.[Account id]) as [Beneficiaries]
,b.[Period]
from contract_data A
LEFT JOIN #temp_dates B on A.[Contract Signed Date] <= B.Max and (A.[Termination Date] >= B.[max] or A.[termination date] is null) 
where b.[Period] is not null
group by
b.[Period]
),

Contracts as
(
select 
count(distinct A.[contract id]) as [Contracts]
,b.[Period]
from contract_data A
LEFT JOIN #temp_dates B on A.[Contract Signed Date] <= B.Max and (A.[Termination Date] >= B.[max] or A.[termination date] is null) 
where b.[Period] is not null
group by
b.[Period]
),

First_Contract as
(
select
 A.[account id]
,min(A.[Contract Signed Date]) as [first contract]
from contract_data A
where A.[Contract Signed Date] is not null
group by
 A.[account id]
),

new_bene as
(
select
 B.[Period]
,count(A.[account id]) as [New Beneficiaries]
from first_contract A
LEFT JOIN #temp_dates B on [first contract] >= B.min and [first contract] <= B.Max
where b.[Period] is not null
group by
b.[Period]
),

KPIs as
(
Select
 D.[Period]
,A.[Beneficiaries]
,B.[Contracts]
,A.[Beneficiaries] - lead(A.[beneficiaries], 1) over (order by A.[Period] desc) as [Beneficiary Movement]
,C.[New Beneficiaries]
,FORMAT((CAST(A.[Beneficiaries] as decimal) - CAST(C.[New Beneficiaries] as decimal)) / CAST(lead(A.[beneficiaries], 1) over (order by A.[Period] desc) as decimal), 'P2') as [CRR]
FROM #temp_dates D
left join Beneficiaries A on D.[Period] = A.[Period]
left join contracts B on D.[Period] = B.[Period]
left join new_bene C on D.[Period] = C.[Period]
)


select
*
from KPIs
where 
order by [Period] desc
drop table  #temp_dates
GO


