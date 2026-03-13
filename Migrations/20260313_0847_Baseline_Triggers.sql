/*
Migration: 20260313_0847_Baseline_Triggers
Author: Admin
Date: 2026-03-13
Description: Deploys 7 table triggers that exist in the Triggers/ directory but
             were omitted from the 20260313_0846_Baseline_ObjectsDeployed tracking
             migration. This migration is self-contained — it creates/replaces each
             trigger directly and should be run against any database that already has
             the baseline tables and functions deployed.

             Triggers deployed (7):
               1. ACC.UserInsert               — AFTER INSERT  on ACC.Users
               2. RSU.UserResourcesUpdate      — AFTER UPDATE  on RSU.UserResources
               3. ACE.trgAutoGen_Customers_CUD         — AFTER INSERT,UPDATE on ACE.Customers
               4. ACE.trgAutoGen_MasterFileAccounts_CUD — AFTER INSERT,UPDATE on ACE.MasterFileAccounts
               5. ACE.trgAutoGen_MasterFiles_CUD        — AFTER INSERT,UPDATE on ACE.MasterFiles
               6. QAL.trgAutoGen_LeadAddresses_CUD      — AFTER INSERT,UPDATE on QAL.LeadAddresses
               7. QAL.trgAutoGen_Leads_CUD              — AFTER INSERT,UPDATE on QAL.Leads

             NOTE (Trigger 2 — RSU.UserResourcesUpdate): The source file contains
             a WHILE (@@FETCH_STATUS <> 0) condition that appears inverted; the
             standard pattern is @@FETCH_STATUS = 0 (success). This migration
             reproduces the source faithfully. Review separately if the sync
             behaviour is not firing as expected.

Dependencies: 00000000_0000_CreateSchemaVersionTable
              20260313_0845_Baseline_Schemas
              20260313_0846_Baseline_ObjectsDeployed
              (ACC.fxGetContextUserTable must exist for triggers 3-7)
*/

