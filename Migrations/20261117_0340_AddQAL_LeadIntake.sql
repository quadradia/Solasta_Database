/*
Migration: 20261117_0340_AddQAL_LeadIntake
Author: Andres Sosa
Date: 2026-11-17
Description: Lets QAL.Leads take leads from the website and GoHighLevel (lead-to-quote Phase 2).
  1. QAL.Leads gets ExternalSource / ExternalId (the GoHighLevel contact id, unique per tenant and
     source) and Notes (survey answers).
  2. Sales-assignment columns become optional, since a new web lead has no rep, season, team
     location or geocode yet (decision of 2026-11-16):
       QAL.Leads: LeadAddressId, TeamLocationId, SeasonId, SalesRepId, Gender
       QAL.LeadAddresses: AddressValidationVendorId, AddressValidationStateId, PoliticalTimeZoneId,
                          SeasonId, TeamLocationId, SalesRepId, Latitude, Longitude
     LeadAddresses.StreetAddress widens to nvarchar(200) and City to nvarchar(100) to fit the website
     form; DPV defaults to 0.
  3. Seeds ACE.CustomerTypes RES and COM when missing, global QAL.LeadDispositions (the lead pipeline)
     and the Solasta Lighting tenant's QAL.LeadSources.
  4. Recreates the audit triggers on ACE.MasterFiles, QAL.LeadAddresses and QAL.Leads. They still read
     DealerId, which 20260505_1800 renamed to DealerTenantId, so every insert into those tables failed.
Dependencies:
  20260505_1800_DeprecateDealers_ReplaceWithDealerTenants
  20261106_1600_SeedACC_SolastaLightingTenant
Expected impact: Columns only become nullable or wider; no data changes besides the seeds.
Rollback: see the ROLLBACK SCRIPT block at the end.
*/

