/******************************************************************************
**		View: [RSU].[vwGen_TerminationReasons]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TerminationReasons' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TerminationReasons];
GO

CREATE   VIEW [RSU].[vwGen_TerminationReasons]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TerminationReasons].[TerminationReasonID]
		, [RSU].[TerminationReasons].[TerminationTypeId]
		, [RSU].[TerminationReasons].[TerminationReasonName]
		, [RSU].[TerminationReasons].[IsActive]
		, [RSU].[TerminationReasons].[CreatedById]
		, [RSU].[TerminationReasons].[CreatedDate]
		, [RSU].[TerminationReasons].[ModifiedById]
		, [RSU].[TerminationReasons].[ModifiedDate]
	FROM
		[RSU].[TerminationReasons]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TerminationReasons') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[TerminationReasons].IsDeleted = 'FALSE')

;
GO