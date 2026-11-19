/*******************************************************************************
 * Object Type: Table
 * Schema: MCH
 * Name: TransactionStatuses
 * Description: Transaction states, NVL9_MAIN codes plus PENDING (ACH not settled) and RETURNED.
 * Author: Andres Sosa
 * Created: 2026-11-20
 * Migrations: 20261120_0300_CreateMCH_MerchantServices
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MCH.TransactionStatuses', N'U') IS NULL
BEGIN
    CREATE TABLE [MCH].[TransactionStatuses]
    (
        [TransactionStatusID] [varchar](20) NOT NULL,
        [TransactionStatusName] [varchar](50) NOT NULL,
        -- 1 when nothing more will change it (OK and PENDING can still move).
        [IsFinal] [bit] NOT NULL CONSTRAINT [DF_TransactionStatuses_IsFinal] DEFAULT ((1)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_TransactionStatuses_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_TransactionStatuses_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionStatuses_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionStatuses_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionStatuses_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_TransactionStatuses_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_TransactionStatuses_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_TransactionStatuses] PRIMARY KEY CLUSTERED ([TransactionStatusID] ASC)
    );
    PRINT 'Created [MCH].[TransactionStatuses]';
END;
GO
