/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: LocationTypes
 * Description: Kinds of inventory location. Seeded with fixed IDs; code reads them
 *              by Code. IsStockHolding = 0 marks locations stock leaves the books to
 *              (a customer's job site, a vendor) so on-hand reports can skip them.
 * Dependencies: none
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.LocationTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[LocationTypes]
    (
        [LocationTypeID] [int] NOT NULL,
        -- Warehouse, Vehicle, Staging, Job, Vendor
        [Code] [varchar](20) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [IsStockHolding] [bit] NOT NULL CONSTRAINT [DF_LocationTypes_IsStockHolding] DEFAULT ((1)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_LocationTypes_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_LocationTypes_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LocationTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_LocationTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LocationTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_LocationTypes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_LocationTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_LocationTypes] PRIMARY KEY CLUSTERED ([LocationTypeID] ASC),
        CONSTRAINT [UQ_LocationTypes_Code] UNIQUE ([Code])
    );
END;
GO