BEGIN TRANSACTION;
BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260313_0847_Baseline_Triggers';
    DECLARE @StartTime     DATETIME2     = GETUTCDATE();
    DECLARE @sql           NVARCHAR(MAX);

    -- =========================================================================
    -- Idempotency check
    -- =========================================================================
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration ' + @MigrationName + ' has already been applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- =========================================================================
    -- Validate prerequisites
    -- =========================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'ACC')
        RAISERROR('Schema ACC not found. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'RSU')
        RAISERROR('Schema RSU not found. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'ACE')
        RAISERROR('Schema ACE not found. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'QAL')
        RAISERROR('Schema QAL not found. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.schemas
WHERE name = 'AUD')
        RAISERROR('Schema AUD not found. Run 20260313_0845_Baseline_Schemas.sql first.', 16, 1);

    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'Users' AND schema_id = SCHEMA_ID('ACC'))
        RAISERROR('Table ACC.Users not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'UserResources' AND schema_id = SCHEMA_ID('RSU'))
        RAISERROR('Table RSU.UserResources not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'Customers' AND schema_id = SCHEMA_ID('ACE'))
        RAISERROR('Table ACE.Customers not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'MasterFileAccounts' AND schema_id = SCHEMA_ID('ACE'))
        RAISERROR('Table ACE.MasterFileAccounts not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'MasterFiles' AND schema_id = SCHEMA_ID('ACE'))
        RAISERROR('Table ACE.MasterFiles not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'Leads' AND schema_id = SCHEMA_ID('QAL'))
        RAISERROR('Table QAL.Leads not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);
    IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'LeadAddresses' AND schema_id = SCHEMA_ID('QAL'))
        RAISERROR('Table QAL.LeadAddresses not found. Run Deploy_Baseline.ps1 (Tables step) first.', 16, 1);

    -- ACC.fxGetContextUserTable is a dependency for triggers 3-7
    IF OBJECT_ID('ACC.fxGetContextUserTable', 'TF') IS NULL
    AND OBJECT_ID('ACC.fxGetContextUserTable', 'IF') IS NULL
    AND OBJECT_ID('ACC.fxGetContextUserTable', 'FN') IS NULL
        RAISERROR('Function ACC.fxGetContextUserTable not found. Run Deploy_Baseline.ps1 (Functions step) first.', 16, 1);

    PRINT 'Validation passed: all prerequisites confirmed.';

    -- =========================================================================
    -- TRIGGER 1 of 7 : ACC.UserInsert
    -- AFTER INSERT on ACC.Users
    -- Self-assigns CreatedById / ModifiedById from the newly inserted UserId.
    -- =========================================================================
    IF OBJECT_ID('[ACC].[UserInsert]', 'TR') IS NOT NULL
        DROP TRIGGER [ACC].[UserInsert];

    SET @sql = N'CREATE TRIGGER [ACC].[UserInsert]
        ON [ACC].[Users]
        AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF ((SELECT COUNT(*) FROM INSERTED) > 1)
    BEGIN
        UPDATE U SET
            U.CreatedById  = I.UserId
          , U.ModifiedById = I.UserId
        FROM [ACC].[Users] AS U WITH (NOLOCK)
        INNER JOIN INSERTED AS I ON (I.UserId = U.UserId)
    END
    ELSE
    BEGIN
        DECLARE @UserId UNIQUEIDENTIFIER = (SELECT UserId FROM INSERTED);

        UPDATE U SET
            CreatedById  = @UserId
          , ModifiedById = @UserId
        FROM [ACC].[Users] AS U WITH (NOLOCK)
        WHERE (U.UserId = @UserId);
    END
END';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 1/7: [ACC].[UserInsert] created.';

    -- =========================================================================
    -- TRIGGER 2 of 7 : RSU.UserResourcesUpdate
    -- AFTER UPDATE on RSU.UserResources
    -- Syncs FirstName, LastName, Email, UserName, PhoneCell, GPEmployeeId,
    -- HRUserId back to the corresponding ACC.Users record.
    -- NOTE: Source file uses @@FETCH_STATUS <> 0; reproduced faithfully.
    -- =========================================================================
    IF OBJECT_ID('[RSU].[UserResourcesUpdate]', 'TR') IS NOT NULL
        DROP TRIGGER [RSU].[UserResourcesUpdate];

    SET @sql = N'CREATE TRIGGER [RSU].[UserResourcesUpdate]
        ON [RSU].[UserResources]
        AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID   UNIQUEIDENTIFIER
          , @Username NVARCHAR(256);

    DECLARE SomeCursor CURSOR LOCAL READ_ONLY FORWARD_ONLY FOR
        SELECT UserID FROM INSERTED;

    OPEN SomeCursor;
    FETCH NEXT FROM SomeCursor INTO @UserID;

    WHILE (@@FETCH_STATUS <> 0)
    BEGIN
        IF (EXISTS (SELECT TOP(1) 1
                    FROM [ACC].[Users]
                    WHERE UserID <> @UserID AND Username = @Username))
        BEGIN
            CLOSE SomeCursor;
            DEALLOCATE SomeCursor;
            RAISERROR(N''Sorry, the username ''''%s'''' has already been taken.'', 18, 1, @Username);
        END

        UPDATE U SET
            U.FirstName    = I.FirstName
          , U.HRUserId     = I.UserResourceID
          , U.LastName     = I.LastName
          , U.GPEmployeeID = I.GPEmployeeId
          , U.Email        = I.Email
          , U.Username     = I.UserName
          , U.PhoneNumber  = I.PhoneCell
        FROM [ACC].[Users]   AS U WITH(NOLOCK)
        INNER JOIN Inserted  AS I ON (I.UserId = U.UserID)
        WHERE (U.UserID = @UserID);

        FETCH NEXT FROM SomeCursor INTO @UserID;
    END;

    CLOSE SomeCursor;
    DEALLOCATE SomeCursor;
END';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 2/7: [RSU].[UserResourcesUpdate] created.';

    -- =========================================================================
    -- TRIGGER 3 of 7 : ACE.trgAutoGen_Customers_CUD
    -- AFTER INSERT, UPDATE on ACE.Customers
    -- Audit CUD trigger: writes to AUD.AuditActions / AUD.AuditActionColumns.
    -- =========================================================================
    IF OBJECT_ID('[ACE].[trgAutoGen_Customers_CUD]', 'TR') IS NOT NULL
        DROP TRIGGER [ACE].[trgAutoGen_Customers_CUD];

    -- Part 1 of 4 — CREATE TRIGGER header, INITIALIZE, @DataTable, RootCTE (Inserted)
    SET @sql = N'CREATE TRIGGER [ACE].[trgAutoGen_Customers_CUD] ON [ACE].[Customers]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId
    FROM [ACC].[fxGetContextUserTable]();

    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable (PKID) SELECT CustomerID FROM Deleted;

    DECLARE @DataTable TABLE (
        PKID BIGINT NOT NULL, AuditActionId BIGINT, AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500), OldValue NVARCHAR(500), NewValue NVARCHAR(500));

    WITH RootCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
        FROM (SELECT MFD.CustomerID AS PKID
            , CAST(CustomerID       AS NVARCHAR(500)) AS CustomerID
            , CAST(CustomerTypeId   AS NVARCHAR(500)) AS CustomerTypeId
            , CAST(MasterFileId     AS NVARCHAR(500)) AS MasterFileId
            , CAST(DealerId         AS NVARCHAR(500)) AS DealerId
            , CAST(CustomerAddressId AS NVARCHAR(500)) AS CustomerAddressId
            , CAST(LeadId           AS NVARCHAR(500)) AS LeadId
            , CAST(LanguageId       AS NVARCHAR(500)) AS LanguageId
            , CAST(Prefix           AS NVARCHAR(500)) AS Prefix
            , CAST(FirstName        AS NVARCHAR(500)) AS FirstName
            , CAST(MiddleName       AS NVARCHAR(500)) AS MiddleName
            , CAST(LastName         AS NVARCHAR(500)) AS LastName
            , CAST(Postfix          AS NVARCHAR(500)) AS Postfix
            , CAST(BusinessName     AS NVARCHAR(500)) AS BusinessName
            , CAST(Gender           AS NVARCHAR(500)) AS Gender
            , CAST(PhoneHome        AS NVARCHAR(500)) AS PhoneHome
            , CAST(PhoneWork        AS NVARCHAR(500)) AS PhoneWork
            , CAST(PhoneMobile      AS NVARCHAR(500)) AS PhoneMobile
            , CAST(Email            AS NVARCHAR(500)) AS Email
            , CAST(DOB              AS NVARCHAR(500)) AS DOB
            , CAST(SSN              AS NVARCHAR(500)) AS SSN
            , CAST(Username         AS NVARCHAR(500)) AS Username
            , CAST(Password         AS NVARCHAR(500)) AS Password
            , CAST(IsActive         AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted        AS NVARCHAR(500)) AS IsDeleted
        FROM Inserted AS MFD WITH(NOLOCK)) AS st2
        UNPIVOT (ColumnNewValue FOR ColumnName IN (
            CustomerID, CustomerTypeId, MasterFileId, DealerId, CustomerAddressId,
            LeadId, LanguageId, Prefix, FirstName, MiddleName, LastName, Postfix,
            BusinessName, Gender, PhoneHome, PhoneWork, PhoneMobile, Email, DOB,
            SSN, Username, Password, IsActive, IsDeleted)) AS InsertValues)';

    -- Part 2 of 4 — WithChangedCTE (Deleted) and ResultCTE → INSERT @DataTable
    SET @sql = @sql + N', WithChangedCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnOldValue
        FROM (SELECT MFD.CustomerID AS PKID
            , CAST(CustomerID       AS NVARCHAR(500)) AS CustomerID
            , CAST(CustomerTypeId   AS NVARCHAR(500)) AS CustomerTypeId
            , CAST(MasterFileId     AS NVARCHAR(500)) AS MasterFileId
            , CAST(DealerId         AS NVARCHAR(500)) AS DealerId
            , CAST(CustomerAddressId AS NVARCHAR(500)) AS CustomerAddressId
            , CAST(LeadId           AS NVARCHAR(500)) AS LeadId
            , CAST(LanguageId       AS NVARCHAR(500)) AS LanguageId
            , CAST(Prefix           AS NVARCHAR(500)) AS Prefix
            , CAST(FirstName        AS NVARCHAR(500)) AS FirstName
            , CAST(MiddleName       AS NVARCHAR(500)) AS MiddleName
            , CAST(LastName         AS NVARCHAR(500)) AS LastName
            , CAST(Postfix          AS NVARCHAR(500)) AS Postfix
            , CAST(BusinessName     AS NVARCHAR(500)) AS BusinessName
            , CAST(Gender           AS NVARCHAR(500)) AS Gender
            , CAST(PhoneHome        AS NVARCHAR(500)) AS PhoneHome
            , CAST(PhoneWork        AS NVARCHAR(500)) AS PhoneWork
            , CAST(PhoneMobile      AS NVARCHAR(500)) AS PhoneMobile
            , CAST(Email            AS NVARCHAR(500)) AS Email
            , CAST(DOB              AS NVARCHAR(500)) AS DOB
            , CAST(SSN              AS NVARCHAR(500)) AS SSN
            , CAST(Username         AS NVARCHAR(500)) AS Username
            , CAST(Password         AS NVARCHAR(500)) AS Password
            , CAST(IsActive         AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted        AS NVARCHAR(500)) AS IsDeleted
        FROM Deleted AS MFD) AS st2
        UNPIVOT (ColumnOldValue FOR ColumnName IN (
            CustomerID, CustomerTypeId, MasterFileId, DealerId, CustomerAddressId,
            LeadId, LanguageId, Prefix, FirstName, MiddleName, LastName, Postfix,
            BusinessName, Gender, PhoneHome, PhoneWork, PhoneMobile, Email, DOB,
            SSN, Username, Password, IsActive, IsDeleted)) AS InsertValues)
    , ResultCTE AS (
        SELECT RTN.PKID, RTN.ColumnName, RTN.ColumnNewValue AS NewValue, RTO.ColumnOldValue AS OldValue
        FROM RootCTE AS RTN WITH(NOLOCK)
        LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
            ON (RTO.PKID = RTN.PKID) AND (RTO.ColumnName = RTN.ColumnName)
        WHERE (RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue))
    INSERT INTO @DataTable (PKID, ColumnName, OldValue, NewValue)
    SELECT RT.PKID, RT.ColumnName, RT.OldValue, RT.NewValue FROM ResultCTE AS RT WITH(NOLOCK);';

    -- Part 3 of 4 — Determine action type (DELETE / UNDELETE / UPDATE / INSERT)
    SET @sql = @sql + N'
    WITH DistinctCTE AS (SELECT DISTINCT RT.PKID FROM @DataTable AS RT)
    , DeletedActionCTE AS (
        SELECT RT.PKID
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
            , CASE WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT) ELSE CAST(''True'' AS BIT) END AS IsUpdateAction
        FROM DistinctCTE AS RT
        LEFT OUTER JOIN @DeletedTable AS DT ON (DT.PKID = RT.PKID))
    , DetermineActionTypeCTE AS (
        SELECT DT.PKID
            , CASE WHEN DACT.IsDeleteAction   = ''True'' THEN ''DELETE''
                   WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
                   WHEN DACT.IsUpdateAction   = ''True'' THEN ''UPDATE''
                   ELSE ''INSERT'' END AS AuditActionTypeId
        FROM @DataTable AS DT
        LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID))
    UPDATE DT SET DT.AuditActionTypeId = DACT.AuditActionTypeId
    FROM @DataTable AS DT
    INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID);';

    -- Part 4 of 4 — Write audit rows to AUD tables
    SET @sql = @sql + N'
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT, PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT DT.AuditActionTypeId, ''ACE'', ''Customers'', CAST(DT.PKID AS VARCHAR(50)), @UserID
    FROM @DataTable AS DT;

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT AAT.AuditActionID, DT.ColumnName, DT.OldValue, DT.NewValue
    FROM @DataTable AS DT
    INNER JOIN @AuditActionTable AS AAT ON (AAT.PKID = DT.PKID)
END;';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 3/7: [ACE].[trgAutoGen_Customers_CUD] created.';

    -- =========================================================================
    -- TRIGGER 4 of 7 : ACE.trgAutoGen_MasterFileAccounts_CUD
    -- AFTER INSERT, UPDATE on ACE.MasterFileAccounts
    -- =========================================================================
    IF OBJECT_ID('[ACE].[trgAutoGen_MasterFileAccounts_CUD]', 'TR') IS NOT NULL
        DROP TRIGGER [ACE].[trgAutoGen_MasterFileAccounts_CUD];

    -- Part 1 of 4 — header, INITIALIZE, @DataTable, RootCTE (Inserted)
    SET @sql = N'CREATE TRIGGER [ACE].[trgAutoGen_MasterFileAccounts_CUD] ON [ACE].[MasterFileAccounts]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId
    FROM [ACC].[fxGetContextUserTable]();

    DECLARE @DeletedTable TABLE (PKID VARCHAR(50) NOT NULL);
    INSERT INTO @DeletedTable (PKID) SELECT MasterFileAccountID FROM Deleted;

    DECLARE @DataTable TABLE (
        PKID VARCHAR(50) NOT NULL, AuditActionId BIGINT, AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500), OldValue NVARCHAR(500), NewValue NVARCHAR(500));

    WITH RootCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
        FROM (SELECT MFD.MasterFileAccountID AS PKID
            , CAST(MasterFileAccountID  AS NVARCHAR(500)) AS MasterFileAccountID
            , CAST(MasterFileId         AS NVARCHAR(500)) AS MasterFileId
            , CAST(DealerId             AS NVARCHAR(500)) AS DealerId
            , CAST(CustomerTypeId       AS NVARCHAR(500)) AS CustomerTypeId
            , CAST(LeadId               AS NVARCHAR(500)) AS LeadId
            , CAST(Lead2Id              AS NVARCHAR(500)) AS Lead2Id
            , CAST(AccountId            AS NVARCHAR(500)) AS AccountId
            , CAST(AccountTypeId        AS NVARCHAR(500)) AS AccountTypeId
            , CAST(CustomerId           AS NVARCHAR(500)) AS CustomerId
            , CAST(Customer2Id          AS NVARCHAR(500)) AS Customer2Id
            , CAST(MonthlyContractId    AS NVARCHAR(500)) AS MonthlyContractId
            , CAST(InstallFeeContractId AS NVARCHAR(500)) AS InstallFeeContractId
            , CAST(BillingDay           AS NVARCHAR(500)) AS BillingDay
            , CAST(EffectiveDate        AS NVARCHAR(500)) AS EffectiveDate
            , CAST(ContractLockDate     AS NVARCHAR(500)) AS ContractLockDate
            , CAST(IsActive             AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted            AS NVARCHAR(500)) AS IsDeleted
        FROM Inserted AS MFD WITH(NOLOCK)) AS st2
        UNPIVOT (ColumnNewValue FOR ColumnName IN (
            MasterFileAccountID, MasterFileId, DealerId, CustomerTypeId,
            LeadId, Lead2Id, AccountId, AccountTypeId, CustomerId, Customer2Id,
            MonthlyContractId, InstallFeeContractId, BillingDay, EffectiveDate,
            ContractLockDate, IsActive, IsDeleted)) AS InsertValues)';

    -- Part 2 of 4 — WithChangedCTE (Deleted) + ResultCTE → INSERT @DataTable
    SET @sql = @sql + N', WithChangedCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnOldValue
        FROM (SELECT MFD.MasterFileAccountID AS PKID
            , CAST(MasterFileAccountID  AS NVARCHAR(500)) AS MasterFileAccountID
            , CAST(MasterFileId         AS NVARCHAR(500)) AS MasterFileId
            , CAST(DealerId             AS NVARCHAR(500)) AS DealerId
            , CAST(CustomerTypeId       AS NVARCHAR(500)) AS CustomerTypeId
            , CAST(LeadId               AS NVARCHAR(500)) AS LeadId
            , CAST(Lead2Id              AS NVARCHAR(500)) AS Lead2Id
            , CAST(AccountId            AS NVARCHAR(500)) AS AccountId
            , CAST(AccountTypeId        AS NVARCHAR(500)) AS AccountTypeId
            , CAST(CustomerId           AS NVARCHAR(500)) AS CustomerId
            , CAST(Customer2Id          AS NVARCHAR(500)) AS Customer2Id
            , CAST(MonthlyContractId    AS NVARCHAR(500)) AS MonthlyContractId
            , CAST(InstallFeeContractId AS NVARCHAR(500)) AS InstallFeeContractId
            , CAST(BillingDay           AS NVARCHAR(500)) AS BillingDay
            , CAST(EffectiveDate        AS NVARCHAR(500)) AS EffectiveDate
            , CAST(ContractLockDate     AS NVARCHAR(500)) AS ContractLockDate
            , CAST(IsActive             AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted            AS NVARCHAR(500)) AS IsDeleted
        FROM Deleted AS MFD) AS st2
        UNPIVOT (ColumnOldValue FOR ColumnName IN (
            MasterFileAccountID, MasterFileId, DealerId, CustomerTypeId,
            LeadId, Lead2Id, AccountId, AccountTypeId, CustomerId, Customer2Id,
            MonthlyContractId, InstallFeeContractId, BillingDay, EffectiveDate,
            ContractLockDate, IsActive, IsDeleted)) AS InsertValues)
    , ResultCTE AS (
        SELECT RTN.PKID, RTN.ColumnName, RTN.ColumnNewValue AS NewValue, RTO.ColumnOldValue AS OldValue
        FROM RootCTE AS RTN WITH(NOLOCK)
        LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
            ON (RTO.PKID = RTN.PKID) AND (RTO.ColumnName = RTN.ColumnName)
        WHERE (RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue))
    INSERT INTO @DataTable (PKID, ColumnName, OldValue, NewValue)
    SELECT RT.PKID, RT.ColumnName, RT.OldValue, RT.NewValue FROM ResultCTE AS RT WITH(NOLOCK);';

    -- Part 3 of 4 — Determine action type
    SET @sql = @sql + N'
    WITH DistinctCTE AS (SELECT DISTINCT RT.PKID FROM @DataTable AS RT)
    , DeletedActionCTE AS (
        SELECT RT.PKID
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
            , CASE WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT) ELSE CAST(''True'' AS BIT) END AS IsUpdateAction
        FROM DistinctCTE AS RT
        LEFT OUTER JOIN @DeletedTable AS DT ON (DT.PKID = RT.PKID))
    , DetermineActionTypeCTE AS (
        SELECT DT.PKID
            , CASE WHEN DACT.IsDeleteAction   = ''True'' THEN ''DELETE''
                   WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
                   WHEN DACT.IsUpdateAction   = ''True'' THEN ''UPDATE''
                   ELSE ''INSERT'' END AS AuditActionTypeId
        FROM @DataTable AS DT
        LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID))
    UPDATE DT SET DT.AuditActionTypeId = DACT.AuditActionTypeId
    FROM @DataTable AS DT
    INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID);';

    -- Part 4 of 4 — Write audit rows
    SET @sql = @sql + N'
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT, PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT DT.AuditActionTypeId, ''ACE'', ''MasterFileAccounts'', CAST(DT.PKID AS VARCHAR(50)), @UserID
    FROM @DataTable AS DT;

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT AAT.AuditActionID, DT.ColumnName, DT.OldValue, DT.NewValue
    FROM @DataTable AS DT
    INNER JOIN @AuditActionTable AS AAT ON (AAT.PKID = DT.PKID)
