/*
Migration: 20260505_1300_CreatePoliticalStatesAndTimeZoneMaps
Author: Andres Sosa
Date: 2026-05-05
Description: Creates the MAC.PoliticalStatesAndTimeZoneMaps table, which maps
             political states to their applicable time zones with an order
             priority to support multiple zone assignments per state.
             Includes all default constraints and foreign keys to
             MAC.PoliticalStates and MAC.PoliticalTimeZones.
Dependencies:
  MAC.PoliticalStates        (must exist — FK target)
  MAC.PoliticalTimeZones     (must exist — FK target)
*/

BEGIN TRANSACTION;
BEGIN TRY

    DECLARE @MigrationName NVARCHAR(255) = '20260505_1300_CreatePoliticalStatesAndTimeZoneMaps';

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
    -- Create table
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'PoliticalStatesAndTimeZoneMaps' AND schema_id = SCHEMA_ID('MAC'))
    BEGIN
    CREATE TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
    (
        [PoliticalStatesAndTimeZoneMapID] [int] IDENTITY(1,1) NOT NULL,
        [PoliticalStateId] [varchar](4) NOT NULL,
        [PoliticalTimeZoneId] [int] NOT NULL,
        [OrderPriority] [smallint] NOT NULL,
        [IsActive] [bit] NOT NULL,
        [IsDeleted] [bit] NOT NULL,
        [ModifiedDate] [datetimeoffset](7) NOT NULL,
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL,
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL,

        CONSTRAINT [PK_PoliticalStatesAndTimeZoneMaps] PRIMARY KEY CLUSTERED
        (
            [PoliticalStatesAndTimeZoneMapID] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY];
END

    -- -------------------------------------------------------------------------
    -- Default constraints
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_Order' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_Order] DEFAULT ((1)) FOR [OrderPriority];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_IsActive' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_IsActive] DEFAULT ((1)) FOR [IsActive];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_IsDeleted' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_IsDeleted] DEFAULT ((0)) FOR [IsDeleted];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_ModifiedDate' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_ModifiedDate] DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_ModifiedById' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_CreatedDate' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_CreatedDate] DEFAULT (sysdatetimeoffset()) FOR [CreatedDate];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_CreatedById' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById];

    IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_PoliticalStatesAndTimeZoneMaps_DEX_ROW_TS' AND type = 'D')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]
            ADD CONSTRAINT [DF_PoliticalStatesAndTimeZoneMaps_DEX_ROW_TS] DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS];

    -- -------------------------------------------------------------------------
    -- Foreign key constraints
    -- -------------------------------------------------------------------------
    IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PoliticalStatesAndTimeZoneMaps_PoliticalStates')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]  WITH CHECK
            ADD CONSTRAINT [FK_PoliticalStatesAndTimeZoneMaps_PoliticalStates] FOREIGN KEY([PoliticalStateId])
            REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID]);

    IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_PoliticalStatesAndTimeZoneMaps_PoliticalTimeZones')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps]  WITH CHECK
            ADD CONSTRAINT [FK_PoliticalStatesAndTimeZoneMaps_PoliticalTimeZones] FOREIGN KEY([PoliticalTimeZoneId])
            REFERENCES [MAC].[PoliticalTimeZones] ([PoliticalTimeZoneID]);

    -- -------------------------------------------------------------------------
    -- Record migration
    -- -------------------------------------------------------------------------
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Creates MAC.PoliticalStatesAndTimeZoneMaps — maps political states to time zones with order priority');

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully: ' + @MigrationName;

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
    -- Remove foreign keys
    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PoliticalStatesAndTimeZoneMaps_PoliticalTimeZones')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps] DROP CONSTRAINT [FK_PoliticalStatesAndTimeZoneMaps_PoliticalTimeZones];

    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PoliticalStatesAndTimeZoneMaps_PoliticalStates')
        ALTER TABLE [MAC].[PoliticalStatesAndTimeZoneMaps] DROP CONSTRAINT [FK_PoliticalStatesAndTimeZoneMaps_PoliticalStates];

    -- Drop table
    DROP TABLE IF EXISTS [MAC].[PoliticalStatesAndTimeZoneMaps];

    -- Remove from SchemaVersion
    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = '20260505_1300_CreatePoliticalStatesAndTimeZoneMaps';
*/
