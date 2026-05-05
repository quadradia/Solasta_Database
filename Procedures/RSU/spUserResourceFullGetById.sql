DROP PROCEDURE IF EXISTS [RSU].[spUserResourceFullGetById];
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
**		Date: 04/21/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	04/21/2017	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceFullGetById]
    (
    @UserResourceId INT = NULL
)
AS
BEGIN
    /** SET NO COUNTING */
    SET NOCOUNT ON

    /** DECLARATIONS */
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50);
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked
    FROM [ACC].[fxGetContextUserTable]();

    BEGIN TRY
		-- ** STATEMENT
		SELECT
        RU.UserResourceID
            , RU.DealerTenantId
            , RU.UserId
            , RU.UserEmployeeTypeId
			, UET.UserEmployeeTypeName
            , RU.UserResourceAddressId
            , RU.RecruitedById
            , RU.GPEmployeeId
            , RU.RecruitedByDate
            , RU.FullName
            , RU.PublicFullName
            , RU.SSN
            , RU.FirstName
            , RU.MiddleName
            , RU.LastName
            , RU.PreferredName
            , RU.CompanyName
            , RU.MaritalStatus
            , RU.SpouseName
            , RU.UserName
            , RU.[Password]
            , RU.BirthDate
            , RU.HomeTown
            , RU.BirthCity
            , RU.BirthState
            , RU.BirthCountry
            , RU.Sex
            , RU.ShirtSize
            , RU.HatSize
            , RU.DLNumber
            , RU.DLState
            , RU.DLCountry
            , RU.DLExpiresOn
            , RU.DLExpiration
            , RU.Height
            , RU.[Weight]
            , RU.EyeColor
            , RU.HairColor
            , RU.PhoneHome
            , RU.PhoneCell
            , RU.PhoneCellCarrierID
            , RU.PhoneFax
            , RU.Email
            , RU.CorporateEmail
            , RU.TreeLevel
            , RU.HasVerifiedAddress
            , RU.RightToWorkExpirationDate
            , RU.RightToWorkNotes
            , RU.RightToWorkStatusID
            , RU.IsLocked
            , RU.IsActive
    FROM
        [RSU].[UserResources] AS RU WITH(NOLOCK)
        INNER JOIN [RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
        ON
				(UET.UserEmployeeTypeID = RU.UserEmployeeTypeId)
    WHERE
			(RU.UserResourceID = @UserResourceId)
        AND (RU.IsDeleted = 'False');

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
