DROP PROCEDURE IF EXISTS [RSU].[spUserResourceAvatarGetJson];
GO

/******************************************************************************
**		File: spUserResourceAvatarGetJson.sql
**		Name: spUserResourceAvatarGetJson
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
**		Date: 03/29/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	03/29/2018	AndrÃ©s Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [RSU].[spUserResourceAvatarGetJson]
(
	@UserResourceID INT
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();

	BEGIN TRY
		/** SECURITY CHECK */
		IF (NOT EXISTS(SELECT TOP(1) 1 FROM [RSU].[UserResources] WHERE UserResourceID = @UserResourceID AND DealerId IN (SELECT DealerId FROM [CNS].[fxGroupMasterDealersTo2000](@DealerId)))) BEGIN
			RAISERROR(N'[30050]:SECURITY VIOLATION:  You do not have access to these resources.', 18, 1);
			RETURN -1;
		END

		/** LOCALS */
		DECLARE @DefaultTable TABLE (
			[UserResourceImageID] [INT] NOT NULL
			, [UserResourceId] [INT] NOT NULL
			, [ImageTypeId] [VARCHAR](20) NOT NULL
			, [Size] [INT] NOT NULL
			, [FileName] [NVARCHAR](500) NOT NULL
			, [Image] [NVARCHAR](MAX) NOT NULL
			, [IsActive] [BIT] NOT NULL
			, [IsDeleted] [BIT] NOT NULL
			, [ModifiedDate] [DATETIMEOFFSET](7) NOT NULL
			, [ModifiedById] [UNIQUEIDENTIFIER] NOT NULL
			, [CreatedDate] [DATETIMEOFFSET](7) NOT NULL
			, [CreatedById] [UNIQUEIDENTIFIER] NOT NULL);
		INSERT INTO @DefaultTable (
			[UserResourceImageID]
			, [UserResourceId]
			, [ImageTypeId]
			, [Size]
			, [FileName]
			, [Image]
			, [IsActive]
			, [IsDeleted]
			, [ModifiedDate]
			, [ModifiedById]
			, [CreatedDate]
			, [CreatedById])
		VALUES ( 
			0 --@UserResourceImageID -- int
			, @UserResourceId -- int
			, 'AVATAR' -- @ImageTypeId -- varchar(20)
			, 156000 -- @Size -- int
			, 'avatar.jpeg' -- @FileName -- nvarchar(500)
			, '/img/avatar.jpeg' -- @Image -- nvarchar(max)
			, 'True' -- @IsActive -- bit
			, 'False' -- @IsDeleted -- bit
			, SYSDATETIMEOFFSET() -- @ModifiedDate -- datetimeoffset(7)
			, 'E6872B58-52B2-415C-A32B-45805F95A70A' -- @ModifiedById -- uniqueidentifier
			, SYSDATETIMEOFFSET() -- @CreatedDate -- datetimeoffset(7)
			, 'E6872B58-52B2-415C-A32B-45805F95A70A' -- @CreatedById -- uniqueidentifier
		);

		/** Return result */
		DECLARE @Result NVARCHAR(MAX), @UserResource NVARCHAR(MAX);
		SELECT @UserResource = (SELECT * FROM [ACC].[fxGetUserInfoByUserResourceIdJSONTABLE](@UserResourceID) FOR JSON PATH, INCLUDE_NULL_VALUES);
		SET @UserResource = SUBSTRING(@UserResource, 2, LEN(@UserResource) - 2);
		SELECT @Result = (
			SELECT TOP (1)
				ISNULL(URI.UserResourceImageID, RT.UserResourceImageID) AS id
				, URI.UserResourceId AS userResourceId
				, JSON_QUERY(@UserResource, '$') AS userResource
				, ISNULL(URI.ImageTypeId, RT.ImageTypeId) AS imageTypeId
				, ISNULL(URI.Size, RT.Size) AS size
				, ISNULL(URI.[FileName], RT.[FileName]) AS [fileName]
				, ISNULL(URI.IsActive, RT.IsActive) AS isActive
				, ISNULL(URI.IsDeleted, RT.IsDeleted) AS isDeleted
				, ISNULL(URI.ModifiedDate, RT.ModifiedDate) AS modifiedDate
				, ISNULL(URI.ModifiedById, RT.ModifiedById) AS modifiedById
				, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URI.ModifiedById), '$') AS modifiedBy
				, ISNULL(URI.CreatedDate, RT.CreatedDate) AS createdDate
				, ISNULL(URI.CreatedById, RT.CreatedById) AS createdById
				, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URI.CreatedById), '$') AS createdBy
				, ISNULL(URI.[Image], RT.[Image]) AS [image]
			FROM
				@DefaultTable AS RT
				LEFT OUTER JOIN [RSU].[UserResourceImages] AS URI WITH(NOLOCK)
				ON
					(URI.UserResourceId = RT.UserResourceId)
			WHERE
				(RT.UserResourceId = @UserResourceID)
				AND (URI.IsDeleted = 'False' OR (URI.IsDeleted IS NULL AND RT.IsDeleted = 'False'))
				AND (URI.IsActive = 'True' OR (URI.IsActive IS NULL AND RT.IsActive = 'True'))
			ORDER BY
				URI.UserResourceImageID
			FOR JSON PATH, INCLUDE_NULL_VALUES);

		/** Fixt to object */
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
