/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: Vendors
 * Description: Suppliers the tenant buys stock from.
 * Dependencies: ACC.DealerTenants, MAC.PoliticalStates
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.Vendors', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[Vendors]
    (
        [VendorID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        -- Short code shown on POs, unique per tenant.
        [Code] [nvarchar](20) NOT NULL,
        [Name] [nvarchar](150) NOT NULL,
        [ContactName] [nvarchar](100) NULL,
        [Email] [nvarchar](256) NULL,
        [Phone] [nvarchar](30) NULL,
        [Website] [nvarchar](256) NULL,
        [StreetAddress] [nvarchar](100) NULL,
        [StreetAddress2] [nvarchar](100) NULL,
        [City] [nvarchar](100) NULL,
        [PoliticalStateId] [varchar](4) NULL,
        [PostalCode] [nvarchar](15) NULL,
        -- Typical days from order to delivery; feeds reorder suggestions.
        [LeadTimeDays] [int] NULL,
        [PaymentTerms] [nvarchar](50) NULL,
        [Notes] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_Vendors_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Vendors_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Vendors_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Vendors_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Vendors_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Vendors_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Vendors_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_Vendors] PRIMARY KEY CLUSTERED ([VendorID] ASC),
        CONSTRAINT [FK_Vendors_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_Vendors_PoliticalStates] FOREIGN KEY ([PoliticalStateId])
            REFERENCES [MAC].[PoliticalStates] ([PoliticalStateID]),
        CONSTRAINT [CK_Vendors_LeadTimeDays] CHECK ([LeadTimeDays] IS NULL OR [LeadTimeDays] >= 0)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'INE.Vendors') AND [name] = N'UQ_Vendors_DealerTenantId_Code')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Vendors_DealerTenantId_Code]
        ON [INE].[Vendors] ([DealerTenantId], [Code]);
GO