END;';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 4/7: [ACE].[trgAutoGen_MasterFileAccounts_CUD] created.';

    -- =========================================================================
    -- TRIGGER 5 of 7 : ACE.trgAutoGen_MasterFiles_CUD
    -- AFTER INSERT, UPDATE on ACE.MasterFiles
    -- =========================================================================
    IF OBJECT_ID('[ACE].[trgAutoGen_MasterFiles_CUD]', 'TR') IS NOT NULL
        DROP TRIGGER [ACE].[trgAutoGen_MasterFiles_CUD];

    SET @sql = N'CREATE TRIGGER [ACE].[trgAutoGen_MasterFiles_CUD] ON [ACE].[MasterFiles]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId
    FROM [ACC].[fxGetContextUserTable]();

    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable (PKID) SELECT MasterFileID FROM Deleted;

    DECLARE @DataTable TABLE (
        PKID BIGINT NOT NULL, AuditActionId BIGINT, AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500), OldValue NVARCHAR(500), NewValue NVARCHAR(500));

    WITH RootCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
        FROM (SELECT MFD.MasterFileID AS PKID
            , CAST(MasterFileID AS NVARCHAR(500)) AS MasterFileID
            , CAST(DealerId     AS NVARCHAR(500)) AS DealerId
            , CAST(IsActive     AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted    AS NVARCHAR(500)) AS IsDeleted
        FROM Inserted AS MFD WITH(NOLOCK)) AS st2
        UNPIVOT (ColumnNewValue FOR ColumnName IN (
            MasterFileID, DealerId, IsActive, IsDeleted)) AS InsertValues)
    , WithChangedCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnOldValue
        FROM (SELECT MFD.MasterFileID AS PKID
            , CAST(MasterFileID AS NVARCHAR(500)) AS MasterFileID
            , CAST(DealerId     AS NVARCHAR(500)) AS DealerId
            , CAST(IsActive     AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted    AS NVARCHAR(500)) AS IsDeleted
        FROM Deleted AS MFD) AS st2
        UNPIVOT (ColumnOldValue FOR ColumnName IN (
            MasterFileID, DealerId, IsActive, IsDeleted)) AS InsertValues)
    , ResultCTE AS (
        SELECT RTN.PKID, RTN.ColumnName, RTN.ColumnNewValue AS NewValue, RTO.ColumnOldValue AS OldValue
        FROM RootCTE AS RTN WITH(NOLOCK)
        LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
            ON (RTO.PKID = RTN.PKID) AND (RTO.ColumnName = RTN.ColumnName)
        WHERE (RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue))
    INSERT INTO @DataTable (PKID, ColumnName, OldValue, NewValue)
    SELECT RT.PKID, RT.ColumnName, RT.OldValue, RT.NewValue FROM ResultCTE AS RT WITH(NOLOCK);

    WITH DistinctCTE AS (SELECT DISTINCT RT.PKID FROM @DataTable AS RT)
    , DeletedActionCTE AS (
        SELECT RT.PKID
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
            , CASE WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT) ELSE CAST(''True'' AS BIT) END AS IsUpdateAction
        FROM DistinctCTE AS RT
        LEFT OUTER JOIN @DeletedTable AS DT ON (DT.PKID = RT.PKID))
    , DetermineActionTypeCTE AS (
        SELECT DT.PKID
            , CASE WHEN DACT.IsDeleteAction   = ''True'' THEN ''DELETE''
                   WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
                   WHEN DACT.IsUpdateAction   = ''True'' THEN ''UPDATE''
                   ELSE ''INSERT'' END AS AuditActionTypeId
        FROM @DataTable AS DT
        LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID))
    UPDATE DT SET DT.AuditActionTypeId = DACT.AuditActionTypeId
    FROM @DataTable AS DT
    INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID);

    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT, PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT DT.AuditActionTypeId, ''ACE'', ''MasterFiles'', CAST(DT.PKID AS VARCHAR(50)), @UserID
    FROM @DataTable AS DT;

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT AAT.AuditActionID, DT.ColumnName, DT.OldValue, DT.NewValue
    FROM @DataTable AS DT
    INNER JOIN @AuditActionTable AS AAT ON (AAT.PKID = DT.PKID)