-- Filtered indexes require these; sqlcmd defaults QUOTED_IDENTIFIER to OFF.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_0340_AddQAL_LeadIntake';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();
    DECLARE @SolastaProxy VARCHAR(100) = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6';
    DECLARE @sql NVARCHAR(MAX);

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'QAL.LeadAddresses', N'U') IS NULL
        THROW 50001, 'QAL.Leads and QAL.LeadAddresses are required.', 1;
    IF COL_LENGTH(N'QAL.Leads', N'DealerTenantId') IS NULL
        THROW 50001, 'Run 20260505_1800_DeprecateDealers_ReplaceWithDealerTenants first.', 1;

    -- =============================================
    -- Step 1: new columns on QAL.Leads
    -- =============================================
    IF COL_LENGTH(N'QAL.Leads', N'ExternalSource') IS NULL
        ALTER TABLE [QAL].[Leads] ADD [ExternalSource] [varchar](20) NULL;
    IF COL_LENGTH(N'QAL.Leads', N'ExternalId') IS NULL
        ALTER TABLE [QAL].[Leads] ADD [ExternalId] [nvarchar](100) NULL;
    IF COL_LENGTH(N'QAL.Leads', N'Notes') IS NULL
        ALTER TABLE [QAL].[Leads] ADD [Notes] [nvarchar](4000) NULL;

    -- =============================================
    -- Step 2: optional sales-assignment columns
    -- A foreign key blocks ALTER COLUMN, so each column's foreign keys are dropped and recreated
    -- under the same name, whatever that name is in this database.
    -- =============================================
    DECLARE @Columns TABLE ([TableName] SYSNAME, [ColumnName] SYSNAME, [Definition] NVARCHAR(100));
    INSERT INTO @Columns VALUES
        (N'QAL.Leads', N'LeadAddressId', N'[bigint] NULL'),
        (N'QAL.Leads', N'TeamLocationId', N'[int] NULL'),
        (N'QAL.Leads', N'SeasonId', N'[int] NULL'),
        (N'QAL.Leads', N'SalesRepId', N'[varchar](10) NULL'),
        (N'QAL.Leads', N'Gender', N'[nvarchar](10) NULL'),
        (N'QAL.LeadAddresses', N'AddressValidationVendorId', N'[varchar](20) NULL'),
        (N'QAL.LeadAddresses', N'AddressValidationStateId', N'[varchar](5) NULL'),
        (N'QAL.LeadAddresses', N'PoliticalTimeZoneId', N'[int] NULL'),
        (N'QAL.LeadAddresses', N'SeasonId', N'[int] NULL'),
        (N'QAL.LeadAddresses', N'TeamLocationId', N'[int] NULL'),
        (N'QAL.LeadAddresses', N'SalesRepId', N'[nvarchar](25) NULL'),
        (N'QAL.LeadAddresses', N'Latitude', N'[float] NULL'),
        (N'QAL.LeadAddresses', N'Longitude', N'[float] NULL'),
        (N'QAL.LeadAddresses', N'StreetAddress', N'[nvarchar](200) NOT NULL'),
        (N'QAL.LeadAddresses', N'City', N'[nvarchar](100) NOT NULL');

    DECLARE @ForeignKeys TABLE ([DropSql] NVARCHAR(MAX), [CreateSql] NVARCHAR(MAX));
    INSERT INTO @ForeignKeys ([DropSql], [CreateSql])
    SELECT DISTINCT
        N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.[parent_object_id])) + N'.' + QUOTENAME(OBJECT_NAME(fk.[parent_object_id]))
            + N' DROP CONSTRAINT ' + QUOTENAME(fk.[name]) + N';',
        N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.[parent_object_id])) + N'.' + QUOTENAME(OBJECT_NAME(fk.[parent_object_id]))
            + N' WITH CHECK ADD CONSTRAINT ' + QUOTENAME(fk.[name]) + N' FOREIGN KEY (' + QUOTENAME(pc.[name]) + N') REFERENCES '
            + QUOTENAME(OBJECT_SCHEMA_NAME(fk.[referenced_object_id])) + N'.' + QUOTENAME(OBJECT_NAME(fk.[referenced_object_id]))
            + N' (' + QUOTENAME(rc.[name]) + N');'
    FROM @Columns AS c
    INNER JOIN [sys].[foreign_key_columns] AS fkc
        ON fkc.[parent_object_id] = OBJECT_ID(c.[TableName]) AND COL_NAME(fkc.[parent_object_id], fkc.[parent_column_id]) = c.[ColumnName]
    INNER JOIN [sys].[foreign_keys] AS fk ON fk.[object_id] = fkc.[constraint_object_id]
    INNER JOIN [sys].[columns] AS pc ON pc.[object_id] = fkc.[parent_object_id] AND pc.[column_id] = fkc.[parent_column_id]
    INNER JOIN [sys].[columns] AS rc ON rc.[object_id] = fkc.[referenced_object_id] AND rc.[column_id] = fkc.[referenced_column_id];

    SELECT @sql = STRING_AGG(CAST([DropSql] AS NVARCHAR(MAX)), NCHAR(10)) FROM @ForeignKeys;
    IF @sql IS NOT NULL EXEC sys.sp_executesql @sql;

    SELECT @sql = STRING_AGG(CAST(N'ALTER TABLE ' + QUOTENAME(PARSENAME(c.[TableName], 2)) + N'.' + QUOTENAME(PARSENAME(c.[TableName], 1))
        + N' ALTER COLUMN ' + QUOTENAME(c.[ColumnName]) + N' ' + c.[Definition] + N';' AS NVARCHAR(MAX)), NCHAR(10))
    FROM @Columns AS c;
    EXEC sys.sp_executesql @sql;

    SELECT @sql = STRING_AGG(CAST([CreateSql] AS NVARCHAR(MAX)), NCHAR(10)) FROM @ForeignKeys;
    IF @sql IS NOT NULL EXEC sys.sp_executesql @sql;

    IF NOT EXISTS (SELECT 1 FROM [sys].[default_constraints] WHERE [name] = N'DF_LeadAddresses_DPV')
        ALTER TABLE [QAL].[LeadAddresses] ADD CONSTRAINT [DF_LeadAddresses_DPV] DEFAULT ((0)) FOR [DPV];

    -- =============================================
    -- Step 3: external id rules and lookups
    -- =============================================
    IF NOT EXISTS (SELECT 1 FROM [sys].[check_constraints] WHERE [name] = N'CK_Leads_ExternalSource')
        EXEC sys.sp_executesql N'ALTER TABLE [QAL].[Leads] WITH CHECK ADD CONSTRAINT [CK_Leads_ExternalSource]
            CHECK ([ExternalId] IS NULL OR [ExternalSource] IS NOT NULL);';

    IF NOT EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [name] = N'IX_Leads_DealerTenantId_ExternalSource_ExternalId' AND [object_id] = OBJECT_ID(N'QAL.Leads'))
        EXEC sys.sp_executesql N'CREATE UNIQUE NONCLUSTERED INDEX [IX_Leads_DealerTenantId_ExternalSource_ExternalId]
            ON [QAL].[Leads] ([DealerTenantId], [ExternalSource], [ExternalId]) WHERE [ExternalId] IS NOT NULL;';

    IF NOT EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [name] = N'IX_Leads_DealerTenantId_Email' AND [object_id] = OBJECT_ID(N'QAL.Leads'))
        EXEC sys.sp_executesql N'CREATE NONCLUSTERED INDEX [IX_Leads_DealerTenantId_Email]
            ON [QAL].[Leads] ([DealerTenantId], [Email]) WHERE [Email] IS NOT NULL;';

    IF NOT EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [name] = N'IX_LeadSources_DealerTenantId_LeadSourceName' AND [object_id] = OBJECT_ID(N'QAL.LeadSources'))
        EXEC sys.sp_executesql N'CREATE UNIQUE NONCLUSTERED INDEX [IX_LeadSources_DealerTenantId_LeadSourceName]
            ON [QAL].[LeadSources] ([DealerTenantId], [LeadSourceName]);';

    -- =============================================
    -- Step 4: seeds
    -- =============================================
    MERGE INTO [ACE].[CustomerTypes] AS target
    USING (VALUES ('RES', N'Residential'), ('COM', N'Commercial')) AS source ([CustomerTypeID], [CustomerTypeName])
    ON target.[CustomerTypeID] = source.[CustomerTypeID]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([CustomerTypeID], [CustomerTypeName], [IsActive], [IsDeleted])
        VALUES (source.[CustomerTypeID], source.[CustomerTypeName], 1, 0);

    -- Global pipeline (DealerTenantId NULL); the API looks these up by name.
    MERGE INTO [QAL].[LeadDispositions] AS target
    USING (VALUES (N'New'), (N'Contacted'), (N'Measured'), (N'Quoted'), (N'Won'), (N'Lost'), (N'Unqualified'))
        AS source ([LeadDispositionName])
    ON target.[DealerTenantId] IS NULL AND target.[LeadDispositionName] = source.[LeadDispositionName]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([DealerTenantId], [LeadDispositionName], [IsActive], [IsDeleted])
        VALUES (NULL, source.[LeadDispositionName], 1, 0);

    DECLARE @SolastaTenantId INT = (SELECT [DealerTenantID] FROM [ACC].[DealerTenants] WHERE [Proxy] = @SolastaProxy);
    IF @SolastaTenantId IS NULL
        PRINT 'Solasta Lighting tenant not found; QAL.LeadSources not seeded.';
    ELSE
        MERGE INTO [QAL].[LeadSources] AS target
        USING (VALUES (N'Website'), (N'Facebook'), (N'Instagram'), (N'Google'), (N'Affiliate Referral'),
                      (N'GoHighLevel'), (N'Phone'), (N'Manual Entry')) AS source ([LeadSourceName])
        ON target.[DealerTenantId] = @SolastaTenantId AND target.[LeadSourceName] = source.[LeadSourceName]
        WHEN NOT MATCHED BY TARGET THEN
            INSERT ([DealerTenantId], [LeadSourceName], [IsActive], [IsDeleted])
            VALUES (@SolastaTenantId, source.[LeadSourceName], 1, 0);

    -- =============================================
    -- Step 5: audit triggers read DealerTenantId (and the new Leads columns)
    -- =============================================
    IF OBJECT_ID(N'[ACE].[trgAutoGen_MasterFiles_CUD]', N'TR') IS NOT NULL
        DROP TRIGGER [ACE].[trgAutoGen_MasterFiles_CUD];
    EXEC sys.sp_executesql N'CREATE TRIGGER [ACE].[trgAutoGen_MasterFiles_CUD] ON [ACE].[MasterFiles]
	AFTER INSERT, UPDATE
