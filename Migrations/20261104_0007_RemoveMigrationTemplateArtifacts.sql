/*
Migration: 20261104_0007_RemoveMigrationTemplateArtifacts
Author: Andres Sosa
Date: 2026-11-04
Description: Removes what _TEMPLATE_Migration.sql left behind when the migration runner
             executed it on 2026-05-04 (before the runner skipped files starting with "_"):
               - the example table dbo.YourTableName
               - the SchemaVersion row 'YYYYMMDD_HHMM_DescriptionOfChange'
             Refuses to drop the table if it holds data or no longer looks like the template.
Dependencies: none
Expected impact: drops one empty table and deletes one SchemaVersion row.
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261104_0007_RemoveMigrationTemplateArtifacts';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'dbo.YourTableName', N'U') IS NOT NULL
    BEGIN
        -- Only the template's four columns: Id, Name, CreatedDate, ModifiedDate.
        IF (SELECT COUNT(*) FROM sys.columns WHERE [object_id] = OBJECT_ID(N'dbo.YourTableName')) <> 4
           OR EXISTS (SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(N'dbo.YourTableName')
                      AND [name] NOT IN (N'Id', N'Name', N'CreatedDate', N'ModifiedDate'))
            THROW 50001, 'dbo.YourTableName does not match the migration template; inspect it before dropping.', 1;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE [referenced_object_id] = OBJECT_ID(N'dbo.YourTableName'))
            THROW 50001, 'dbo.YourTableName is referenced by a foreign key; inspect it before dropping.', 1;

        DECLARE @Rows INT;
        EXEC sys.sp_executesql N'SELECT @Rows = COUNT(*) FROM [dbo].[YourTableName];', N'@Rows INT OUTPUT', @Rows OUTPUT;
        IF @Rows > 0
            THROW 50001, 'dbo.YourTableName contains data; archive it before dropping.', 1;

        DROP TABLE [dbo].[YourTableName];
        PRINT 'Dropped dbo.YourTableName';
    END;

    DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'YYYYMMDD_HHMM_DescriptionOfChange';
    PRINT CONCAT('Deleted ', @@ROWCOUNT, ' template SchemaVersion row(s)');

    INSERT INTO [dbo].[SchemaVersion]
        ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Removes dbo.YourTableName and the template SchemaVersion row left by running _TEMPLATE_Migration.sql.',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration 20261104_0007_RemoveMigrationTemplateArtifacts applied successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/*
ROLLBACK SCRIPT:
-- Nothing worth restoring: the table was empty and the row described no real migration.
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261104_0007_RemoveMigrationTemplateArtifacts';
*/
