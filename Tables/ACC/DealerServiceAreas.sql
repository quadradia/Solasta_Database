/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: DealerServiceAreas
 * Description: ZIP codes (5 digits) or ZIP prefixes (3 digits) a dealer serves; the MCP server finds an
               address's dealer here. A whole ZIP wins over a prefix; lower Priority comes first.
 * Author: Andres Sosa
 * Created: 2026-11-21
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261121_1500_AddPublicEstimatesForMcp
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ACC.DealerServiceAreas', N'U') IS NULL
BEGIN
    CREATE TABLE [ACC].[DealerServiceAreas]
    (
        [DealerServiceAreaID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        -- A whole ZIP code (84043) or a 3-digit prefix (840). A whole ZIP wins over a prefix.
        [PostalCode] [varchar](5) NOT NULL,
        -- Lower comes first when two dealers serve the same ZIP.
        [Priority] [int] NOT NULL CONSTRAINT [DF_DealerServiceAreas_Priority] DEFAULT ((100)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_DealerServiceAreas_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_DealerServiceAreas_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerServiceAreas_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerServiceAreas_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerServiceAreas_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_DealerServiceAreas_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_DealerServiceAreas_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_DealerServiceAreas] PRIMARY KEY CLUSTERED ([DealerServiceAreaID] ASC),
        CONSTRAINT [FK_DealerServiceAreas_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [UQ_DealerServiceAreas_DealerTenantId_PostalCode] UNIQUE ([DealerTenantId], [PostalCode]),
        CONSTRAINT [CK_DealerServiceAreas_PostalCode] CHECK ([PostalCode] LIKE '[0-9][0-9][0-9]' OR [PostalCode] LIKE '[0-9][0-9][0-9][0-9][0-9]')
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACC.DealerServiceAreas') AND [name] = N'IX_DealerServiceAreas_PostalCode')
    CREATE NONCLUSTERED INDEX [IX_DealerServiceAreas_PostalCode] ON [ACC].[DealerServiceAreas] ([PostalCode]) INCLUDE ([DealerTenantId], [Priority]) WHERE [IsActive] = 1;
GO
