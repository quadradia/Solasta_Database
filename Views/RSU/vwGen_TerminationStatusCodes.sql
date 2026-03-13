/******************************************************************************
**		View: [RSU].[vwGen_TerminationStatusCodes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TerminationStatusCodes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TerminationStatusCodes];
GO

CREATE   VIEW [RSU].[vwGen_TerminationStatusCodes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TerminationStatusCodes].[TerminationStatusCodeID]
		, [RSU].[TerminationStatusCodes].[TerminationStatusCodeName]
		, [RSU].[TerminationStatusCodes].[IsActive]
		, [RSU].[TerminationStatusCodes].[CreatedById]
		, [RSU].[TerminationStatusCodes].[CreatedDate]
		, [RSU].[TerminationStatusCodes].[ModifiedById]
		, [RSU].[TerminationStatusCodes].[ModifiedDate]
	FROM
		[RSU].[TerminationStatusCodes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TerminationStatusCodes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[TerminationStatusCodes].IsDeleted = 'FALSE')

;
GO