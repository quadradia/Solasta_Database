DROP PROCEDURE IF EXISTS [RSU].[spUserRecruitCreateFromResourceId];
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
**		Date: 05/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	05/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spUserRecruitCreateFromResourceId]
(
	@UserResourceId INT
	, @SeasonId INT
	, @UserTypeId INT
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @UserDealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @UserDealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	/** LOCALS */
	DECLARE @UserResourceAddressId INT
		, @UserRecruitAddressId INT
		, @DealerId INT;

	/** Init */
	SELECT @DealerId = DealerId, @UserResourceAddressId = UserResourceAddressId FROM [RSU].[UserResources] WHERE (UserResourceID = @UserResourceId);

	/** VALIDATE REQUEST */
	IF (@UserDealerId <> (SELECT DealerId FROM [RSU].[UserResources] WHERE UserResourceID = @UserResourceId)) BEGIN
		RAISERROR(N'SECURITY VIOLATION:  Request is comming from a foreign dealer...', 18, 1);
		RETURN;
	END

	BEGIN TRY
		-- ** EXECUTE
		-- ** ** Create UserRecruitAddress
		INSERT INTO [RSU].[UserRecruitAddresses] (
			[PoliticalStateId]
			,[PoliticalCountryId]
			,[PoliticalTimeZoneId]
			,[StreetAddress]
			,[StreetAddress2]
			,[City]
			,[PostalCode]
			,[PlusFour]
			,[ModifiedById]
			,[CreatedById]
		)
		SELECT 
			URA.PoliticalStateId
			, URA.PoliticalCountryId
			, URA.PoliticalTimeZoneId
			, URA.StreetAddress
			, URA.StreetAddress2
			, URA.City
			, URA.PostalCode
			, URA.PlusFour
			, @UserID AS ModifiedById
			, @UserID AS CreatedById
		FROM
			[RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
		WHERE
			(URA.UserResourceAddressID = @UserResourceAddressId);
		SET @UserRecruitAddressId = SCOPE_IDENTITY();

		DECLARE @UserRecruitID INT;
		INSERT INTO [RSU].[UserRecruits] (
			[UserResourceId]
			,[UserTypeId]
			,[UserRecruitAddressId]
			,[DealerId]
			,[SeasonId]
			,[IsRecruiter]
			,[SignatureDate]
			,[HireDate]
			,[SocialSecCardStatusID]
			,[DriversLicenseStatusID]
			,[W4StatusID]
			,[I9StatusID]
			,[W9StatusID]
			,[RentExempt]
			,[IsServiceTech]
			,[StateId]
			,[CountryId]
			,[StreetAddress]
			,[StreetAddress2]
			,[City]
			,[PostalCode]
		)
		SELECT
			@UserResourceId
			, @UserTypeId
			, URA.UserRecruitAddressID
			, @DealerId
			, @SeasonId
			, 'False' AS IsRecruiter
			, SYSDATETIMEOFFSET() AS SignatureDate
			, SYSDATETIMEOFFSET() AS HireDate
			, 0 AS [SocialSecCardStatusID]
			, 0 AS [DriversLicenseStatusID]
			, -1 AS [W4StatusID]
			, -1 AS [I9StatusID]
			, -1 AS [W9StatusID]
			, 'False' AS [RentExempt]
			, 'False' AS [IsServiceTech]
			, URA.PoliticalStateId AS StateId
			, URA.PoliticalCountryId AS CountryId
			, URA.StreetAddress
			, URA.StreetAddress2
			, URA.City
			, URA.PostalCode
		FROM
			[RSU].[UserRecruitAddresses] AS URA WITH(NOLOCK)
		WHERE
			(URA.UserRecruitAddressID = @UserRecruitAddressId);
		SET @UserRecruitID = SCOPE_IDENTITY();

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH

	/** Return result */
	SELECT
		UR.UserRecruitID AS Id
        , UR.UserResourceId
        , UR.UserTypeId
        , UR.ReportsToId
        , UR.UserRecruitAddressId
        , UR.DealerId
        , UR.SeasonId
        , UR.OwnerApprovalId
        , UR.TeamId
        , UR.PayScaleId
        , UR.SchoolId
        , UR.ShackingUpId
        , UR.UserRecruitCohabbitTypeId
        , UR.AlternatePayScheduleId
        , UR.[Location]
        , UR.OwnerApprovalDate
        , UR.ManagerApprovalDate
        , UR.EmergencyName
        , UR.EmergencyPhone
        , UR.EmergencyRelationship
        , UR.IsRecruiter
        , UR.PreviousSummer
        , UR.SignatureDate
        , UR.HireDate
        , UR.GPExemptions
        , UR.GPW4Allowances
        , UR.GPW9Name
        , UR.GPW9BusinessName
        , UR.GPW9TIN
        , UR.SocialSecCardStatusID
        , UR.DriversLicenseStatusID
        , UR.W4StatusID
        , UR.I9StatusID
        , UR.W9StatusID
        , UR.SocialSecCardNotes
        , UR.DriversLicenseNotes
        , UR.W4Notes
        , UR.I9Notes
        , UR.W9Notes
        , UR.EIN
        , UR.SUTA
        , UR.WorkersComp
        , UR.FedFilingStatus
        , UR.EICFilingStatus
        , UR.TaxWitholdingState
        , UR.StateFilingStatus
        , UR.GPDependents
        , UR.CriminalOffense
        , UR.Offense
        , UR.OffenseExplanation
        , UR.Rent
        , UR.Pet
        , UR.Utilities
        , UR.Fuel
        , UR.Furniture
        , UR.CellPhoneCredit
        , UR.GasCredit
        , UR.RentExempt
        , UR.IsServiceTech
        , UR.StateId
        , UR.CountryId
        , UR.StreetAddress
        , UR.StreetAddress2
        , UR.City
        , UR.PostalCode
        , UR.CBxSocialSecCard
        , UR.CBxDriversLicense
        , UR.CBxW4
        , UR.CBxI9
        , UR.CBxW9
        , UR.PersonalMultiple
        , UR.IsActive
        , UR.IsDeleted
        , UR.CreatedById
        , UR.CreatedDate
        , UR.ModifiedById
        , UR.ModifiedDate
	FROM
		[RSU].[UserRecruits] AS UR WITH(NOLOCK)
	WHERE
		(UR.UserRecruitID = @UserRecruitID);
END

GO
