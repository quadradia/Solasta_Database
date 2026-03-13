DROP PROCEDURE IF EXISTS [RSU].[spUserResourceNewDefaultPlusUser];
GO

/******************************************************************************
**		File: spUserResourceNewDefaultPlusUser.sql
**		Name: spUserResourceNewDefaultPlusUser
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
**		Date: 01/21/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	01/21/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceNewDefaultPlusUser]
(
	@DealerId INT
	, @SeasonId INT
	, @FirstName NVARCHAR(50)
	, @MiddleName NVARCHAR(50) = NULL
	, @LastName NVARCHAR(50)
	, @Email NVARCHAR(256)
	, @PhoneNumber NVARCHAR(15)
	, @RoleId UNIQUEIDENTIFIER = NULL
	, @UserTypeID SMALLINT = 1 
	, @UserEmployeeTypeId VARCHAR(20)
	, @UserID UNIQUEIDENTIFIER OUTPUT
	, @UserResourceID INT OUTPUT
	, @UserRecruitID INT OUTPUT
	, @ShowOutput BIT = 'True'
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** DECLARATIONS */
	DECLARE @LanguageId NVARCHAR(50) = 'en'
		, @DealerName NVARCHAR(50)
		, @PasswordHash NVARCHAR(MAX) = 'AGYHF9mURPPLzuj4tmmgapy1APJ0PYHZb225Emn52RGpHahbTaTYVta7Li1xhGAZlw=='  -- Nuvol9CRM
		, @SecurityStamp NVARCHAR(MAX) = 'ea342a9a-bad3-4e9a-9fb2-3f5e20a0c424'

	BEGIN TRY
		-- ** Set the UserId
		SET @UserID = NEWID();

		-- ** Get Dealer information 
		SELECT @DealerName = DealerName FROM [ACC].[Dealers] WHERE DealerID = @DealerId;

		-- ** Check for duplicate users
		IF(EXISTS(SELECT TOP 1 1 FROM [ACC].[Users] WHERE (Email = @Email AND DealerId = @DealerId))) BEGIN
			RAISERROR (N'[30200]:This user already exists with email "%s" for dealer "%s (%d)"'
				, 18 -- Severity
				, 1 -- State
				, @Email
				, @DealerName
				, @DealerId);
		END

		-- ** STATEMENT
		INSERT INTO [ACC].[Users] (
			[UserID]
			, [DealerId]
			, [LanguageId]
			, [FirstName]
			, [LastName]
			, [Email]
			, [EmailConfirmed]
			, [Username]
			, [PasswordHash]
			, [SecurityStamp]
			, [PhoneNumber]
			, [PhoneNumberConfirmed]
			, [TwoFactorEnabled]
			, [LockoutEnabled]
			, [AccessFailedCount]
		) VALUES (
			@UserID, -- UserID - uniqueidentifier
			@DealerId , -- DealerId - int
			@LanguageId , -- LanguageId - nvarchar(50)
			@FirstName , -- FirstName - nvarchar(max)
			@LastName , -- LastName - nvarchar(max)
			@Email , -- Email - nvarchar(max)
			'False' , -- EmailConfirmed - bit
			@Email , -- Username - nvarchar(256)
			@PasswordHash , -- PasswordHash - nvarchar(max)
			@SecurityStamp , -- SecurityStamp - nvarchar(max)
			@PhoneNumber , -- PhoneNumber - nvarchar(max)
			'False' , -- PhoneNumberConfirmed - bit
			'False' , -- TwoFactorEnabled - bit
			'False' , -- LockoutEnabled - bit
			0 -- AccessFailedCount - int
		);

		IF (@RoleId IS NOT NULL) BEGIN
			INSERT INTO [ACC].[UserRoles] ([UserId], [RoleId]) VALUES (@UserID, @RoleId);
		END

		-- ** Create User Resources
		-- ** ** Create Address First
		DECLARE @UserResourceAddressID INT;
		INSERT INTO [RSU].[UserResourceAddresses] (
			[PoliticalStateId]
			, [PoliticalCountryId]
			, [PoliticalTimeZoneId]
			, [StreetAddress]
			, [StreetAddress2]
			, [City]
			, [PostalCode]
			, [PlusFour]
		) VALUES (
			'UT' , -- PoliticalStateId - varchar(4)
			N'USA' , -- PoliticalCountryId - nvarchar(10)
			7 , -- PoliticalTimeZoneId - int
			N'' , -- StreetAddress - nvarchar(50)
			N'' , -- StreetAddress2 - nvarchar(50)
			N'' , -- City - nvarchar(50)
			N'' , -- PostalCode - nvarchar(10)
			N'' -- PlusFour - nvarchar(4)
		);
		SET @UserResourceAddressID = SCOPE_IDENTITY();
		-- ** ** Create Resource Second
		DECLARE @GPEmployeeId NVARCHAR(25) = [UTL].fxCreateGpEmployeeNumberNxN(@FirstName, @LastName, @DealerId, 3, 3);
		INSERT INTO [RSU].[UserResources] (
			[DealerId]
			, [UserId]
			, [UserEmployeeTypeId]
			, [UserResourceAddressId]
			, [GPEmployeeId]
			, [RecruitedByDate]
			, [FullName]
			, [PublicFullName]
			, [FirstName]
			, [MiddleName]
			, [LastName]
			, [PreferredName]
			, [UserName]
			, [Password]
			, [Sex]
			, [PhoneCell]
			, [Email]
			, [CorporateEmail]
			, [HasVerifiedAddress]
			, [IsLocked]
		) VALUES (
			@DealerId , -- DealerId - int
			@UserID , -- UserId - uniqueidentifier
			@UserEmployeeTypeId , -- UserEmployeeTypeId - varchar(20)
			@UserResourceAddressID , -- UserResourceAddressId - int
			@GPEmployeeId , -- GPEmployeeId - nvarchar(25)
			SYSDATETIMEOFFSET() , -- RecruitedByDate - datetimeoffset
			@FirstName + N' ' + @LastName , -- FullName - nvarchar(101)
			@FirstName + N' ' + @LastName , -- PublicFullName - nvarchar(53)
			@FirstName , -- FirstName - nvarchar(50)
			@MiddleName ,
			@LastName , -- LastName - nvarchar(50)
			@FirstName + N' ' + @LastName , -- PreferredName - nvarchar(50)
			@Email , -- UserName - nvarchar(50)
			'Nuvol9CRM' , -- Password - varchar(60)
			0 , -- Sex - tinyint
			@PhoneNumber ,
			@Email , -- Email - nvarchar(100)
			@Email , -- CorporateEmail - nvarchar(100)
			'False' , -- HasVerifiedAddress - bit
			'False' -- IsLocked - bit
		);
		SET @UserResourceID = SCOPE_IDENTITY();

		-- ** Update ACC.Users with new UserResource ID
		UPDATE [ACC].[Users] SET HRUserId = @UserResourceID WHERE UserID = @UserID;

		-- ** Create User Recruit or Contract
		-- ** ** Create Address First
		DECLARE @UserRecruitAddressId INT;
		INSERT INTO [RSU].[UserRecruitAddresses] (
			[PoliticalStateId]
			, [PoliticalCountryId]
			, [PoliticalTimeZoneId]
			, [StreetAddress]
			, [StreetAddress2]
			, [City]
			, [PostalCode]
			, [PlusFour]
		) SELECT TOP 1
            URA.PoliticalStateId
            , URA.PoliticalCountryId
            , URA.PoliticalTimeZoneId
            , URA.StreetAddress
            , URA.StreetAddress2
            , URA.City
            , URA.PostalCode
            , URA.PlusFour
		FROM
			[RSU].[UserResourceAddresses] AS URA WITH (NOLOCK)
		WHERE (URA.UserResourceAddressID = @UserResourceAddressID);
		SET @UserRecruitAddressId = SCOPE_IDENTITY();
		-- ** ** Create Recruit (Contract) Second
		INSERT INTO [RSU].[UserRecruits] (
			[UserResourceId]
			, [UserTypeId]
			, [UserRecruitAddressId]
			, [DealerId]
			, [SeasonId]
			, [IsRecruiter]
			, [SocialSecCardStatusID]
			, [DriversLicenseStatusID]
			, [W4StatusID]
			, [I9StatusID]
			, [W9StatusID]
			, [SocialSecCardNotes]
			, [DriversLicenseNotes]
			, [RentExempt]
			, [IsServiceTech]
			, [StateId]
			, [CountryId]
			, [StreetAddress]
			, [StreetAddress2]
			, [City]
			, [PostalCode]
		) 
		SELECT
			@UserResourceID -- UserResourceId - int
			, @UserTypeID -- UserTypeId - smallint (	CORPGROUP	Administrator )
			, @UserRecruitAddressId -- UserRecruitAddressId - int
			, @DealerId
			, @SeasonId -- SeasonId - int
			, 'FALSE' -- IsRecruiter - bit
			, 0 -- SocialSecCardStatusID - int
			, 0 -- DriversLicenseStatusID - int
			, 0 -- W4StatusID - int
			, 0 -- I9StatusID - int
			, 0 -- W9StatusID - int
			, N'[Missing]' -- SocialSecCardNotes - nvarchar(250)
			, N'[Missing]' -- DriversLicenseNotes - nvarchar(250)
			, 'FALSE' -- RentExempt - bit
			, 'FALSE' -- IsServiceTech - bit
			, URA.PoliticalStateId -- StateId - varchar(4)
			, URA.PoliticalCountryId -- CountryId - nvarchar(10)
			, URA.StreetAddress -- StreetAddress - nvarchar(50)
			, URA.StreetAddress2 -- StreetAddress2 - nvarchar(50)
			, URA.City -- City - nvarchar(50)
			, URA.PostalCode -- PostalCode - nvarchar(10)
		FROM
			[RSU].[UserResourceAddresses] AS URA WITH (NOLOCK)
		WHERE
			(URA.UserResourceAddressID = @UserResourceAddressID);
		SET @UserRecruitID = SCOPE_IDENTITY();


		/** Update ACC.Users with GPEmployeeID */
		UPDATE ACC.Users SET GPEmployeeID = @GPEmployeeId WHERE (UserID = @UserID);

		/** Return New Resource */
		IF (@ShowOutput = 1) BEGIN
			SELECT * FROM [RSU].[vwUserResourceFullSearchDataSet] WHERE Id = @UserResourceID;
		END;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
