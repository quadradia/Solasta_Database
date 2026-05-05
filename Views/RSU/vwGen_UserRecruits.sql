/******************************************************************************
**		View: [RSU].[vwGen_UserRecruits]
**		Desc:
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT *
FROM sys.views
WHERE name = 'vwGen_UserRecruits' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_UserRecruits];
GO

CREATE   VIEW [RSU].[vwGen_UserRecruits]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[UserRecruits].[UserRecruitID]
		, [RSU].[UserRecruits].[UserResourceId]
		, [RSU].[UserRecruits].[UserTypeId]
		, [RSU].[UserRecruits].[ReportsToId]
		, [RSU].[UserRecruits].[UserRecruitAddressId]
		, [RSU].[UserRecruits].[DealerTenantId]
		, [RSU].[UserRecruits].[SeasonId]
		, [RSU].[UserRecruits].[OwnerApprovalId]
		, [RSU].[UserRecruits].[TeamId]
		, [RSU].[UserRecruits].[PayScaleId]
		, [RSU].[UserRecruits].[SchoolId]
		, [RSU].[UserRecruits].[ShackingUpId]
		, [RSU].[UserRecruits].[UserRecruitCohabbitTypeId]
		, [RSU].[UserRecruits].[AlternatePayScheduleId]
		, [RSU].[UserRecruits].[Location]
		, [RSU].[UserRecruits].[OwnerApprovalDate]
		, [RSU].[UserRecruits].[ManagerApprovalDate]
		, [RSU].[UserRecruits].[EmergencyName]
		, [RSU].[UserRecruits].[EmergencyPhone]
		, [RSU].[UserRecruits].[EmergencyRelationship]
		, [RSU].[UserRecruits].[IsRecruiter]
		, [RSU].[UserRecruits].[PreviousSummer]
		, [RSU].[UserRecruits].[SignatureDate]
		, [RSU].[UserRecruits].[HireDate]
		, [RSU].[UserRecruits].[GPExemptions]
		, [RSU].[UserRecruits].[GPW4Allowances]
		, [RSU].[UserRecruits].[GPW9Name]
		, [RSU].[UserRecruits].[GPW9BusinessName]
		, [RSU].[UserRecruits].[GPW9TIN]
		, [RSU].[UserRecruits].[SocialSecCardStatusID]
		, [RSU].[UserRecruits].[DriversLicenseStatusID]
		, [RSU].[UserRecruits].[W4StatusID]
		, [RSU].[UserRecruits].[I9StatusID]
		, [RSU].[UserRecruits].[W9StatusID]
		, [RSU].[UserRecruits].[SocialSecCardNotes]
		, [RSU].[UserRecruits].[DriversLicenseNotes]
		, [RSU].[UserRecruits].[W4Notes]
		, [RSU].[UserRecruits].[I9Notes]
		, [RSU].[UserRecruits].[W9Notes]
		, [RSU].[UserRecruits].[EIN]
		, [RSU].[UserRecruits].[SUTA]
		, [RSU].[UserRecruits].[WorkersComp]
		, [RSU].[UserRecruits].[FedFilingStatus]
		, [RSU].[UserRecruits].[EICFilingStatus]
		, [RSU].[UserRecruits].[TaxWitholdingState]
		, [RSU].[UserRecruits].[StateFilingStatus]
		, [RSU].[UserRecruits].[GPDependents]
		, [RSU].[UserRecruits].[CriminalOffense]
		, [RSU].[UserRecruits].[Offense]
		, [RSU].[UserRecruits].[OffenseExplanation]
		, [RSU].[UserRecruits].[Rent]
		, [RSU].[UserRecruits].[Pet]
		, [RSU].[UserRecruits].[Utilities]
		, [RSU].[UserRecruits].[Fuel]
		, [RSU].[UserRecruits].[Furniture]
		, [RSU].[UserRecruits].[CellPhoneCredit]
		, [RSU].[UserRecruits].[GasCredit]
		, [RSU].[UserRecruits].[RentExempt]
		, [RSU].[UserRecruits].[IsServiceTech]
		, [RSU].[UserRecruits].[StateId]
		, [RSU].[UserRecruits].[CountryId]
		, [RSU].[UserRecruits].[StreetAddress]
		, [RSU].[UserRecruits].[StreetAddress2]
		, [RSU].[UserRecruits].[City]
		, [RSU].[UserRecruits].[PostalCode]
		, [RSU].[UserRecruits].[CBxSocialSecCard]
		, [RSU].[UserRecruits].[CBxDriversLicense]
		, [RSU].[UserRecruits].[CBxW4]
		, [RSU].[UserRecruits].[CBxI9]
		, [RSU].[UserRecruits].[CBxW9]
		, [RSU].[UserRecruits].[PersonalMultiple]
		, [RSU].[UserRecruits].[IsActive]
		, [RSU].[UserRecruits].[CreatedById]
		, [RSU].[UserRecruits].[CreatedDate]
		, [RSU].[UserRecruits].[ModifiedById]
		, [RSU].[UserRecruits].[ModifiedDate]
	FROM
		[RSU].[UserRecruits]
		INNER JOIN (SELECT TOP 1
			*
		FROM [GEN].fxGetAccessLevel('Read', 'RSU','UserRecruits') AS ALIN
		WHERE (ALIN.ReadAccessId >= 1)
		ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[UserRecruits].IsDeleted = 'FALSE')

;
GO