END;';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 5/7: [ACE].[trgAutoGen_MasterFiles_CUD] created.';

    -- =========================================================================
    -- TRIGGER 6 of 7 : QAL.trgAutoGen_LeadAddresses_CUD
    -- AFTER INSERT, UPDATE on QAL.LeadAddresses
    -- =========================================================================
    IF OBJECT_ID('[QAL].[trgAutoGen_LeadAddresses_CUD]', 'TR') IS NOT NULL
        DROP TRIGGER [QAL].[trgAutoGen_LeadAddresses_CUD];

    -- Part 1 of 4 — header + RootCTE (Inserted)
    SET @sql = N'CREATE TRIGGER [QAL].[trgAutoGen_LeadAddresses_CUD] ON [QAL].[LeadAddresses]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId
    FROM [ACC].[fxGetContextUserTable]();

    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable (PKID) SELECT LeadAddressID FROM Deleted;

    DECLARE @DataTable TABLE (
        PKID BIGINT NOT NULL, AuditActionId BIGINT, AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500), OldValue NVARCHAR(500), NewValue NVARCHAR(500));

    WITH RootCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
        FROM (SELECT MFD.LeadAddressID AS PKID
            , CAST(LeadAddressID                AS NVARCHAR(500)) AS LeadAddressID
            , CAST(DealerId                     AS NVARCHAR(500)) AS DealerId
            , CAST(LanguageId                   AS NVARCHAR(500)) AS LanguageId
            , CAST(AddressValidationVendorId    AS NVARCHAR(500)) AS AddressValidationVendorId
            , CAST(AddressValidationStateId     AS NVARCHAR(500)) AS AddressValidationStateId
            , CAST(PoliticalStateId             AS NVARCHAR(500)) AS PoliticalStateId
            , CAST(PoliticalCountryId           AS NVARCHAR(500)) AS PoliticalCountryId
            , CAST(PoliticalTimeZoneId          AS NVARCHAR(500)) AS PoliticalTimeZoneId
            , CAST(AddressTypeId                AS NVARCHAR(500)) AS AddressTypeId
            , CAST(AddressStreetTypeId          AS NVARCHAR(500)) AS AddressStreetTypeId
            , CAST(SeasonId                     AS NVARCHAR(500)) AS SeasonId
            , CAST(TeamLocationId               AS NVARCHAR(500)) AS TeamLocationId
            , CAST(SalesRepId                   AS NVARCHAR(500)) AS SalesRepId
            , CAST(StreetAddress                AS NVARCHAR(500)) AS StreetAddress
            , CAST(StreetAddress2               AS NVARCHAR(500)) AS StreetAddress2
            , CAST(StreetNumber                 AS NVARCHAR(500)) AS StreetNumber
            , CAST(StreetName                   AS NVARCHAR(500)) AS StreetName
            , CAST(StreetType                   AS NVARCHAR(500)) AS StreetType
            , CAST(PreDirectional               AS NVARCHAR(500)) AS PreDirectional
            , CAST(PostDirectional              AS NVARCHAR(500)) AS PostDirectional
            , CAST(Extension                    AS NVARCHAR(500)) AS Extension
            , CAST(ExtensionNumber              AS NVARCHAR(500)) AS ExtensionNumber
            , CAST(County                       AS NVARCHAR(500)) AS County
            , CAST(CountyCode                   AS NVARCHAR(500)) AS CountyCode
            , CAST(Urbanization                 AS NVARCHAR(500)) AS Urbanization
            , CAST(UrbanizationCode             AS NVARCHAR(500)) AS UrbanizationCode
            , CAST(City                         AS NVARCHAR(500)) AS City
            , CAST(PostalCode                   AS NVARCHAR(500)) AS PostalCode
            , CAST(PlusFour                     AS NVARCHAR(500)) AS PlusFour
            , CAST(PostalCodeFull               AS NVARCHAR(500)) AS PostalCodeFull
            , CAST(Phone                        AS NVARCHAR(500)) AS Phone
            , CAST(DeliveryPoint                AS NVARCHAR(500)) AS DeliveryPoint
            , CAST(CrossStreet                  AS NVARCHAR(500)) AS CrossStreet
            , CAST(Latitude                     AS NVARCHAR(500)) AS Latitude
            , CAST(Longitude                    AS NVARCHAR(500)) AS Longitude
            , CAST(CongressionalDistric         AS NVARCHAR(500)) AS CongressionalDistric
            , CAST(DPV                          AS NVARCHAR(500)) AS DPV
            , CAST(DPVResponse                  AS NVARCHAR(500)) AS DPVResponse
            , CAST(DPVFootnote                  AS NVARCHAR(500)) AS DPVFootnote
            , CAST(CarrierRoute                 AS NVARCHAR(500)) AS CarrierRoute
            , CAST(IsActive                     AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted                    AS NVARCHAR(500)) AS IsDeleted
        FROM Inserted AS MFD WITH(NOLOCK)) AS st2
        UNPIVOT (ColumnNewValue FOR ColumnName IN (
            LeadAddressID, DealerId, LanguageId, AddressValidationVendorId, AddressValidationStateId,
            PoliticalStateId, PoliticalCountryId, PoliticalTimeZoneId, AddressTypeId, AddressStreetTypeId,
            SeasonId, TeamLocationId, SalesRepId, StreetAddress, StreetAddress2, StreetNumber, StreetName,
            StreetType, PreDirectional, PostDirectional, Extension, ExtensionNumber, County, CountyCode,
            Urbanization, UrbanizationCode, City, PostalCode, PlusFour, PostalCodeFull, Phone,
            DeliveryPoint, CrossStreet, Latitude, Longitude, CongressionalDistric,
            DPV, DPVResponse, DPVFootnote, CarrierRoute, IsActive, IsDeleted)) AS InsertValues)';

    -- Part 2 of 4 — WithChangedCTE (Deleted) + ResultCTE → INSERT @DataTable
    SET @sql = @sql + N', WithChangedCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnOldValue
        FROM (SELECT MFD.LeadAddressID AS PKID
            , CAST(LeadAddressID                AS NVARCHAR(500)) AS LeadAddressID
            , CAST(DealerId                     AS NVARCHAR(500)) AS DealerId
            , CAST(LanguageId                   AS NVARCHAR(500)) AS LanguageId
            , CAST(AddressValidationVendorId    AS NVARCHAR(500)) AS AddressValidationVendorId
            , CAST(AddressValidationStateId     AS NVARCHAR(500)) AS AddressValidationStateId
            , CAST(PoliticalStateId             AS NVARCHAR(500)) AS PoliticalStateId
            , CAST(PoliticalCountryId           AS NVARCHAR(500)) AS PoliticalCountryId
            , CAST(PoliticalTimeZoneId          AS NVARCHAR(500)) AS PoliticalTimeZoneId
            , CAST(AddressTypeId                AS NVARCHAR(500)) AS AddressTypeId
            , CAST(AddressStreetTypeId          AS NVARCHAR(500)) AS AddressStreetTypeId
            , CAST(SeasonId                     AS NVARCHAR(500)) AS SeasonId
            , CAST(TeamLocationId               AS NVARCHAR(500)) AS TeamLocationId
            , CAST(SalesRepId                   AS NVARCHAR(500)) AS SalesRepId
            , CAST(StreetAddress                AS NVARCHAR(500)) AS StreetAddress
            , CAST(StreetAddress2               AS NVARCHAR(500)) AS StreetAddress2
            , CAST(StreetNumber                 AS NVARCHAR(500)) AS StreetNumber
            , CAST(StreetName                   AS NVARCHAR(500)) AS StreetName
            , CAST(StreetType                   AS NVARCHAR(500)) AS StreetType
            , CAST(PreDirectional               AS NVARCHAR(500)) AS PreDirectional
            , CAST(PostDirectional              AS NVARCHAR(500)) AS PostDirectional
            , CAST(Extension                    AS NVARCHAR(500)) AS Extension
            , CAST(ExtensionNumber              AS NVARCHAR(500)) AS ExtensionNumber
            , CAST(County                       AS NVARCHAR(500)) AS County
            , CAST(CountyCode                   AS NVARCHAR(500)) AS CountyCode
            , CAST(Urbanization                 AS NVARCHAR(500)) AS Urbanization
            , CAST(UrbanizationCode             AS NVARCHAR(500)) AS UrbanizationCode
            , CAST(City                         AS NVARCHAR(500)) AS City
            , CAST(PostalCode                   AS NVARCHAR(500)) AS PostalCode
            , CAST(PlusFour                     AS NVARCHAR(500)) AS PlusFour
            , CAST(PostalCodeFull               AS NVARCHAR(500)) AS PostalCodeFull
            , CAST(Phone                        AS NVARCHAR(500)) AS Phone
            , CAST(DeliveryPoint                AS NVARCHAR(500)) AS DeliveryPoint
            , CAST(CrossStreet                  AS NVARCHAR(500)) AS CrossStreet
            , CAST(Latitude                     AS NVARCHAR(500)) AS Latitude
            , CAST(Longitude                    AS NVARCHAR(500)) AS Longitude
            , CAST(CongressionalDistric         AS NVARCHAR(500)) AS CongressionalDistric
            , CAST(DPV                          AS NVARCHAR(500)) AS DPV
            , CAST(DPVResponse                  AS NVARCHAR(500)) AS DPVResponse
            , CAST(DPVFootnote                  AS NVARCHAR(500)) AS DPVFootnote
            , CAST(CarrierRoute                 AS NVARCHAR(500)) AS CarrierRoute
            , CAST(IsActive                     AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted                    AS NVARCHAR(500)) AS IsDeleted
        FROM Deleted AS MFD) AS st2
        UNPIVOT (ColumnOldValue FOR ColumnName IN (
            LeadAddressID, DealerId, LanguageId, AddressValidationVendorId, AddressValidationStateId,
            PoliticalStateId, PoliticalCountryId, PoliticalTimeZoneId, AddressTypeId, AddressStreetTypeId,
            SeasonId, TeamLocationId, SalesRepId, StreetAddress, StreetAddress2, StreetNumber, StreetName,
            StreetType, PreDirectional, PostDirectional, Extension, ExtensionNumber, County, CountyCode,
            Urbanization, UrbanizationCode, City, PostalCode, PlusFour, PostalCodeFull, Phone,
            DeliveryPoint, CrossStreet, Latitude, Longitude, CongressionalDistric,
            DPV, DPVResponse, DPVFootnote, CarrierRoute, IsActive, IsDeleted)) AS InsertValues)
    , ResultCTE AS (
        SELECT RTN.PKID, RTN.ColumnName, RTN.ColumnNewValue AS NewValue, RTO.ColumnOldValue AS OldValue
        FROM RootCTE AS RTN WITH(NOLOCK)
        LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
            ON (RTO.PKID = RTN.PKID) AND (RTO.ColumnName = RTN.ColumnName)
        WHERE (RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue))
    INSERT INTO @DataTable (PKID, ColumnName, OldValue, NewValue)
    SELECT RT.PKID, RT.ColumnName, RT.OldValue, RT.NewValue FROM ResultCTE AS RT WITH(NOLOCK);';

    -- Part 3 of 4 — Determine action type
    SET @sql = @sql + N'
    WITH DistinctCTE AS (SELECT DISTINCT RT.PKID FROM @DataTable AS RT)
    , DeletedActionCTE AS (
        SELECT RT.PKID
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
            , CASE WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT) ELSE CAST(''True'' AS BIT) END AS IsUpdateAction
        FROM DistinctCTE AS RT
        LEFT OUTER JOIN @DeletedTable AS DT ON (DT.PKID = RT.PKID))
    , DetermineActionTypeCTE AS (
        SELECT DT.PKID
            , CASE WHEN DACT.IsDeleteAction   = ''True'' THEN ''DELETE''
                   WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
                   WHEN DACT.IsUpdateAction   = ''True'' THEN ''UPDATE''
                   ELSE ''INSERT'' END AS AuditActionTypeId
        FROM @DataTable AS DT
        LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID))
    UPDATE DT SET DT.AuditActionTypeId = DACT.AuditActionTypeId
    FROM @DataTable AS DT
    INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID);';

    -- Part 4 of 4 — Write audit rows
    SET @sql = @sql + N'
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT, PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT DT.AuditActionTypeId, ''QAL'', ''LeadAddresses'', CAST(DT.PKID AS VARCHAR(50)), @UserID
    FROM @DataTable AS DT;

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT AAT.AuditActionID, DT.ColumnName, DT.OldValue, DT.NewValue
    FROM @DataTable AS DT
    INNER JOIN @AuditActionTable AS AAT ON (AAT.PKID = DT.PKID)
