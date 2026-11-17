/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Measurements
 * Description: One roofline measurement of a lead (QAL.Leads), usually from a Google Earth KML
 *              file kept in DOC.Documents. LengthBasis and AllowancePct drive the per-location feet
 *              that a quote prices.
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: ACC.DealerTenants, QAL.Leads, DOC.Documents
 * Migrations: 20261117_0400_CreateMAC_Measurements
 * API mappings: Models/MAC/Measurement.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

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
        [OriginLatitude] [float] NULL,
        [OriginLongitude] [float] NULL,
        -- Things the parser or run detection could not settle, one per line.
        [Warnings] [nvarchar](4000) NULL,
        [Notes] [nvarchar](2000) NULL,
        -- Locations measured but not priced (the measuring tool's Include? = No), one per line; NULL = all priced.
        [ExcludedLocations] [nvarchar](400) NULL,
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
GO
