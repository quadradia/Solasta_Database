/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: BucksTransactionTypes
 * Description: Kinds of Solasta Bucks ledger entries and their registered Proxy-ID
 *              prefixes: AFBP (Post Reward), AFBR (Referral Reward), AFBD (Redemption),
 *              AFBA (Adjustment).
 * Dependencies: (none)
 * Author: Andres Sosa
 * Created: 2026-11-03
 ******************************************************************************/

IF OBJECT_ID(N'AFL.BucksTransactionTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [AFL].[BucksTransactionTypes]
    (
        [BucksTransactionTypeID] [int] IDENTITY(1,1) NOT NULL,
        [Prefix] [varchar](4) NOT NULL,
        [BucksTransactionTypeName] [nvarchar](100) NOT NULL,
        [BucksTransactionTypeDescription] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_BucksTransactionTypes_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_BucksTransactionTypes_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactionTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactionTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_BucksTransactionTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_BucksTransactionTypes] PRIMARY KEY CLUSTERED ([BucksTransactionTypeID]),
        CONSTRAINT [UQ_BucksTransactionTypes_Prefix] UNIQUE ([Prefix]),
        CONSTRAINT [CK_BucksTransactionTypes_Prefix] CHECK
            (DATALENGTH([Prefix]) = 4 AND [Prefix] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z0-9]%')
    );
END;
GO
