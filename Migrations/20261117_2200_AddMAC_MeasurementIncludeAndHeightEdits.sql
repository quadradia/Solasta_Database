/*
Migration: 20261117_2200_AddMAC_MeasurementIncludeAndHeightEdits
Author: Andres Sosa
Date: 2026-11-17
Description: Two fields the KML measuring tool already has:
               MAC.Measurements.ExcludedLocations   locations whose feet are measured but not priced
                                                    (the tool's "Include?" = No), one per line; NULL = all priced
               MAC.MeasurementPoints.IsEdited       set when staff changed the pin's height by hand
                                                    (AltitudeMeters), which changes the sloped feet of its segments
Dependencies:
  20261117_0400_CreateMAC_Measurements
Rollback:
  ALTER TABLE [MAC].[MeasurementPoints] DROP CONSTRAINT [DF_MeasurementPoints_IsEdited];
  ALTER TABLE [MAC].[MeasurementPoints] DROP COLUMN [IsEdited];
  ALTER TABLE [MAC].[Measurements] DROP COLUMN [ExcludedLocations];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_2200_AddMAC_MeasurementIncludeAndHeightEdits';
Expected impact: Two new columns (one nullable, one with a default); existing rows keep every location priced
  and no pin marked edited.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_2200_AddMAC_MeasurementIncludeAndHeightEdits';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Measurements', N'U') IS NULL OR OBJECT_ID(N'MAC.MeasurementPoints', N'U') IS NULL
        THROW 50001, 'Run 20261117_0400_CreateMAC_Measurements first.', 1;

    IF COL_LENGTH(N'MAC.Measurements', N'ExcludedLocations') IS NULL
        ALTER TABLE [MAC].[Measurements] ADD [ExcludedLocations] [nvarchar](400) NULL;

    IF COL_LENGTH(N'MAC.MeasurementPoints', N'IsEdited') IS NULL
        ALTER TABLE [MAC].[MeasurementPoints]
            ADD [IsEdited] [bit] NOT NULL CONSTRAINT [DF_MeasurementPoints_IsEdited] DEFAULT ((0));

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Add MAC.Measurements.ExcludedLocations and MAC.MeasurementPoints.IsEdited',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
