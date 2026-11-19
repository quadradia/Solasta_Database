/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: PaymentApplications
 * Description: How much of a payment (MAC.Payments) pays which invoice (MAC.Invoices). One payment can pay
 *              several invoices and one invoice can be paid by several payments. Removing an application keeps the
 *              row with IsActive = 0 and UnappliedDate set.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Dependencies: MAC.Payments, MAC.Invoices
 * Migrations: 20261120_0200_AddMAC_InvoicesAndPayments
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.PaymentApplications', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[PaymentApplications]
    (
        [PaymentApplicationID] [bigint] IDENTITY(1,1) NOT NULL,
        [PaymentId] [bigint] NOT NULL,
        [InvoiceId] [bigint] NOT NULL,
        [Amount] [decimal](18, 2) NOT NULL,
        [AppliedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_AppliedDate] DEFAULT (SYSDATETIMEOFFSET()),
        -- Set, with IsActive = 0, when staff remove the application; the row is kept as history.
        [UnappliedDate] [datetimeoffset](7) NULL,
        [Notes] [nvarchar](500) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_PaymentApplications_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_PaymentApplications_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PaymentApplications_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_PaymentApplications_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_PaymentApplications_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_PaymentApplications] PRIMARY KEY CLUSTERED ([PaymentApplicationID] ASC),
        CONSTRAINT [FK_PaymentApplications_Payments] FOREIGN KEY ([PaymentId]) REFERENCES [MAC].[Payments] ([PaymentID]),
        CONSTRAINT [FK_PaymentApplications_Invoices] FOREIGN KEY ([InvoiceId]) REFERENCES [MAC].[Invoices] ([InvoiceID]),
        CONSTRAINT [CK_PaymentApplications_Amount] CHECK ([Amount] > 0),
        CONSTRAINT [CK_PaymentApplications_Unapplied] CHECK (([IsActive] = 1 AND [UnappliedDate] IS NULL)
                                                             OR ([IsActive] = 0 AND [UnappliedDate] IS NOT NULL))
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PaymentApplications') AND [name] = N'IX_PaymentApplications_PaymentId')
    CREATE NONCLUSTERED INDEX [IX_PaymentApplications_PaymentId] ON [MAC].[PaymentApplications] ([PaymentId]) INCLUDE ([InvoiceId], [Amount], [IsActive]);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MAC.PaymentApplications') AND [name] = N'IX_PaymentApplications_InvoiceId')
    CREATE NONCLUSTERED INDEX [IX_PaymentApplications_InvoiceId] ON [MAC].[PaymentApplications] ([InvoiceId]) INCLUDE ([PaymentId], [Amount], [IsActive]);
GO
