DROP PROCEDURE IF EXISTS [RSU].[spUserResourceFullGetByContextDealerJSON];
GO

/******************************************************************************
**		File: spAutoACEUtilDropACESPROCS.sql
**		Name: spAutoACEUtilDropACESPROCS
**		Desc:
**
**		This template can be customized:
**
**		Return values:
**
**		Called by:
**
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andres Sosa
**		Date: 02/01/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	02/01/2018	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceFullGetByContextDealerJSON]
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerTenantId
	FROM [ACC].[fxGetContextUserTable]();

	BEGIN TRY
		-- ** STATEMENT
		SELECT
		(SELECT
			RU.UserResourceID AS id
				, RU.DealerTenantId AS dealerId
				, RU.UserId AS userId
				, RU.UserEmployeeTypeId AS userEmployeeTypeId
				, UET.UserEmployeeTypeName AS userEmployeeTypeName
				, RU.RecruitedById AS recruitedById
				, RU.GpEmployeeId AS companyId
				, RU.GpEmployeeId AS gpEmployeeId
				, RU.RecruitedByDate AS recruitedOn
				, RU.FullName AS fullName
				, RU.PublicFullName AS publicFullName
				, RU.SSN AS sSN
				, RU.FirstName AS firstName
				, RU.MiddleName AS middleName
				, RU.LastName AS lastName
				, RU.PreferredName AS preferredName
				, RU.CompanyName AS companyName
				, RU.MaritalStatus AS maritalStatus
				, RU.SpouseName AS spouseName
				, RU.Username AS username
				, RU.[Password] AS [password]
				, RU.BirthDate AS birthDate
				, RU.HomeTown AS homeTown
				, RU.BirthCity AS birthCity
				, RU.BirthState AS birthState
				, RU.BirthCountry AS birthCountry
				, RU.Sex AS sex
				, RU.ShirtSize AS shirtSize
				, RU.HatSize AS hatSize
				, RU.DLNumber AS dLNumber
				, RU.DLState AS dLState
				, RU.DLCountry AS dLCountry
				, RU.DLExpiresOn AS dLExpiresOn
				, RU.DLExpiration AS dLExpiration
				, RU.Height AS height
				, RU.[Weight] AS [weight]
				, RU.EyeColor AS eyeColor
				, RU.HairColor AS hairColor
				, RU.PhoneHome AS phoneHome
				, RU.PhoneCell AS phoneCell
				, RU.PhoneFax AS phoneFax
				, RU.Email AS email
				, URA.StreetAddress AS streetAddress
				, URA.City AS city
				, URA.PoliticalStateId AS politicalStateId
				, URA.PostalCode AS postalCode
				, RU.CorporateEmail AS corporateEmail
				, RU.TreeLevel AS treeLevel
				, RU.HasVerifiedAddress AS hasVerifiedAddress
				, RU.RightToWorkExpirationDate AS rightToWorkExpirationDate
				, RU.RightToWorkNotes AS rightToWorkNotes
				, RU.RightToWorkStatusID AS rightToWorkStatusID
				, RU.IsLocked AS isLocked
				, RU.IsActive AS isActive
				, (SELECT
				URS.UserRecruitID AS id
						, URS.UserResourceId AS userResourceId
						, URS.UserTypeId AS userTypeId
						, (SELECT
					UT.UserTypeID AS id
								, UT.UserTypeTeamTypeId AS userTypeTeamTypeId
								, UT.UserTypeGroupId AS userTypeGroupId
								, UTG.UserTypeGroupName AS userTypeGroupName
								, UT.UserTypeName AS userTypeName
								, UT.SecurityLevel AS securityLevel
								, UT.SpawnTypeId AS spawnTypeId
								, UT.RoleLocationId AS roleLocationId
								, UT.ReportingLevel AS reportingLevel
								, UT.IsCommissionable AS isCommissionable
								, UT.IsActive AS isActive
								, UT.IsDeleted AS isDeleted
								, UT.ModifiedDate AS modifiedDate
								, UT.ModifiedById AS modifiedById
								, UT.CreatedDate AS createdDate
								, UT.CreatedById AS createdById
				FROM
					[RSU].[UserTypes] AS UT WITH(NOLOCK)
					INNER JOIN [RSU].[UserTypeGroups] AS UTG WITH(NOLOCK)
					ON
									(UTG.UserTypeGroupID = UT.UserTypeGroupId)
				WHERE
								(UT.UserTypeID = URS.UserTypeId)
				FOR JSON PATH, INCLUDE_NULL_VALUES
						) AS userType
						, URS.ReportsToId AS reportsToId
						, URS.UserRecruitAddressId AS userRecruitAddressId
						, URS.DealerTenantId AS dealerId
						, URS.SeasonId AS seasonId
						, JSON_QUERY(RSU.fxGetSeasonByRecruitIdJSON(URS.UserRecruitID), '$') AS season
						, URS.OwnerApprovalId AS ownerApprovalId
						, URS.TeamId AS teamId
						, URS.PayScaleId AS payScaleId
						, URS.SchoolId AS schoolId
						, URS.ShackingUpId AS shackingUpId
						, URS.UserRecruitCohabbitTypeId AS userRecruitCohabbitTypeId
						, URS.AlternatePayScheduleId AS alternatePayScheduleId
						, URS.[Location] AS [location]
						, URS.OwnerApprovalDate AS ownerApprovalDate
						, URS.ManagerApprovalDate AS managerApprovalDate
						, URS.EmergencyName AS emergencyName
						, URS.EmergencyPhone AS emergencyPhone
						, URS.EmergencyRelationship AS emergencyRelationship
						, URS.IsRecruiter AS isRecruiter
						, URS.PreviousSummer AS previousSummer
						, URS.SignatureDate AS signatureDate
						, URS.HireDate AS hireDate
						, URS.GPExemptions AS gPExemptions
						, URS.GPW4Allowances AS gPW4Allowances
						, URS.GPW9Name AS gPW9Name
						, URS.GPW9BusinessName AS gPW9BusinessName
						, URS.GPW9TIN AS gPW9TIN
						, URS.SocialSecCardStatusID AS socialSecCardStatusID
						, URS.DriversLicenseStatusID AS driversLicenseStatusID
						, URS.W4StatusID AS w4StatusID
						, URS.I9StatusID AS i9StatusID
						, URS.W9StatusID AS w9StatusID
						, URS.SocialSecCardNotes AS socialSecCardNotes
						, URS.DriversLicenseNotes AS driversLicenseNotes
						, URS.W4Notes AS w4Notes
						, URS.I9Notes AS i9Notes
						, URS.W9Notes AS w9Notes
						, URS.EIN AS eIN
						, URS.SUTA AS sUTA
						, URS.WorkersComp AS workersComp
						, URS.FedFilingStatus AS fedFilingStatus
						, URS.EICFilingStatus AS eICFilingStatus
						, URS.TaxWitholdingState AS taxWitholdingState
						, URS.StateFilingStatus AS stateFilingStatus
						, URS.GPDependents AS gPDependents
						, URS.CriminalOffense AS criminalOffense
						, URS.Offense AS offense
						, URS.OffenseExplanation AS offenseExplanation
						, URS.Rent AS rent
						, URS.Pet AS pet
						, URS.Utilities AS utilities
						, URS.Fuel AS fuel
						, URS.Furniture AS furniture
						, URS.CellPhoneCredit AS cellPhoneCredit
						, URS.GasCredit AS gasCredit
						, URS.RentExempt AS rentExempt
						, URS.IsServiceTech AS isServiceTech
						, URS.StateId AS stateId
						, URS.CountryId AS countryId
						, URS.StreetAddress AS streetAddress
						, URS.StreetAddress2 AS streetAddress2
						, URS.City AS city
						, URS.PostalCode AS postalCode
						, URS.CBxSocialSecCard AS cBxSocialSecCard
						, URS.CBxDriversLicense AS cBxDriversLicense
						, URS.CBxW4 AS cBxW4
						, URS.CBxI9 AS cBxI9
						, URS.CBxW9 AS cBxW9
						, URS.PersonalMultiple AS personalMultiple
						, URS.IsActive AS isActive
						, URS.IsDeleted AS isDeleted
						, URS.CreatedById AS createdById
						, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URS.CreatedById), '$') AS createdBy
						, URS.CreatedDate AS createdDate
						, URS.ModifiedById AS modifiedById
						, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URS.ModifiedById), '$') AS modifiedBy
						, URS.ModifiedDate AS modifiedDate
			FROM
				[RSU].[UserRecruits] AS URS WITH(NOLOCK)
				INNER JOIN [RSU].[Seasons] AS S WITH(NOLOCK)
				ON
							(S.SeasonID = URS.SeasonId)
				INNER JOIN [RSU].[UserTypes] AS UT WITH(NOLOCK)
				ON
							(UT.UserTypeID = URS.UserTypeId)
			WHERE
						(URS.UserResourceId = RU.UserResourceID)
				AND (URS.IsActive = 'True' AND URS.IsDeleted = 'False')
			FOR JSON PATH, INCLUDE_NULL_VALUES
				) AS contracts
		FROM
			[RSU].[UserResources] AS RU WITH(NOLOCK)
			INNER JOIN [ACC].[Users] AS ACCU WITH(NOLOCK)
			ON
					(ACCU.UserID = RU.UserId)
				AND (ACCU.IsActive = 'True' AND ACCU.IsDeleted = 'False')
			INNER JOIN [RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
			ON
					(UET.UserEmployeeTypeID = RU.UserEmployeeTypeId)
			INNER JOIN [RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
			ON
					(URA.UserResourceAddressID = RU.UserResourceAddressId)
		WHERE
					(RU.DealerTenantId = @DealerId)
			AND ((RU.IsActive = 'True') AND (RU.IsDeleted = 'False'))
		-- DEBUGGER				AND (RU.GPEmployeeId = 'TIP001')
		ORDER BY
				RU.FirstName, RU.LastName
		FOR JSON PATH, INCLUDE_NULL_VALUES) AS JsonOutputMethod

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