END;';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 6/7: [QAL].[trgAutoGen_LeadAddresses_CUD] created.';

    -- =========================================================================
    -- TRIGGER 7 of 7 : QAL.trgAutoGen_Leads_CUD
    -- AFTER INSERT, UPDATE on QAL.Leads
    -- =========================================================================
    IF OBJECT_ID('[QAL].[trgAutoGen_Leads_CUD]', 'TR') IS NOT NULL
        DROP TRIGGER [QAL].[trgAutoGen_Leads_CUD];

    -- Part 1 of 4 — header + RootCTE (Inserted)
    SET @sql = N'CREATE TRIGGER [QAL].[trgAutoGen_Leads_CUD] ON [QAL].[Leads]
    AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerId = DealerId
    FROM [ACC].[fxGetContextUserTable]();

    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable (PKID) SELECT LeadID FROM Deleted;

    DECLARE @DataTable TABLE (
        PKID BIGINT NOT NULL, AuditActionId BIGINT, AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500), OldValue NVARCHAR(500), NewValue NVARCHAR(500));

    WITH RootCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
        FROM (SELECT MFD.LeadID AS PKID
            , CAST(LeadID                   AS NVARCHAR(500)) AS LeadID
            , CAST(LeadAddressId            AS NVARCHAR(500)) AS LeadAddressId
            , CAST(CustomerTypeId           AS NVARCHAR(500)) AS CustomerTypeId
            , CAST(MasterFileId             AS NVARCHAR(500)) AS MasterFileId
            , CAST(DealerId                 AS NVARCHAR(500)) AS DealerId
            , CAST(LanguageId               AS NVARCHAR(500)) AS LanguageId
            , CAST(TeamLocationId           AS NVARCHAR(500)) AS TeamLocationId
            , CAST(SeasonId                 AS NVARCHAR(500)) AS SeasonId
            , CAST(SalesRepId               AS NVARCHAR(500)) AS SalesRepId
            , CAST(LeadSourceId             AS NVARCHAR(500)) AS LeadSourceId
            , CAST(LeadDispositionId        AS NVARCHAR(500)) AS LeadDispositionId
            , CAST(LeadDispositionDateChange AS NVARCHAR(500)) AS LeadDispositionDateChange
            , CAST(Prefix                   AS NVARCHAR(500)) AS Prefix
            , CAST(FirstName                AS NVARCHAR(500)) AS FirstName
            , CAST(MiddleName               AS NVARCHAR(500)) AS MiddleName
            , CAST(LastName                 AS NVARCHAR(500)) AS LastName
            , CAST(PostFix                  AS NVARCHAR(500)) AS PostFix
            , CAST(Gender                   AS NVARCHAR(500)) AS Gender
            , CAST(SSN                      AS NVARCHAR(500)) AS SSN
            , CAST(DOB                      AS NVARCHAR(500)) AS DOB
            , CAST(DL                       AS NVARCHAR(500)) AS DL
            , CAST(DLStateID                AS NVARCHAR(500)) AS DLStateID
            , CAST(Email                    AS NVARCHAR(500)) AS Email
            , CAST(PhoneHome                AS NVARCHAR(500)) AS PhoneHome
            , CAST(PhoneWork                AS NVARCHAR(500)) AS PhoneWork
            , CAST(PhoneMobile              AS NVARCHAR(500)) AS PhoneMobile
            , CAST(IsActive                 AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted                AS NVARCHAR(500)) AS IsDeleted
        FROM Inserted AS MFD WITH(NOLOCK)) AS st2
        UNPIVOT (ColumnNewValue FOR ColumnName IN (
            LeadID, LeadAddressId, CustomerTypeId, MasterFileId, DealerId, LanguageId,
            TeamLocationId, SeasonId, SalesRepId, LeadSourceId, LeadDispositionId,
            LeadDispositionDateChange, Prefix, FirstName, MiddleName, LastName, PostFix,
            Gender, SSN, DOB, DL, DLStateID, Email, PhoneHome, PhoneWork, PhoneMobile,
            IsActive, IsDeleted)) AS InsertValues)';

    -- Part 2 of 4 — WithChangedCTE (Deleted) + ResultCTE → INSERT @DataTable
    SET @sql = @sql + N', WithChangedCTE AS (
        SELECT PKID, InsertValues.ColumnName, InsertValues.ColumnOldValue
        FROM (SELECT MFD.LeadID AS PKID
            , CAST(LeadID                   AS NVARCHAR(500)) AS LeadID
            , CAST(LeadAddressId            AS NVARCHAR(500)) AS LeadAddressId
            , CAST(CustomerTypeId           AS NVARCHAR(500)) AS CustomerTypeId
            , CAST(MasterFileId             AS NVARCHAR(500)) AS MasterFileId
            , CAST(DealerId                 AS NVARCHAR(500)) AS DealerId
            , CAST(LanguageId               AS NVARCHAR(500)) AS LanguageId
            , CAST(TeamLocationId           AS NVARCHAR(500)) AS TeamLocationId
            , CAST(SeasonId                 AS NVARCHAR(500)) AS SeasonId
            , CAST(SalesRepId               AS NVARCHAR(500)) AS SalesRepId
            , CAST(LeadSourceId             AS NVARCHAR(500)) AS LeadSourceId
            , CAST(LeadDispositionId        AS NVARCHAR(500)) AS LeadDispositionId
            , CAST(LeadDispositionDateChange AS NVARCHAR(500)) AS LeadDispositionDateChange
            , CAST(Prefix                   AS NVARCHAR(500)) AS Prefix
            , CAST(FirstName                AS NVARCHAR(500)) AS FirstName
            , CAST(MiddleName               AS NVARCHAR(500)) AS MiddleName
            , CAST(LastName                 AS NVARCHAR(500)) AS LastName
            , CAST(PostFix                  AS NVARCHAR(500)) AS PostFix
            , CAST(Gender                   AS NVARCHAR(500)) AS Gender
            , CAST(SSN                      AS NVARCHAR(500)) AS SSN
            , CAST(DOB                      AS NVARCHAR(500)) AS DOB
            , CAST(DL                       AS NVARCHAR(500)) AS DL
            , CAST(DLStateID                AS NVARCHAR(500)) AS DLStateID
            , CAST(Email                    AS NVARCHAR(500)) AS Email
            , CAST(PhoneHome                AS NVARCHAR(500)) AS PhoneHome
            , CAST(PhoneWork                AS NVARCHAR(500)) AS PhoneWork
            , CAST(PhoneMobile              AS NVARCHAR(500)) AS PhoneMobile
            , CAST(IsActive                 AS NVARCHAR(500)) AS IsActive
            , CAST(IsDeleted                AS NVARCHAR(500)) AS IsDeleted
        FROM Deleted AS MFD) AS st2
        UNPIVOT (ColumnOldValue FOR ColumnName IN (
            LeadID, LeadAddressId, CustomerTypeId, MasterFileId, DealerId, LanguageId,
            TeamLocationId, SeasonId, SalesRepId, LeadSourceId, LeadDispositionId,
            LeadDispositionDateChange, Prefix, FirstName, MiddleName, LastName, PostFix,
            Gender, SSN, DOB, DL, DLStateID, Email, PhoneHome, PhoneWork, PhoneMobile,
            IsActive, IsDeleted)) AS InsertValues)
    , ResultCTE AS (
        SELECT RTN.PKID, RTN.ColumnName, RTN.ColumnNewValue AS NewValue, RTO.ColumnOldValue AS OldValue
        FROM RootCTE AS RTN WITH(NOLOCK)
        LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
            ON (RTO.PKID = RTN.PKID) AND (RTO.ColumnName = RTN.ColumnName)
        WHERE (RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue))
    INSERT INTO @DataTable (PKID, ColumnName, OldValue, NewValue)
    SELECT RT.PKID, RT.ColumnName, RT.OldValue, RT.NewValue FROM ResultCTE AS RT WITH(NOLOCK);';

    -- Part 3 of 4 — Determine action type
    SET @sql = @sql + N'
    WITH DistinctCTE AS (SELECT DISTINCT RT.PKID FROM @DataTable AS RT)
    , DeletedActionCTE AS (
        SELECT RT.PKID
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
            , (SELECT CAST(''True'' AS BIT) FROM @DataTable
               WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
            , CASE WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT) ELSE CAST(''True'' AS BIT) END AS IsUpdateAction
        FROM DistinctCTE AS RT
        LEFT OUTER JOIN @DeletedTable AS DT ON (DT.PKID = RT.PKID))
    , DetermineActionTypeCTE AS (
        SELECT DT.PKID
            , CASE WHEN DACT.IsDeleteAction   = ''True'' THEN ''DELETE''
                   WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
                   WHEN DACT.IsUpdateAction   = ''True'' THEN ''UPDATE''
                   ELSE ''INSERT'' END AS AuditActionTypeId
        FROM @DataTable AS DT
        LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID))
    UPDATE DT SET DT.AuditActionTypeId = DACT.AuditActionTypeId
    FROM @DataTable AS DT
    INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK) ON (DACT.PKID = DT.PKID);';

    -- Part 4 of 4 — Write audit rows
    SET @sql = @sql + N'
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT, PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT DT.AuditActionTypeId, ''QAL'', ''Leads'', CAST(DT.PKID AS VARCHAR(50)), @UserID
    FROM @DataTable AS DT;

    INSERT INTO [AUD].[AuditActionColumns] ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT AAT.AuditActionID, DT.ColumnName, DT.OldValue, DT.NewValue
    FROM @DataTable AS DT
    INNER JOIN @AuditActionTable AS AAT ON (AAT.PKID = DT.PKID)
