-- ##### SQL_SCALAR_FUNCTION INE.fxGetAdHocRandomBarcodeId
/******************************************************************************
**		File: fxGetAdHocRandomBarcodeId.sql
**		Name: fxGetAdHocRandomBarcodeId
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andrés E. Sosa
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	07/10/2017	Andrés E. Sosa	Created By
**	
*******************************************************************************/
CREATE FUNCTION [INE].[fxGetAdHocRandomBarcodeId] (
	@DealerId INT
)
RETURNS NVARCHAR(60)
AS
BEGIN
	/** LOCALS */
	DECLARE @Result NVARCHAR(60);

	SELECT @Result = 'ADHC-' + [UTL].fxGetAlphaNumericRandom(39) + '|' + CAST(@DealerId AS NVARCHAR(20));

	/** Result */
	RETURN @Result;
END

GO
-- ##### SQL_SCALAR_FUNCTION INE.fxGetPurchaseOrderAsJson
/******************************************************************************
**		File: fxGetPurchaseOrderAsJson.sql
**		Name: fxGetPurchaseOrderAsJson
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andrés E. Sosa
**		Date: 08/28/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	08/28/2017	Andrés E. Sosa	Created By
**	
*******************************************************************************/
CREATE FUNCTION INE.fxGetPurchaseOrderAsJson (
	@PurchaseOrderID BIGINT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	/** LOCALS */
	RETURN (
	SELECT TOP 1 
		@PurchaseOrderID AS id
		, PO.PurchaseOrderID AS purchaseOrderID
		, PO.DealerId AS dealerId
		, PO.VendorId AS vendorId
		, V.VendorName AS vendorName
		, PO.WarehouseSiteId AS warehouseSiteId
		, WS.WarehouseSiteName AS warehouseSiteName
		, PO.AttentionLine AS attentionLine
		, PO.GPPONumber AS gPPONumber
		, PO.VendorRefNumber AS vendorRefNumber
		, PO.CreditTerms AS creditTerms
		, PO.SubTotal AS subTotal
		, PO.Tax AS tax
		, PO.Total AS total
		, PO.SubmittedDate AS submittedDate
		, PO.CompletedDate AS completedDate
		, PO.Comments AS comments
		, PO.IsActive AS isActive
		, PO.ModifiedDate AS modifiedDate
		, MDU.UserID AS [modifidedBy.id]
		, MDU.FullName AS [modifidedBy.fullName]
		, MDU.FullNameWithGPID AS [modifidedBy.fullNameWithGPID]
		, PO.CreatedDate AS createdDate
		, CDU.UserID AS [createdBy.id]
		, CDU.FullName AS [createdBy.fullName]
		, CDU.FullNameWithGPID AS [createdBy.fullNameWithGPID]
	FROM
		[INE].[PurchaseOrders] AS PO WITH(NOLOCK)
		INNER JOIN [INE].[Vendors] AS V WITH(NOLOCK)
		ON
			(@PurchaseOrderID = PO.PurchaseOrderID)
			AND (V.VendorID = PO.VendorId)
		INNER JOIN [INE].[WarehouseSites] AS WS WITH(NOLOCK)
		ON
			(WS.WarehouseSiteID = PO.WarehouseSiteId)
		INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS MDU 
		ON
			(MDU.UserID = PO.ModifiedById)
		INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS CDU
		ON
			(CDU.UserID = PO.CreatedById)

	FOR JSON PATH);
END

GO
-- ##### SQL_SCALAR_FUNCTION INE.fxGetPurchaseOrderItemAsJson
/******************************************************************************
**		File: fxGetPurchaseOrderItemAsJson.sql
**		Name: fxGetPurchaseOrderItemAsJson
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andrés E. Sosa
**		Date: 08/28/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	08/28/2017	Andrés E. Sosa	Created By
**	
*******************************************************************************/
CREATE FUNCTION INE.fxGetPurchaseOrderItemAsJson (
	@PurchaseOrderItemID BIGINT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	/** LOCALS */
	RETURN (
	SELECT TOP 1 
		@PurchaseOrderItemID AS id
		, POI.PurchaseOrderItemID AS purchaseOrderItemID
		, POI.PurchaseOrderId AS purchaseOrderId
		, POI.WarehouseSiteId AS warehouseSiteId
		, WS.WarehouseSiteName AS warehouseSiteName
		, POI.Quantity AS quantity
		, POI.IsActive AS isActive
		, POI.ModifiedDate AS modifiedDate
		, MDU.UserID AS [modifidedBy.id]
		, MDU.FullName AS [modifidedBy.fullName]
		, MDU.FullNameWithGPID AS [modifidedBy.fullNameWithGPID]
		, POI.CreatedDate AS createdDate
		, CDU.UserID AS [createdBy.id]
		, CDU.FullName AS [createdBy.fullName]
		, CDU.FullNameWithGPID AS [createdBy.fullNameWithGPID]
	FROM
		[INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
		INNER JOIN [INE].[WarehouseSites] AS WS WITH(NOLOCK)
		ON
			(POI.PurchaseOrderItemID = @PurchaseOrderItemID)
			AND (WS.WarehouseSiteID = POI.WarehouseSiteId)
		INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS MDU 
		ON
			(MDU.UserID = POI.ModifiedById)
		INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS CDU
		ON
			(CDU.UserID = POI.CreatedById)

	FOR JSON PATH);
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_Audits_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_Audits_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[Audits]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_Audits_CREATE]
(
		@LocationTypeId VARCHAR(20)
		, @LocationIdentifier VARCHAR(20)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @AuditID BIGINT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','Audits') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','Audits') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[Audits]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.Audits (
		[LocationTypeId]
		, [LocationIdentifier]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@LocationTypeId
		, @LocationIdentifier
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.Audits
		WHERE
		(AuditID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_Audits_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_Audits_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[Audits]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_Audits_DELETE]
(
	@AuditID bigint
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','Audits') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','Audits') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[Audits]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.Audits SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(AuditID = @AuditID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.Audits
	 WHERE
		(AuditID = @AuditID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_Audits_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_Audits_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[Audits]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_Audits_UPDATE]
(
		@AuditID BIGINT		
		, @LocationTypeId VARCHAR(20)		
		, @LocationIdentifier VARCHAR(20)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','Audits') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','Audits') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[Audits]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.Audits SET
		[LocationTypeId] = @LocationTypeId
		, [LocationIdentifier] = @LocationIdentifier
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(AuditID = @AuditID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.Audits
	 WHERE
		(AuditID = @AuditID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_LocationTypes_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_LocationTypes_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[LocationTypes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_LocationTypes_CREATE]
(
		
		@LocationTypeID VARCHAR(20)
		, @LocationTypeName NVARCHAR(50)
		, @TableName NVARCHAR(60)
		, @FieldID NVARCHAR(60)
		, @FieldName NVARCHAR(60)
		, @SqlStmt NVARCHAR(MAX)
		, @Comment NVARCHAR(MAX)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','LocationTypes') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','LocationTypes') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[LocationTypes]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.LocationTypes (
		[LocationTypeID]
		, [LocationTypeName]
		, [TableName]
		, [FieldID]
		, [FieldName]
		, [SqlStmt]
		, [Comment]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@LocationTypeID
		, @LocationTypeName
		, @TableName
		, @FieldID
		, @FieldName
		, @SqlStmt
		, @Comment
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.LocationTypes
		WHERE
		(LocationTypeID = @LocationTypeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_LocationTypes_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_LocationTypes_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[LocationTypes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_LocationTypes_DELETE]
(
	@LocationTypeID varchar(20)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','LocationTypes') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','LocationTypes') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[LocationTypes]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.LocationTypes SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(LocationTypeID = @LocationTypeID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.LocationTypes
	 WHERE
		(LocationTypeID = @LocationTypeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_LocationTypes_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_LocationTypes_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[LocationTypes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_LocationTypes_UPDATE]
(
		@LocationTypeID VARCHAR(20)		
		, @LocationTypeName NVARCHAR(50)		
		, @TableName NVARCHAR(60)		
		, @FieldID NVARCHAR(60)		
		, @FieldName NVARCHAR(60)		
		, @SqlStmt NVARCHAR(MAX)		
		, @Comment NVARCHAR(MAX)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','LocationTypes') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','LocationTypes') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[LocationTypes]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.LocationTypes SET
		[LocationTypeName] = @LocationTypeName
		, [TableName] = @TableName
		, [FieldID] = @FieldID
		, [FieldName] = @FieldName
		, [SqlStmt] = @SqlStmt
		, [Comment] = @Comment
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(LocationTypeID = @LocationTypeID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.LocationTypes
	 WHERE
		(LocationTypeID = @LocationTypeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PackingSlipItems_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PackingSlipItems_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PackingSlipItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PackingSlipItems_CREATE]
(
		@PackingSlipId BIGINT
		, @PurchaseOrderItemId BIGINT
		, @ProductSkwId BIGINT
		, @Quantity INT
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @PackingSlipItemID BIGINT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','PackingSlipItems') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','PackingSlipItems') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PackingSlipItems]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.PackingSlipItems (
		[PackingSlipId]
		, [PurchaseOrderItemId]
		, [ProductSkwId]
		, [Quantity]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@PackingSlipId
		, @PurchaseOrderItemId
		, @ProductSkwId
		, @Quantity
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.PackingSlipItems
		WHERE
		(PackingSlipItemID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PackingSlipItems_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PackingSlipItems_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PackingSlipItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PackingSlipItems_DELETE]
(
	@PackingSlipItemID bigint
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','PackingSlipItems') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','PackingSlipItems') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PackingSlipItems]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PackingSlipItems SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(PackingSlipItemID = @PackingSlipItemID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PackingSlipItems
	 WHERE
		(PackingSlipItemID = @PackingSlipItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PackingSlipItems_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PackingSlipItems_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[PackingSlipItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PackingSlipItems_UPDATE]
(
		@PackingSlipItemID BIGINT		
		, @PackingSlipId BIGINT		
		, @PurchaseOrderItemId BIGINT		
		, @ProductSkwId BIGINT		
		, @Quantity INT		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','PackingSlipItems') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','PackingSlipItems') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PackingSlipItems]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PackingSlipItems SET
		[PackingSlipId] = @PackingSlipId
		, [PurchaseOrderItemId] = @PurchaseOrderItemId
		, [ProductSkwId] = @ProductSkwId
		, [Quantity] = @Quantity
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(PackingSlipItemID = @PackingSlipItemID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PackingSlipItems
	 WHERE
		(PackingSlipItemID = @PackingSlipItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PackingSlips_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PackingSlips_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PackingSlips]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PackingSlips_CREATE]
(
		@DealerId INT
		, @PurchaseOrderId BIGINT
		, @ArrivalDate DATETIMEOFFSET
		, @CloseDate DATETIMEOFFSET
		, @PackingSlipNumber NVARCHAR(25)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @PackingSlipID BIGINT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','PackingSlips') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','PackingSlips') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PackingSlips]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.PackingSlips (
		[DealerId]
		, [PurchaseOrderId]
		, [ArrivalDate]
		, [CloseDate]
		, [PackingSlipNumber]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@DealerId
		, @PurchaseOrderId
		, @ArrivalDate
		, @CloseDate
		, @PackingSlipNumber
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.PackingSlips
		WHERE
		(PackingSlipID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PackingSlips_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PackingSlips_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PackingSlips]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PackingSlips_DELETE]
(
	@PackingSlipID bigint
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','PackingSlips') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','PackingSlips') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PackingSlips]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PackingSlips SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(PackingSlipID = @PackingSlipID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PackingSlips
	 WHERE
		(PackingSlipID = @PackingSlipID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PackingSlips_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PackingSlips_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[PackingSlips]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PackingSlips_UPDATE]
(
		@PackingSlipID BIGINT		
		, @DealerId INT		
		, @PurchaseOrderId BIGINT		
		, @ArrivalDate DATETIMEOFFSET		
		, @CloseDate DATETIMEOFFSET		
		, @PackingSlipNumber NVARCHAR(25)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','PackingSlips') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','PackingSlips') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PackingSlips]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PackingSlips SET
		[DealerId] = @DealerId
		, [PurchaseOrderId] = @PurchaseOrderId
		, [ArrivalDate] = @ArrivalDate
		, [CloseDate] = @CloseDate
		, [PackingSlipNumber] = @PackingSlipNumber
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(PackingSlipID = @PackingSlipID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PackingSlips
	 WHERE
		(PackingSlipID = @PackingSlipID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeBundles_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeBundles_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodeBundles]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeBundles_CREATE]
(
		
		@ProductBarcodeBundleID NVARCHAR(50)
		, @ProductBarcodeId NVARCHAR(60)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodeBundles') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodeBundles') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeBundles]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.ProductBarcodeBundles (
		[ProductBarcodeBundleID]
		, [ProductBarcodeId]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ProductBarcodeBundleID
		, @ProductBarcodeId
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeBundles
		WHERE
		(ProductBarcodeBundleID = @ProductBarcodeBundleID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeBundles_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeBundles_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodeBundles]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeBundles_DELETE]
(
	@ProductBarcodeBundleID nvarchar(50)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodeBundles') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodeBundles') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeBundles]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodeBundles SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(ProductBarcodeBundleID = @ProductBarcodeBundleID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeBundles
	 WHERE
		(ProductBarcodeBundleID = @ProductBarcodeBundleID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeBundles_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeBundles_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[ProductBarcodeBundles]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeBundles_UPDATE]
(
		@ProductBarcodeBundleID NVARCHAR(50)		
		, @ProductBarcodeId NVARCHAR(60)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodeBundles') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodeBundles') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeBundles]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodeBundles SET
		[ProductBarcodeId] = @ProductBarcodeId
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(ProductBarcodeBundleID = @ProductBarcodeBundleID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeBundles
	 WHERE
		(ProductBarcodeBundleID = @ProductBarcodeBundleID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodes_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodes_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodes_CREATE]
(
		
		@ProductBarcodeID NVARCHAR(60)
		, @DealerId INT
		, @PurchaseOrderItemId BIGINT
		, @PackingSlipItemId BIGINT
		, @LastProductBarcodeTrackingId BIGINT
		, @ProductBarcodeBundleId NVARCHAR(50)
		, @SimGUID VARCHAR(50)
		, @BarcodeNumber NVARCHAR(50)
		, @IsAdHoc BIT
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodes') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodes') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodes]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.ProductBarcodes (
		[ProductBarcodeID]
		, [DealerId]
		, [PurchaseOrderItemId]
		, [PackingSlipItemId]
		, [LastProductBarcodeTrackingId]
		, [ProductBarcodeBundleId]
		, [SimGUID]
		, [BarcodeNumber]
		, [IsAdHoc]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ProductBarcodeID
		, @DealerId
		, @PurchaseOrderItemId
		, @PackingSlipItemId
		, @LastProductBarcodeTrackingId
		, @ProductBarcodeBundleId
		, @SimGUID
		, @BarcodeNumber
		, @IsAdHoc
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodes
		WHERE
		(ProductBarcodeID = @ProductBarcodeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodes_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodes_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodes_DELETE]
(
	@ProductBarcodeID nvarchar(60)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodes') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodes') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodes]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodes SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(ProductBarcodeID = @ProductBarcodeID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodes
	 WHERE
		(ProductBarcodeID = @ProductBarcodeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodes_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodes_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[ProductBarcodes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodes_UPDATE]
(
		@ProductBarcodeID NVARCHAR(60)		
		, @DealerId INT		
		, @PurchaseOrderItemId BIGINT		
		, @PackingSlipItemId BIGINT		
		, @LastProductBarcodeTrackingId BIGINT		
		, @ProductBarcodeBundleId NVARCHAR(50)		
		, @SimGUID VARCHAR(50)		
		, @BarcodeNumber NVARCHAR(50)		
		, @IsAdHoc BIT		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodes') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodes') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodes]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodes SET
		[DealerId] = @DealerId
		, [PurchaseOrderItemId] = @PurchaseOrderItemId
		, [PackingSlipItemId] = @PackingSlipItemId
		, [LastProductBarcodeTrackingId] = @LastProductBarcodeTrackingId
		, [ProductBarcodeBundleId] = @ProductBarcodeBundleId
		, [SimGUID] = @SimGUID
		, [BarcodeNumber] = @BarcodeNumber
		, [IsAdHoc] = @IsAdHoc
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(ProductBarcodeID = @ProductBarcodeID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodes
	 WHERE
		(ProductBarcodeID = @ProductBarcodeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeTracking_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeTracking_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodeTracking]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeTracking_CREATE]
(
		@ProductBarcodeTrackingTypeId VARCHAR(20)
		, @ProductBarcodeId NVARCHAR(60)
		, @DealerId INT
		, @AuditId BIGINT
		, @LocationTypeId VARCHAR(20)
		, @LocationIdentifier VARCHAR(50)
		, @Comment NVARCHAR(MAX)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ProductBarcodeTrackingID BIGINT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodeTracking') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodeTracking') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeTracking]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.ProductBarcodeTracking (
		[ProductBarcodeTrackingTypeId]
		, [ProductBarcodeId]
		, [DealerId]
		, [AuditId]
		, [LocationTypeId]
		, [LocationIdentifier]
		, [Comment]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ProductBarcodeTrackingTypeId
		, @ProductBarcodeId
		, @DealerId
		, @AuditId
		, @LocationTypeId
		, @LocationIdentifier
		, @Comment
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeTracking
		WHERE
		(ProductBarcodeTrackingID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeTracking_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeTracking_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodeTracking]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeTracking_DELETE]
(
	@ProductBarcodeTrackingID bigint
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodeTracking') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodeTracking') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeTracking]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodeTracking SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(ProductBarcodeTrackingID = @ProductBarcodeTrackingID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeTracking
	 WHERE
		(ProductBarcodeTrackingID = @ProductBarcodeTrackingID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeTracking_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeTracking_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[ProductBarcodeTracking]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeTracking_UPDATE]
(
		@ProductBarcodeTrackingID BIGINT		
		, @ProductBarcodeTrackingTypeId VARCHAR(20)		
		, @ProductBarcodeId NVARCHAR(60)		
		, @DealerId INT		
		, @AuditId BIGINT		
		, @LocationTypeId VARCHAR(20)		
		, @LocationIdentifier VARCHAR(50)		
		, @Comment NVARCHAR(MAX)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodeTracking') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodeTracking') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeTracking]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodeTracking SET
		[ProductBarcodeTrackingTypeId] = @ProductBarcodeTrackingTypeId
		, [ProductBarcodeId] = @ProductBarcodeId
		, [DealerId] = @DealerId
		, [AuditId] = @AuditId
		, [LocationTypeId] = @LocationTypeId
		, [LocationIdentifier] = @LocationIdentifier
		, [Comment] = @Comment
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(ProductBarcodeTrackingID = @ProductBarcodeTrackingID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeTracking
	 WHERE
		(ProductBarcodeTrackingID = @ProductBarcodeTrackingID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeTrackingTypes_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeTrackingTypes_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodeTrackingTypes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeTrackingTypes_CREATE]
(
		
		@ProductBarcodeTrackingTypeID VARCHAR(20)
		, @ProductBarcodeTrackingTypeName NVARCHAR(100)
		, @Comment NVARCHAR(MAX)
		, @IsInventoryMove BIT
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodeTrackingTypes') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','ProductBarcodeTrackingTypes') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeTrackingTypes]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.ProductBarcodeTrackingTypes (
		[ProductBarcodeTrackingTypeID]
		, [ProductBarcodeTrackingTypeName]
		, [Comment]
		, [IsInventoryMove]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ProductBarcodeTrackingTypeID
		, @ProductBarcodeTrackingTypeName
		, @Comment
		, @IsInventoryMove
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeTrackingTypes
		WHERE
		(ProductBarcodeTrackingTypeID = @ProductBarcodeTrackingTypeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeTrackingTypes_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeTrackingTypes_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ProductBarcodeTrackingTypes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeTrackingTypes_DELETE]
(
	@ProductBarcodeTrackingTypeID varchar(20)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodeTrackingTypes') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','ProductBarcodeTrackingTypes') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeTrackingTypes]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodeTrackingTypes SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(ProductBarcodeTrackingTypeID = @ProductBarcodeTrackingTypeID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeTrackingTypes
	 WHERE
		(ProductBarcodeTrackingTypeID = @ProductBarcodeTrackingTypeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ProductBarcodeTrackingTypes_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ProductBarcodeTrackingTypes_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[ProductBarcodeTrackingTypes]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ProductBarcodeTrackingTypes_UPDATE]
(
		@ProductBarcodeTrackingTypeID VARCHAR(20)		
		, @ProductBarcodeTrackingTypeName NVARCHAR(100)		
		, @Comment NVARCHAR(MAX)		
		, @IsInventoryMove BIT		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodeTrackingTypes') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','ProductBarcodeTrackingTypes') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ProductBarcodeTrackingTypes]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ProductBarcodeTrackingTypes SET
		[ProductBarcodeTrackingTypeName] = @ProductBarcodeTrackingTypeName
		, [Comment] = @Comment
		, [IsInventoryMove] = @IsInventoryMove
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(ProductBarcodeTrackingTypeID = @ProductBarcodeTrackingTypeID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ProductBarcodeTrackingTypes
	 WHERE
		(ProductBarcodeTrackingTypeID = @ProductBarcodeTrackingTypeID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PurchaseOrderItems_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PurchaseOrderItems_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PurchaseOrderItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PurchaseOrderItems_CREATE]
(
		@PurchaseOrderId BIGINT
		, @ProductSkwId BIGINT
		, @WarehouseSiteId VARCHAR(20)
		, @Quantity INT
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @PurchaseOrderItemID BIGINT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','PurchaseOrderItems') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','PurchaseOrderItems') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PurchaseOrderItems]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.PurchaseOrderItems (
		[PurchaseOrderId]
		, [ProductSkwId]
		, [WarehouseSiteId]
		, [Quantity]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@PurchaseOrderId
		, @ProductSkwId
		, @WarehouseSiteId
		, @Quantity
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.PurchaseOrderItems
		WHERE
		(PurchaseOrderItemID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PurchaseOrderItems_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PurchaseOrderItems_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PurchaseOrderItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PurchaseOrderItems_DELETE]
(
	@PurchaseOrderItemID bigint
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','PurchaseOrderItems') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','PurchaseOrderItems') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PurchaseOrderItems]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PurchaseOrderItems SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(PurchaseOrderItemID = @PurchaseOrderItemID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PurchaseOrderItems
	 WHERE
		(PurchaseOrderItemID = @PurchaseOrderItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PurchaseOrderItems_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PurchaseOrderItems_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[PurchaseOrderItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PurchaseOrderItems_UPDATE]
(
		@PurchaseOrderItemID BIGINT		
		, @PurchaseOrderId BIGINT		
		, @ProductSkwId BIGINT		
		, @WarehouseSiteId VARCHAR(20)		
		, @Quantity INT		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','PurchaseOrderItems') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','PurchaseOrderItems') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PurchaseOrderItems]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PurchaseOrderItems SET
		[PurchaseOrderId] = @PurchaseOrderId
		, [ProductSkwId] = @ProductSkwId
		, [WarehouseSiteId] = @WarehouseSiteId
		, [Quantity] = @Quantity
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(PurchaseOrderItemID = @PurchaseOrderItemID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PurchaseOrderItems
	 WHERE
		(PurchaseOrderItemID = @PurchaseOrderItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PurchaseOrders_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PurchaseOrders_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PurchaseOrders]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PurchaseOrders_CREATE]
(
		@DealerId INT
		, @VendorId VARCHAR(20)
		, @WarehouseSiteId VARCHAR(20)
		, @AttentionLine NVARCHAR(250)
		, @GPPONumber VARCHAR(50)
		, @VendorRefNumber VARCHAR(50)
		, @CreditTerms VARCHAR(50)
		, @SubTotal MONEY
		, @Tax MONEY
		, @Total MONEY
		, @SubmittedDate DATETIMEOFFSET
		, @CompletedDate DATETIMEOFFSET
		, @Comments NVARCHAR(MAX)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @PurchaseOrderID BIGINT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','PurchaseOrders') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','PurchaseOrders') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PurchaseOrders]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.PurchaseOrders (
		[DealerId]
		, [VendorId]
		, [WarehouseSiteId]
		, [AttentionLine]
		, [GPPONumber]
		, [VendorRefNumber]
		, [CreditTerms]
		, [SubTotal]
		, [Tax]
		, [Total]
		, [SubmittedDate]
		, [CompletedDate]
		, [Comments]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@DealerId
		, @VendorId
		, @WarehouseSiteId
		, @AttentionLine
		, @GPPONumber
		, @VendorRefNumber
		, @CreditTerms
		, @SubTotal
		, @Tax
		, @Total
		, @SubmittedDate
		, @CompletedDate
		, @Comments
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.PurchaseOrders
		WHERE
		(PurchaseOrderID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PurchaseOrders_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PurchaseOrders_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[PurchaseOrders]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PurchaseOrders_DELETE]
(
	@PurchaseOrderID bigint
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','PurchaseOrders') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','PurchaseOrders') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PurchaseOrders]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PurchaseOrders SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(PurchaseOrderID = @PurchaseOrderID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PurchaseOrders
	 WHERE
		(PurchaseOrderID = @PurchaseOrderID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_PurchaseOrders_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_PurchaseOrders_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[PurchaseOrders]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_PurchaseOrders_UPDATE]
(
		@PurchaseOrderID BIGINT		
		, @DealerId INT		
		, @VendorId VARCHAR(20)		
		, @WarehouseSiteId VARCHAR(20)		
		, @AttentionLine NVARCHAR(250)		
		, @GPPONumber VARCHAR(50)		
		, @VendorRefNumber VARCHAR(50)		
		, @CreditTerms VARCHAR(50)		
		, @SubTotal MONEY		
		, @Tax MONEY		
		, @Total MONEY		
		, @SubmittedDate DATETIMEOFFSET		
		, @CompletedDate DATETIMEOFFSET		
		, @Comments NVARCHAR(MAX)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','PurchaseOrders') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','PurchaseOrders') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[PurchaseOrders]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.PurchaseOrders SET
		[DealerId] = @DealerId
		, [VendorId] = @VendorId
		, [WarehouseSiteId] = @WarehouseSiteId
		, [AttentionLine] = @AttentionLine
		, [GPPONumber] = @GPPONumber
		, [VendorRefNumber] = @VendorRefNumber
		, [CreditTerms] = @CreditTerms
		, [SubTotal] = @SubTotal
		, [Tax] = @Tax
		, [Total] = @Total
		, [SubmittedDate] = @SubmittedDate
		, [CompletedDate] = @CompletedDate
		, [Comments] = @Comments
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(PurchaseOrderID = @PurchaseOrderID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.PurchaseOrders
	 WHERE
		(PurchaseOrderID = @PurchaseOrderID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ReturnToManufacturerItems_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ReturnToManufacturerItems_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ReturnToManufacturerItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ReturnToManufacturerItems_CREATE]
(
		
		@ReturnToManufacturerItemID VARCHAR(50)
		, @ReturnToManufacturerId NVARCHAR(50)
		, @Description VARCHAR(MAX)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','ReturnToManufacturerItems') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','ReturnToManufacturerItems') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ReturnToManufacturerItems]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.ReturnToManufacturerItems (
		[ReturnToManufacturerItemID]
		, [ReturnToManufacturerId]
		, [Description]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ReturnToManufacturerItemID
		, @ReturnToManufacturerId
		, @Description
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.ReturnToManufacturerItems
		WHERE
		(ReturnToManufacturerItemID = @ReturnToManufacturerItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ReturnToManufacturerItems_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ReturnToManufacturerItems_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ReturnToManufacturerItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ReturnToManufacturerItems_DELETE]
(
	@ReturnToManufacturerItemID varchar(50)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','ReturnToManufacturerItems') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','ReturnToManufacturerItems') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ReturnToManufacturerItems]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ReturnToManufacturerItems SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(ReturnToManufacturerItemID = @ReturnToManufacturerItemID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ReturnToManufacturerItems
	 WHERE
		(ReturnToManufacturerItemID = @ReturnToManufacturerItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ReturnToManufacturerItems_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ReturnToManufacturerItems_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[ReturnToManufacturerItems]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ReturnToManufacturerItems_UPDATE]
(
		@ReturnToManufacturerItemID VARCHAR(50)		
		, @ReturnToManufacturerId NVARCHAR(50)		
		, @Description VARCHAR(MAX)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','ReturnToManufacturerItems') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','ReturnToManufacturerItems') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ReturnToManufacturerItems]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ReturnToManufacturerItems SET
		[ReturnToManufacturerId] = @ReturnToManufacturerId
		, [Description] = @Description
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(ReturnToManufacturerItemID = @ReturnToManufacturerItemID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ReturnToManufacturerItems
	 WHERE
		(ReturnToManufacturerItemID = @ReturnToManufacturerItemID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ReturnToManufacturers_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ReturnToManufacturers_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ReturnToManufacturers]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ReturnToManufacturers_CREATE]
(
		
		@ReturnToManufacturerID NVARCHAR(50)
		, @ManufacturerId VARCHAR(20)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','ReturnToManufacturers') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','ReturnToManufacturers') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ReturnToManufacturers]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.ReturnToManufacturers (
		[ReturnToManufacturerID]
		, [ManufacturerId]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ReturnToManufacturerID
		, @ManufacturerId
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.ReturnToManufacturers
		WHERE
		(ReturnToManufacturerID = @ReturnToManufacturerID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ReturnToManufacturers_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ReturnToManufacturers_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[ReturnToManufacturers]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ReturnToManufacturers_DELETE]
(
	@ReturnToManufacturerID nvarchar(50)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','ReturnToManufacturers') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','ReturnToManufacturers') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ReturnToManufacturers]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ReturnToManufacturers SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(ReturnToManufacturerID = @ReturnToManufacturerID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ReturnToManufacturers
	 WHERE
		(ReturnToManufacturerID = @ReturnToManufacturerID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_ReturnToManufacturers_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_ReturnToManufacturers_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[ReturnToManufacturers]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_ReturnToManufacturers_UPDATE]
(
		@ReturnToManufacturerID NVARCHAR(50)		
		, @ManufacturerId VARCHAR(20)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','ReturnToManufacturers') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','ReturnToManufacturers') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[ReturnToManufacturers]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.ReturnToManufacturers SET
		[ManufacturerId] = @ManufacturerId
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(ReturnToManufacturerID = @ReturnToManufacturerID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.ReturnToManufacturers
	 WHERE
		(ReturnToManufacturerID = @ReturnToManufacturerID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_StockingLevels_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_StockingLevels_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[StockingLevels]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_StockingLevels_CREATE]
(
		@ProductSkwId BIGINT
		, @LocationTypeId VARCHAR(20)
		, @LocationIdentifier VARCHAR(50)
		, @ReorderLevelQty INT
		, @StockingLevelQty INT
		, @OrderQuantity INT
		, @Comment NVARCHAR(MAX)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @StockingLevelID INT
		, @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','StockingLevels') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','StockingLevels') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[StockingLevels]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.StockingLevels (
		[ProductSkwId]
		, [LocationTypeId]
		, [LocationIdentifier]
		, [ReorderLevelQty]
		, [StockingLevelQty]
		, [OrderQuantity]
		, [Comment]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@ProductSkwId
		, @LocationTypeId
		, @LocationIdentifier
		, @ReorderLevelQty
		, @StockingLevelQty
		, @OrderQuantity
		, @Comment
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.StockingLevels
		WHERE
		(StockingLevelID = SCOPE_IDENTITY());

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_StockingLevels_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_StockingLevels_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[StockingLevels]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_StockingLevels_DELETE]
(
	@StockingLevelID int
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','StockingLevels') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','StockingLevels') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[StockingLevels]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.StockingLevels SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(StockingLevelID = @StockingLevelID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.StockingLevels
	 WHERE
		(StockingLevelID = @StockingLevelID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_StockingLevels_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_StockingLevels_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[StockingLevels]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_StockingLevels_UPDATE]
(
		@StockingLevelID INT		
		, @ProductSkwId BIGINT		
		, @LocationTypeId VARCHAR(20)		
		, @LocationIdentifier VARCHAR(50)		
		, @ReorderLevelQty INT		
		, @StockingLevelQty INT		
		, @OrderQuantity INT		
		, @Comment NVARCHAR(MAX)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','StockingLevels') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','StockingLevels') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[StockingLevels]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.StockingLevels SET
		[ProductSkwId] = @ProductSkwId
		, [LocationTypeId] = @LocationTypeId
		, [LocationIdentifier] = @LocationIdentifier
		, [ReorderLevelQty] = @ReorderLevelQty
		, [StockingLevelQty] = @StockingLevelQty
		, [OrderQuantity] = @OrderQuantity
		, [Comment] = @Comment
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(StockingLevelID = @StockingLevelID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.StockingLevels
	 WHERE
		(StockingLevelID = @StockingLevelID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_Vendors_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_Vendors_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[Vendors]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_Vendors_CREATE]
(
		
		@VendorID VARCHAR(20)
		, @DealerId INT
		, @PoliticalStateId VARCHAR(4)
		, @VendorName VARCHAR(100)
		, @StreetAddress NVARCHAR(50)
		, @StreetAddress2 NVARCHAR(50)
		, @City NVARCHAR(50)
		, @PostalCode VARCHAR(15)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','Vendors') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','Vendors') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[Vendors]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.Vendors (
		[VendorID]
		, [DealerId]
		, [PoliticalStateId]
		, [VendorName]
		, [StreetAddress]
		, [StreetAddress2]
		, [City]
		, [PostalCode]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@VendorID
		, @DealerId
		, @PoliticalStateId
		, @VendorName
		, @StreetAddress
		, @StreetAddress2
		, @City
		, @PostalCode
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.Vendors
		WHERE
		(VendorID = @VendorID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_Vendors_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_Vendors_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[Vendors]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_Vendors_DELETE]
(
	@VendorID varchar(20)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','Vendors') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','Vendors') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[Vendors]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.Vendors SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(VendorID = @VendorID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.Vendors
	 WHERE
		(VendorID = @VendorID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_Vendors_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_Vendors_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[Vendors]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_Vendors_UPDATE]
(
		@VendorID VARCHAR(20)		
		, @DealerId INT		
		, @PoliticalStateId VARCHAR(4)		
		, @VendorName VARCHAR(100)		
		, @StreetAddress NVARCHAR(50)		
		, @StreetAddress2 NVARCHAR(50)		
		, @City NVARCHAR(50)		
		, @PostalCode VARCHAR(15)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','Vendors') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','Vendors') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[Vendors]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.Vendors SET
		[DealerId] = @DealerId
		, [PoliticalStateId] = @PoliticalStateId
		, [VendorName] = @VendorName
		, [StreetAddress] = @StreetAddress
		, [StreetAddress2] = @StreetAddress2
		, [City] = @City
		, [PostalCode] = @PostalCode
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(VendorID = @VendorID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.Vendors
	 WHERE
		(VendorID = @VendorID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_WarehouseSites_CREATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_WarehouseSites_CREATE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[WarehouseSites]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_WarehouseSites_CREATE]
(
		
		@WarehouseSiteID VARCHAR(20)
		, @DealerId INT
		, @PoliticalStateId VARCHAR(4)
		, @PoliticalTimeZoneId INT
		, @WarehouseSiteName NVARCHAR(150)
		, @StreetAddress NVARCHAR(50)
		, @StreetAddress2 NVARCHAR(50)
		, @City NVARCHAR(50)
		, @PostalCode VARCHAR(15)
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

		/**********************************
		 * SET Modified And Created By IDs
		 **********************************/
		IF (@ModifiedById IS NULL OR @ModifiedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @ModifiedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
		IF (@CreatedById IS NULL OR @CreatedById = '00000000-0000-0000-0000-000000000000') BEGIN
			SET @CreatedById = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
		END 
	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('CREATE','INE','WarehouseSites') AS AL WHERE (AL.CreateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.CreateAccessId  FROM [GEN].fxGetAccessLevel('CREATE','INE','WarehouseSites') AS AL WHERE (AL.CreateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR ('[50100]:The user "%s" does not have CREATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[WarehouseSites]');

		RETURN;
	 END

	 /************
	 * CREATE ROW
	 ************/
	 INSERT INTO INE.WarehouseSites (
		[WarehouseSiteID]
		, [DealerId]
		, [PoliticalStateId]
		, [PoliticalTimeZoneId]
		, [WarehouseSiteName]
		, [StreetAddress]
		, [StreetAddress2]
		, [City]
		, [PostalCode]
		, [IsActive]
		, [ModifiedById]
		, [CreatedById]
	 )VALUES (
		@WarehouseSiteID
		, @DealerId
		, @PoliticalStateId
		, @PoliticalTimeZoneId
		, @WarehouseSiteName
		, @StreetAddress
		, @StreetAddress2
		, @City
		, @PostalCode
		, @IsActive
		, @ModifiedById
		, @CreatedById
	 );

	 /*************
	 * Return ROW
	 **************/
	 SELECT * FROM INE.WarehouseSites
		WHERE
		(WarehouseSiteID = @WarehouseSiteID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_WarehouseSites_DELETE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_WarehouseSites_DELETE]
**		Desc: Autogenerated SPROC to CREATE a row for [INE].[WarehouseSites]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_WarehouseSites_DELETE]
(
	@WarehouseSiteID varchar(20)
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('DELETE','INE','WarehouseSites') AS AL WHERE (AL.DeleteAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('DELETE','INE','WarehouseSites') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50130]|The user "%s" does not have DELETE privileges on table "%s".'
           , 11 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[WarehouseSites]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.WarehouseSites SET
		IsDeleted = 1
		, ModifiedDate = SYSDATETIMEOFFSET()
		, ModifiedById = @ACLUserID
	 
	 WHERE
		(WarehouseSiteID = @WarehouseSiteID);


	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.WarehouseSites
	 WHERE
		(WarehouseSiteID = @WarehouseSiteID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spAutoGen_WarehouseSites_UPDATE

/**********************************************************************************************************************
**		Name: [INE].[spAutoGen_WarehouseSites_UPDATE]
**		Desc: Autogenerated SPROC to UPDATE a row for [INE].[WarehouseSites]
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
***********************************************************************************************************************/
CREATE Procedure [INE].[spAutoGen_WarehouseSites_UPDATE]
(
		@WarehouseSiteID VARCHAR(20)		
		, @DealerId INT		
		, @PoliticalStateId VARCHAR(4)		
		, @PoliticalTimeZoneId INT		
		, @WarehouseSiteName NVARCHAR(150)		
		, @StreetAddress NVARCHAR(50)		
		, @StreetAddress2 NVARCHAR(50)		
		, @City NVARCHAR(50)		
		, @PostalCode VARCHAR(15)		
		, @IsActive BIT		
		, @ModifiedDate DATETIMEOFFSET		
		, @ModifiedById UNIQUEIDENTIFIER		
		, @CreatedDate DATETIMEOFFSET		
		, @CreatedById UNIQUEIDENTIFIER
)
AS
BEGIN
	/**************
	 * INITIALIZE
	 **************/
	 DECLARE @ACLUserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGUID NVARCHAR(MAX)
		, @CreatedAccessId SMALLINT;

	/*********************
	 * CHECK ACCESS LEVEL
	 *********************/
	 IF (NOT EXISTS(SELECT * FROM [GEN].fxGetAccessLevel('UPDATE','INE','WarehouseSites') AS AL WHERE (AL.UpdateAccessId > 0))) BEGIN
		--** Get ACL Information
		--SELECT @ACLUserID = UserId, @UserGUID = @UserGUID, @CreatedAccessId = AL.UpdateAccessId  FROM [GEN].fxGetAccessLevel('UPDATE','INE','WarehouseSites') AS AL WHERE (AL.UpdateAccessId > 0)

		--** Check that there is a user
		SELECT TOP 1 @UserGUID = UserGuidIDMasked FROM [GEN].fxGetUserInfo();

		RAISERROR (N'[50120]|The user "%s" does not have UPDATE privileges on table "%s".'
           , 18 -- Severity,
           , 1 -- State,
           , @UserGUID
		   , N'[INE].[WarehouseSites]');
		RETURN;
	 END

	 /************
	 * UPDATE ROW
	 ************/
	 UPDATE INE.WarehouseSites SET
		[DealerId] = @DealerId
		, [PoliticalStateId] = @PoliticalStateId
		, [PoliticalTimeZoneId] = @PoliticalTimeZoneId
		, [WarehouseSiteName] = @WarehouseSiteName
		, [StreetAddress] = @StreetAddress
		, [StreetAddress2] = @StreetAddress2
		, [City] = @City
		, [PostalCode] = @PostalCode
		, [IsActive] = @IsActive
		, [ModifiedDate] = SYSDATETIMEOFFSET()
		, [ModifiedById] = UTL.fxGetDefaultGuidId(@ModifiedById)
	 WHERE
		(WarehouseSiteID = @WarehouseSiteID);

	 /**************
	 * RETURN ROW
	 **************/
	 SELECT * FROM INE.WarehouseSites
	 WHERE
		(WarehouseSiteID = @WarehouseSiteID);

END;

GO
-- ##### SQL_STORED_PROCEDURE INE.spGetInventoryByLocationAndIdentifier
/******************************************************************************
**		File: spGetInventoryByLocationAndIdentifier.sql
**		Name: spGetInventoryByLocationAndIdentifier
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
**		Auth: Andrés Sosa
**		Date: 02/20/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	02/20/2018	Andrés Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spGetInventoryByLocationAndIdentifier]
(
	@LocationIdentifier NVARCHAR(50)
	, @LocationTypeId VARCHAR(20) = 'Technician'
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @ResourceFullName NVARCHAR(150);

		IF (@LocationTypeId = 'Technician' OR @LocationTypeId = 'SalesRep') BEGIN
			DECLARE @UserResourceID INT = CAST(@LocationIdentifier AS INT);
			SELECT @ResourceFullName = FullName + ' (' + URS.GPEmployeeId + ')' FROM [RSU].[UserResources] AS URS WITH(NOLOCK) WHERE URS.UserResourceID = @UserResourceID AND (URS.DealerId = @DealerId);
			IF (@ResourceFullName IS NULL) BEGIN
				RAISERROR(N'[30100]:NOT FOUND.  This %s with ID of %s was not found.', 18, 1, @LocationTypeId, @LocationIdentifier);
				RETURN -1;
			END;
		END ELSE IF (@LocationTypeId = 'Received') BEGIN
			SELECT @ResourceFullName = WarehouseSiteName FROM [INE].[WarehouseSites] WHERE (WarehouseSiteID = @LocationIdentifier) AND (DealerId = @DealerId);
			IF (@ResourceFullName IS NULL) BEGIN
				RAISERROR(N'[30100]:NOT FOUND.  This %s with ID of %s was not found.', 18, 1, @LocationTypeId, @LocationIdentifier);
				RETURN -1;
			END;
		END ELSE BEGIN
			RAISERROR(N'[30400]:FEATURE NOT IMPLEMENTED.  The location type ''%s'' has not been implemented.', 18, 1, @LocationTypeId);
			RETURN -1;
		END;

		WITH RootCTE AS (
			SELECT
				PBT.ProductBarcodeTrackingID
				, PBT.ProductBarcodeId
				, PBT.ProductBarcodeTrackingTypeId
				, PBT.LocationTypeId
				, PBT.LocationIdentifier
				, ROW_NUMBER() OVER (PARTITION BY PBT.ProductBarcodeId ORDER BY PBT.ProductBarcodeTrackingID DESC) AS RNW
			FROM 
				[INE].[ProductBarcodeTracking] AS PBT WITH(NOLOCK)
			WHERE
				(PBT.IsActive = 'True' AND PBT.IsDeleted = 'False')
		)
		--SELECT * FROM RootCTE;
		, TechStockRootCte AS (
			SELECT
				RT.ProductBarcodeTrackingID
				, RT.ProductBarcodeId
				, RT.ProductBarcodeTrackingTypeId
				, RT.LocationTypeId
				, RT.LocationIdentifier
				, PB.BarcodeNumber
				, PSK.Skw
				, PSK.ProductName
				, CASE
					WHEN SUBSTRING(PB.BarcodeNumber, 1, 4) = 'ADHC' THEN CAST('True' AS BIT)
					ELSE CAST('False' AS BIT)
				  END IsAdHock
			FROM 
				RootCTE AS RT WITH(NOLOCK)
				INNER JOIN [INE].[ProductBarcodes] AS PB WITH(NOLOCK)
				ON
					(PB.ProductBarcodeID = RT.ProductBarcodeId)
				INNER JOIN [INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
				ON
					(POI.PurchaseOrderItemID = PB.PurchaseOrderItemId)
				INNER JOIN [ACE].[ProductSkws] AS PSK WITH(NOLOCK)
				ON
					(PSK.ProductSkwID = POI.ProductSkwId)
			WHERE
				(RT.RNW = 1)
				AND (RT.LocationTypeId = @LocationTypeId)
				AND (RT.LocationIdentifier = @LocationIdentifier)
		)
		--SELECT * FROM TechStockRootCte;
		, AggregateAdHocCTE AS (
			SELECT
				TSRT.Skw AS skw
				, @ResourceFullName AS [techFullName]
				, TSRT.ProductName AS productName
				, 'ADHC-XXX...XXX' AS barcodeNumber
				, 'ADHC-XXX...XXX' AS barcodeNumberMask
				, COUNT(*) AS qty
				, TSRT.IsAdHock AS isAdHock
			FROM
				TechStockRootCte AS TSRT WITH(NOLOCK)
			WHERE
				(TSRT.IsAdHock = 'True')
			GROUP BY
				TSRT.Skw
				, TSRT.ProductName
				, TSRT.IsAdHock
		), AggregateBarCodeCTE AS (
			SELECT
				TSRT.Skw AS skw
				, @ResourceFullName AS [techFullName]
				, TSRT.ProductName AS productName
				, TSRT.BarcodeNumber AS barcodeNumber
				, TSRT.BarcodeNumber AS barcodeNumberMask
				, COUNT(*) AS qty
				, TSRT.IsAdHock AS isAdHock
			FROM
				TechStockRootCte AS TSRT WITH(NOLOCK)
			WHERE
				(TSRT.IsAdHock = 'False')
			GROUP BY
				TSRT.Skw
				, TSRT.ProductName
				, TSRT.BarcodeNumber
				, TSRT.IsAdHock
		)
		SELECT (
			SELECT 
				ASDF.*
			FROM
				(SELECT * FROM AggregateBarCodeCTE
				UNION
				SELECT * FROM AggregateAdHocCTE) AS ASDF
			FOR JSON PATH, INCLUDE_NULL_VALUES
		) AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spGetLocationInventory
/******************************************************************************
**		File: spGetLocationInventory.sql
**		Name: spGetLocationInventory
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
**		Date: 09/01/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	09/01/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spGetLocationInventory
(
	@LocationTypeID VARCHAR(20)
	, @LocationIdentifier VARCHAR(50)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		-- ** STATEMENT
		WITH OnRootCTE AS
		(
			SELECT
				BS.ProductBarcodeID AS id
				, BS.ProductBarcodeID AS productBarcodeID
                , BS.BarcodeNumber AS barcodeNumber
                , BS.ProductBarcodeTrackingID AS productBarcodeTrackingID
                , BS.ProductBarcodeTrackingTypeId AS productBarcodeTrackingTypeId
                , BS.ProductSkwID AS productSkwId
                , BS.Skw AS skw
                , BS.IsAdHoc AS isAdHoc
			FROM
				[INE].[fxGetLocationInventory](@LocationTypeID, @LocationIdentifier, @DealerId) AS BS
		)
		, SummaryCTE AS (
			SELECT
				RT.productSkwId
				, RT.skw
				, RT.isAdHoc
				, COUNT(*) AS quantity
			FROM 
				OnRootCTE AS RT WITH(NOLOCK)
			GROUP BY
				RT.productSkwId
				, RT.skw
				, RT.isAdHoc
		) 
		SELECT ISNULL((
			SELECT
				CASE
					WHEN RT.isAdHoc = 1 THEN 'AD-' + CAST(RT.productSkwId AS VARCHAR(50))
					ELSE 'BC-' + CAST(RT.productSkwId AS VARCHAR(50))
				END AS id
				, RT.productSkwId
				, RT.skw
				, PSKW.ShortName AS shortName
				, RT.quantity
				, RT.isAdHoc
				, (SELECT
						BS.BarcodeNumber AS barcodeNumber
					FROM 
						[INE].[fxGetLocationInventory](@LocationTypeID, @LocationIdentifier, @DealerId) AS BS
					WHERE
						(BS.ProductSkwID = RT.ProductSkwID)
						AND (BS.IsAdHoc = 'False')
					FOR JSON PATH
				) AS bcList
			FROM
				SummaryCTE AS RT WITH(NOLOCK)
				INNER JOIN [ACE].[ProductSkws] AS PSKW WITH(NOLOCK)
				ON
					(PSKW.ProductSkwID = RT.productSkwId)
			FOR JSON PATH
		), '[]') AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spGetMetaData
/******************************************************************************
**		File: spGetMetaData.sql
**		Name: spGetMetaData
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spGetMetaData
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		-- ** STATEMENT
		WITH VendorsCte AS
		(
			SELECT
				V.VendorID AS id
				, V.DealerId AS dealerId
				, V.PoliticalStateId AS politicalStateId
				, V.VendorName AS vendorName
				, V.StreetAddress AS streetAddress
				, V.StreetAddress2 AS streetAddress2
				, V.City AS city
				, V.PostalCode AS postalCode
				, V.IsActive AS isActive
			FROM
				[INE].[Vendors] AS V WITH(NOLOCK)
			WHERE
				(V.IsDeleted = 'False')
				AND (V.DealerId = 0 OR V.DealerId = @DealerId)
		)
		, WarehouseCte AS 
		(
			SELECT
				W.WarehouseSiteID AS id
				, W.DealerId AS dealerId
				, W.PoliticalStateId AS politicalStateId
				, W.WarehouseSiteName AS warehouseSiteName
				, W.StreetAddress AS streetAddress
				, W.StreetAddress2 AS streetAddress2
				, W.City AS city
				, W.PostalCode AS postalCode
				, W.IsActive AS isActive
			FROM
				[INE].[WarehouseSites] AS W WITH(NOLOCK)
			WHERE
				(W.IsDeleted = 'False')
				AND (W.DealerId = 0 OR W.DealerId = @DealerId)
		)
		, LocationTypesCte AS (
			SELECT
				LT.LocationTypeID AS id
                , LT.LocationTypeName AS locationTypeName
                --, LT.TableName
                --, LT.FieldID
                --, LT.FieldName
                --, LT.SqlStmt AS sqlStmt
                , LT.Comment AS comment
                , LT.IsActive AS isActive
			FROM
				[INE].[LocationTypes] AS LT
			WHERE
				(LT.IsDeleted = 'False')
		), PBTrackingTypesCte AS (
			SELECT
				LT.ProductBarcodeTrackingTypeID AS id
                , LT.ProductBarcodeTrackingTypeName AS productBarcodeTrackingTypeName
                , LT.Comment AS comment
                , LT.IsInventoryMove AS isInventoryMove
                , LT.IsActive AS isActive
			FROM
				[INE].[ProductBarcodeTrackingTypes] AS LT WITH(NOLOCK)
			WHERE
				(LT.IsDeleted = 'False')
		)
		SELECT
			(SELECT
				(SELECT V.*
				FROM VendorsCte AS V WITH(NOLOCK)
				FOR JSON PATH) AS [vendorsList]
				, (SELECT
					W.*
				FROM WarehouseCte AS W WITH(NOLOCK)
				FOR JSON PATH) AS [warehouseList]
				, (SELECT
					LT.*
				FROM LocationTypesCte AS LT WITH(NOLOCK)
				FOR JSON PATH) AS [locationTypesList]
				, (SELECT
					LT.*
				FROM PBTrackingTypesCte AS LT WITH(NOLOCK)
				FOR JSON PATH) AS [productBarcodeTrackingTypesList]
			FOR JSON PATH) AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spGetTechnicianInventory
/******************************************************************************
**		File: spGetTechnicianInventory.sql
**		Name: spGetTechnicianInventory
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
**		Auth: Andrés Sosa
**		Date: 02/20/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	02/20/2018	Andrés Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spGetTechnicianInventory]
(
	@UserResourceID INT = NULL
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @TechFullName NVARCHAR(150)
			, @LocationIdentifier NVARCHAR(50) = CAST(@UserResourceID AS NVARCHAR(50))
			, @LocationTypeId VARCHAR(20) = 'Technician';

		SELECT @TechFullName = FullName + ' (' + URS.GPEmployeeId + ')' FROM [RSU].[UserResources] AS URS WITH(NOLOCK) WHERE URS.UserResourceID = @UserResourceID AND (URS.DealerId = @DealerId);
		IF (@TechFullName IS NULL) BEGIN
			RAISERROR(N'[30050]:SECURITY VIOLATION.  You don''t have rights to this resource.', 18, 1);
			RETURN -1;
		END;

		WITH RootCTE AS (
			SELECT
				PBT.ProductBarcodeTrackingID
				, PBT.ProductBarcodeId
				, PBT.ProductBarcodeTrackingTypeId
				, PBT.LocationTypeId
				, PBT.LocationIdentifier
				, ROW_NUMBER() OVER (PARTITION BY PBT.ProductBarcodeId ORDER BY PBT.ProductBarcodeTrackingID DESC) AS RNW
			FROM 
				[INE].[ProductBarcodeTracking] AS PBT WITH(NOLOCK)
			WHERE
				(PBT.IsActive = 'True' AND PBT.IsDeleted = 'False')
		), TechStockRootCte AS (
			SELECT
				RT.ProductBarcodeTrackingID
				, RT.ProductBarcodeId
				, RT.ProductBarcodeTrackingTypeId
				, RT.LocationTypeId
				, RT.LocationIdentifier
				, PB.BarcodeNumber
				, PSK.Skw
				, PSK.ProductName
				, CASE
					WHEN SUBSTRING(PB.BarcodeNumber, 1, 4) = 'ADHC' THEN CAST('True' AS BIT)
					ELSE CAST('False' AS BIT)
				  END IsAdHock
			FROM 
				RootCTE AS RT WITH(NOLOCK)
				INNER JOIN [INE].[ProductBarcodes] AS PB WITH(NOLOCK)
				ON
					(PB.ProductBarcodeID = RT.ProductBarcodeId)
				INNER JOIN [INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
				ON
					(POI.PurchaseOrderItemID = PB.PurchaseOrderItemId)
				INNER JOIN [ACE].[ProductSkws] AS PSK WITH(NOLOCK)
				ON
					(PSK.ProductSkwID = POI.ProductSkwId)
			WHERE
				(RT.RNW = 1)
				AND (RT.LocationTypeId = @LocationTypeId)
				AND (RT.LocationIdentifier = @LocationIdentifier)
		), AggregateAdHocCTE AS (
			SELECT
				TSRT.Skw AS skw
				, @TechFullName AS [techFullName]
				, TSRT.ProductName AS productName
				, 'ADHC-XXX...XXX' AS barcodeNumber
				, 'ADHC-XXX...XXX' AS barcodeNumberMask
				, COUNT(*) AS qty
				, TSRT.IsAdHock AS isAdHock
			FROM
				TechStockRootCte AS TSRT WITH(NOLOCK)
			WHERE
				(TSRT.IsAdHock = 'True')
			GROUP BY
				TSRT.Skw
				, TSRT.ProductName
				, TSRT.IsAdHock
		), AggregateBarCodeCTE AS (
			SELECT
				TSRT.Skw AS skw
				, @TechFullName AS [techFullName]
				, TSRT.ProductName AS productName
				, TSRT.BarcodeNumber AS barcodeNumber
				, TSRT.BarcodeNumber AS barcodeNumberMask
				, COUNT(*) AS qty
				, TSRT.IsAdHock AS isAdHock
			FROM
				TechStockRootCte AS TSRT WITH(NOLOCK)
			WHERE
				(TSRT.IsAdHock = 'False')
			GROUP BY
				TSRT.Skw
				, TSRT.ProductName
				, TSRT.BarcodeNumber
				, TSRT.IsAdHock
		)
		SELECT (
			SELECT 
				ASDF.*
			FROM
				(SELECT * FROM AggregateBarCodeCTE
				UNION
				SELECT * FROM AggregateAdHocCTE) AS ASDF
			FOR JSON PATH, INCLUDE_NULL_VALUES
		) AS [JsonOutPutMethod]

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spLocationsGetByLocationTypes
/******************************************************************************
**		File: spLocationsGetByLocationTypes.sql
**		Name: spLocationsGetByLocationTypes
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
**		Date: 08/25/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	08/25/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spLocationsGetByLocationTypes
(
	@LocationTypeID VARCHAR(20)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		-- ** STATEMENT
		DECLARE @TableName NVARCHAR(60), @FieldID NVARCHAR(60), @FieldName NVARCHAR(60)
			, @SqlStmt NVARCHAR(MAX);
		SELECT
			@TableName = LT.TableName
			, @FieldID  = LT.FieldID
			, @FieldName  = LT.FieldName
			, @SqlStmt  = LT.SqlStmt
		FROM
			[INE].[LocationTypes] AS LT WITH(NOLOCK)
		WHERE
			(LT.LocationTypeID = @LocationTypeID);

		DECLARE @ParmDef NVARCHAR(500) = N'@DealerId INT';

		/** EXECUTE STATEMENT */
		EXECUTE sp_executesql @SqlStmt, @ParmDef, @DealerId = @DealerId;
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPackingSlipeSaveWithJsonInput
/******************************************************************************
**		File: spPackingSlipeSaveWithJsonInput.sql
**		Name: spPackingSlipeSaveWithJsonInput
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spPackingSlipeSaveWithJsonInput]
(
	@JsonInput NVARCHAR(MAX)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @DealerId INT;
	SELECT @UserID = UserID, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @PackingSlipId BIGINT
			, @PurchaseOrderId BIGINT
			, @PackingSlipNumber NVARCHAR(25)
			, @ArrivalDate NVARCHAR(50)
			, @CloseDate NVARCHAR(50)

		-- ** STATEMENT
		SELECT
			@PackingSlipId = PackingSlipId
			, @PurchaseOrderId = PurchaseOrderId
			, @PackingSlipNumber = PackingSlipNumber
			, @ArrivalDate = CASE
				WHEN ArrivalDate = '' OR ArrivalDate IS NULL THEN NULL
				ELSE REPLACE(ArrivalDate, 'T', ' ')
			  END
			, @CloseDate = CASE
				WHEN CloseDate = '' OR CloseDate IS NULL THEN NULL
				ELSE REPLACE(CloseDate, 'T', ' ')
			  END
		FROM
			OPENJSON(@JsonInput, '$')
		WITH (
			[PackingSlipId] BIGINT '$.id'
			, [PurchaseOrderId] BIGINT '$.purchaseOrderId'
			, [PackingSlipNumber] NVARCHAR(25) '$.packingSlipNumber'
			, [ArrivalDate] NVARCHAR(50) '$.arrivalDate'
			, [CloseDate] NVARCHAR(50) '$.closeDate'
		);

		/** FIND TIMEZONE FOR WAREHOUSE */
		SELECT
			@ArrivalDate = CASE
				WHEN @ArrivalDate IS NOT NULL THEN @ArrivalDate + TZ.SqlTimeZoneOffsetFormat
				ELSE NULL
			  END
			, @CloseDate = CASE
				WHEN @CloseDate IS NOT NULL THEN @CloseDate + TZ.SqlTimeZoneOffsetFormat
				ELSE NULL
			  END
		FROM
			[INE].[PurchaseOrders] AS PO WITH(NOLOCK)
			INNER JOIN [INE].[WarehouseSites] AS WS WITH(NOLOCK)
			ON
				(WS.WarehouseSiteID = PO.WarehouseSiteId)
			INNER JOIN [MAC].[PoliticalTimeZones] AS TZ WITH(NOLOCK)
			ON
				(TZ.PoliticalTimeZoneID = WS.PoliticalTimeZoneId)
		WHERE
			(PO.PurchaseOrderID = @PurchaseOrderId);

		/** PERFORM ACTION */
		IF (@PackingSlipId IS NULL) BEGIN
			INSERT INTO [INE].[PackingSlips] (
				[DealerId]
				,[PurchaseOrderId]
				,[ArrivalDate]
				,[CloseDate]
				,[PackingSlipNumber]
				,[ModifiedById]
				,[CreatedById]
			) VALUES (
				@DealerId
				, @PurchaseOrderId
				, @ArrivalDate
				, @CloseDate
				, @PackingSlipNumber
				, @UserID
				, @UserID);
			SET @PackingSlipId = SCOPE_IDENTITY();
		END ELSE BEGIN
			UPDATE [INE].[PackingSlips] SET
				PurchaseOrderId = @PurchaseOrderId
				, PackingSlipNumber = @PackingSlipNumber
				, ArrivalDate = @ArrivalDate
				, CloseDate = @CloseDate
			WHERE (PackingSlipID = @PackingSlipId);
		END

		/*************
		* Return ROW
		**************/
		DECLARE @CreatedById UNIQUEIDENTIFIER, @ModifiedById UNIQUEIDENTIFIER;
		SELECT @CreatedById=MAC.CreatedById, @ModifiedById = MAC.ModifiedById FROM [INE].[PackingSlips] AS MAC WITH(NOLOCK) WHERE (MAC.PackingSlipID = @PackingSlipID);
		SELECT (
			SELECT
				PS.PackingSlipID AS id 
				, PS.PackingSlipID AS packingSlipID
				, PS.PurchaseOrderId AS purchaseOrderId
				, PS.ArrivalDate AS arrivalDate
				, PS.CloseDate AS closeDate
				, PS.PackingSlipNumber AS packingSlipNumber
				, PS.IsActive AS isActive
				, PS.ModifiedDate AS modifiedDate
				, MU.UserId AS [modifiedBy.id]
				, MU.firstName AS [modifiedBy.firstName]
				, MU.lastName AS [modifiedBy.lastName]
				, MU.fullName AS [modifiedBy.fullName]
				, MU.fullNameWithGPID AS [modifiedBy.fullNameWithGPID]
				, MU.gPEmployeeId AS [modifiedBy.gPEmployeeId]
				, PS.CreatedDate AS createdDate
				, CU.UserId AS [createdBy.id]
				, CU.firstName AS [createdBy.firstName]
				, CU.lastName AS [createdBy.lastName]
				, CU.fullName AS [createdBy.fullName]
				, CU.fullNameWithGPID AS [createdBy.fullNameWithGPID]
				, CU.gPEmployeeId AS [createdBy.gPEmployeeId]
			FROM
				[INE].[PackingSlips] AS PS WITH(NOLOCK)
				LEFT OUTER JOIN ACC.fxGetUserInfoByUserIdJSONTABLE(@CreatedById) AS CU
				ON
					(CU.userID = @CreatedById)
				LEFT OUTER JOIN ACC.fxGetUserInfoByUserIdJSONTABLE(@ModifiedById) AS MU
				ON
					(MU.userID = @ModifiedById)
			WHERE
				(PS.PackingSlipID = @PackingSlipId)
			FOR JSON PATH) AS JsonOutPutMethod;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spProductBarcodeAssignAddHoc
/******************************************************************************
**		File: spProductBarcodeAssignAddHoc.sql
**		Name: spProductBarcodeAssignAddHoc
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	08/25/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spProductBarcodeAssignAddHoc
(
	@Skw VARCHAR(20) = 'GC3'
	, @Qty INT = 4
	, @ProductBarcodeTrackingTypeId VARCHAR(20) = 'TRNF'
	, @SrcLocationTypeID VARCHAR(20) = 'Received'
	, @SrcLocationIdentifier VARCHAR(50) = 'CORP'
	, @LocationTypeID VARCHAR(20) = 'Technician'
	, @LocationIdentifier VARCHAR(50) = '1'
	, @Comment NVARCHAR(MAX) = N'Yes I''m testing everything....'
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** Validate that there is enough */
		DECLARE @AvailableQty INT = (SELECT COUNT(*) FROM [INE].[fxGetLocationInventory](@SrcLocationTypeID, @SrcLocationIdentifier, @DealerId) AS BS WHERE (BS.IsAdHoc = 'True') AND (BS.Skw = @Skw));
		IF (@AvailableQty < @Qty) BEGIN
			RAISERROR(N'[30500]:Sorry the source only has %d %s''s.  You are asking for %d.', 18, 1, @AvailableQty, @Skw, @Qty);
			RETURN;
		END

		/** Find and Assign Available Product */
		DECLARE @PBTable TABLE (ProductBarcodeID NVARCHAR(60));
		WITH OnRootCTE AS (
			SELECT
				BS.*
				, ROW_NUMBER() OVER (PARTITION BY BS.Skw ORDER BY BS.ProductBarcodeTrackingID) AS RWN
			FROM
				[INE].[fxGetLocationInventory](@SrcLocationTypeID, @SrcLocationIdentifier, @DealerId) AS BS
			WHERE
				(BS.IsAdHoc = 'True')
				AND (BS.Skw = @Skw)
		)
		INSERT INTO @PBTable (ProductBarcodeID) 
		SELECT RT.ProductBarcodeID FROM OnRootCTE AS RT WHERE RT.RWN <= @Qty ORDER BY RT.ProductBarcodeTrackingID;

		/** Create Cursor for looping through the selections */
		DECLARE @PBID NVARCHAR(60), @PBTID BIGINT;
		DECLARE PBCursor CURSOR LOCAL FOR
		SELECT ProductBarcodeID FROM @PBTable;

		OPEN PBCursor;
		FETCH NEXT FROM PBCursor INTO @PBID;

		WHILE (@@FETCH_STATUS = 0) BEGIN
			/** Save Tracking Info */
			INSERT INTO [INE].[ProductBarcodeTracking] ([ProductBarcodeTrackingTypeId], [ProductBarcodeId], [DealerId], [LocationTypeId], [LocationIdentifier], [Comment], [ModifiedById], [CreatedById])
			VALUES (@ProductBarcodeTrackingTypeId, @PBID, @DealerId, @LocationTypeID, @LocationIdentifier, @Comment, @UserID, @UserID);
			SET @PBTID = SCOPE_IDENTITY();

			/** Update BP Last Track Info */
			UPDATE PB SET PB.LastProductBarcodeTrackingId = @PBTID FROM [INE].[ProductBarcodes] AS PB WITH(NOLOCK) WHERE (PB.ProductBarcodeID = @PBID);

			/** Get Next */
			FETCH NEXT FROM PBCursor INTO @PBID;
		END

		CLOSE PBCursor;
		DEALLOCATE PBCursor;

		/** Return results */
		SELECT
			PB.ProductBarcodeID AS Id
			, PB.*
		FROM
			[INE].[ProductBarcodes] AS PB WITH(NOLOCK)
			INNER JOIN @PBTable AS PBT
			ON
				(PBT.ProductBarcodeID = PB.ProductBarcodeID);

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spProductBarcodeAssignAddHocWithJsonInput
/******************************************************************************
**		File: spProductBarcodeAssignAddHocWithJsonInput.sql
**		Name: spProductBarcodeAssignAddHocWithJsonInput
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	08/25/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spProductBarcodeAssignAddHocWithJsonInput
(
	@JsonInput NVARCHAR(MAX) = N'{}'
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
		DECLARE @ProductBarcodeTrackingTypeId VARCHAR(20)
			, @SrcLocationTypeID VARCHAR(20)
			, @SrcLocationIdentifier VARCHAR(50)
			, @LocationTypeID VARCHAR(20)
			, @LocationIdentifier VARCHAR(50)
			, @Comment NVARCHAR(MAX)

		/** Get Input Header Fields */
		SELECT
			 @ProductBarcodeTrackingTypeId = ProductBarcodeTrackingTypeId
			, @SrcLocationTypeID = SrcLocationTypeID
			, @SrcLocationIdentifier = SrcLocationIdentifier
			, @LocationTypeID = LocationTypeID
			, @LocationIdentifier = LocationIdentifier
			, @Comment = Comment
		FROM OPENJSON(@JsonInput, '$')
		WITH (
			ProductBarcodeTrackingTypeId VARCHAR(20) '$.productBarcodeTrackingTypeId'
			, SrcLocationTypeId VARCHAR(20) '$.srcLocationTypeId'
			, SrcLocationIdentifier VARCHAR(50) '$.srcLocationIdentifier'
			, LocationTypeId VARCHAR(20) '$.locationTypeId'
			, LocationIdentifier VARCHAR(50) '$.locationIdentifier'
			, Comment NVARCHAR(MAX) '$.comment'
		);
		/** CREATE OUTPUT TABLE */
		DECLARE @OutputTable TABLE (
			[Id] [NVARCHAR](60) NOT NULL
			, [ProductBarcodeID] [NVARCHAR](60) NOT NULL
			, [DealerId] [INT] NOT NULL
			, [PurchaseOrderItemId] [BIGINT] NOT NULL
			, [PackingSlipItemId] [BIGINT] NULL
			, [LastProductBarcodeTrackingId] [BIGINT] NULL
			, [ProductBarcodeBundleId] [NVARCHAR](50) NULL
			, [SimGUID] [VARCHAR](50) NULL
			, [BarcodeNumber] [NVARCHAR](50) NOT NULL
			, [IsAdHoc] [BIT] NOT NULL
			, [IsActive] [BIT] NOT NULL
			, [IsDeleted] [BIT] NOT NULL
			, [ModifiedDate] [DATETIMEOFFSET](7) NOT NULL
			, [ModifiedById] [UNIQUEIDENTIFIER] NOT NULL
			, [CreatedDate] [DATETIMEOFFSET](7) NOT NULL
			, [CreatedById] [UNIQUEIDENTIFIER] NOT NULL
			, [DEX_ROW] [BIGINT] NOT NULL
			, [DEX_ROW_TS] [DATETIMEOFFSET](7) NOT NULL
		);

		/** CREATE CURSOR */
		DECLARE itemsCur CURSOR LOCAL FOR
		SELECT
			Skw
			, Qty
		FROM OPENJSON(@JsonInput, '$.items')
		WITH (
			Skw VARCHAR(20) '$.skw'
			, Qty INT '$.qty'
		);

		/** OPEN AND GET FIRST */
		DECLARE @Skw VARCHAR(20), @Qty INT;
		OPEN itemsCur;
		FETCH itemsCur INTO @Skw, @Qty;

		WHILE (@@FETCH_STATUS=0) BEGIN
			/** EXECUTE LINE ITEM */
			INSERT INTO @OutputTable (Id, ProductBarcodeID, DealerId, PurchaseOrderItemId, PackingSlipItemId, LastProductBarcodeTrackingId, ProductBarcodeBundleId, SimGUID, BarcodeNumber, IsAdHoc, IsActive, IsDeleted, ModifiedDate, ModifiedById, CreatedDate, CreatedById, DEX_ROW, DEX_ROW_TS)
			EXEC [INE].[spProductBarcodeAssignAddHoc] @Skw = @Skw,
			                                          @Qty = @Qty,
			                                          @ProductBarcodeTrackingTypeId = @ProductBarcodeTrackingTypeId,
			                                          @SrcLocationTypeID = @SrcLocationTypeID,
			                                          @SrcLocationIdentifier = @SrcLocationIdentifier,
			                                          @LocationTypeID = @LocationTypeID,
			                                          @LocationIdentifier = @LocationIdentifier,
			                                          @Comment = @Comment;

			/** Move to Next Item */
			FETCH itemsCur INTO @Skw, @Qty;
		END

		CLOSE itemsCur;
		DEALLOCATE itemsCur;

		/** DISPLAY RESULTS */
		--SELECT * FROM @OutputTable;
		EXEC [INE].[spGetLocationInventory] @LocationTypeID, @LocationIdentifier;


	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spProductBarcodeAssignToLocation
/******************************************************************************
**		File: spProductBarcodeAssignToLocation.sql
**		Name: spProductBarcodeAssignToLocation
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	08/25/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spProductBarcodeAssignToLocation
(
	@BarcodeNumber VARCHAR(50)
	, @ProductBarcodeTrackingTypeId VARCHAR(20) = 'TRNF'
	, @LocationTypeID VARCHAR(20) = 'Technician'
	, @LocationIdentifier VARCHAR(50) = '1'
	, @Comment NVARCHAR(MAX)
)
AS
BEGIN
	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
	SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();

	/** INIT */
	DECLARE @ProductBarcodeID VARCHAR(60) = @BarcodeNumber + '|' + CAST(@DealerId AS VARCHAR(50));
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @ProductBarcodeTrackingID BIGINT;
		INSERT INTO [INE].[ProductBarcodeTracking] (
			[ProductBarcodeTrackingTypeId]
			, [ProductBarcodeId]
			, [DealerId]
			, [LocationTypeId]
			, [LocationIdentifier]
			, [Comment]
			, [ModifiedById]
			, [CreatedById]
		) VALUES (
			@ProductBarcodeTrackingTypeId -- ProductBarcodeTrackingTypeId - varchar(20)
			, @ProductBarcodeID			 -- ProductBarcodeId - nvarchar(60)
			, @DealerId					 -- DealerId - int
			, @LocationTypeId			 -- LocationTypeId - varchar(20)
			, @LocationIdentifier		 -- LocationIdentifier - varchar(50)
			, @Comment					 -- Comment - nvarchar(max)
			, @UserID					 -- ModifiedById - uniqueidentifier
			, @UserID					 -- CreatedById - uniqueidentifier
		);
		SET @ProductBarcodeTrackingID = SCOPE_IDENTITY();
		UPDATE PB SET
			PB.LastProductBarcodeTrackingId = @ProductBarcodeTrackingID
		FROM
			[INE].[ProductBarcodes] AS PB
		WHERE
			(PB.ProductBarcodeID = @ProductBarcodeID)
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spProductBarcodeAssignToLocationWithJsonInput
/******************************************************************************
**		File: spProductBarcodeAssignToLocationWithJsonInput.sql
**		Name: spProductBarcodeAssignToLocationWithJsonInput
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
**		Date: 09/01/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	09/01/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spProductBarcodeAssignToLocationWithJsonInput]
(
	@JsonInput NVARCHAR(MAX) = N'{}'
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @BarcodeNumber VARCHAR(50)
			, @ProductBarcodeTrackingTypeId VARCHAR(20)
			, @LocationTypeID VARCHAR(20)
			, @LocationIdentifier VARCHAR(50)
			, @Comment NVARCHAR(MAX)

		SELECT
			@ProductBarcodeTrackingTypeId=ProductBarcodeTrackingTypeId
			, @LocationTypeID=LocationTypeID
			, @LocationIdentifier=LocationIdentifier
			, @Comment=Comment
		FROM
			OPENJSON(@JsonInput, '$')
			WITH (
				--BarcodeNumber VARCHAR(50) '$.barcodeNumber'
				ProductBarcodeTrackingTypeId VARCHAR(20) '$.productBarcodeTrackingTypeId'
				, LocationTypeID VARCHAR(20) '$.locationTypeId'
				, LocationIdentifier VARCHAR(50) '$.locationIdentifier'
				, Comment NVARCHAR(MAX) '$.comment'
			);

		/** CHECK SECURITY */
		IF (NOT EXISTS(SELECT TOP(1) 1 FROM [RSU].[UserResources] WHERE UserResourceID = @LocationIdentifier AND DealerId = @DealerId)) BEGIN
			RAISERROR(N'[30050]:SECURITY VIOLATION.  Sorry you do not have access to this resource.', 18, 1);
			RETURN -1;
		END

		/** Loop through the list of barcodes. */
		DECLARE barCodeCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
		SELECT
			BarcodeNumber
		FROM
			OPENJSON(@JsonInput, '$.barcodes')
			WITH (
				BarcodeNumber VARCHAR(50) '$.barcodeNumber'
			);

		OPEN barCodeCursor;
		FETCH NEXT FROM barCodeCursor INTO @BarcodeNumber;

		WHILE(@@FETCH_STATUS = 0) BEGIN
			/** Execute Transfer */
			EXEC INE.spProductBarcodeAssignToLocation @BarcodeNumber=@BarcodeNumber, @ProductBarcodeTrackingTypeId=@ProductBarcodeTrackingTypeId, @LocationTypeID=@LocationTypeID, @LocationIdentifier=@LocationIdentifier, @Comment=@Comment;

			/** Move Cursor*/
			FETCH NEXT FROM barCodeCursor INTO @BarcodeNumber;
		END

		CLOSE barCodeCursor;
		DEALLOCATE barCodeCursor;

		/** DISPLAY RESULTS */
		--SELECT * FROM @OutputTable;
		EXEC [INE].[spGetLocationInventory] @LocationTypeID=@LocationTypeID, @LocationIdentifier=@LocationIdentifier;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spProductBarcodeTrackingHistoryGETByBarcodeJSON
/******************************************************************************
**		File: spProductBarcodeTrackingHistoryGETByBarcodeJSON.sql
**		Name: spProductBarcodeTrackingHistoryGETByBarcodeJSON
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
**		Auth: Andrés Sosa
**		Date: 02/27/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	02/27/2018	Andrés Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spProductBarcodeTrackingHistoryGETByBarcodeJSON]
(
	@ProductBarcodeId VARCHAR(50)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();

	/** CHECK SECURITY */
	IF (NOT EXISTS(SELECT TOP(1) 1 FROM [INE].[ProductBarcodeTracking] AS PBT WITH(NOLOCK) WHERE (PBT.ProductBarcodeId = @ProductBarcodeId) AND (PBT.DealerId = @DealerId))) BEGIN
		RAISERROR(N'[30050]:SECURITY VIOLATION.  You do not have access to these resources.', 18, 1);
		RETURN -1;
	END
	
	BEGIN TRY
		-- ** STATEMENT
		SELECT (SELECT 
				PBT.ProductBarcodeTrackingID AS id
				, PBT.ProductBarcodeTrackingTypeId AS productBarcodeTrackingTypeId
				, PBT.ProductBarcodeId AS productBarcodeId
				, PBT.DealerId AS dealerId
				, PBT.AuditId AS auditId
				, PBT.LocationTypeId AS locationTypeId
				, PBT.LocationIdentifier AS locationIdentifier
				, PBT.Comment AS comment
				, PBT.IsActive AS isActive
				, PBT.IsDeleted AS isDeleted
				, PBT.ModifiedDate AS modifiedDate
				, PBT.ModifiedById AS modifiedById
				, PBT.CreatedDate AS createdDate
				, PBT.CreatedById AS createdById
			FROM
				[INE].[ProductBarcodeTracking] AS PBT WITH(NOLOCK)
			WHERE
				(PBT.ProductBarcodeId = @ProductBarcodeId)
				AND (PBT.IsDeleted = 'False')
			ORDER BY
				PBT.ProductBarcodeTrackingID DESC
			FOR JSON PATH, INCLUDE_NULL_VALUES) AS JsonOutPutMethod;

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPurchaseOrderItemDelete_JSON
/******************************************************************************
**		File: [spPurchaseOrderItemDelete_JSON.sql
**		Name: [spPurchaseOrderItemDelete_JSON
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spPurchaseOrderItemDelete_JSON]
(
	@PurchaseOrderItemID BIGINT
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @DealerId INT;
	SELECT @UserID = UserID, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		
		/**	VALIDATIONS */
		IF (NOT EXISTS(SELECT TOP(1) 1 
				FROM 
					[INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
					INNER JOIN [INE].[PurchaseOrders] AS PO WITH(NOLOCK)
					ON
						(PO.PurchaseOrderID = POI.PurchaseOrderId)
						AND (PO.DealerId = @DealerId)
					WHERE 
						(POI.PurchaseOrderItemID = @PurchaseOrderItemID))) BEGIN
			DECLARE @POItemID VARCHAR(50) = CAST(@PurchaseOrderItemID AS VARCHAR(50));
			RAISERROR(N'[30500]:SECURITY VIOLATION.  Sorry but the PO Item ID "%s" does not exists or you do not have rights to it.', 18, 1, @POItemID);
		END
		
		-- ** STATEMENT
		UPDATE [INE].[PurchaseOrderItems] SET
			IsActive = 'False'
			, IsDeleted = 'True'
			, ModifiedDate = SYSDATETIMEOFFSET()
			, ModifiedById = @UserID
		WHERE
			(PurchaseOrderItemID = @PurchaseOrderItemID);
		
		/** RETURN RESULT */
		SELECT [INE].[fxGetPurchaseOrderItemAsJson](@PurchaseOrderItemID) AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPurchaseOrderItemReceiveItemsWithJsonInput
/******************************************************************************
**		File: spPurchaseOrderItemReceiveItemsWithJsonInput.sql
**		Name: spPurchaseOrderItemReceiveItemsWithJsonInput
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spPurchaseOrderItemReceiveItemsWithJsonInput
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
	
	/** LOCALS */
	DECLARE @RootTable TABLE (
		PurchaseOrderItemId BIGINT NOT NULL
		, ProductSkwId BIGINT NOT NULL
		, PackingSlipId BIGINT NULL
		, ProductBarcodeTrackingTypeID VARCHAR(20) NOT NULL
		, LocationTypeId VARCHAR(20) NOT NULL
		, LocationIdentifier VARCHAR(50) NOT NULL
		, InventoryType VARCHAR(20) NULL
		, Quantity INT NOT NULL
		, BarcodeNumber VARCHAR(50)
	);
	DECLARE @ProdBarcodeTableId TABLE (ProductBarcodeID NVARCHAR(60) NOT NULL);

	BEGIN TRY
		-- ** STATEMENT
		WITH RootAdHocCte AS (
			SELECT 
				JSON_VALUE(@JsonInput, '$.productBarcodeTrackingTypeId') AS DefaultProductBarcodeTrackingTypeId
				, JSON_VALUE(@JsonInput, '$.locationTypeId') AS DefaultLocationTypeId
				, JSON_VALUE(@JsonInput, '$.locationIdentifier') AS DefaultLocationIdentifier
				, CAST(JSON_VALUE(@JsonInput, '$.packingSlipId') AS BIGINT) AS PackingSlipId
				, 'AdHoc' AS DefaultInventoryType
				, BS.PurchaseOrderItemId
				, BS.Quantity
				, NULL AS BarcodeNumber
			FROM
				OPENJSON(JSON_QUERY(@JsonInput, '$.adHocItems'), '$')
			WITH (
				PurchaseOrderItemId BIGINT '$.purchaseOrderItemId'
				, Quantity INT '$.qty'
			) AS BS
		)
		--SELECT * FROM RootAdHocCte WHERE RootAdHocCte.Quantity > 0;
		, RootBcCTE AS (
			SELECT 
				JSON_VALUE(@JsonInput, '$.productBarcodeTrackingTypeId') AS DefaultProductBarcodeTrackingTypeId
				, JSON_VALUE(@JsonInput, '$.locationTypeId') AS DefaultLocationTypeId
				, JSON_VALUE(@JsonInput, '$.locationIdentifier') AS DefaultLocationIdentifier
				, CAST(JSON_VALUE(@JsonInput, '$.packingSlipId') AS BIGINT) AS PackingSlipId
				, 'BCode' AS DefaultInventoryType
				, BS.PurchaseOrderItemId
				, 1 AS Quantity
				, BS.BarcodeNumber
			FROM
				OPENJSON(JSON_QUERY(@JsonInput, '$.bCodeItems'), '$')
			WITH (
				PurchaseOrderItemId BIGINT '$.purchaseOrderItemId'
				, BarcodeNumber NVARCHAR(50) '$.barcodeNumber'
			) AS BS
		)
		, RootCTE AS (
			SELECT * FROM RootAdHocCte WHERE RootAdHocCte.Quantity > 0
			UNION
			SELECT * FROM RootBcCTE
		)
		--SELECT * FROM RootCTE;
		, ProdItems AS (
			SELECT
				RC.DefaultProductBarcodeTrackingTypeId
				, RC.DefaultLocationTypeId
				, ISNULL(RC.DefaultLocationIdentifier, POI.WarehouseSiteId) AS DefaultLocationIdentifier
				, RC.DefaultInventoryType
				, RC.PackingSlipId
				, POI.ProductSkwId
				, RC.PurchaseOrderItemId
				, RC.Quantity
				, RC.BarcodeNumber
			FROM 
				RootCte AS RC WITH(NOLOCK)
				INNER JOIN [INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
				ON
					(POI.PurchaseOrderItemID = RC.PurchaseOrderItemId)
		)
		INSERT INTO @RootTable (PurchaseOrderItemId, ProductSkwId, PackingSlipId, ProductBarcodeTrackingTypeID, LocationTypeId, LocationIdentifier, InventoryType, Quantity, BarcodeNumber)
		SELECT 
			ProdItems.PurchaseOrderItemId
			, ProdItems.ProductSkwId
			, ProdItems.PackingSlipId
			, ProdItems.DefaultProductBarcodeTrackingTypeId
			, ProdItems.DefaultLocationTypeId
			, ProdItems.DefaultLocationIdentifier
			, ProdItems.DefaultInventoryType
			, ProdItems.Quantity
			, ProdItems.BarcodeNumber
		FROM ProdItems;

		/** CREATE CURSOR */
		DECLARE @PurchaseOrderItemId BIGINT
			, @ProductSkwId BIGINT
			, @ProductBarcodeTrackingTypeID VARCHAR(20)
			, @PackingSlipId BIGINT
			, @LocationTypeId VARCHAR(20)
			, @LocationIdentifier VARCHAR(50)
			, @InventoryType VARCHAR(20)
			, @Quantity INT
			, @BarcodeNumber VARCHAR(50)

		DECLARE curActions CURSOR FOR
		SELECT * FROM @RootTable;

		OPEN curActions;
		FETCH NEXT FROM curActions
		INTO @PurchaseOrderItemId, @ProductSkwId, @PackingSlipId, @ProductBarcodeTrackingTypeID, @LocationTypeId, @LocationIdentifier, @InventoryType, @Quantity, @BarcodeNumber;

		WHILE (@@FETCH_STATUS = 0) BEGIN
			/** LOCALS */
			DECLARE @Counter INT = 0;

			/** Check that the current user belongs to the correct dealer */
			IF(NOT EXISTS(SELECT TOP 1 1 FROM [INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
				INNER JOIN [INE].[PurchaseOrders] AS PO WITH(NOLOCK)
				ON
					(POI.PurchaseOrderItemID = @PurchaseOrderItemId)
					AND (PO.PurchaseOrderID = POI.PurchaseOrderId)
					AND (PO.DealerId = @DealerId))) BEGIN

				CLOSE curActions;
				DEALLOCATE curActions;

				RAISERROR(N'[30050]:Security Violation: "The items passed do not belong to the signed in dealer."', 18, 1);
				RETURN;
			END

			/** Create PackingSlipItem */
			DECLARE @PackingSlipItemId BIGINT = NULL;
			IF (@PackingSlipId IS NOT NULL) BEGIN
				SET @PackingSlipItemId = (SELECT TOP 1 PackingSlipItemID FROM [INE].[PackingSlipItems] WHERE PackingSlipId = @PackingSlipId AND PurchaseOrderItemId = @PurchaseOrderItemId);
				IF (@PackingSlipItemId IS NULL) BEGIN
					INSERT INTO [INE].[PackingSlipItems] ([PackingSlipId], [PurchaseOrderItemId], [ProductSkwId], [Quantity], [ModifiedById], [CreatedById])
					VALUES (@PackingSlipId, @PurchaseOrderItemId, @ProductSkwId, @Quantity, @UserID, @UserID);
					SET @PackingSlipItemId = SCOPE_IDENTITY();
				END ELSE BEGIN
					UPDATE [INE].[PackingSlipItems] SET Quantity = Quantity + @Quantity WHERE PackingSlipItemID = @PackingSlipItemId;
				END
			END

			/** LOCALS */
			DECLARE @ProductBarcodeId VARCHAR(60)
				, @ProductBarcodeTrackingID BIGINT;

			/** CHECK THE TYPE OF BARCODE */
			IF (@InventoryType = 'ADHOC') BEGIN
				/** INIT */
				SET @ProductBarcodeId = [INE].[fxGetAdHocRandomBarcodeId](@DealerId);
				SET @BarcodeNumber = (SELECT BarcodeNumber FROM [INE].[fxGetBarcodeNumberBreakOut](@ProductBarcodeId));

				/** LOOP THROUGH EACH ITEM */
				WHILE(@Counter < @Quantity) BEGIN
					/** LOCALS */
					SET @ProductBarcodeId = [INE].[fxGetAdHocRandomBarcodeId](@DealerId);
					SET @BarcodeNumber = (SELECT BarcodeNumber FROM [INE].[fxGetBarcodeNumberBreakOut](@ProductBarcodeId));
					INSERT INTO @ProdBarcodeTableId ( ProductBarcodeID ) VALUES ( @ProductBarcodeId );

					/** Add to Tracking */
					INSERT INTO [INE].[ProductBarcodes] ([ProductBarcodeID], [DealerId], [PurchaseOrderItemId], [PackingSlipItemId],[BarcodeNumber],[IsAdHoc],[ModifiedById],[CreatedById])
					VALUES (@ProductBarcodeID, @DealerId, @PurchaseOrderItemId, @PackingSlipItemId, @BarcodeNumber, CAST('True' AS BIT), @UserID, @UserID);
					INSERT INTO [INE].[ProductBarcodeTracking] ([ProductBarcodeTrackingTypeId],[ProductBarcodeId],[DealerId],[LocationTypeId],[LocationIdentifier],[ModifiedById],[CreatedById])
					VALUES (@ProductBarcodeTrackingTypeId, @ProductBarcodeId, @DealerId, @LocationTypeId, @LocationIdentifier, @UserID, @UserID);
					SET @ProductBarcodeTrackingID = SCOPE_IDENTITY();
					UPDATE [INE].[ProductBarcodes] SET LastProductBarcodeTrackingId = @ProductBarcodeTrackingID WHERE (ProductBarcodeID = @ProductBarcodeId);

					/** MOVE COUNTER */
					SET @Counter = @Counter + 1;
				END
			END ELSE BEGIN
				/** LOCALS */
				SET @ProductBarcodeId = @BarcodeNumber + '|' + CAST(@DealerId AS VARCHAR(20));

				/** Check to see if the Barcode Exists. */
				IF (EXISTS(SELECT TOP 1 1 FROM [INE].[ProductBarcodes] WHERE ProductBarcodeID = @ProductBarcodeId)) BEGIN
					RAISERROR (N'[30100]:Sorry but the Barcode Number "%s" is already in our database.', 18, 1, @BarcodeNumber);
					RETURN;
				END

				/** Save BarCode Number for Result Output */
				INSERT INTO @ProdBarcodeTableId ( ProductBarcodeID ) VALUES ( @ProductBarcodeId );

				/** Add to Tracking */
				INSERT INTO [INE].[ProductBarcodes] ([ProductBarcodeID], [DealerId], [PurchaseOrderItemId], [PackingSlipItemId],[BarcodeNumber],[IsAdHoc],[ModifiedById],[CreatedById])
				VALUES (@ProductBarcodeID, @DealerId, @PurchaseOrderItemId, @PackingSlipItemId, @BarcodeNumber, CAST('False' AS BIT), @UserID, @UserID);
				INSERT INTO [INE].[ProductBarcodeTracking] ([ProductBarcodeTrackingTypeId],[ProductBarcodeId],[DealerId],[LocationTypeId],[LocationIdentifier],[ModifiedById],[CreatedById])
				VALUES (@ProductBarcodeTrackingTypeId, @ProductBarcodeId, @DealerId, @LocationTypeId, @LocationIdentifier, @UserID, @UserID);
				SET @ProductBarcodeTrackingID = SCOPE_IDENTITY();
				UPDATE [INE].[ProductBarcodes] SET LastProductBarcodeTrackingId = @ProductBarcodeTrackingID WHERE (ProductBarcodeID = @ProductBarcodeId);

			END
			
			/** NEXT */
			FETCH NEXT FROM curActions
			INTO @PurchaseOrderItemId, @ProductSkwId, @PackingSlipId, @ProductBarcodeTrackingTypeID, @LocationTypeId, @LocationIdentifier, @InventoryType, @Quantity, @BarcodeNumber;
		END

		CLOSE curActions;
		DEALLOCATE curActions;
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH

	/** RETURN RESULT of All PB's Added */
	SELECT
	(SELECT
		PB.ProductBarcodeID AS id
		, PB.ProductBarcodeID AS productBarcodeID
        , PB.DealerId AS dealerId
        , PB.PurchaseOrderItemId AS purchaseOrderItemId
        , PB.PackingSlipItemId AS packingSlipItemId
        , PB.LastProductBarcodeTrackingId AS lastProductBarcodeTrackingId
        , PB.ProductBarcodeBundleId AS productBarcodeBundleId
        , PB.SimGUID AS simGUID
        , PB.BarcodeNumber AS barcodeNumber
        , PB.IsAdHoc AS isAdHoc
        , PB.IsActive AS isActive
        , PB.ModifiedDate
		, MDU.UserID AS [modifidedBy.id]
		, MDU.FullName AS [modifidedBy.fullName]
		, MDU.FullNameWithGPID AS [modifidedBy.fullNameWithGPID]
        , PB.CreatedDate
		, CDU.UserID AS [createdBy.id]
		, CDU.FullName AS [createdBy.fullName]
		, CDU.FullNameWithGPID AS [createdBy.fullNameWithGPID]
	FROM
		[INE].[ProductBarcodes] AS PB WITH(NOLOCK)
		INNER JOIN @ProdBarcodeTableId AS PBTID
		ON
			(PBTID.ProductBarcodeID = PB.ProductBarcodeID)
		INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS MDU 
		ON
			(MDU.UserID = PB.ModifiedById)
		INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS CDU
		ON
			(CDU.UserID = PB.CreatedById)
	FOR JSON PATH) AS [JsonOutPutMethod];
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPurchaseOrderItemSaveWithJsonInput
/******************************************************************************
**		File: spPurchaseOrderItemSaveWithJsonInput.sql
**		Name: spPurchaseOrderItemSaveWithJsonInput
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spPurchaseOrderItemSaveWithJsonInput]
(
	@JsonInput NVARCHAR(MAX)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @UserID UNIQUEIDENTIFIER, @DealerId INT;
	SELECT @UserID = UserID, @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @PurchaseOrderItemID BIGINT = (SELECT [PurchaseOrderItemID] FROM OPENJSON(@JsonInput, '$') WITH (PurchaseOrderItemID BIGINT '$.id'))
			, @PurchaseOrderId BIGINT = (SELECT [PurchaseOrderId] FROM OPENJSON(@JsonInput, '$') WITH (PurchaseOrderId BIGINT '$.purchaseOrderId'))
			, @ProductSkwId BIGINT = (SELECT [ProductSkwId] FROM OPENJSON(@JsonInput, '$') WITH (ProductSkwId BIGINT '$.productSkwId'))
			, @WarehouseSiteId VARCHAR(20) = (SELECT [WarehouseSiteId] FROM OPENJSON(@JsonInput, '$') WITH (WarehouseSiteId VARCHAR(20) '$.warehouseSiteId'))
			, @Quantity INT = (SELECT [Quantity] FROM OPENJSON(@JsonInput, '$') WITH (Quantity INT '$.quantity'));
		
		/**	VALIDATIONS */
		IF (@PurchaseOrderItemID <> 0 AND NOT EXISTS(SELECT TOP 1 1 
				FROM 
					[INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
					INNER JOIN [INE].[PurchaseOrders] AS PO WITH(NOLOCK)
					ON
						(PO.PurchaseOrderID = POI.PurchaseOrderId)
						AND (PO.PurchaseOrderID = @PurchaseOrderId)
						AND (PO.DealerId = @DealerId)
					WHERE 
						(POI.PurchaseOrderItemID = @PurchaseOrderItemID))) BEGIN
			DECLARE @POItemID VARCHAR(50) = CAST(@PurchaseOrderItemID AS VARCHAR(50));
			RAISERROR(N'[30500]: Sorry but the PO Item ID "%s" does not exits', 18, 1, @POItemID);
		END
		IF (@PurchaseOrderId IS NULL OR @PurchaseOrderId = 0) BEGIN
			RAISERROR(N'[30500]: Sorry but a PO ID must be passed', 18, 1);
		END
		IF (@ProductSkwId IS NULL OR @ProductSkwId = 0) BEGIN
			RAISERROR(N'[30500]: Sorry but a ProdSkw ID must be passed', 18, 1);
		END
		IF (@WarehouseSiteId IS NULL OR @WarehouseSiteId = '') BEGIN
			RAISERROR(N'[30500]: Sorry but a Warehouse Site ID must be passed', 18, 1);
		END
		
		-- ** STATEMENT
		PRINT '@PurchaseOrderItemID:' + CAST(@PurchaseOrderItemID AS VARCHAR(50))
		IF (@PurchaseOrderItemID = 0) BEGIN
			PRINT 'CREATING...';
			INSERT INTO [INE].[PurchaseOrderItems] ([PurchaseOrderId],[ProductSkwId],[WarehouseSiteId],[Quantity],[IsActive],[ModifiedById],[CreatedById])
			SELECT
				@PurchaseOrderId
				, @ProductSkwId
				, @WarehouseSiteId
				, Quantity
				, ISNULL(IsActive, 1) AS IsActive
				, @UserID
				, @UserID
			FROM OPENJSON(@JsonInput, '$') WITH (
				Quantity BIGINT '$.quantity'
				, IsActive BIT '$.isActive'
			);
			SET @PurchaseOrderItemID = SCOPE_IDENTITY();
		END ELSE BEGIN
			PRINT 'UPDATING...';
			UPDATE POI SET
				POI.ProductSkwId = @ProductSkwId
				, POI.WarehouseSiteId = @WarehouseSiteId
				, POI.Quantity = @Quantity
				, POI.ModifiedById = @UserID
				, POI.ModifiedDate = SYSDATETIMEOFFSET()
			FROM
				[INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
			WHERE
				(POI.PurchaseOrderItemID = @PurchaseOrderItemID);
		END

		
		/** RETURN RESULT */
		SELECT [INE].[fxGetPurchaseOrderItemAsJson](@PurchaseOrderItemID) AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPurchaseOrderSaveWithJsonInput
/******************************************************************************
**		File: spPurchaseOrderSaveWithJsonInput.sql
**		Name: spPurchaseOrderSaveWithJsonInput
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spPurchaseOrderSaveWithJsonInput
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
		DECLARE @PurchaseOrderID BIGINT = (SELECT [PurchaseOrderID] FROM OPENJSON(@JsonInput, '$') WITH (PurchaseOrderID BIGINT '$.id'));

		/**	VALIDATE PO# */
		IF (@PurchaseOrderID <> 0 AND NOT EXISTS(SELECT TOP 1 1 FROM [INE].[PurchaseOrders] WHERE DealerId = @DealerId AND PurchaseOrderID = @PurchaseOrderID)) BEGIN
			DECLARE @POID VARCHAR(50) = CAST(@PurchaseOrderID AS VARCHAR(50));
			RAISERROR(N'[30500]: Sorry but the PO "%s" does not exits', 18, 1, @POID);
		END
		-- ** STATEMENT
		PRINT '@PurchaseOrderID:' + CAST(@PurchaseOrderID AS VARCHAR(50))

		IF(@PurchaseOrderID = 0) BEGIN
			PRINT 'Creating PO';
			INSERT INTO [INE].[PurchaseOrders] (
				[DealerId]
				,[VendorId]
				,[WarehouseSiteId]
				,[AttentionLine]
				,[GPPONumber]
				,[VendorRefNumber]
				,[CreditTerms]
				,[SubTotal]
				,[Tax]
				,[Total]
				,[Comments]
				,[IsActive]
				,[ModifiedById]
				,[CreatedById])
			SELECT
				@DealerId
				, VendorId
				, WarehouseSiteId
				, AttentionLine
				, GPPONumber
				, VendorRefNumber
				, CreditTerms
				, SubTotal
				, Tax
				, Total
				, Comments
				, ISNULL(IsActive, 1) AS IsActive
				, @UserID
				, @UserID
			FROM OPENJSON (@JsonInput, '$')
			WITH (
				VendorId VARCHAR(20) '$.vendorId'
				, WarehouseSiteId VARCHAR(20) '$.warehouseSiteId'
				, AttentionLine VARCHAR(255) '$.attentionLine'
				, GPPONumber VARCHAR(50) '$.gPPONumber'
				, VendorRefNumber VARCHAR(50) '$.vendorRefNumber'
				, CreditTerms VARCHAR(50) '$.creditTerms'
				, SubTotal MONEY '$.subTotal'
				, Tax MONEY '$.tax'
				, Total MONEY '$.total'
				, CompletedDate DATETIMEOFFSET(7) '$.completedDate'
				, Comments NVARCHAR(MAX) '$.comments'
				, IsActive BIT '$.isActive');
			SET @PurchaseOrderID = SCOPE_IDENTITY();

		END ELSE BEGIN
			PRINT 'Upating PO';
			UPDATE PO SET 
				PO.VendorId = RT.VendorId
				, PO.WarehouseSiteId = RT.WarehouseSiteId
				, PO.AttentionLine = RT.AttentionLine
				, PO.GPPONumber = RT.GPPONumber
				, PO.VendorRefNumber = RT.VendorRefNumber
				, PO.CreditTerms = RT.CreditTerms
				, PO.SubTotal = RT.SubTotal
				, PO.Tax = RT.Tax
				, PO.Total = RT.Total
				, PO.Comments = RT.Comments
				, PO.IsActive = RT.IsActive
				, PO.ModifiedDate = SYSDATETIMEOFFSET()
				, PO.ModifiedById = @UserID
			FROM
				[INE].[PurchaseOrders] AS PO WITH(NOLOCK)
				INNER JOIN (SELECT
						PurchaseOrderID
						, VendorId
						, WarehouseSiteId
						, AttentionLine
						, GPPONumber
						, VendorRefNumber
						, CreditTerms
						, SubTotal
						, Tax
						, Total
						, Comments
						, ISNULL(IsActive, 1) AS IsActive
					FROM OPENJSON (@JsonInput, '$')
					WITH (
						PurchaseOrderID BIGINT '$.id'
						, VendorId VARCHAR(20) '$.vendorId'
						, WarehouseSiteId VARCHAR(20) '$.warehouseSiteId'
						, AttentionLine VARCHAR(255) '$.attentionLine'
						, GPPONumber VARCHAR(50) '$.gPPONumber'
						, VendorRefNumber VARCHAR(50) '$.vendorRefNumber'
						, CreditTerms VARCHAR(50) '$.creditTerms'
						, SubTotal MONEY '$.subTotal'
						, Tax MONEY '$.tax'
						, Total MONEY '$.total'
						, CompletedDate DATETIMEOFFSET(7) '$.completedDate'
						, Comments NVARCHAR(MAX) '$.comments'
						, IsActive BIT '$.isActive')

					) AS RT
				ON
					(RT.PurchaseOrderID = PO.PurchaseOrderID)
		END

		/** RETURN RESULT */
		SELECT [INE].[fxGetPurchaseOrderAsJson](@PurchaseOrderID) AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPurchaseOrderSearch
/******************************************************************************
**		File: spPurchaseOrderSearch.sql
**		Name: spPurchaseOrderSearch
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure [INE].[spPurchaseOrderSearch]
(
	@PurchaseOrderId BIGINT
	, @GPPONumber VARCHAR(50) = NULL
	, @VendorId VARCHAR(20) = NULL
	, @StartDate DATETIMEOFFSET(7) = NULL
	, @EndDate DATETIMEOFFSET(7) = NULL
	, @Status VARCHAR(50) = NULL
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();

	/** INITIALIZE */
	SET @GPPONumber = REPLACE(@GPPONumber, '*', '%');
	
	BEGIN TRY
		-- ** STATEMENT
		WITH RootCte AS
		(
			SELECT
				PO.PurchaseOrderID
				, PO.DealerId
				, PO.VendorId
				, V.VendorName
				, PO.WarehouseSiteId
				, W.WarehouseSiteName
				, PO.GPPONumber
				, PO.VendorRefNumber
				, PO.CompletedDate
				, PO.SubmittedDate
				, PO.CreditTerms
				, PO.AttentionLine
				, PO.Comments
				, CASE
					WHEN PO.SubmittedDate IS NULL THEN 'Open'
					WHEN PO.CompletedDate IS NULL THEN 'Submitted'
					ELSE 'Closed'
				  END AS [Status]
				, PO.SubTotal
				, PO.Tax
				, PO.Total
				, PO.IsActive
				, PO.ModifiedDate
				, PO.ModifiedById
				, PO.CreatedDate
				, PO.CreatedById
			FROM
				[INE].[PurchaseOrders] AS PO WITH(NOLOCK)
				INNER JOIN [INE].[Vendors] AS V WITH(NOLOCK)
				ON
					(V.VendorID = PO.VendorId)
				INNER JOIN [INE].[WarehouseSites] AS W WITH(NOLOCK)
				ON
					(W.WarehouseSiteID = PO.WarehouseSiteId)
			WHERE
				(PO.DealerId = @DealerId)
				AND (@PurchaseOrderId IS NULL OR PO.PurchaseOrderID = @PurchaseOrderId)
				AND (@VendorId IS NULL OR PO.VendorId = @VendorId)
				AND (@StartDate IS NULL OR @EndDate IS NULL OR PO.CreatedDate BETWEEN @StartDate AND @EndDate)
				AND (@GPPONumber IS NULL OR PO.GPPONumber LIKE @GPPONumber)
				AND (PO.IsDeleted = 'False')
		)
		, OnPORootCte AS (
			SELECT
				RT.*
			FROM
				RootCte AS RT WITH(NOLOCK)
			WHERE 
				(@Status IS NULL OR RT.[Status] = @Status)
		)
		--SELECT * FROM OnPORootCte;
		, OnPOItemRootCte AS (
			SELECT
				POI.PurchaseOrderItemID
				, POI.PurchaseOrderId
				, POI.ProductSkwId
				, POI.WarehouseSiteId
				, POI.Quantity
				, (SELECT COUNT(*) FROM [INE].[fxGetPurchaseOrderItemAssignments](POI.PurchaseOrderItemID)) AS [Received]
				, POI.IsActive
				, POI.ModifiedDate
				, MDU.UserID AS [modifidedBy.id]
				, MDU.FullName AS [modifidedBy.fullName]
				, MDU.FullNameWithGPID AS [modifidedBy.fullNameWithGPID]
				, POI.CreatedDate
				, CDU.UserID AS [createdBy.id]
				, CDU.FullName AS [createdBy.fullName]
				, CDU.FullNameWithGPID AS [createdBy.fullNameWithGPID]
			FROM 
				[INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
				INNER JOIN OnPORootCte AS RT WITH(NOLOCK)
				ON
					(RT.PurchaseOrderID = POI.PurchaseOrderId)
				INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS MDU 
				ON
					(MDU.UserID = RT.ModifiedById)
				INNER JOIN [ACC].[fxGetUserInfoByUserIdTABLE](NULL) AS CDU
				ON
					(CDU.UserID = RT.CreatedById)
			WHERE
				(@Status IS NULL OR @Status = RT.[Status])
				AND (POI.IsDeleted = 'False')
		)
		SELECT 
			(SELECT
				RT.PurchaseOrderID AS id
				, RT.PurchaseOrderID AS purchaseOrderID
				, RT.DealerId AS dealerId
				, RT.VendorId AS vendorId
				, RT.VendorName AS vendorName
				, RT.WarehouseSiteId AS warehouseSiteId
				, RT.WarehouseSiteName AS warehouseSiteName
				, RT.VendorRefNumber AS vendorRefNumber
				, RT.CreditTerms AS creditTerms
				, RT.GPPONumber AS gPPONumber
				, RT.CompletedDate AS completedDate
				, RT.SubmittedDate AS submittedDate
				, RT.[Status] AS [status]
				, RT.AttentionLine AS attentionLine
				, RT.Comments AS comments
				, RT.IsActive AS isActive
				, RT.ModifiedDate AS modifiedDate
				--, RT.ModifiedById AS modifiedById
				, MDU.UserID AS [modifiedBy.id]
				, MDU.FullName AS [modifiedBy.fullName]
				, MDU.FullNameWithGPID AS [modifiedBy.fullNameWithGPID]
				, RT.CreatedDate AS createdDate
				--, RT.CreatedById AS createdById
				, CDU.UserID AS [createdBy.id]
				, CDU.FullName AS [createdBy.fullName]
				, CDU.FullNameWithGPID AS [createdBy.fullNameWithGPID]
				, (SELECT
					RTI.PurchaseOrderItemID AS id
					, RTI.PurchaseOrderId AS purchaseOrderId
					, RTI.PurchaseOrderItemID AS purchaseOrderItemID
					, RTI.ProductSkwId AS productSkwId
					, PSK.ProductSkwID AS  [productSkw.id]
					, PSK.Skw AS [productSkw.skw]
					, PSK.ShortName AS [productSkw.shortName]
					, PSK.ProductName AS [productSkw.productName]
					, PSK.ProductDescription AS [productSkw.productDescription]
					, RTI.WarehouseSiteId AS warehouseSiteId
					, RTI.Quantity AS quantity
					, RTI.Received AS received
					, RTI.Quantity - RTI.Received AS [outstanding]
					, RTI.IsActive AS isActive
					, RTI.ModifiedDate AS modifiedDate
					, RTI.[modifidedBy.id]
					, RTI.[modifidedBy.fullName]
					, RTI.[modifidedBy.fullNameWithGPID]
					, RTI.CreatedDate AS createdDate
					, RTI.[createdBy.id]
					, RTI.[createdBy.fullName]
					, RTI.[createdBy.fullNameWithGPID]
				FROM 
					OnPOItemRootCte AS RTI WITH(NOLOCK)
					INNER JOIN [ACE].[ProductSkws] AS PSK WITH(NOLOCK)
					ON
						(PSK.ProductSkwID = RTI.ProductSkwId)
				WHERE 
					(RT.PurchaseOrderID = RTI.PurchaseOrderId)
				FOR JSON PATH, INCLUDE_NULL_VALUES) AS invoiceItems
				, (SELECT
					PS.PackingSlipID AS id
					, PS.PackingSlipID AS packingSlipID
					, PS.PurchaseOrderId AS purchaseOrderId
					, PS.ArrivalDate AS arrivalDate
					, PS.CloseDate AS closeDate
					, PS.PackingSlipNumber AS packingSlipNumber
					, PS.IsActive AS isActive
					, PS.ModifiedDate AS modifiedDate
					, MDU.UserID AS [modifiedBy.id]
					, MDU.FullName AS [modifiedBy.fullName]
					, MDU.FullNameWithGPID AS [modifiedBy.fullNameWithGPID]
					, PS.CreatedDate AS createdDate
					, CDU.UserID AS [createdBy.id]
					, CDU.FullName AS [createdBy.fullName]
					, CDU.FullNameWithGPID AS [createdBy.fullNameWithGPID]
				FROM
					[INE].[PackingSlips] AS PS WITH(NOLOCK)
					INNER JOIN [ACC].[vwUserSummaryInfo] AS MDU 
					ON
						(PS.PurchaseOrderId = RT.PurchaseOrderID)
						AND (MDU.UserID = PS.ModifiedById)
						AND (PS.IsDeleted = 'False')
					INNER JOIN [ACC].[vwUserSummaryInfo] AS CDU
					ON
						(CDU.UserID = PS.CreatedById)
				FOR JSON PATH, INCLUDE_NULL_VALUES) AS packingSlips
			FROM 
				OnPORootCte AS RT WITH(NOLOCK)
				INNER JOIN [ACC].[vwUserSummaryInfo] AS MDU 
				ON
					(MDU.UserID = RT.ModifiedById)
				INNER JOIN [ACC].[vwUserSummaryInfo] AS CDU
				ON
					(CDU.UserID = RT.CreatedById)
			ORDER BY
				RT.PurchaseOrderID DESC
			FOR JSON PATH, INCLUDE_NULL_VALUES) AS [JsonOutPutMethod];

	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_STORED_PROCEDURE INE.spPurchaseOrderUpdateWithJsonInput
/******************************************************************************
**		File: spPurchaseOrderUpdateWithJsonInput.sql
**		Name: spPurchaseOrderUpdateWithJsonInput
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
**		Date: 07/10/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	07/10/2017	Andres Sosa		Created By
**	
*******************************************************************************/
CREATE Procedure INE.spPurchaseOrderUpdateWithJsonInput
(
	@JsonInput NVARCHAR(MAX)
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** SECURITY */
	DECLARE @DealerId INT;
	SELECT @DealerId = DealerId FROM [ACC].[fxGetContextUserTable]();
	
	BEGIN TRY
		/** LOCALS */
		DECLARE @PurchaseOrderID BIGINT
			, @Action VARCHAR(25)
			, @SubmittedDate DATETIMEOFFSET(7)
			, @CompletedDate DATETIMEOFFSET(7);

		-- ** STATEMENT
		DECLARE @PoliticalTimeZoneId INT = (SELECT TOP (1) PoliticalTimeZoneId FROM [ACC].[Dealers] WHERE (DealerID = @DealerId) ORDER BY PoliticalTimeZoneId);
		WITH RootCTE AS (
			SELECT
				PurchaseOrderID
                , [Action]
				, CASE
					WHEN [SubmittedDate] IS NOT NULL THEN [UTL].[fxGetDateTimeOffsetFromDateByTimeZoneId](SubmittedDate, @PoliticalTimeZoneId, 'False')
					ELSE SYSDATETIMEOFFSET()
				  END AS [SubmittedDate]
				, CASE
					WHEN [CompletedDate] IS NOT NULL THEN [UTL].[fxGetDateTimeOffsetFromDateByTimeZoneId](SubmittedDate, @PoliticalTimeZoneId, 'False')
					ELSE SYSDATETIMEOFFSET()
				  END AS [CompletedDate]
			FROM
				OPENJSON(@JsonInput, '$')
			WITH (
				[PurchaseOrderID] BIGINT '$.id'
				, [Action] VARCHAR(20) '$.action'
				, [SubmittedDate] DATE '$.submittedDate'
				, [CompletedDate] DATE '$.completedDate'
			)
		)
		SELECT
			@PurchaseOrderID = RT.PurchaseOrderID
            , @Action = RT.[Action]
            , @SubmittedDate = RT.SubmittedDate
            , @CompletedDate = RT.CompletedDate 
		FROM
			RootCTE AS RT WITH(NOLOCK);

		/** Perform Action */
		IF (@Action = 'SubmitPO') BEGIN
			UPDATE PO SET PO.SubmittedDate = @SubmittedDate FROM [INE].[PurchaseOrders] AS PO WITH(NOLOCK) WHERE (PO.PurchaseOrderID = @PurchaseOrderID);
		END ELSE IF (@Action = 'ClosePO') BEGIN
			UPDATE PO SET PO.CompletedDate = @CompletedDate FROM [INE].[PurchaseOrders] AS PO WITH(NOLOCK) WHERE (PO.PurchaseOrderID = @PurchaseOrderID);
		END ELSE BEGIN
			RAISERROR(N'[30100]:Sorry but the action passed "%s" is not supported', 18, 1, @Action);
		END

		/** Return result */
		EXEC [INE].[spPurchaseOrderSearch] @PurchaseOrderID=@PurchaseOrderID, @GPPONumber=NULL, @VendorId=NULL, @StartDate=NULL, @EndDate=NULL, @Status=NULL;
	END TRY
	BEGIN CATCH
		EXEC GEN.spExceptionsThrown;
		RETURN -1;
	END CATCH
END

GO
-- ##### SQL_TABLE_VALUED_FUNCTION INE.fxGetBarcodeNumberBreakOut
/******************************************************************************
**		File: fxGetBarcodeNumberBreakOut.sql
**		Name: fxGetBarcodeNumberBreakOut
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andrés E. Sosa
**		Date: 08/08/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	08/08/2017	Andrés E. Sosa	Created By
**	
*******************************************************************************/
CREATE FUNCTION INE.fxGetBarcodeNumberBreakOut(
	@ProductBarcodeId NVARCHAR(60)
)
RETURNS 
@ReturnList TABLE
(
	NDX INT NOT NULL
	, ProductBarcodeId NVARCHAR(60) NOT NULL
	, BarcodeNumber NVARCHAR(50) NOT NULL
	, DealerId INT
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	
	INSERT INTO @ReturnList
	SELECT
		CHARINDEX('|', @ProductBarcodeId) AS [NDX]
		, @ProductBarcodeId AS ProductBarcodeId
		, SUBSTRING(@ProductBarcodeId, 1, CHARINDEX('|', @ProductBarcodeId) - 1) AS [BarcodeNumber]
		, CAST(SUBSTRING(@ProductBarcodeId, CHARINDEX('|', @ProductBarcodeId) + 1, LEN(@ProductBarcodeId) - (CHARINDEX('|', @ProductBarcodeId) + 0)) AS INT) AS [DealerId]

	RETURN;
END

GO
-- ##### SQL_TABLE_VALUED_FUNCTION INE.fxGetLocationInventory
/******************************************************************************
**		File: fxGetLocationInventory.sql
**		Name: fxGetLocationInventory
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andrés E. Sosa
**		Date: 08/08/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	08/08/2017	Andrés E. Sosa	Created By
**	
*******************************************************************************/
CREATE FUNCTION INE.fxGetLocationInventory (
	 @LocationTypeID VARCHAR(20) = 'Technician'
	, @LocationIdentifier VARCHAR(50) = '1'
	, @DealerId INT = 2000
)
RETURNS 
@ReturnList TABLE
(
	[ProductBarcodeID] VARCHAR(60) NOT NULL
	, [BarcodeNumber] VARCHAR(60) NOT NULL
	, [ProductBarcodeTrackingID] BIGINT NOT NULL
	, [ProductBarcodeTrackingTypeId] VARCHAR(20) NOT NULL
	, [ProductSkwID] BIGINT NOT NULL
	, [Skw] VARCHAR(20) NOT NULL
	, [IsAdHoc] BIT NOT NULL
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	--WITH RootCte AS (
	--	SELECT
	--		PSK.ProductSkwID
	--		, PSK.Skw
	--	FROM
	--		[ACE].[ProductSkws] AS PSK WITH(NOLOCK)
	--	WHERE
	--		(PSK.Skw = @Skw)
	--		AND (PSK.DealerId = @DealerId)
	--		AND (PSK.IsDeleted = 'False')
	--)
	----SELECT * FROM RootCte;
	WITH ProdBarCodeCte AS (
		SELECT
			PB.ProductBarcodeID
			, PB.BarcodeNumber
			, PBT.ProductBarcodeTrackingID
			, PBT.ProductBarcodeTrackingTypeId
			, POI.ProductSkwId
			, PKWS.Skw
			, PB.IsAdHoc
		FROM 
			[INE].[ProductBarcodes] AS PB WITH(NOLOCK)
			INNER JOIN [INE].[ProductBarcodeTracking] AS PBT WITH(NOLOCK)
			ON
				(PBT.ProductBarcodeTrackingID = PB.LastProductBarcodeTrackingId)
				AND (PB.DealerId = @DealerId)
				AND (PBT.LocationTypeId = @LocationTypeID)
				AND (PBT.LocationIdentifier = @LocationIdentifier)
				AND (PB.IsDeleted = 'False')
			INNER JOIN [INE].[PurchaseOrderItems] AS POI WITH(NOLOCK)
			ON
				(PB.PurchaseOrderItemId = POI.PurchaseOrderItemID)
			INNER JOIN [ACE].[ProductSkws] AS PKWS WITH(NOLOCK)
			ON
				(PKWS.ProductSkwID = POI.ProductSkwId)
	)
	INSERT INTO @ReturnList
	SELECT PBC.ProductBarcodeID
           , PBC.BarcodeNumber
           , PBC.ProductBarcodeTrackingID
           , PBC.ProductBarcodeTrackingTypeId
           , PBC.ProductSkwId
           , PBC.Skw
           , PBC.IsAdHoc
	FROM ProdBarCodeCte AS PBC WITH(NOLOCK);

	RETURN;
END

GO
-- ##### SQL_TABLE_VALUED_FUNCTION INE.fxGetPurchaseOrderItemAssignments
/******************************************************************************
**		File: fxGetPurchaseOrderItemAssignments.sql
**		Name: fxGetPurchaseOrderItemAssignments
**		Desc: 
**
**		This template can be customized:
**              
**		Return values: Table of IDs/Ints
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: Andrés E. Sosa
**		Date: 08/08/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	08/08/2017	Andrés E. Sosa	Created By
**	
*******************************************************************************/
CREATE FUNCTION [INE].[fxGetPurchaseOrderItemAssignments] (
	@PurchaseOrderItemID BIGINT
)
RETURNS 
@ReturnList TABLE
(
	PurchaseOrderItemID BIGINT NOT NULL
	, ProductBarcodeId VARCHAR(60) NOT NULL
	, ProductBarcodeTrackingTypeId VARCHAR(20) NOT NULL
	, [AuditId] BIGINT NULL
	, [LocationTypeId] VARCHAR(20) NULL
	, [LocationIdentifier] VARCHAR(50) NULL
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	--DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
	--	, @UserGuidMasked VARCHAR(50);

--	SET @UserGuidMasked = (SELECT 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))
	
	INSERT INTO @ReturnList
		SELECT
			PB.PurchaseOrderItemID
			, PBT.ProductBarcodeId
			, PBT.ProductBarcodeTrackingTypeId
			,  PBT.AuditId
			, PBT.LocationTypeId
			, PBT.LocationIdentifier
		FROM
			[INE].[ProductBarcodes] AS PB WITH(NOLOCK)
			INNER JOIN [INE].[ProductBarcodeTracking] AS PBT WITH(NOLOCK)
			ON
				(PB.PurchaseOrderItemId = @PurchaseOrderItemID)
				AND (PBT.ProductBarcodeId = PB.ProductBarcodeID)
		WHERE
		/** WE ONLY WANT TO COUNT the Tracking line where the item was received. */
			(PBT.ProductBarcodeTrackingTypeId = 'REC') -- REC	Receive Shipment
			AND (PBT.IsActive = 'True')
			AND (PBT.IsDeleted = 'False');

	RETURN;
END

GO
-- ##### VIEW INE.vwGen_Audits

/******************************************************************************
**		View: [INE].[vwGen_Audits]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_Audits]
AS
	-- QUERY VIEW
	SELECT
		[INE].[Audits].[AuditID]
		, [INE].[Audits].[LocationTypeId]
		, [INE].[Audits].[LocationIdentifier]
		, [INE].[Audits].[IsActive]
		, [INE].[Audits].[ModifiedDate]
		, [INE].[Audits].[ModifiedById]
		, [INE].[Audits].[CreatedDate]
		, [INE].[Audits].[CreatedById]
	FROM
		[INE].[Audits]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','Audits') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[Audits].CreatedById = AL.UserId))
			AND ([INE].[Audits].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_LocationTypes

/******************************************************************************
**		View: [INE].[vwGen_LocationTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_LocationTypes]
AS
	-- QUERY VIEW
	SELECT
		[INE].[LocationTypes].[LocationTypeID]
		, [INE].[LocationTypes].[LocationTypeName]
		, [INE].[LocationTypes].[TableName]
		, [INE].[LocationTypes].[FieldID]
		, [INE].[LocationTypes].[FieldName]
		, [INE].[LocationTypes].[SqlStmt]
		, [INE].[LocationTypes].[Comment]
		, [INE].[LocationTypes].[IsActive]
		, [INE].[LocationTypes].[ModifiedDate]
		, [INE].[LocationTypes].[ModifiedById]
		, [INE].[LocationTypes].[CreatedDate]
		, [INE].[LocationTypes].[CreatedById]
	FROM
		[INE].[LocationTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','LocationTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[LocationTypes].CreatedById = AL.UserId))
			AND ([INE].[LocationTypes].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_PackingSlipItems

/******************************************************************************
**		View: [INE].[vwGen_PackingSlipItems]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_PackingSlipItems]
AS
	-- QUERY VIEW
	SELECT
		[INE].[PackingSlipItems].[PackingSlipItemID]
		, [INE].[PackingSlipItems].[PackingSlipId]
		, [INE].[PackingSlipItems].[PurchaseOrderItemId]
		, [INE].[PackingSlipItems].[ProductSkwId]
		, [INE].[PackingSlipItems].[Quantity]
		, [INE].[PackingSlipItems].[IsActive]
		, [INE].[PackingSlipItems].[ModifiedDate]
		, [INE].[PackingSlipItems].[ModifiedById]
		, [INE].[PackingSlipItems].[CreatedDate]
		, [INE].[PackingSlipItems].[CreatedById]
	FROM
		[INE].[PackingSlipItems]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','PackingSlipItems') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[PackingSlipItems].CreatedById = AL.UserId))
			AND ([INE].[PackingSlipItems].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_PackingSlips

/******************************************************************************
**		View: [INE].[vwGen_PackingSlips]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_PackingSlips]
AS
	-- QUERY VIEW
	SELECT
		[INE].[PackingSlips].[PackingSlipID]
		, [INE].[PackingSlips].[DealerId]
		, [INE].[PackingSlips].[PurchaseOrderId]
		, [INE].[PackingSlips].[ArrivalDate]
		, [INE].[PackingSlips].[CloseDate]
		, [INE].[PackingSlips].[PackingSlipNumber]
		, [INE].[PackingSlips].[IsActive]
		, [INE].[PackingSlips].[ModifiedDate]
		, [INE].[PackingSlips].[ModifiedById]
		, [INE].[PackingSlips].[CreatedDate]
		, [INE].[PackingSlips].[CreatedById]
	FROM
		[INE].[PackingSlips]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','PackingSlips') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[PackingSlips].CreatedById = AL.UserId))
			AND ([INE].[PackingSlips].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_ProductBarcodeBundles

/******************************************************************************
**		View: [INE].[vwGen_ProductBarcodeBundles]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_ProductBarcodeBundles]
AS
	-- QUERY VIEW
	SELECT
		[INE].[ProductBarcodeBundles].[ProductBarcodeBundleID]
		, [INE].[ProductBarcodeBundles].[ProductBarcodeId]
		, [INE].[ProductBarcodeBundles].[IsActive]
		, [INE].[ProductBarcodeBundles].[ModifiedDate]
		, [INE].[ProductBarcodeBundles].[ModifiedById]
		, [INE].[ProductBarcodeBundles].[CreatedDate]
		, [INE].[ProductBarcodeBundles].[CreatedById]
	FROM
		[INE].[ProductBarcodeBundles]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','ProductBarcodeBundles') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[ProductBarcodeBundles].CreatedById = AL.UserId))
			AND ([INE].[ProductBarcodeBundles].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_ProductBarcodes

/******************************************************************************
**		View: [INE].[vwGen_ProductBarcodes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_ProductBarcodes]
AS
	-- QUERY VIEW
	SELECT
		[INE].[ProductBarcodes].[ProductBarcodeID]
		, [INE].[ProductBarcodes].[DealerId]
		, [INE].[ProductBarcodes].[PurchaseOrderItemId]
		, [INE].[ProductBarcodes].[PackingSlipItemId]
		, [INE].[ProductBarcodes].[LastProductBarcodeTrackingId]
		, [INE].[ProductBarcodes].[ProductBarcodeBundleId]
		, [INE].[ProductBarcodes].[SimGUID]
		, [INE].[ProductBarcodes].[BarcodeNumber]
		, [INE].[ProductBarcodes].[IsAdHoc]
		, [INE].[ProductBarcodes].[IsActive]
		, [INE].[ProductBarcodes].[ModifiedDate]
		, [INE].[ProductBarcodes].[ModifiedById]
		, [INE].[ProductBarcodes].[CreatedDate]
		, [INE].[ProductBarcodes].[CreatedById]
	FROM
		[INE].[ProductBarcodes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','ProductBarcodes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[ProductBarcodes].CreatedById = AL.UserId))
			AND ([INE].[ProductBarcodes].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_ProductBarcodeTracking

/******************************************************************************
**		View: [INE].[vwGen_ProductBarcodeTracking]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_ProductBarcodeTracking]
AS
	-- QUERY VIEW
	SELECT
		[INE].[ProductBarcodeTracking].[ProductBarcodeTrackingID]
		, [INE].[ProductBarcodeTracking].[ProductBarcodeTrackingTypeId]
		, [INE].[ProductBarcodeTracking].[ProductBarcodeId]
		, [INE].[ProductBarcodeTracking].[DealerId]
		, [INE].[ProductBarcodeTracking].[AuditId]
		, [INE].[ProductBarcodeTracking].[LocationTypeId]
		, [INE].[ProductBarcodeTracking].[LocationIdentifier]
		, [INE].[ProductBarcodeTracking].[Comment]
		, [INE].[ProductBarcodeTracking].[IsActive]
		, [INE].[ProductBarcodeTracking].[ModifiedDate]
		, [INE].[ProductBarcodeTracking].[ModifiedById]
		, [INE].[ProductBarcodeTracking].[CreatedDate]
		, [INE].[ProductBarcodeTracking].[CreatedById]
	FROM
		[INE].[ProductBarcodeTracking]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','ProductBarcodeTracking') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[ProductBarcodeTracking].CreatedById = AL.UserId))
			AND ([INE].[ProductBarcodeTracking].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_ProductBarcodeTrackingTypes

/******************************************************************************
**		View: [INE].[vwGen_ProductBarcodeTrackingTypes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_ProductBarcodeTrackingTypes]
AS
	-- QUERY VIEW
	SELECT
		[INE].[ProductBarcodeTrackingTypes].[ProductBarcodeTrackingTypeID]
		, [INE].[ProductBarcodeTrackingTypes].[ProductBarcodeTrackingTypeName]
		, [INE].[ProductBarcodeTrackingTypes].[Comment]
		, [INE].[ProductBarcodeTrackingTypes].[IsInventoryMove]
		, [INE].[ProductBarcodeTrackingTypes].[IsActive]
		, [INE].[ProductBarcodeTrackingTypes].[ModifiedDate]
		, [INE].[ProductBarcodeTrackingTypes].[ModifiedById]
		, [INE].[ProductBarcodeTrackingTypes].[CreatedDate]
		, [INE].[ProductBarcodeTrackingTypes].[CreatedById]
	FROM
		[INE].[ProductBarcodeTrackingTypes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','ProductBarcodeTrackingTypes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[ProductBarcodeTrackingTypes].CreatedById = AL.UserId))
			AND ([INE].[ProductBarcodeTrackingTypes].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_PurchaseOrderItems

/******************************************************************************
**		View: [INE].[vwGen_PurchaseOrderItems]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_PurchaseOrderItems]
AS
	-- QUERY VIEW
	SELECT
		[INE].[PurchaseOrderItems].[PurchaseOrderItemID]
		, [INE].[PurchaseOrderItems].[PurchaseOrderId]
		, [INE].[PurchaseOrderItems].[ProductSkwId]
		, [INE].[PurchaseOrderItems].[WarehouseSiteId]
		, [INE].[PurchaseOrderItems].[Quantity]
		, [INE].[PurchaseOrderItems].[IsActive]
		, [INE].[PurchaseOrderItems].[ModifiedDate]
		, [INE].[PurchaseOrderItems].[ModifiedById]
		, [INE].[PurchaseOrderItems].[CreatedDate]
		, [INE].[PurchaseOrderItems].[CreatedById]
	FROM
		[INE].[PurchaseOrderItems]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','PurchaseOrderItems') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[PurchaseOrderItems].CreatedById = AL.UserId))
			AND ([INE].[PurchaseOrderItems].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_PurchaseOrders

/******************************************************************************
**		View: [INE].[vwGen_PurchaseOrders]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_PurchaseOrders]
AS
	-- QUERY VIEW
	SELECT
		[INE].[PurchaseOrders].[PurchaseOrderID]
		, [INE].[PurchaseOrders].[DealerId]
		, [INE].[PurchaseOrders].[VendorId]
		, [INE].[PurchaseOrders].[WarehouseSiteId]
		, [INE].[PurchaseOrders].[AttentionLine]
		, [INE].[PurchaseOrders].[GPPONumber]
		, [INE].[PurchaseOrders].[VendorRefNumber]
		, [INE].[PurchaseOrders].[CreditTerms]
		, [INE].[PurchaseOrders].[SubTotal]
		, [INE].[PurchaseOrders].[Tax]
		, [INE].[PurchaseOrders].[Total]
		, [INE].[PurchaseOrders].[SubmittedDate]
		, [INE].[PurchaseOrders].[CompletedDate]
		, [INE].[PurchaseOrders].[Comments]
		, [INE].[PurchaseOrders].[IsActive]
		, [INE].[PurchaseOrders].[ModifiedDate]
		, [INE].[PurchaseOrders].[ModifiedById]
		, [INE].[PurchaseOrders].[CreatedDate]
		, [INE].[PurchaseOrders].[CreatedById]
	FROM
		[INE].[PurchaseOrders]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','PurchaseOrders') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[PurchaseOrders].CreatedById = AL.UserId))
			AND ([INE].[PurchaseOrders].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_ReturnToManufacturerItems

/******************************************************************************
**		View: [INE].[vwGen_ReturnToManufacturerItems]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_ReturnToManufacturerItems]
AS
	-- QUERY VIEW
	SELECT
		[INE].[ReturnToManufacturerItems].[ReturnToManufacturerItemID]
		, [INE].[ReturnToManufacturerItems].[ReturnToManufacturerId]
		, [INE].[ReturnToManufacturerItems].[Description]
		, [INE].[ReturnToManufacturerItems].[IsActive]
		, [INE].[ReturnToManufacturerItems].[ModifiedDate]
		, [INE].[ReturnToManufacturerItems].[ModifiedById]
		, [INE].[ReturnToManufacturerItems].[CreatedDate]
		, [INE].[ReturnToManufacturerItems].[CreatedById]
	FROM
		[INE].[ReturnToManufacturerItems]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','ReturnToManufacturerItems') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[ReturnToManufacturerItems].CreatedById = AL.UserId))
			AND ([INE].[ReturnToManufacturerItems].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_ReturnToManufacturers

/******************************************************************************
**		View: [INE].[vwGen_ReturnToManufacturers]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_ReturnToManufacturers]
AS
	-- QUERY VIEW
	SELECT
		[INE].[ReturnToManufacturers].[ReturnToManufacturerID]
		, [INE].[ReturnToManufacturers].[ManufacturerId]
		, [INE].[ReturnToManufacturers].[IsActive]
		, [INE].[ReturnToManufacturers].[ModifiedDate]
		, [INE].[ReturnToManufacturers].[ModifiedById]
		, [INE].[ReturnToManufacturers].[CreatedDate]
		, [INE].[ReturnToManufacturers].[CreatedById]
	FROM
		[INE].[ReturnToManufacturers]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','ReturnToManufacturers') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[ReturnToManufacturers].CreatedById = AL.UserId))
			AND ([INE].[ReturnToManufacturers].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_StockingLevels

/******************************************************************************
**		View: [INE].[vwGen_StockingLevels]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_StockingLevels]
AS
	-- QUERY VIEW
	SELECT
		[INE].[StockingLevels].[StockingLevelID]
		, [INE].[StockingLevels].[ProductSkwId]
		, [INE].[StockingLevels].[LocationTypeId]
		, [INE].[StockingLevels].[LocationIdentifier]
		, [INE].[StockingLevels].[ReorderLevelQty]
		, [INE].[StockingLevels].[StockingLevelQty]
		, [INE].[StockingLevels].[OrderQuantity]
		, [INE].[StockingLevels].[Comment]
		, [INE].[StockingLevels].[IsActive]
		, [INE].[StockingLevels].[ModifiedDate]
		, [INE].[StockingLevels].[ModifiedById]
		, [INE].[StockingLevels].[CreatedDate]
		, [INE].[StockingLevels].[CreatedById]
	FROM
		[INE].[StockingLevels]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','StockingLevels') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[StockingLevels].CreatedById = AL.UserId))
			AND ([INE].[StockingLevels].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_Vendors

/******************************************************************************
**		View: [INE].[vwGen_Vendors]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_Vendors]
AS
	-- QUERY VIEW
	SELECT
		[INE].[Vendors].[VendorID]
		, [INE].[Vendors].[DealerId]
		, [INE].[Vendors].[PoliticalStateId]
		, [INE].[Vendors].[VendorName]
		, [INE].[Vendors].[StreetAddress]
		, [INE].[Vendors].[StreetAddress2]
		, [INE].[Vendors].[City]
		, [INE].[Vendors].[PostalCode]
		, [INE].[Vendors].[IsActive]
		, [INE].[Vendors].[ModifiedDate]
		, [INE].[Vendors].[ModifiedById]
		, [INE].[Vendors].[CreatedDate]
		, [INE].[Vendors].[CreatedById]
	FROM
		[INE].[Vendors]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','Vendors') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[Vendors].CreatedById = AL.UserId))
			AND ([INE].[Vendors].IsDeleted = 'FALSE')

;
GO
-- ##### VIEW INE.vwGen_WarehouseSites

/******************************************************************************
**		View: [INE].[vwGen_WarehouseSites]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
CREATE VIEW [INE].[vwGen_WarehouseSites]
AS
	-- QUERY VIEW
	SELECT
		[INE].[WarehouseSites].[WarehouseSiteID]
		, [INE].[WarehouseSites].[DealerId]
		, [INE].[WarehouseSites].[PoliticalStateId]
		, [INE].[WarehouseSites].[PoliticalTimeZoneId]
		, [INE].[WarehouseSites].[WarehouseSiteName]
		, [INE].[WarehouseSites].[StreetAddress]
		, [INE].[WarehouseSites].[StreetAddress2]
		, [INE].[WarehouseSites].[City]
		, [INE].[WarehouseSites].[PostalCode]
		, [INE].[WarehouseSites].[IsActive]
		, [INE].[WarehouseSites].[ModifiedDate]
		, [INE].[WarehouseSites].[ModifiedById]
		, [INE].[WarehouseSites].[CreatedDate]
		, [INE].[WarehouseSites].[CreatedById]
	FROM
		[INE].[WarehouseSites]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'INE','WarehouseSites') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2) OR ([INE].[WarehouseSites].CreatedById = AL.UserId))
			AND ([INE].[WarehouseSites].IsDeleted = 'FALSE')

;
GO
