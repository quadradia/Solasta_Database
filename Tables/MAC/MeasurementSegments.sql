/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: MeasurementSegments
 * Description: The stretch between two neighbouring pins of a measurement, with sloped and flat
 *              feet, its run (Rail) or a jumper between runs (Gap), and the house location it is
 *              priced in. Office staff can fix the proposed segments (IsEdited).
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: MAC.Measurements, MAC.MeasurementPoints
 * Migrations: 20261117_0400_CreateMAC_Measurements
 * API mappings: Models/MAC/MeasurementSegment.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
GO
