DROP PROCEDURE IF EXISTS [RSU].[spUserResourceAvatarSaveJson];
GO

-- Batch submitted through debugger: spUserResourceAvatarSaveJson.sql|16|0|C:\CodeBaseNVL9\Nuvol9-Services\Databases\Nuvol9.Database.Main\Nuvol9.Database.Main\Scripts\STORED_PROCEDURES\RSU\spUserResourceAvatarSaveJson.sql
/******************************************************************************
**		File: spUserResourceAvatarSaveJson.sql
**		Name: spUserResourceAvatarSaveJson
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
CREATE   Procedure [RSU].[spUserResourceAvatarSaveJson]
(
	@JsonInput NVARCHAR(MAX)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();

	BEGIN TRY
		/** LOCALS */
		DECLARE @UserResourceImageID INT, @UserResourceId INT, @ImageTypeId VARCHAR(20), @Size INT, @FileName NVARCHAR(500), @Image NVARCHAR(MAX), @IsActive BIT;
		SELECT
			@UserResourceImageID = RT.UserResourceImageID
			, @UserResourceId = RT.UserResourceId
			, @ImageTypeId = RT.ImageTypeId
			, @Size = RT.Size
			, @FileName = RT.FileName
			, @Image = RT.Image
			, @IsActive = RT.IsActive
		FROM 
			OPENJSON(@JsonInput, '$')
		WITH (
			UserResourceImageID INT '$.id'
			, UserResourceId INT '$.userResourceId'
			, ImageTypeId VARCHAR(20) '$.imageTypeId'
			, Size INT '$.size'
			, [FileName] NVARCHAR(500) '$.fileName'
			, [Image] NVARCHAR(MAX) '$.image'
			, IsActive BIT '$.isActive'
		) AS RT;

		/** SECURITY CHECK */
		IF (NOT EXISTS(SELECT TOP(1) 1 FROM [RSU].[UserResources] WHERE DealerId = @DealerId AND UserResourceID = @UserResourceId)) BEGIN
			RAISERROR(N'[30050]:SECURITY VIOLATION:  You do not have access to these resources.', 18, 1);
			RETURN -1;
		END

		/** CHECK IF THIS IS an UPDATE Or CREATE */
		IF (@UserResourceImageID IS NULL) BEGIN
			PRINT 'CREATING...';
			INSERT INTO [RSU].[UserResourceImages] (
				[ImageTypeId]
				, [UserResourceId]
				, [Size]
				, [FileName]
				, [Image]
				, [IsActive]
				, [ModifiedById]
				, [CreatedById]
			) VALUES (
				@ImageTypeId -- varchar(20)
				, @UserResourceId -- int
				, @Size -- int
				, @FileName -- nvarchar(500)
				, @Image -- varbinary(max)
				, @IsActive
				, @UserID
				, @UserID
			);
			SET @UserResourceImageID = SCOPE_IDENTITY();
		END ELSE BEGIN
			PRINT 'UPDATING...';
			UPDATE URI SET
				URI.ImageTypeId = @ImageTypeId -- varchar(20)
				, URI.UserResourceId = @UserResourceId -- int
				, URI.Size = @Size -- int
				, URI.FileName = @FileName -- nvarchar(500)
				, URI.Image = @Image -- varbinary(max)
				, URI.IsActive = @IsActive
				, URI.ModifiedDate = SYSDATETIMEOFFSET()
				, URI.ModifiedById = @UserID
			FROM
				[RSU].[UserResourceImages] AS URI WITH(NOLOCK)
			WHERE
				(URI.UserResourceImageID = @UserResourceImageID);
		END;

		/** Return result */
		DECLARE @Result NVARCHAR(MAX);
		SELECT @Result = (
			SELECT 
				URI.UserResourceImageID AS id
				, URI.UserResourceId AS userResourceId
				, URI.ImageTypeId AS imageTypeId
				, URI.Size AS size
				, URI.[FileName] AS [fileName]
				, URI.IsActive AS isActive
				, URI.IsDeleted AS isDeleted
				, URI.ModifiedDate AS modifiedDate
				, URI.ModifiedById AS modifiedById
				, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URI.ModifiedById), '$') AS modifiedBy
				, URI.CreatedDate AS createdDate
				, URI.CreatedById AS createdById
				, JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URI.CreatedById), '$') AS createdBy
				, URI.[Image] AS [image]
			FROM
				[RSU].[UserResourceImages] AS URI WITH(NOLOCK)
			WHERE
				(URI.UserResourceImageID = @UserResourceImageID)
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
