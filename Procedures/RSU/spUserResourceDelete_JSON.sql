DROP PROCEDURE IF EXISTS [RSU].[spUserResourceDelete_JSON];
GO

/******************************************************************************
**		File: spUserResourceDelete_JSON.sql
**		Name: spUserResourceDelete_JSON
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
**		Auth: AndrÃ©s Sosa
**		Date: 04/14/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	04/14/2018	AndrÃ©s Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceDelete_JSON]
	(
	@UserResourceId INT
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @ContextUserID UNIQUEIDENTIFIER, @DealerId INT;
	SELECT @ContextUserID = UserID, @DealerId = DealerTenantId
	FROM [ACC].[fxGetContextUserTable]();

	/** VALIDATION CHECK */
	IF (NOT EXISTS(SELECT TOP(1)
		1
	FROM [RSU].[UserResources]
	WHERE DealerTenantId = @DealerId AND UserResourceID = @UserResourceId)) BEGIN
		RAISERROR(N'[30050]:SECURITY VIOLATION.  You do not have access to these resources.', 18, 1);
		RETURN -1;
	END

	/** LOCALS */
	DECLARE @UserID UNIQUEIDENTIFIER
		, @IsActive BIT = 'False'
		, @IsDeleted BIT = 'True';
	SELECT @UserID = UserId
	FROM [RSU].[UserResources]
	WHERE UserResourceID = @UserResourceId;

	BEGIN TRY
		-- ** STATEMENT
		UPDATE [RSU].[UserResources] SET
			IsActive = @IsActive
			, IsDeleted = @IsDeleted
			, ModifiedDate = SYSDATETIMEOFFSET()
			, ModifiedById = @ContextUserID
		WHERE
			UserResourceID = @UserResourceId;

		UPDATE [ACC].[Users] SET
			IsActive = @IsActive
			, IsDeleted = @IsDeleted
		WHERE
			UserID = @UserId;

		/** RETURN RESULT */
		DECLARE @Result NVARCHAR(MAX);
		SELECT @Result = (
			SELECT
			UR.UserResourceID AS id
				, UR.UserResourceID AS userResourceID
				, UR.DealerTenantId AS dealerId
				, UR.UserId AS userId
				, UR.UserEmployeeTypeId AS userEmployeeTypeId
				, UR.UserResourceAddressId AS userResourceAddressId
				, UR.RecruitedById AS recruitedById
				, UR.GPEmployeeId AS gPEmployeeId
				, UR.GPEmployeeId AS companyId
				, UR.RecruitedByDate AS recruitedByDate
				, UR.FullName AS fullName
				, UR.PublicFullName AS publicFullName
				, UR.SSN AS sSN
				, UR.FirstName AS firstName
				, UR.MiddleName AS middleName
				, UR.LastName AS lastName
				, UR.PreferredName AS preferredName
				, UR.CompanyName AS companyName
				, UR.MaritalStatus AS maritalStatus
				, UR.SpouseName AS spouseName
				, UR.UserName AS userName
				, UR.[Password] AS [password]
				, UR.BirthDate AS birthDate
				, UR.HomeTown AS homeTown
				, UR.BirthCity AS birthCity
				, UR.BirthState AS birthState
				, UR.BirthCountry AS birthCountry
				, UR.Sex AS sex
				, UR.ShirtSize AS shirtSize
				, UR.HatSize AS hatSize
				, UR.DLNumber AS dLNumber
				, UR.DLState AS dLState
				, UR.DLCountry AS dLCountry
				, UR.DLExpiresOn AS dLExpiresOn
				, UR.DLExpiration AS dLExpiration
				, UR.Height AS height
				, UR.[Weight] AS [weight]
				, UR.EyeColor AS eyeColor
				, UR.HairColor AS hairColor
				, UR.PhoneHome AS phoneHome
				, UR.PhoneCell AS phoneCell
				, UR.PhoneCellCarrierID AS phoneCellCarrierID
				, UR.PhoneFax AS phoneFax
				, UR.Email AS email
				, UR.CorporateEmail AS corporateEmail
				, UR.TreeLevel AS treeLevel
				, UR.HasVerifiedAddress AS hasVerifiedAddress
				, UR.RightToWorkExpirationDate AS rightToWorkExpirationDate
				, UR.RightToWorkNotes AS rightToWorkNotes
				, UR.RightToWorkStatusID AS rightToWorkStatusID
				, UR.IsLocked AS isLocked
				, UR.IsActive AS isActive
				, UR.IsDeleted AS isDeleted
				, UR.ModifiedDate AS modifiedDate
				, UR.ModifiedById AS modifiedById
				, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](UR.ModifiedById), '$') AS modifiedBy
				, UR.CreatedDate AS createdDate
				, UR.CreatedById AS createdById
				, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](UR.CreatedById), '$') AS createdBy
		FROM
			[RSU].[UserResources] AS UR WITH(NOLOCK)
		WHERE
				(UR.UserResourceID = @UserResourceId)
		FOR JSON PATH, INCLUDE_NULL_VALUES);

			/** FIX RESULT */
			SET @Result = SUBSTRING(@Result, 2, LEN(@Result) - 2);

			/** RETURN RESULT */
			SELECT @Result AS JsonOutPutMethod;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