END;';

    EXEC sp_executesql @sql;
    PRINT 'Trigger 7/7: [QAL].[trgAutoGen_Leads_CUD] created.';

    -- =========================================================================
    -- Post-deploy validation — confirm all 7 triggers were created
    -- =========================================================================
    IF OBJECT_ID('[ACC].[UserInsert]',                          'TR') IS NULL RAISERROR('Trigger ACC.UserInsert was not created.',                          16, 1);
    IF OBJECT_ID('[RSU].[UserResourcesUpdate]',                 'TR') IS NULL RAISERROR('Trigger RSU.UserResourcesUpdate was not created.',                 16, 1);
    IF OBJECT_ID('[ACE].[trgAutoGen_Customers_CUD]',            'TR') IS NULL RAISERROR('Trigger ACE.trgAutoGen_Customers_CUD was not created.',            16, 1);
    IF OBJECT_ID('[ACE].[trgAutoGen_MasterFileAccounts_CUD]',   'TR') IS NULL RAISERROR('Trigger ACE.trgAutoGen_MasterFileAccounts_CUD was not created.',   16, 1);
    IF OBJECT_ID('[ACE].[trgAutoGen_MasterFiles_CUD]',          'TR') IS NULL RAISERROR('Trigger ACE.trgAutoGen_MasterFiles_CUD was not created.',          16, 1);
    IF OBJECT_ID('[QAL].[trgAutoGen_LeadAddresses_CUD]',        'TR') IS NULL RAISERROR('Trigger QAL.trgAutoGen_LeadAddresses_CUD was not created.',        16, 1);
    IF OBJECT_ID('[QAL].[trgAutoGen_Leads_CUD]',                'TR') IS NULL RAISERROR('Trigger QAL.trgAutoGen_Leads_CUD was not created.',                16, 1);

    PRINT 'Post-deploy validation passed: all 7 triggers confirmed.';

    -- =========================================================================
    -- Record migration in SchemaVersion
    -- =========================================================================
    DECLARE @ExecutionTimeMs INT = DATEDIFF(MILLISECOND, @StartTime, GETUTCDATE());

    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description], [ExecutionTimeMs], [Success])
