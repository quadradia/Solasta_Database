/******************************************************************************
**		File: vwUserSummaryInfo.sql
**		Name: vwUserSummaryInfo
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andres Sosa
**		Date: 01/05/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	01/05/2017	Andres Sosa		Created by
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwUserSummaryInfo' AND schema_id = SCHEMA_ID('ACC'))
    DROP VIEW [ACC].[vwUserSummaryInfo];
GO

CREATE   VIEW [ACC].[vwUserSummaryInfo]
AS
	-- Enter Query here
	SELECT 
		U.UserID
		, UR.UserResourceID
		, ISNULL(UR.FirstName, U.FirstName) AS FirstName
		, ISNULL(UR.LastName, U.LastName) AS LastName
		, ISNULL(UR.FullName, U.FirstName + ' ' + U.LastName) AS FullName
		, ISNULL(UR.FullName, U.FirstName + ' ' + U.LastName) + ' (' + ISNULL(UR.GPEmployeeId, 'OOO000') + ')' AS FullNameWithGPID
		, ISNULL(UR.GPEmployeeId, 'OOO000') AS GPEmployeeId
		, ISNULL(UR.Email, U.Email) AS Email
		, ISNULL(UR.PhoneCell, U.PhoneNumber) AS phone
	FROM 
		[ACC].[Users] AS U WITH (NOLOCK)
		LEFT OUTER JOIN [RSU].[UserResources] AS UR WITH(NOLOCK)
		ON
			(UR.UserId = U.UserID)
GO