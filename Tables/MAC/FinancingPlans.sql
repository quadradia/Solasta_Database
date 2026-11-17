/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: FinancingPlans
 * Description: Financing options per lender or broker (Enhancify): term in months and APR.
 *              An APR of 0 means the monthly payment is the total divided by the months.
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261117_0330_CreateMAC_PricingCatalog
 * API mappings: Models/MAC/PricingCatalog.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.FinancingPlans', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[FinancingPlans]
    (
        [FinancingPlanID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [Lender] [nvarchar](100) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [TermMonths] [int] NOT NULL,
        [Apr] [decimal](9, 6) NOT NULL,
        [Note] [nvarchar](400) NULL,
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_FinancingPlans_SortOrder] DEFAULT ((0)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_FinancingPlans_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_FinancingPlans_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_FinancingPlans_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FinancingPlans_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_FinancingPlans_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FinancingPlans_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_FinancingPlans_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_FinancingPlans] PRIMARY KEY CLUSTERED ([FinancingPlanID] ASC),
        CONSTRAINT [FK_FinancingPlans_DealerTenants] FOREIGN KEY ([DealerTenantId])
            REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [CK_FinancingPlans_TermMonths] CHECK ([TermMonths] > 0),
        CONSTRAINT [CK_FinancingPlans_Apr] CHECK ([Apr] >= 0 AND [Apr] < 1)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.FinancingPlans') AND [name] = N'UQ_FinancingPlans_DealerTenantId_Lender_TermMonths')
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_FinancingPlans_DealerTenantId_Lender_TermMonths]
        ON [MAC].[FinancingPlans] ([DealerTenantId], [Lender], [TermMonths]);
GO
