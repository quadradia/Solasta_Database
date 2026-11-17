/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: MeasurementPoints
 * Description: Every roofline pin (KML placemark) of a measurement: name, folder, description
 *              tag (LEC, REC, Gable, OutCorner, InCorner), level and WGS84 position.
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: MAC.Measurements
 * Migrations: 20261117_0400_CreateMAC_Measurements
 * API mappings: Models/MAC/MeasurementPoint.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO
