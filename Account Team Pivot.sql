/****** Object:  View [Shared].[Salesforce_Account_Ownership]    Script Date: 25/05/2023 13:24:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Shared].[Salesforce_Account_Ownership] AS WITH team AS 

 /****************************************
  ________________________________
 /This script pivots the existing \
|	Salesforce ownership table to  |
| give one row per account for all |
|  regions, escrow and assurance.  |
|         created by JF			   |
 \    Last updated 2023.01.17     /
  \______________________________/
      \ 
       \   ^__^
        \  (oo)\_______
           (__)\       )\/\
               ||----w |
               ||     ||

****************************************/


/* Get the Account Team data in a CTE and add a rank using row_number. This allows us to remove duplicates */


(
  SELECT
    a.[account team id] AS [AccountTeamID],
    a.[account id] AS [AccountID],
    a.[division] AS [Division],
    a.[role],
    a.[USER id] AS [UserID],
    b.[USER name] AS [FullName],
    ROW_NUMBER () OVER ( PARTITION BY a.[account id], a.[division], a.[role] 
  ORDER BY
    a.[created DATE] desc ) AS [RowNum] 
  FROM
    [Shared].[Account_Team] a 
    LEFT JOIN
      [Shared].[USER] b 
      ON a.[USER id] = b.id 
)

,

/* Pivoting the data by role - AM, External or Internal. Other roles are filtered out. This leaves one row per account and division, with three columns of ownership */

Roles AS 
(
  SELECT
    * 
  FROM
    (
      SELECT
        a.accountid,
        a.division,
        a.role,
        a.fullname 
      FROM
        team a 
      WHERE
        RowNum = 1 
        AND division IS NOT NULL 
    ) t 
	
	pivot ( MAX(t.fullname) FOR role IN 
    (
      [Account Manager],
      [EXTERNAL Sales],
      [Internal Sales] 
    )
) AS pivot_table 
)

,

/* With the above row level data, using coalesce to pick the first non-null result out of the three ownership roles. This data is then pivoted again - this time by division */

Ownership AS
(
  SELECT
    * 
  FROM
    (
      SELECT
        AccountID,
        Division,
        COALESCE( [account manager], [EXTERNAL sales], [internal sales] ) AS [Owner] 
      FROM
        roles 
      WHERE
        COALESCE( [account manager], [EXTERNAL sales], [internal sales] ) IS NOT NULL 
    )
    t pivot ( MAX([Owner]) FOR Division IN 
    (
      [Assurance Australia],
      [Assurance Benelux],
      [Assurance Canada],
      [Assurance DACH],
      [Assurance Iberia],
      [Assurance Japan],
      [Assurance Nordics],
      [Assurance Singapore],
      [Assurance UK],
      [Assurance USA],
      [Escrow Germany],
      [Escrow Netherlands],
      [Escrow Switzerland],
      [Escrow UK],
      [Escrow USA] 
    )
) AS pivot_table 
)


SELECT
  * 
FROM
  Ownership;
GO


