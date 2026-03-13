/******************************************************************************
**		View: [RSU].[vwGen_UserPhotos]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserPhotos' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserPhotos];
GO

CREATE   VIEW [RSU].[vwGen_UserPhotos]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserPhotos].[UserPhotoID]
		, [RSU].[UserPhotos].[UserResourceId]
		, [RSU].[UserPhotos].[PhotoImage]
		, [RSU].[UserPhotos].[FileSize]
		, [RSU].[UserPhotos].[MimeType]
		, [RSU].[UserPhotos].[IsActive]
		, [RSU].[UserPhotos].[CreatedById]
		, [RSU].[UserPhotos].[CreatedDate]
		, [RSU].[UserPhotos].[ModifiedById]
		, [RSU].[UserPhotos].[ModifiedDate]
	FROM
		[RSU].[UserPhotos]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserPhotos') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[UserPhotos].IsDeleted = 'FALSE')

;
GO