AS
BEGIN
    /**************
	 * INITIALIZE
	 **************/
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerTenantId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerTenantId = DealerTenantId
    FROM [ACC].[fxGetContextUserTable]();
    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable
        ( PKID )
    SELECT MasterFileID
    FROM Deleted;

    /** Build Data Changes */
    DECLARE @DataTable TABLE (PKID BIGINT NOT NULL,
        AuditActionId BIGINT,
        AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500),
        OldValue NVARCHAR(500),
        NewValue NVARCHAR(500));
    WITH
        RootCTE
        AS
        (
            SELECT
                PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
            FROM
                (SELECT
                    MFD.MasterFileID AS PKID
			, CAST(MasterFileID AS NVARCHAR(500)) AS MasterFileID
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Inserted AS MFD WITH(NOLOCK)) AS st2
		UNPIVOT (
			ColumnNewValue FOR ColumnName IN (
			MasterFileID
			, DealerTenantId
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        WithChangedCTE
        AS
        (
            SELECT
                PKID
			, InsertValues.ColumnName
			, InsertValues.ColumnOldValue
            FROM
                (SELECT
                    MFD.MasterFileID AS PKID
			, CAST(MasterFileID AS NVARCHAR(500)) AS MasterFileID
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Deleted AS MFD) AS st2
		UNPIVOT (
			ColumnOldValue FOR ColumnName IN (
			MasterFileID
			, DealerTenantId
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        ResultCTE
        AS
        (
            SELECT
                RTN.PKID
			, RTN.ColumnName
			, RTN.ColumnNewValue AS NewValue
			, RTO.ColumnOldValue AS OldValue
            FROM
                RootCTE AS RTN WITH(NOLOCK)
                LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
                ON
				(RTO.PKID = RTN.PKID)
                    AND (RTO.ColumnName = RTN.ColumnName)
            WHERE
			(RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue)
        )
    INSERT INTO @DataTable
        (PKID, ColumnName, OldValue, NewValue)
    SELECT
        RT.PKID
        , RT.ColumnName
        , RT.OldValue
        , RT.NewValue
    FROM
        ResultCTE AS RT WITH(NOLOCK);

    /** Determin Action */
    WITH
        DistinctCTE
        AS
        (
            SELECT DISTINCT
                RT.PKID
            FROM
                @DataTable AS RT
        )
	,
        DeletedActionCTE
        AS
        (
            SELECT
                RT.PKID
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
			, CASE
				WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT)
				ELSE CAST(''True'' AS BIT)
			  END AS IsUpdateAction
            FROM
                DistinctCTE AS RT
                LEFT OUTER JOIN @DeletedTable AS DT
                ON
				(DT.PKID = RT.PKID)
        )
	,
        DetermineActionTypeCTE
        AS
        (
            SELECT
                DT.PKID
			, CASE
				WHEN DACT.IsDeleteAction = ''True'' THEN ''DELETE''
				WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
				WHEN DACT.IsUpdateAction = ''True'' THEN ''UPDATE''
				ELSE ''INSERT''
			  END AS AuditActionTypeId
            FROM
                @DataTable AS DT
                LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK)
                ON
				(DACT.PKID = DT.PKID)
        )
	UPDATE DT SET
		DT.AuditActionTypeId = DACT.AuditActionTypeId
	FROM
        @DataTable AS DT
        INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK)
        ON
			(DACT.PKID = DT.PKID);

    /** CREATE THE AUDIT ACTIONS */
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT,
        PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT
        DT.AuditActionTypeId
		, ''ACE''
		, ''MasterFiles''
		, CAST(DT.PKID AS VARCHAR(50))
		, @UserID
    FROM
        @DataTable AS DT;

    /** CREATE THE AUDIT ACTION COLUMNS */
    INSERT INTO [AUD].[AuditActionColumns]
        ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT
        AAT.AuditActionID
		, DT.ColumnName
		, DT.OldValue
		, DT.NewValue
    FROM
        @DataTable AS DT
        INNER JOIN @AuditActionTable AS AAT
        ON
			(AAT.PKID = DT.PKID)
END;';
    PRINT 'Recreated [ACE].[trgAutoGen_MasterFiles_CUD]';

    IF OBJECT_ID(N'[QAL].[trgAutoGen_LeadAddresses_CUD]', N'TR') IS NOT NULL
        DROP TRIGGER [QAL].[trgAutoGen_LeadAddresses_CUD];
    EXEC sys.sp_executesql N'CREATE TRIGGER [QAL].[trgAutoGen_LeadAddresses_CUD] ON [QAL].[LeadAddresses]
	AFTER INSERT, UPDATE
AS
BEGIN
    /**************
	 * INITIALIZE
	 **************/
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerTenantId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerTenantId = DealerTenantId
    FROM [ACC].[fxGetContextUserTable]();
    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable
        ( PKID )
    SELECT LeadAddressID
    FROM Deleted;

    /** Build Data Changes */
    DECLARE @DataTable TABLE (PKID BIGINT NOT NULL,
        AuditActionId BIGINT,
        AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500),
        OldValue NVARCHAR(500),
        NewValue NVARCHAR(500));
    WITH
        RootCTE
        AS
        (
            SELECT
                PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
            FROM
                (SELECT
                    MFD.LeadAddressID AS PKID
			, CAST(LeadAddressID AS NVARCHAR(500)) AS LeadAddressID
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(LanguageId AS NVARCHAR(500)) AS LanguageId
			, CAST(AddressValidationVendorId AS NVARCHAR(500)) AS AddressValidationVendorId
			, CAST(AddressValidationStateId AS NVARCHAR(500)) AS AddressValidationStateId
			, CAST(PoliticalStateId AS NVARCHAR(500)) AS PoliticalStateId
			, CAST(PoliticalCountryId AS NVARCHAR(500)) AS PoliticalCountryId
			, CAST(PoliticalTimeZoneId AS NVARCHAR(500)) AS PoliticalTimeZoneId
			, CAST(AddressTypeId AS NVARCHAR(500)) AS AddressTypeId
			, CAST(AddressStreetTypeId AS NVARCHAR(500)) AS AddressStreetTypeId
			, CAST(SeasonId AS NVARCHAR(500)) AS SeasonId
			, CAST(TeamLocationId AS NVARCHAR(500)) AS TeamLocationId
			, CAST(SalesRepId AS NVARCHAR(500)) AS SalesRepId
			, CAST(StreetAddress AS NVARCHAR(500)) AS StreetAddress
			, CAST(StreetAddress2 AS NVARCHAR(500)) AS StreetAddress2
			, CAST(StreetNumber AS NVARCHAR(500)) AS StreetNumber
			, CAST(StreetName AS NVARCHAR(500)) AS StreetName
			, CAST(StreetType AS NVARCHAR(500)) AS StreetType
			, CAST(PreDirectional AS NVARCHAR(500)) AS PreDirectional
			, CAST(PostDirectional AS NVARCHAR(500)) AS PostDirectional
			, CAST(Extension AS NVARCHAR(500)) AS Extension
			, CAST(ExtensionNumber AS NVARCHAR(500)) AS ExtensionNumber
			, CAST(County AS NVARCHAR(500)) AS County
			, CAST(CountyCode AS NVARCHAR(500)) AS CountyCode
			, CAST(Urbanization AS NVARCHAR(500)) AS Urbanization
			, CAST(UrbanizationCode AS NVARCHAR(500)) AS UrbanizationCode
			, CAST(City AS NVARCHAR(500)) AS City
			, CAST(PostalCode AS NVARCHAR(500)) AS PostalCode
			, CAST(PlusFour AS NVARCHAR(500)) AS PlusFour
			, CAST(PostalCodeFull AS NVARCHAR(500)) AS PostalCodeFull
			, CAST(Phone AS NVARCHAR(500)) AS Phone
			, CAST(DeliveryPoint AS NVARCHAR(500)) AS DeliveryPoint
			, CAST(CrossStreet AS NVARCHAR(500)) AS CrossStreet
			, CAST(Latitude AS NVARCHAR(500)) AS Latitude
			, CAST(Longitude AS NVARCHAR(500)) AS Longitude
			, CAST(CongressionalDistric AS NVARCHAR(500)) AS CongressionalDistric
			, CAST(DPV AS NVARCHAR(500)) AS DPV
			, CAST(DPVResponse AS NVARCHAR(500)) AS DPVResponse
			, CAST(DPVFootnote AS NVARCHAR(500)) AS DPVFootnote
			, CAST(CarrierRoute AS NVARCHAR(500)) AS CarrierRoute
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Inserted AS MFD WITH(NOLOCK)) AS st2
		UNPIVOT (
			ColumnNewValue FOR ColumnName IN (
			LeadAddressID
			, DealerTenantId
			, LanguageId
			, AddressValidationVendorId
			, AddressValidationStateId
			, PoliticalStateId
			, PoliticalCountryId
			, PoliticalTimeZoneId
			, AddressTypeId
			, AddressStreetTypeId
			, SeasonId
			, TeamLocationId
			, SalesRepId
			, StreetAddress
			, StreetAddress2
			, StreetNumber
			, StreetName
			, StreetType
			, PreDirectional
			, PostDirectional
			, Extension
			, ExtensionNumber
			, County
			, CountyCode
			, Urbanization
			, UrbanizationCode
			, City
			, PostalCode
			, PlusFour
			, PostalCodeFull
			, Phone
			, DeliveryPoint
			, CrossStreet
			, Latitude
			, Longitude
			, CongressionalDistric
			, DPV
			, DPVResponse
			, DPVFootnote
			, CarrierRoute
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        WithChangedCTE
        AS
        (
            SELECT
                PKID
			, InsertValues.ColumnName
			, InsertValues.ColumnOldValue
            FROM
                (SELECT
                    MFD.LeadAddressID AS PKID
			, CAST(LeadAddressID AS NVARCHAR(500)) AS LeadAddressID
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(LanguageId AS NVARCHAR(500)) AS LanguageId
			, CAST(AddressValidationVendorId AS NVARCHAR(500)) AS AddressValidationVendorId
			, CAST(AddressValidationStateId AS NVARCHAR(500)) AS AddressValidationStateId
			, CAST(PoliticalStateId AS NVARCHAR(500)) AS PoliticalStateId
			, CAST(PoliticalCountryId AS NVARCHAR(500)) AS PoliticalCountryId
			, CAST(PoliticalTimeZoneId AS NVARCHAR(500)) AS PoliticalTimeZoneId
			, CAST(AddressTypeId AS NVARCHAR(500)) AS AddressTypeId
			, CAST(AddressStreetTypeId AS NVARCHAR(500)) AS AddressStreetTypeId
			, CAST(SeasonId AS NVARCHAR(500)) AS SeasonId
			, CAST(TeamLocationId AS NVARCHAR(500)) AS TeamLocationId
			, CAST(SalesRepId AS NVARCHAR(500)) AS SalesRepId
			, CAST(StreetAddress AS NVARCHAR(500)) AS StreetAddress
			, CAST(StreetAddress2 AS NVARCHAR(500)) AS StreetAddress2
			, CAST(StreetNumber AS NVARCHAR(500)) AS StreetNumber
			, CAST(StreetName AS NVARCHAR(500)) AS StreetName
			, CAST(StreetType AS NVARCHAR(500)) AS StreetType
			, CAST(PreDirectional AS NVARCHAR(500)) AS PreDirectional
			, CAST(PostDirectional AS NVARCHAR(500)) AS PostDirectional
			, CAST(Extension AS NVARCHAR(500)) AS Extension
			, CAST(ExtensionNumber AS NVARCHAR(500)) AS ExtensionNumber
			, CAST(County AS NVARCHAR(500)) AS County
			, CAST(CountyCode AS NVARCHAR(500)) AS CountyCode
			, CAST(Urbanization AS NVARCHAR(500)) AS Urbanization
			, CAST(UrbanizationCode AS NVARCHAR(500)) AS UrbanizationCode
			, CAST(City AS NVARCHAR(500)) AS City
			, CAST(PostalCode AS NVARCHAR(500)) AS PostalCode
			, CAST(PlusFour AS NVARCHAR(500)) AS PlusFour
			, CAST(PostalCodeFull AS NVARCHAR(500)) AS PostalCodeFull
			, CAST(Phone AS NVARCHAR(500)) AS Phone
			, CAST(DeliveryPoint AS NVARCHAR(500)) AS DeliveryPoint
			, CAST(CrossStreet AS NVARCHAR(500)) AS CrossStreet
			, CAST(Latitude AS NVARCHAR(500)) AS Latitude
			, CAST(Longitude AS NVARCHAR(500)) AS Longitude
			, CAST(CongressionalDistric AS NVARCHAR(500)) AS CongressionalDistric
			, CAST(DPV AS NVARCHAR(500)) AS DPV
			, CAST(DPVResponse AS NVARCHAR(500)) AS DPVResponse
			, CAST(DPVFootnote AS NVARCHAR(500)) AS DPVFootnote
			, CAST(CarrierRoute AS NVARCHAR(500)) AS CarrierRoute
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Deleted AS MFD) AS st2
		UNPIVOT (
			ColumnOldValue FOR ColumnName IN (
			LeadAddressID
			, DealerTenantId
			, LanguageId
			, AddressValidationVendorId
			, AddressValidationStateId
			, PoliticalStateId
			, PoliticalCountryId
			, PoliticalTimeZoneId
			, AddressTypeId
			, AddressStreetTypeId
			, SeasonId
			, TeamLocationId
			, SalesRepId
			, StreetAddress
			, StreetAddress2
			, StreetNumber
			, StreetName
			, StreetType
			, PreDirectional
			, PostDirectional
			, Extension
			, ExtensionNumber
			, County
			, CountyCode
			, Urbanization
			, UrbanizationCode
			, City
			, PostalCode
			, PlusFour
			, PostalCodeFull
			, Phone
			, DeliveryPoint
			, CrossStreet
			, Latitude
			, Longitude
			, CongressionalDistric
			, DPV
			, DPVResponse
			, DPVFootnote
			, CarrierRoute
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        ResultCTE
        AS
        (
            SELECT
                RTN.PKID
			, RTN.ColumnName
			, RTN.ColumnNewValue AS NewValue
			, RTO.ColumnOldValue AS OldValue
            FROM
                RootCTE AS RTN WITH(NOLOCK)
                LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
                ON
				(RTO.PKID = RTN.PKID)
                    AND (RTO.ColumnName = RTN.ColumnName)
            WHERE
			(RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue)
        )
    INSERT INTO @DataTable
        (PKID, ColumnName, OldValue, NewValue)
    SELECT
        RT.PKID
        , RT.ColumnName
        , RT.OldValue
        , RT.NewValue
    FROM
        ResultCTE AS RT WITH(NOLOCK);

    /** Determin Action */
    WITH
        DistinctCTE
        AS
        (
            SELECT DISTINCT
                RT.PKID
            FROM
                @DataTable AS RT
        )
	,
        DeletedActionCTE
        AS
        (
            SELECT
                RT.PKID
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
			, CASE
				WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT)
				ELSE CAST(''True'' AS BIT)
			  END AS IsUpdateAction
            FROM
                DistinctCTE AS RT
                LEFT OUTER JOIN @DeletedTable AS DT
                ON
				(DT.PKID = RT.PKID)
        )
	,
        DetermineActionTypeCTE
        AS
        (
            SELECT
                DT.PKID
			, CASE
				WHEN DACT.IsDeleteAction = ''True'' THEN ''DELETE''
				WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
				WHEN DACT.IsUpdateAction = ''True'' THEN ''UPDATE''
				ELSE ''INSERT''
			  END AS AuditActionTypeId
            FROM
                @DataTable AS DT
                LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK)
                ON
				(DACT.PKID = DT.PKID)
        )
	UPDATE DT SET
		DT.AuditActionTypeId = DACT.AuditActionTypeId
	FROM
        @DataTable AS DT
        INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK)
        ON
			(DACT.PKID = DT.PKID);

    /** CREATE THE AUDIT ACTIONS */
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT,
        PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT
        DT.AuditActionTypeId
		, ''QAL''
		, ''LeadAddresses''
		, CAST(DT.PKID AS VARCHAR(50))
		, @UserID
    FROM
        @DataTable AS DT;

    /** CREATE THE AUDIT ACTION COLUMNS */
    INSERT INTO [AUD].[AuditActionColumns]
        ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT
        AAT.AuditActionID
		, DT.ColumnName
		, DT.OldValue
		, DT.NewValue
    FROM
        @DataTable AS DT
        INNER JOIN @AuditActionTable AS AAT
        ON
			(AAT.PKID = DT.PKID)
END;';
    PRINT 'Recreated [QAL].[trgAutoGen_LeadAddresses_CUD]';

    IF OBJECT_ID(N'[QAL].[trgAutoGen_Leads_CUD]', N'TR') IS NOT NULL
        DROP TRIGGER [QAL].[trgAutoGen_Leads_CUD];
    EXEC sys.sp_executesql N'CREATE TRIGGER [QAL].[trgAutoGen_Leads_CUD] ON [QAL].[Leads]
	AFTER INSERT, UPDATE
AS
BEGIN
    /**************
	 * INITIALIZE
	 **************/
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerTenantId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerTenantId = DealerTenantId
    FROM [ACC].[fxGetContextUserTable]();
    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable
        ( PKID )
    SELECT LeadID
    FROM Deleted;

    /** Build Data Changes */
    DECLARE @DataTable TABLE (PKID BIGINT NOT NULL,
        AuditActionId BIGINT,
        AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500),
        OldValue NVARCHAR(500),
        NewValue NVARCHAR(500));
    WITH
        RootCTE
        AS
        (
            SELECT
                PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
            FROM
                (SELECT
                    MFD.LeadID AS PKID
			, CAST(LeadID AS NVARCHAR(500)) AS LeadID
			, CAST(LeadAddressId AS NVARCHAR(500)) AS LeadAddressId
			, CAST(CustomerTypeId AS NVARCHAR(500)) AS CustomerTypeId
			, CAST(MasterFileId AS NVARCHAR(500)) AS MasterFileId
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(LanguageId AS NVARCHAR(500)) AS LanguageId
			, CAST(TeamLocationId AS NVARCHAR(500)) AS TeamLocationId
			, CAST(SeasonId AS NVARCHAR(500)) AS SeasonId
			, CAST(SalesRepId AS NVARCHAR(500)) AS SalesRepId
			, CAST(LeadSourceId AS NVARCHAR(500)) AS LeadSourceId
			, CAST(LeadDispositionId AS NVARCHAR(500)) AS LeadDispositionId
			, CAST(LeadDispositionDateChange AS NVARCHAR(500)) AS LeadDispositionDateChange
			, CAST(Prefix AS NVARCHAR(500)) AS Prefix
			, CAST(FirstName AS NVARCHAR(500)) AS FirstName
			, CAST(MiddleName AS NVARCHAR(500)) AS MiddleName
			, CAST(LastName AS NVARCHAR(500)) AS LastName
			, CAST(PostFix AS NVARCHAR(500)) AS PostFix
			, CAST(Gender AS NVARCHAR(500)) AS Gender
			, CAST(SSN AS NVARCHAR(500)) AS SSN
			, CAST(DOB AS NVARCHAR(500)) AS DOB
			, CAST(DL AS NVARCHAR(500)) AS DL
			, CAST(DLStateID AS NVARCHAR(500)) AS DLStateID
			, CAST(Email AS NVARCHAR(500)) AS Email
			, CAST(PhoneHome AS NVARCHAR(500)) AS PhoneHome
			, CAST(PhoneWork AS NVARCHAR(500)) AS PhoneWork
			, CAST(PhoneMobile AS NVARCHAR(500)) AS PhoneMobile
			, CAST(ExternalSource AS NVARCHAR(500)) AS ExternalSource
			, CAST(ExternalId AS NVARCHAR(500)) AS ExternalId
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Inserted AS MFD WITH(NOLOCK)) AS st2
		UNPIVOT (
			ColumnNewValue FOR ColumnName IN (
			LeadID
			, LeadAddressId
			, CustomerTypeId
			, MasterFileId
			, DealerTenantId
			, LanguageId
			, TeamLocationId
			, SeasonId
			, SalesRepId
			, LeadSourceId
			, LeadDispositionId
			, LeadDispositionDateChange
			, Prefix
			, FirstName
			, MiddleName
			, LastName
			, PostFix
			, Gender
			, SSN
			, DOB
			, DL
			, DLStateID
			, Email
			, PhoneHome
			, PhoneWork
			, PhoneMobile
			, ExternalSource
			, ExternalId
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        WithChangedCTE
        AS
        (
            SELECT
                PKID
			, InsertValues.ColumnName
			, InsertValues.ColumnOldValue
            FROM
                (SELECT
                    MFD.LeadID AS PKID
			, CAST(LeadID AS NVARCHAR(500)) AS LeadID
			, CAST(LeadAddressId AS NVARCHAR(500)) AS LeadAddressId
			, CAST(CustomerTypeId AS NVARCHAR(500)) AS CustomerTypeId
			, CAST(MasterFileId AS NVARCHAR(500)) AS MasterFileId
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(LanguageId AS NVARCHAR(500)) AS LanguageId
			, CAST(TeamLocationId AS NVARCHAR(500)) AS TeamLocationId
			, CAST(SeasonId AS NVARCHAR(500)) AS SeasonId
			, CAST(SalesRepId AS NVARCHAR(500)) AS SalesRepId
			, CAST(LeadSourceId AS NVARCHAR(500)) AS LeadSourceId
			, CAST(LeadDispositionId AS NVARCHAR(500)) AS LeadDispositionId
			, CAST(LeadDispositionDateChange AS NVARCHAR(500)) AS LeadDispositionDateChange
			, CAST(Prefix AS NVARCHAR(500)) AS Prefix
			, CAST(FirstName AS NVARCHAR(500)) AS FirstName
			, CAST(MiddleName AS NVARCHAR(500)) AS MiddleName
			, CAST(LastName AS NVARCHAR(500)) AS LastName
			, CAST(PostFix AS NVARCHAR(500)) AS PostFix
			, CAST(Gender AS NVARCHAR(500)) AS Gender
			, CAST(SSN AS NVARCHAR(500)) AS SSN
			, CAST(DOB AS NVARCHAR(500)) AS DOB
			, CAST(DL AS NVARCHAR(500)) AS DL
			, CAST(DLStateID AS NVARCHAR(500)) AS DLStateID
			, CAST(Email AS NVARCHAR(500)) AS Email
			, CAST(PhoneHome AS NVARCHAR(500)) AS PhoneHome
			, CAST(PhoneWork AS NVARCHAR(500)) AS PhoneWork
			, CAST(PhoneMobile AS NVARCHAR(500)) AS PhoneMobile
			, CAST(ExternalSource AS NVARCHAR(500)) AS ExternalSource
			, CAST(ExternalId AS NVARCHAR(500)) AS ExternalId
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Deleted AS MFD) AS st2
		UNPIVOT (
			ColumnOldValue FOR ColumnName IN (
			LeadID
			, LeadAddressId
			, CustomerTypeId
			, MasterFileId
			, DealerTenantId
			, LanguageId
			, TeamLocationId
			, SeasonId
			, SalesRepId
			, LeadSourceId
			, LeadDispositionId
			, LeadDispositionDateChange
			, Prefix
			, FirstName
			, MiddleName
			, LastName
			, PostFix
			, Gender
			, SSN
			, DOB
			, DL
			, DLStateID
			, Email
			, PhoneHome
			, PhoneWork
			, PhoneMobile
			, ExternalSource
			, ExternalId
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        ResultCTE
        AS
        (
            SELECT
                RTN.PKID
			, RTN.ColumnName
			, RTN.ColumnNewValue AS NewValue
			, RTO.ColumnOldValue AS OldValue
            FROM
                RootCTE AS RTN WITH(NOLOCK)
                LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
                ON
				(RTO.PKID = RTN.PKID)
                    AND (RTO.ColumnName = RTN.ColumnName)
            WHERE
			(RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue)
        )
    INSERT INTO @DataTable
        (PKID, ColumnName, OldValue, NewValue)
    SELECT
        RT.PKID
        , RT.ColumnName
        , RT.OldValue
        , RT.NewValue
    FROM
        ResultCTE AS RT WITH(NOLOCK);

    /** Determin Action */
    WITH
        DistinctCTE
        AS
        (
            SELECT DISTINCT
                RT.PKID
            FROM
                @DataTable AS RT
        )
	,
        DeletedActionCTE
        AS
        (
            SELECT
                RT.PKID
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
			, CASE
				WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT)
				ELSE CAST(''True'' AS BIT)
			  END AS IsUpdateAction
            FROM
                DistinctCTE AS RT
                LEFT OUTER JOIN @DeletedTable AS DT
                ON
				(DT.PKID = RT.PKID)
        )
	,
        DetermineActionTypeCTE
        AS
        (
            SELECT
                DT.PKID
			, CASE
				WHEN DACT.IsDeleteAction = ''True'' THEN ''DELETE''
				WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
				WHEN DACT.IsUpdateAction = ''True'' THEN ''UPDATE''
				ELSE ''INSERT''
			  END AS AuditActionTypeId
            FROM
                @DataTable AS DT
                LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK)
                ON
				(DACT.PKID = DT.PKID)
        )
	UPDATE DT SET
		DT.AuditActionTypeId = DACT.AuditActionTypeId
	FROM
        @DataTable AS DT
        INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK)
        ON
			(DACT.PKID = DT.PKID);

    /** CREATE THE AUDIT ACTIONS */
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT,
        PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT
        DT.AuditActionTypeId
		, ''QAL''
		, ''Leads''
		, CAST(DT.PKID AS VARCHAR(50))
		, @UserID
    FROM
        @DataTable AS DT;

    /** CREATE THE AUDIT ACTION COLUMNS */
    INSERT INTO [AUD].[AuditActionColumns]
        ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT
        AAT.AuditActionID
		, DT.ColumnName
		, DT.OldValue
		, DT.NewValue
    FROM
        @DataTable AS DT
        INNER JOIN @AuditActionTable AS AAT
        ON
			(AAT.PKID = DT.PKID)
END;';
    PRINT 'Recreated [QAL].[trgAutoGen_Leads_CUD]';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Lead intake: external ids, optional sales fields, lead seeds, audit triggers on DealerTenantId',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT:
Making the columns NOT NULL again only works while no lead has them empty, so it is not scripted.
BEGIN TRANSACTION;
DROP INDEX [IX_Leads_DealerTenantId_ExternalSource_ExternalId] ON [QAL].[Leads];
DROP INDEX [IX_Leads_DealerTenantId_Email] ON [QAL].[Leads];
DROP INDEX [IX_LeadSources_DealerTenantId_LeadSourceName] ON [QAL].[LeadSources];
ALTER TABLE [QAL].[Leads] DROP CONSTRAINT [CK_Leads_ExternalSource];
-- Recreate trgAutoGen_Leads_CUD without ExternalSource/ExternalId first, then:
ALTER TABLE [QAL].[Leads] DROP COLUMN [ExternalSource], [ExternalId], [Notes];
ALTER TABLE [QAL].[LeadAddresses] DROP CONSTRAINT [DF_LeadAddresses_DPV];
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_0340_AddQAL_LeadIntake';
COMMIT TRANSACTION;
Seeded CustomerTypes, LeadDispositions and LeadSources stay; delete them only if no lead uses them.
*/