VALUES
    (@MigrationName,
        '7 triggers deployed: ACC.UserInsert, RSU.UserResourcesUpdate, ACE.trgAutoGen_Customers_CUD, ACE.trgAutoGen_MasterFileAccounts_CUD, ACE.trgAutoGen_MasterFiles_CUD, QAL.trgAutoGen_LeadAddresses_CUD, QAL.trgAutoGen_Leads_CUD',
        @ExecutionTimeMs, 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully in ' + CAST(@ExecutionTimeMs AS NVARCHAR(10)) + 'ms';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
    DECLARE @ErrorState    INT            = ERROR_STATE();

    PRINT 'ERROR in migration 20260313_0847_Baseline_Triggers: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH
GO

/*
ROLLBACK SCRIPT:
BEGIN TRANSACTION;
    IF OBJECT_ID('[ACC].[UserInsert]',                        'TR') IS NOT NULL DROP TRIGGER [ACC].[UserInsert];
    IF OBJECT_ID('[RSU].[UserResourcesUpdate]',               'TR') IS NOT NULL DROP TRIGGER [RSU].[UserResourcesUpdate];
    IF OBJECT_ID('[ACE].[trgAutoGen_Customers_CUD]',          'TR') IS NOT NULL DROP TRIGGER [ACE].[trgAutoGen_Customers_CUD];
    IF OBJECT_ID('[ACE].[trgAutoGen_MasterFileAccounts_CUD]', 'TR') IS NOT NULL DROP TRIGGER [ACE].[trgAutoGen_MasterFileAccounts_CUD];
    IF OBJECT_ID('[ACE].[trgAutoGen_MasterFiles_CUD]',        'TR') IS NOT NULL DROP TRIGGER [ACE].[trgAutoGen_MasterFiles_CUD];
    IF OBJECT_ID('[QAL].[trgAutoGen_LeadAddresses_CUD]',      'TR') IS NOT NULL DROP TRIGGER [QAL].[trgAutoGen_LeadAddresses_CUD];
    IF OBJECT_ID('[QAL].[trgAutoGen_Leads_CUD]',              'TR') IS NOT NULL DROP TRIGGER [QAL].[trgAutoGen_Leads_CUD];
    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260313_0847_Baseline_Triggers';
COMMIT TRANSACTION;
*/
