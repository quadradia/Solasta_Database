/*
Migration: 20260505_1700_ReorderColumns_DealerTenants
Author: Andres Sosa
Date: 2026-05-05
Description: Recreates ACC.DealerTenants with the correct physical column order
             per constitutional standards:
               1. PK column
               2. FK columns (immediately after PK)
               3. Business/payload columns
               4. Audit columns (IsActive, IsDeleted, Modified*, Created*, DEX_ROW_TS)
             PoliticalTimeZoneId was added via ALTER TABLE and ended up at position 14.
             This migration fixes that by recreating the table with proper order.
Dependencies:
  20260505_1600_RenamePoliticalTimeZoneId_DealerTenants
*/

BEGIN TRANSACTION;
BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260505_1700_ReorderColumns_DealerTenants';

    -- Check if already applied
    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- -------------------------------------------------------------------------
    -- 1. Create replacement table with correct column order
    -- -------------------------------------------------------------------------
    IF OBJECT_ID('ACC.DealerTenants_Reordered', 'U') IS NOT NULL
        DROP TABLE [ACC].[DealerTenants_Reordered];

    CREATE TABLE [ACC].[DealerTenants_Reordered]
(
    -- PK
    [DealerTenantID] [int] IDENTITY(1,1) NOT NULL,
    -- FK columns (immediately after PK per constitutional standard)
    [DealerTenantTypeId] [int] NOT NULL,
    [PoliticalTimeZoneId] [int] NOT NULL,
    -- Business columns
    [Proxy] [varchar](100) NOT NULL,
    [PartKey] [varchar](6) NOT NULL,
    [DealerTenantName] [nvarchar](100) NOT NULL,
    [DealerTenantDescription] [nvarchar](max) NULL,
    -- Audit columns (always last per constitutional standard)
    [IsActive] [bit] NOT NULL,
    [IsDeleted] [bit] NOT NULL,
    [ModifiedDate] [datetimeoffset](7) NOT NULL,
    [ModifiedById] [int] NOT NULL,
    [CreatedDate] [datetimeoffset](7) NOT NULL,
    [CreatedById] [int] NOT NULL,
    [DEX_ROW_TS] [datetimeoffset](7) NOT NULL
);

    PRINT 'DealerTenants_Reordered created.';

    -- -------------------------------------------------------------------------
    -- 2. Copy all data (IDENTITY_INSERT to preserve IDs)
    -- -------------------------------------------------------------------------
    SET IDENTITY_INSERT [ACC].[DealerTenants_Reordered] ON;

    INSERT INTO [ACC].[DealerTenants_Reordered]
    ([DealerTenantID], [DealerTenantTypeId], [PoliticalTimeZoneId],
    [Proxy], [PartKey], [DealerTenantName], [DealerTenantDescription],
    [IsActive], [IsDeleted],
    [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS])
SELECT
    [DealerTenantID], [DealerTenantTypeId], [PoliticalTimeZoneId],
    [Proxy], [PartKey], [DealerTenantName], [DealerTenantDescription],
    [IsActive], [IsDeleted],
    [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById], [DEX_ROW_TS]
FROM [ACC].[DealerTenants];

    SET IDENTITY_INSERT [ACC].[DealerTenants_Reordered] OFF;

    PRINT 'Data copied to DealerTenants_Reordered.';

    -- -------------------------------------------------------------------------
    -- 3. Drop all constraints on the original table
    -- -------------------------------------------------------------------------
    -- Default constraints
    IF OBJECT_ID('DF_DealerTenants_PoliticalTimeZoneId', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_DealerTenants_PoliticalTimeZoneId];
    IF OBJECT_ID('DF_Tenants_IsActive', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_IsActive];
    IF OBJECT_ID('DF_Tenants_IsDeleted', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_IsDeleted];
    IF OBJECT_ID('DF_Tenants_ModifiedDate', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_ModifiedDate];
    IF OBJECT_ID('DF_Tenants_ModifiedById', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_ModifiedById];
    IF OBJECT_ID('DF_Tenants_CreatedDate', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_CreatedDate];
    IF OBJECT_ID('DF_Tenants_CreatedById', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_CreatedById];
    IF OBJECT_ID('DF_Tenants_DEX_ROW_TS', 'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [DF_Tenants_DEX_ROW_TS];

    -- Foreign keys
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_PoliticalTimeZones')
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [FK_DealerTenants_PoliticalTimeZones];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_DealerTenants_DealerTenantTypes')
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [FK_DealerTenants_DealerTenantTypes];

    -- Primary key
    IF EXISTS (SELECT 1
FROM sys.key_constraints
WHERE name = 'PK_Tenants')
        ALTER TABLE [ACC].[DealerTenants] DROP CONSTRAINT [PK_Tenants];

    PRINT 'All constraints dropped from original DealerTenants.';

    -- -------------------------------------------------------------------------
    -- 4. Drop original table and rename replacement
    -- -------------------------------------------------------------------------
    DROP TABLE [ACC].[DealerTenants];
    EXEC sp_rename 'ACC.DealerTenants_Reordered', 'DealerTenants', 'OBJECT';

    PRINT 'Original dropped; DealerTenants_Reordered renamed to DealerTenants.';

    -- -------------------------------------------------------------------------
    -- 5. Re-add all constraints to the renamed table
    -- -------------------------------------------------------------------------
    -- Primary key
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [PK_Tenants] PRIMARY KEY CLUSTERED ([DealerTenantID] ASC)
        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
              ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

    -- Foreign keys
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [FK_DealerTenants_DealerTenantTypes]
        FOREIGN KEY ([DealerTenantTypeId])
        REFERENCES [ACC].[DealerTenantTypes] ([DealerTenantTypeID]);

    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [FK_DealerTenants_PoliticalTimeZones]
        FOREIGN KEY ([PoliticalTimeZoneId])
        REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID]);

    -- Default constraints
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_DealerTenants_PoliticalTimeZoneId] DEFAULT ((4)) FOR [PoliticalTimeZoneId];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_IsActive]     DEFAULT ((1))                FOR [IsActive];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_IsDeleted]    DEFAULT ((0))                FOR [IsDeleted];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_ModifiedDate] DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_ModifiedById] DEFAULT ((0))                FOR [ModifiedById];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_CreatedById]  DEFAULT ((0))                FOR [CreatedById];
    ALTER TABLE [ACC].[DealerTenants]
        ADD CONSTRAINT [DF_Tenants_DEX_ROW_TS]   DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS];

    PRINT 'All constraints re-applied to DealerTenants.';

    -- -------------------------------------------------------------------------
    -- Record migration
    -- -------------------------------------------------------------------------
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName,
        'Recreates ACC.DealerTenants with constitutional column order: PK, FKs, business, audit');

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully: ' + @MigrationName;

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    -- Clean up temp table if it was created before the error
    IF OBJECT_ID('ACC.DealerTenants_Reordered', 'U') IS NOT NULL
        DROP TABLE [ACC].[DealerTenants_Reordered];
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
    -- This migration recreates the table; rollback requires re-running the prior
    -- state manually or restoring from backup.
    -- To revert column order only (no data loss), re-run steps 1-5 above but
    -- with the old column order (PoliticalTimeZoneId at the end).
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260505_1700_ReorderColumns_DealerTenants';
*/
