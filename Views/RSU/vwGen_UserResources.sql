/******************************************************************************
**		View: [RSU].[vwGen_UserResources]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserResources' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserResources];
GO

CREATE   VIEW [RSU].[vwGen_UserResources]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserResources].[UserResourceID]
		, [RSU].[UserResources].[DealerId]
		, [RSU].[UserResources].[UserId]
		, [RSU].[UserResources].[UserEmployeeTypeId]
		, [RSU].[UserResources].[UserResourceAddressId]
		, [RSU].[UserResources].[RecruitedById]
		, [RSU].[UserResources].[GPEmployeeId]
		, [RSU].[UserResources].[RecruitedByDate]
		, [RSU].[UserResources].[FullName]
		, [RSU].[UserResources].[PublicFullName]
		, [RSU].[UserResources].[SSN]
		, [RSU].[UserResources].[FirstName]
		, [RSU].[UserResources].[MiddleName]
		, [RSU].[UserResources].[LastName]
		, [RSU].[UserResources].[PreferredName]
		, [RSU].[UserResources].[CompanyName]
		, [RSU].[UserResources].[MaritalStatus]
		, [RSU].[UserResources].[SpouseName]
		, [RSU].[UserResources].[UserName]
		, [RSU].[UserResources].[Password]
		, [RSU].[UserResources].[BirthDate]
		, [RSU].[UserResources].[HomeTown]
		, [RSU].[UserResources].[BirthCity]
		, [RSU].[UserResources].[BirthState]
		, [RSU].[UserResources].[BirthCountry]
		, [RSU].[UserResources].[Sex]
		, [RSU].[UserResources].[ShirtSize]
		, [RSU].[UserResources].[HatSize]
		, [RSU].[UserResources].[DLNumber]
		, [RSU].[UserResources].[DLState]
		, [RSU].[UserResources].[DLCountry]
		, [RSU].[UserResources].[DLExpiresOn]
		, [RSU].[UserResources].[DLExpiration]
		, [RSU].[UserResources].[Height]
		, [RSU].[UserResources].[Weight]
		, [RSU].[UserResources].[EyeColor]
		, [RSU].[UserResources].[HairColor]
		, [RSU].[UserResources].[PhoneHome]
		, [RSU].[UserResources].[PhoneCell]
		, [RSU].[UserResources].[PhoneCellCarrierID]
		, [RSU].[UserResources].[PhoneFax]
		, [RSU].[UserResources].[Email]
		, [RSU].[UserResources].[CorporateEmail]
		, [RSU].[UserResources].[TreeLevel]
		, [RSU].[UserResources].[HasVerifiedAddress]
		, [RSU].[UserResources].[RightToWorkExpirationDate]
		, [RSU].[UserResources].[RightToWorkNotes]
		, [RSU].[UserResources].[RightToWorkStatusID]
		, [RSU].[UserResources].[IsLocked]
		, [RSU].[UserResources].[IsActive]
		, [RSU].[UserResources].[ModifiedDate]
		, [RSU].[UserResources].[ModifiedById]
		, [RSU].[UserResources].[CreatedDate]
		, [RSU].[UserResources].[CreatedById]
	FROM
		[RSU].[UserResources]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserResources') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserResources].CreatedById = AL.UserId))
			AND ([RSU].[UserResources].IsDeleted = 'FALSE')

;
GO