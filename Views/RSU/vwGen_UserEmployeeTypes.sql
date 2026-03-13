/******************************************************************************
**		View: [RSU].[vwGen_UserEmployeeTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserEmployeeTypes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserEmployeeTypes];
GO

CREATE   VIEW [RSU].[vwGen_UserEmployeeTypes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserEmployeeTypes].[UserEmployeeTypeID]
		, [RSU].[UserEmployeeTypes].[UserEmployeeTypeName]
		, [RSU].[UserEmployeeTypes].[IsActive]
		, [RSU].[UserEmployeeTypes].[CreatedById]
		, [RSU].[UserEmployeeTypes].[CreatedDate]
		, [RSU].[UserEmployeeTypes].[ModifiedById]
		, [RSU].[UserEmployeeTypes].[ModifiedDate]
	FROM
		[RSU].[UserEmployeeTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserEmployeeTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[UserEmployeeTypes].IsDeleted = 'FALSE')

;
GO