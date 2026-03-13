/******************************************************************************
**		View: [RSU].[vwGen_TerminationTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TerminationTypes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TerminationTypes];
GO

CREATE   VIEW [RSU].[vwGen_TerminationTypes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TerminationTypes].[TerminationTypeID]
		, [RSU].[TerminationTypes].[TerminationTypeName]
		, [RSU].[TerminationTypes].[IsActive]
		, [RSU].[TerminationTypes].[CreatedById]
		, [RSU].[TerminationTypes].[CreatedDate]
		, [RSU].[TerminationTypes].[ModifiedById]
		, [RSU].[TerminationTypes].[ModifiedDate]
	FROM
		[RSU].[TerminationTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TerminationTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[TerminationTypes].IsDeleted = 'FALSE')

;
GO