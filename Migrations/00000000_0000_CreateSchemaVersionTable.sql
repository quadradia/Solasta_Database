/*
Migration: 00000000_0000_CreateSchemaVersionTable
Author: Database Team
Date: 2026-01-07
Description: Creates the SchemaVersion table for tracking applied migrations
Dependencies: None (Base migration)
*/

-- This is the foundational migration that creates the schema version tracking table
-- All subsequent migrations will be recorded in this table

-- Create SchemaVersion table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SchemaVersion' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[SchemaVersion] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [MigrationName] NVARCHAR(255) NOT NULL UNIQUE,
        [AppliedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [AppliedBy] NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
        [Description] NVARCHAR(500) NULL,
        [ScriptChecksum] NVARCHAR(64) NULL,
        [ExecutionTimeMs] INT NULL,
        [Success] BIT NOT NULL DEFAULT 1
    );

    -- Create index for faster lookups
    CREATE INDEX IX_SchemaVersion_MigrationName ON [dbo].[SchemaVersion]([MigrationName]);
    CREATE INDEX IX_SchemaVersion_AppliedDate ON [dbo].[SchemaVersion]([AppliedDate]);

    PRINT 'SchemaVersion table created successfully';
END
ELSE
BEGIN
    PRINT 'SchemaVersion table already exists';
END
GO

-- Insert record for this migration
IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '00000000_0000_CreateSchemaVersionTable')
BEGIN
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success])
    VALUES ('00000000_0000_CreateSchemaVersionTable', 'Creates the SchemaVersion tracking table', 1);
    
    PRINT 'Migration 00000000_0000_CreateSchemaVersionTable recorded';
END
GO

/*
ROLLBACK SCRIPT:
-- Use with caution! This will remove all migration tracking
-- DROP TABLE IF EXISTS [dbo].[SchemaVersion];
*/
