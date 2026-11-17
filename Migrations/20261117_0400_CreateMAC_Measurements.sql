/*
Migration: 20261117_0400_CreateMAC_Measurements
Author: Andres Sosa
Date: 2026-11-17
Description: Creates the roofline measurement tables for the lead-to-quote process (phase 3):
               MAC.Measurements         one roofline measurement of a lead (QAL.Leads), usually from a
                                        Google Earth KML file kept in DOC.Documents
               MAC.MeasurementPoints    every roofline pin (KML placemark) of a measurement
               MAC.MeasurementSegments  the stretch between two neighbouring pins, with its sloped and flat
                                        feet, the run it belongs to and the house location it is priced in
             The Solasta API parses the KML, computes the lengths with the workbook's WGS84
             meters-per-degree formulas, proposes runs from each LEC to its REC, and lets office staff
             fix them before the per-location feet (plus the allowance) feed a quote.
Dependencies:
  QAL.Leads, ACC.DealerTenants, DOC.Documents
Rollback:
  DROP TABLE [MAC].[MeasurementSegments];
  DROP TABLE [MAC].[MeasurementPoints];
  DROP TABLE [MAC].[Measurements];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_0400_CreateMAC_Measurements';
  (The KML files stay in DOC.Documents; deactivate them separately if wanted.)
Expected impact: New tables only; no existing object changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_0400_CreateMAC_Measurements';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
       OR OBJECT_ID(N'DOC.Documents', N'U') IS NULL
        THROW 50001, 'MAC.Measurements requires QAL.Leads, ACC.DealerTenants and DOC.Documents.', 1;

    IF OBJECT_ID(N'MAC.Measurements', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[Measurements]
        (
            [MeasurementID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [LeadId] [bigint] NOT NULL,
            [Proxy] [varchar](100) NOT NULL,
            [PartKey] [varchar](20) NOT NULL,
            [Title] [nvarchar](255) NOT NULL,
            -- KML (Google Earth file) or Manual (feet typed in).
            [Source] [varchar](10) NOT NULL CONSTRAINT [DF_Measurements_Source] DEFAULT ('KML'),
            -- Draft until office staff confirm the runs and locations.
            [Status] [varchar](10) NOT NULL CONSTRAINT [DF_Measurements_Status] DEFAULT ('Draft'),
            -- Sloped for pitched roofs and gables; Flat only for a flat-roof job.
            [LengthBasis] [varchar](10) NOT NULL CONSTRAINT [DF_Measurements_LengthBasis] DEFAULT ('Sloped'),
            -- Added to each location's feet before rounding (the workbook's 10%).
            [AllowancePct] [decimal](5,2) NOT NULL CONSTRAINT [DF_Measurements_AllowancePct] DEFAULT ((10.00)),
            -- The uploaded KML file.
            [DocumentId] [bigint] NULL,
            -- Where the east/north feet of the points are measured from (the average pin position).
            -- Coordinates are float (double) so the KML values round-trip exactly.
            [OriginLatitude] [float] NULL,
            [OriginLongitude] [float] NULL,
            -- Things the parser or run detection could not settle, one per line.
            [Warnings] [nvarchar](4000) NULL,
            [Notes] [nvarchar](2000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Measurements_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Measurements_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Measurements_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Measurements_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Measurements_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Measurements_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Measurements_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Measurements] PRIMARY KEY CLUSTERED ([MeasurementID] ASC),
            CONSTRAINT [FK_Measurements_DealerTenants] FOREIGN KEY ([DealerTenantId])
                REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Measurements_Leads] FOREIGN KEY ([LeadId])
                REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Measurements_Documents] FOREIGN KEY ([DocumentId])
                REFERENCES [DOC].[Documents] ([DocumentID]),
            CONSTRAINT [UQ_Measurements_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_Measurements_Source] CHECK ([Source] IN ('KML', 'Manual')),
            CONSTRAINT [CK_Measurements_Status] CHECK ([Status] IN ('Draft', 'Reviewed')),
            CONSTRAINT [CK_Measurements_LengthBasis] CHECK ([LengthBasis] IN ('Sloped', 'Flat')),
            CONSTRAINT [CK_Measurements_AllowancePct] CHECK ([AllowancePct] >= 0 AND [AllowancePct] <= 100)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.Measurements') AND [name] = N'IX_Measurements_DealerTenantId_LeadId')
        CREATE NONCLUSTERED INDEX [IX_Measurements_DealerTenantId_LeadId]
            ON [MAC].[Measurements] ([DealerTenantId], [LeadId])
            WHERE [IsActive] = 1;

    IF OBJECT_ID(N'MAC.MeasurementPoints', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[MeasurementPoints]
        (
            [MeasurementPointID] [bigint] IDENTITY(1,1) NOT NULL,
            [MeasurementId] [bigint] NOT NULL,
            -- Placemark name as drawn, e.g. "Back 016 + Right 005".
            [Name] [nvarchar](255) NOT NULL,
            -- Folder path in the KML, e.g. "Front - lvl 2/Gable 1".
            [FolderPath] [nvarchar](500) NULL,
            -- Description text with the HTML removed, e.g. "Out Corner".
            [Description] [nvarchar](1000) NULL,
            -- LEC, REC, Gable, OutCorner, InCorner or Corner; NULL for an untagged pin.
            [PointType] [varchar](10) NULL,
            -- Side and number names of this pin, one per folder it is in, e.g. "Back 16|Right 5".
            [SideKeys] [nvarchar](255) NOT NULL,
            -- Roof level: 1 = first floor, 2 = second floor, ...
            [Level] [tinyint] NOT NULL CONSTRAINT [DF_MeasurementPoints_Level] DEFAULT ((1)),
            [Latitude] [float] NOT NULL,
            [Longitude] [float] NOT NULL,
            [AltitudeMeters] [float] NOT NULL,
            -- Order in the KML file.
            [SortOrder] [int] NOT NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MeasurementPoints_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MeasurementPoints_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MeasurementPoints_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MeasurementPoints_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MeasurementPoints_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MeasurementPoints_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MeasurementPoints_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MeasurementPoints] PRIMARY KEY CLUSTERED ([MeasurementPointID] ASC),
            CONSTRAINT [FK_MeasurementPoints_Measurements] FOREIGN KEY ([MeasurementId])
                REFERENCES [MAC].[Measurements] ([MeasurementID]),
            CONSTRAINT [CK_MeasurementPoints_PointType]
                CHECK ([PointType] IS NULL OR [PointType] IN ('LEC', 'REC', 'Gable', 'OutCorner', 'InCorner', 'Corner')),
            CONSTRAINT [CK_MeasurementPoints_Level] CHECK ([Level] >= 1)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.MeasurementPoints') AND [name] = N'IX_MeasurementPoints_MeasurementId')
        CREATE NONCLUSTERED INDEX [IX_MeasurementPoints_MeasurementId]
            ON [MAC].[MeasurementPoints] ([MeasurementId], [SortOrder]);

    IF OBJECT_ID(N'MAC.MeasurementSegments', N'U') IS NULL
    BEGIN
        CREATE TABLE [MAC].[MeasurementSegments]
        (
            [MeasurementSegmentID] [bigint] IDENTITY(1,1) NOT NULL,
            [MeasurementId] [bigint] NOT NULL,
            [FromPointId] [bigint] NOT NULL,
            [ToPointId] [bigint] NOT NULL,
            -- Rail is priced; Gap is the stretch between a REC and the next LEC (a jumper, no rail).
            [SegmentType] [varchar](10) NOT NULL CONSTRAINT [DF_MeasurementSegments_SegmentType] DEFAULT ('Rail'),
            -- Run 1, 2, ... for rail; NULL for a gap.
            [RunNumber] [int] NULL,
            -- Order of the segment in the measurement (runs in order, then gaps).
            [SortOrder] [int] NOT NULL,
            -- House location the feet are priced in: Front, Side-Left, Side-Right, Back, Back - Low, ...
            [Location] [nvarchar](30) NOT NULL,
            [Level] [tinyint] NOT NULL CONSTRAINT [DF_MeasurementSegments_Level] DEFAULT ((1)),
            [SlopedFeet] [decimal](9,2) NOT NULL,
            [FlatFeet] [decimal](9,2) NOT NULL,
            -- 1 when office staff changed the proposed segment.
            [IsEdited] [bit] NOT NULL CONSTRAINT [DF_MeasurementSegments_IsEdited] DEFAULT ((0)),
            [Note] [nvarchar](500) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_MeasurementSegments_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MeasurementSegments_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MeasurementSegments_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MeasurementSegments_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MeasurementSegments_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MeasurementSegments_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MeasurementSegments_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_MeasurementSegments] PRIMARY KEY CLUSTERED ([MeasurementSegmentID] ASC),
            CONSTRAINT [FK_MeasurementSegments_Measurements] FOREIGN KEY ([MeasurementId])
                REFERENCES [MAC].[Measurements] ([MeasurementID]),
            CONSTRAINT [FK_MeasurementSegments_MeasurementPoints_From] FOREIGN KEY ([FromPointId])
                REFERENCES [MAC].[MeasurementPoints] ([MeasurementPointID]),
            CONSTRAINT [FK_MeasurementSegments_MeasurementPoints_To] FOREIGN KEY ([ToPointId])
                REFERENCES [MAC].[MeasurementPoints] ([MeasurementPointID]),
            CONSTRAINT [CK_MeasurementSegments_SegmentType] CHECK ([SegmentType] IN ('Rail', 'Gap')),
            CONSTRAINT [CK_MeasurementSegments_Points] CHECK ([FromPointId] <> [ToPointId]),
            CONSTRAINT [CK_MeasurementSegments_Feet] CHECK ([SlopedFeet] >= 0 AND [FlatFeet] >= 0),
            CONSTRAINT [CK_MeasurementSegments_Level] CHECK ([Level] >= 1)
        );
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.MeasurementSegments') AND [name] = N'IX_MeasurementSegments_MeasurementId')
        CREATE NONCLUSTERED INDEX [IX_MeasurementSegments_MeasurementId]
            ON [MAC].[MeasurementSegments] ([MeasurementId], [SortOrder]);

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Create MAC.Measurements, MeasurementPoints and MeasurementSegments for KML roofline measurement',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
