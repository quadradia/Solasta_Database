/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: Locations
 * Description: Every place stock can be: a warehouse, an installer's vehicle, a staging
 *              area, a customer's job site or a vendor. Unlike the legacy INE
 *              (LocationTypeId + free-text identifier), each location is a real row so
 *              movements and balances can use foreign keys. A Vehicle names the user who
 *              drives it; a Job names the lead (QAL.Leads) it is for; a Vendor location
 *              names the vendor stock is returned to.
 * Dependencies: ACC.DealerTenants, ACC.Users, QAL.Leads, INE.LocationTypes, INE.Vendors,
 *               MAC.PoliticalStates
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.Locations', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[Locations]
    (
        [LocationID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [LocationTypeId] [int] NOT NULL,
        -- Vehicle: the installer who holds the stock.
        [UserId] [uniqueidentifier] NULL,
        -- Job: the lead the stock was issued to.
        [LeadId] [bigint] NULL,
        -- Vendor: the supplier stock is returned to.
        [VendorId] [int] NULL,
        [PoliticalStateId] [varchar](4) NULL,
        -- Short code, unique per tenant, e.g. MAIN, VAN-03, JOB-1042.
        [Code] [nvarchar](30) NOT NULL,
        [Name] [nvarchar](150) NOT NULL,
        [StreetAddress] [nvarchar](100) NULL,
        [StreetAddress2] [nvarchar](100) NULL,
        [City] [nvarchar](100) NULL,
        [PostalCode] [nvarchar](15) NULL,
        [Notes] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Locations_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Locations_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Locations_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Locations_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Locations_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Locations_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Locations_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Locations] PRIMARY KEY CLUSTERED ([LocationID] ASC),
        CONSTRAINT [FK_Locations_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Locations_LocationTypes] FOREIGN KEY ([LocationTypeId])
            REFERENCES [INE].[LocationTypes] ([LocationTypeID]),
        CONSTRAINT [FK_Locations_Users] FOREIGN KEY ([UserId])
            REFERENCES [ACC].[Users] ([UserID]),
        CONSTRAINT [FK_Locations_Leads] FOREIGN KEY ([LeadId])
            REFERENCES [QAL].[Leads] ([LeadID]),
        CONSTRAINT [FK_Locations_Vendors] FOREIGN KEY ([VendorId])
            REFERENCES [INE].[Vendors] ([VendorID]),
        CONSTRAINT [FK_Locations_PoliticalStates] FOREIGN KEY ([PoliticalStateId])
            REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID])
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Locations') AND [name] = N'UQ_Locations_DealerTenantId_Code')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Locations_DealerTenantId_Code]
        ON [INE].[Locations] ([DealerTenantId], [Code]);

-- One job location per lead.
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Locations') AND [name] = N'UQ_Locations_LeadId')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Locations_LeadId]
        ON [INE].[Locations] ([LeadId])
        WHERE [LeadId] IS NOT NULL;
GO
