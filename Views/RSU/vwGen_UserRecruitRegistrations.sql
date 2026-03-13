/******************************************************************************
**		View: [RSU].[vwGen_UserRecruitRegistrations]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_UserRecruitRegistrations' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruitRegistrations];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruitRegistrations]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruitRegistrations].[UserRecruitRegistrationID]
		, [RSU].[UserRecruitRegistrations].[UniqueRegistrationId]
		, [RSU].[UserRecruitRegistrations].[InvitedByUserResourceId]
		, [RSU].[UserRecruitRegistrations].[ExistingUserResourceId]
		, [RSU].[UserRecruitRegistrations].[RegistrationDate]
		, [RSU].[UserRecruitRegistrations].[RecruitedByUserResourceId]
		, [RSU].[UserRecruitRegistrations].[UserRecruitAddressId]
		, [RSU].[UserRecruitRegistrations].[SSN]
		, [RSU].[UserRecruitRegistrations].[FirstName]
		, [RSU].[UserRecruitRegistrations].[MiddleName]
		, [RSU].[UserRecruitRegistrations].[LastName]
		, [RSU].[UserRecruitRegistrations].[PreferredName]
		, [RSU].[UserRecruitRegistrations].[FullName]
		, [RSU].[UserRecruitRegistrations].[UserName]
		, [RSU].[UserRecruitRegistrations].[BirthDate]
		, [RSU].[UserRecruitRegistrations].[BirthCity]
		, [RSU].[UserRecruitRegistrations].[BirthState]
		, [RSU].[UserRecruitRegistrations].[BirthCountry]
		, [RSU].[UserRecruitRegistrations].[Sex]
		, [RSU].[UserRecruitRegistrations].[ShirtSize]
		, [RSU].[UserRecruitRegistrations].[HatSize]
		, [RSU].[UserRecruitRegistrations].[DLNumber]
		, [RSU].[UserRecruitRegistrations].[DLState]
		, [RSU].[UserRecruitRegistrations].[DLCountry]
		, [RSU].[UserRecruitRegistrations].[DLExpiration]
		, [RSU].[UserRecruitRegistrations].[Height]
		, [RSU].[UserRecruitRegistrations].[Weight]
		, [RSU].[UserRecruitRegistrations].[EyeColor]
		, [RSU].[UserRecruitRegistrations].[HairColor]
		, [RSU].[UserRecruitRegistrations].[PhoneHome]
		, [RSU].[UserRecruitRegistrations].[PhoneCell]
		, [RSU].[UserRecruitRegistrations].[PhoneCellCarrierID]
		, [RSU].[UserRecruitRegistrations].[Email]
		, [RSU].[UserRecruitRegistrations].[UserTypeId]
		, [RSU].[UserRecruitRegistrations].[ReportsToID]
		, [RSU].[UserRecruitRegistrations].[CurrentAddressID]
		, [RSU].[UserRecruitRegistrations].[PayScaleID]
		, [RSU].[UserRecruitRegistrations].[SchoolId]
		, [RSU].[UserRecruitRegistrations].[HasPet]
		, [RSU].[UserRecruitRegistrations].[NeedsExtraHousing]
		, [RSU].[UserRecruitRegistrations].[EmergencyName]
		, [RSU].[UserRecruitRegistrations].[EmergencyPhone]
		, [RSU].[UserRecruitRegistrations].[EmergencyRelationship]
		, [RSU].[UserRecruitRegistrations].[PreviousSummer]
		, [RSU].[UserRecruitRegistrations].[CriminalOffense]
		, [RSU].[UserRecruitRegistrations].[Offense]
		, [RSU].[UserRecruitRegistrations].[OffenseExplanation]
		, [RSU].[UserRecruitRegistrations].[StartDate]
		, [RSU].[UserRecruitRegistrations].[StartingState]
		, [RSU].[UserRecruitRegistrations].[IsActive]
		, [RSU].[UserRecruitRegistrations].[ModifiedDate]
		, [RSU].[UserRecruitRegistrations].[ModifiedById]
		, [RSU].[UserRecruitRegistrations].[CreatedDate]
		, [RSU].[UserRecruitRegistrations].[CreatedById]
	FROM
		[RSU].[UserRecruitRegistrations]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruitRegistrations') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([RSU].[UserRecruitRegistrations].CreatedById = AL.UserId))
			AND ([RSU].[UserRecruitRegistrations].IsDeleted = 'FALSE')

;
GO