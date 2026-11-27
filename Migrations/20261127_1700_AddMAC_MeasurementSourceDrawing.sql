/*
Migration: 20261127_1700_AddMAC_MeasurementSourceDrawing
Author: Andres Sosa
Date: 2026-11-27
Description: Lets MAC.Measurements.Source be 'Drawing': a measurement the API traced from the roof plan of an
             architectural drawing set (PDF) uploaded at POST api/leads/{leadId}/measurements/drawing.
Dependencies:
  20261117_0400_CreateMAC_Measurements
Rollback:
  (only once no row has Source 'Drawing')
  ALTER TABLE [MAC].[Measurements] DROP CONSTRAINT [CK_Measurements_Source];
  ALTER TABLE [MAC].[Measurements] WITH CHECK ADD CONSTRAINT [CK_Measurements_Source] CHECK ([Source] IN ('KML', 'Manual'));
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261127_1700_AddMAC_MeasurementSourceDrawing';
Expected impact: The CHECK constraint is replaced; no data changes. No generated code changes (MAC.Measurements is
  mapped by hand in the API).
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261127_1700_AddMAC_MeasurementSourceDrawing';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Measurements', N'U') IS NULL
        THROW 50001, 'Run 20261117_0400_CreateMAC_Measurements first.', 1;

    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Measurements_Source'
                                                     AND [parent_object_id] = OBJECT_ID(N'MAC.Measurements'))
        ALTER TABLE [MAC].[Measurements] DROP CONSTRAINT [CK_Measurements_Source];

    ALTER TABLE [MAC].[Measurements] WITH CHECK
        ADD CONSTRAINT [CK_Measurements_Source] CHECK ([Source] IN ('KML', 'Manual', 'Drawing'));

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Allow MAC.Measurements.Source Drawing (roof plans traced from PDF drawing sets)',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
