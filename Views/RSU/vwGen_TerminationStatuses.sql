/******************************************************************************
**		View: [RSU].[vwGen_TerminationStatuses]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TerminationStatuses' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TerminationStatuses];
GO

CREATE   VIEW [RSU].[vwGen_TerminationStatuses]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TerminationStatuses].[TerminationStatusID]
		, [RSU].[TerminationStatuses].[TerminationId]
		, [RSU].[TerminationStatuses].[TerminationStatusCodeId]
		, [RSU].[TerminationStatuses].[Comments]
		, [RSU].[TerminationStatuses].[IsActive]
		, [RSU].[TerminationStatuses].[CreatedById]
		, [RSU].[TerminationStatuses].[CreatedDate]
		, [RSU].[TerminationStatuses].[ModifiedById]
		, [RSU].[TerminationStatuses].[ModifiedDate]
	FROM
		[RSU].[TerminationStatuses]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TerminationStatuses') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[TerminationStatuses].IsDeleted = 'FALSE')

;
GO