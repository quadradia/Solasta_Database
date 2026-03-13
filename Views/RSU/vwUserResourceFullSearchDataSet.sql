/******************************************************************************
**		File: vwUserResourceFullSearchDataSet.sql
**		Name: vwUserResourceFullSearchDataSet
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
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwUserResourceFullSearchDataSet' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwUserResourceFullSearchDataSet];
GO

CREATE   VIEW [RSU].[vwUserResourceFullSearchDataSet]
AS
	-- Enter Query here
	SELECT
		RSU.UserResourceID AS ID
        , RSU.DealerId
        , RSU.UserId
		, RSU.UserResourceAddressId
        , RSU.UserEmployeeTypeId
		, UET.UserEmployeeTypeName --AS [CorpPosition]
        --, RSU.UserResourceAddressId
        , RSU.RecruitedById
        , RSU.GPEmployeeId AS [CompanyId]
        , CAST(RSU.RecruitedByDate AS DATETIME) AS [RecruitedOn]
        , RSU.FullName
        , RSU.PublicFullName
        , ISNULL(RSU.SSN, '') AS SSN
        , RSU.FirstName
        , ISNULL(RSU.MiddleName, '') AS [MiddleName]
        , RSU.LastName
        , RSU.PreferredName
        , ISNULL(RSU.CompanyName, '') AS [CompanyName]
        , CASE 
			WHEN RSU.MaritalStatus = 1 THEN 'Married'
			WHEN RSU.MaritalStatus IS NULL THEN 'Undefined'
			ELSE 'Single'
		  END AS [MaritalStatus]
        , ISNULL(RSU.SpouseName, '') AS [SpouseName]
        , U.UserName
        , RSU.[Password]
        , RSU.BirthDate
        , RSU.HomeTown
        , RSU.BirthCity
        , RSU.BirthState
        , RSU.BirthCountry
        , CASE
			WHEN RSU.Sex = 1 THEN 'Male'
			WHEN RSU.Sex = 0 THEN 'Female'
			ELSE ''
		  END AS [Sex]
        , RSU.ShirtSize
        , RSU.HatSize
        , RSU.DLNumber
        , RSU.DLState
        , RSU.DLCountry
        , RSU.DLExpiresOn
        , RSU.DLExpiration
        , RSU.Height
        , RSU.[Weight]
        , RSU.EyeColor
        , RSU.HairColor
        , UTL.fxRemovePhoneDecorations(RSU.PhoneHome) AS [PhoneHome]
        , UTL.fxRemovePhoneDecorations(RSU.PhoneCell) AS [PhoneCell]
        --, RSU.PhoneCellCarrierID
        , UTL.fxRemovePhoneDecorations(RSU.PhoneFax) AS [PhoneFax]
        , RSU.Email
		, URA.StreetAddress
		, URA.City
		, URA.PoliticalStateId
		, URA.PostalCode
        , RSU.CorporateEmail
        , RSU.TreeLevel
        , RSU.HasVerifiedAddress
        , CAST(RSU.RightToWorkExpirationDate AS DATE) AS [RightToWorkExpirationDate]
        , RSU.RightToWorkNotes
        , RSU.RightToWorkStatusID
        , RSU.IsLocked
        , RSU.IsActive
        --, RSU.IsDeleted
        --, RSU.ModifiedDate
        --, RSU.ModifiedById
        --, RSU.CreatedDate
        --, RSU.CreatedById
        --, RSU.DEX_ROW_TS
	FROM
		[RSU].[UserResources] AS RSU WITH(NOLOCK)
		INNER JOIN [RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
		ON
			(UET.UserEmployeeTypeID = RSU.UserEmployeeTypeId)
			AND (RSU.IsDeleted = 'False')
		LEFT OUTER JOIN [ACC].[Users] AS U WITH(NOLOCK)
		ON
			(U.UserID = RSU.UserId)
		LEFT OUTER JOIN [RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
		ON
			(URA.UserResourceAddressID = RSU.UserResourceAddressId)
GO