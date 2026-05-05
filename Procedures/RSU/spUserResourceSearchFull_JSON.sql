DROP PROCEDURE IF EXISTS [RSU].[spUserResourceSearchFull_JSON];
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
**		Date: 04/14/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	04/14/2018	Andres Sosa		Created By
**
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceSearchFull_JSON]
	(
	@JsonInput NVARCHAR(MAX)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerTenantId
	FROM [ACC].[fxGetContextUserTable]();

	/** BUILD ARGS */
	DECLARE @PhoneNumber VARCHAR(20) = NULL
	, @FirstName NVARCHAR(50) = NULL
	, @LastName NVARCHAR(50) = NULL
	, @Email NVARCHAR(100) = NULL
	, @Street NVARCHAR(50) = NULL
	, @UserResourceId INT = NULL;

	/** Acquire Args */
	SELECT
		@PhoneNumber = [UTL].[fxRemovePhoneDecorations](PhoneNumber)
        , @FirstName = FirstName
        , @LastName = LastName
        , @Email = Email
        , @Street = Street
        , @UserResourceId = UserResourceId
	FROM
		OPENJSON(@JsonInput, '$.args')
	WITH (
		PhoneNumber VARCHAR(20) '$.phoneNumber'
		, FirstName NVARCHAR(50) '$.firstName'
		, LastName NVARCHAR(50) '$.lastName'
		, Email NVARCHAR(100) '$.email'
		, Street NVARCHAR(50) '$.street'
		, UserResourceId INT '$.userResourceId'
	);

	/** CHECK VALUES */
	IF (LTRIM(RTRIM(@PhoneNumber)) = '') BEGIN
		SET @PhoneNumber = NULL;
	END;
	IF (LTRIM(RTRIM(@FirstName)) = '') BEGIN
		SET @FirstName = NULL;
	END;
	IF (LTRIM(RTRIM(@LastName)) = '') BEGIN
		SET @LastName = NULL;
	END;
	IF (LTRIM(RTRIM(@Email)) = '') BEGIN
		SET @Email = NULL;
	END;
	IF (LTRIM(RTRIM(@Street)) = '') BEGIN
		SET @Street = NULL;
	END;

	/** Acquire Paging */
	DECLARE  @OffsetValue INT = 0
		, @TotalRows INT
		, @PageSize INT
		, @PageNumber INT
		, @Pages INT;
	SELECT
		@TotalRows = TotalRows
		, @PageSize = PageSize
		, @PageNumber = PageNumber
		, @Pages = Pages
	FROM
		OPENJSON(@JsonInput, '$.pagingInfo')
	WITH (
		TotalRows INT '$.totalRows'
		, PageSize INT '$.pageSize'
		, PageNumber INT '$.pageNumber'
		, Pages INT '$.pages'
	);

	/** INITIALIZE PAGING */
	PRINT '@PageSize: ' + CAST(@PageSize AS VARCHAR(20)) + ' | @PageNumber: ' + CAST(@PageNumber AS VARCHAR(20)) + ' | @OffsetValue: ' + CAST(@OffsetValue AS VARCHAR(20));
	EXEC [UTL].[spPagingCalculateOffset] @PageSize=@PageSize OUTPUT, @PageNumber=@PageNumber OUTPUT, @OffsetValue=@OffsetValue OUTPUT;
	PRINT '@PageSize: ' + CAST(@PageSize AS VARCHAR(20)) + ' | @PageNumber: ' + CAST(@PageNumber AS VARCHAR(20)) + ' | @OffsetValue: ' + CAST(@OffsetValue AS VARCHAR(20));

	/** BUILD QUERY */
	DECLARE @Result NVARCHAR(MAX);
	WITH
		RootCTE
		AS
		(
			SELECT
				RSU.*
			--, ROW_NUMBER() OVER (PARTITION BY RSU.ID ORDER BY RSU.ID) AS Rwn
			FROM
				[RSU].[vwUserResourceFullSearchDataSet] AS RSU WITH(NOLOCK)
				LEFT OUTER JOIN [ACC].[Users] AS U WITH(NOLOCK)
				ON
				(U.UserID = RSU.UserId)
				LEFT OUTER JOIN [RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
				ON
				(URA.UserResourceAddressID = RSU.UserResourceAddressId)
			WHERE
			(RSU.DealerTenantId IN (SELECT DealerTenantId
				FROM [CNS].[fxGroupMasterDealersTo2000](@DealerId)))
				AND ((@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](RSU.PhoneHome) = @PhoneNumber)
				OR (@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](RSU.PhoneCell) = @PhoneNumber)
				OR (@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](U.PhoneNumber) = @PhoneNumber))
				AND (@FirstName IS NULL OR RSU.FirstName LIKE @FirstName + '%')
				AND (@LastName IS NULL OR RSU.LastName LIKE @LastName + '%')
				AND (@Email IS NULL OR RSU.Email LIKE @Email + '%')
				AND (@Street IS NULL OR URA.StreetAddress LIKE @Street +'%')
				AND (@UserResourceId IS NULL OR RSU.Id = @UserResourceId)
				AND (/*U.IsActive = 'True' AND */U.IsDeleted = 'False')
		),
		TotalCountCTE
		AS
		(
			SELECT COUNT(*) AS TotalRows
			FROM RootCTE
		),
		ResourceInfoCTE
		AS
		(
			SELECT
				RT.ID AS id
            , RT.DealerTenantId AS dealerId
            , RT.UserId AS userId
            , RT.UserResourceAddressId AS userResourceAddressId
            , RT.UserEmployeeTypeId AS userEmployeeTypeId
            , RT.UserEmployeeTypeName AS userEmployeeTypeName
            , RT.RecruitedById AS recruitedById
            , RT.CompanyId AS companyId
            , RT.RecruitedOn AS recruitedOn
            , RT.FullName AS fullName
            , RT.PublicFullName AS publicFullName
            , RT.SSN AS sSN
            , RT.FirstName AS firstName
            , RT.MiddleName AS middleName
            , RT.LastName AS lastName
            , RT.PreferredName AS preferredName
            , RT.CompanyName AS companyName
            , RT.MaritalStatus AS maritalStatus
            , RT.SpouseName AS spouseName
            , RT.UserName AS userName
            , RT.Password AS password
            , RT.BirthDate AS birthDate
            , RT.HomeTown AS homeTown
            , RT.BirthCity AS birthCity
            , RT.BirthState AS birthState
            , RT.BirthCountry AS birthCountry
            , RT.Sex AS sex
            , RT.ShirtSize AS shirtSize
            , RT.HatSize AS hatSize
            , RT.DLNumber AS dLNumber
            , RT.DLState AS dLState
            , RT.DLCountry AS dLCountry
            , RT.DLExpiresOn AS dLExpiresOn
            , RT.DLExpiration AS dLExpiration
            , RT.Height AS height
            , RT.Weight AS weight
            , RT.EyeColor AS eyeColor
            , RT.HairColor AS hairColor
            , RT.PhoneHome AS phoneHome
            , RT.PhoneCell AS phoneCell
            , RT.PhoneFax AS phoneFax
            , RT.Email AS email
            , RT.StreetAddress AS streetAddress
            , RT.City AS city
            , RT.PoliticalStateId AS politicalStateId
            , RT.PostalCode AS postalCode
            , RT.CorporateEmail AS corporateEmail
            , RT.TreeLevel AS treeLevel
            , RT.HasVerifiedAddress AS hasVerifiedAddress
            , RT.RightToWorkExpirationDate AS rightToWorkExpirationDate
            , RT.RightToWorkNotes AS rightToWorkNotes
            , RT.RightToWorkStatusID AS rightToWorkStatusID
            , RT.IsLocked AS isLocked
            , RT.IsActive AS isActive
			FROM
				RootCTE AS RT WITH(NOLOCK)
			ORDER BY
			RT.FullName
		OFFSET @OffsetValue ROWS
		FETCH NEXT @PageSize ROWS ONLY
		)
	-- SELECT * FROM ResourceInfoCTE;
	SELECT
		@Result = (SELECT *
		FROM ResourceInfoCTE
		FOR JSON PATH, INCLUDE_NULL_VALUES)
		, @TotalRows = (SELECT TOP(1)
			TotalCountCTE.TotalRows
		FROM TotalCountCTE
		ORDER BY TotalCountCTE.TotalRows);

	/** INIT DATA */
	DECLARE @TotalPages INT = @TotalRows / @PageSize
			, @Reminder INT =  @TotalRows % @PageSize;

	IF (@Reminder > 0) SET @TotalPages = @TotalPages + 1;

	/** DISPLAY Pageing Info */
	DECLARE @Totals NVARCHAR(MAX) = (
			SELECT
		@TotalPages AS totalPages
				, @PageSize AS pageSize
				, @PageNumber AS pageNumber
				, @TotalRows AS totalRows
	FOR JSON PATH, INCLUDE_NULL_VALUES);
	SET @Totals = SUBSTRING(@Totals, 2, LEN(@Totals) - 2);

	/** RETURN RESULT */
	SELECT @Result = (
			SELECT
			JSON_QUERY(@Totals, '$') AS pagingInfo
				, JSON_QUERY(@Result, '$') AS resultSet
		FOR JSON PATH, INCLUDE_NULL_VALUES);

	/** FIX RESULT */
	SET @Result = SUBSTRING(@Result, 2, LEN(@Result) - 2);
	SELECT @Result AS JsonOutPutMethod;

END

GO
