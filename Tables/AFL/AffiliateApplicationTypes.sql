/*******************************************************************************
 * Object Type: Table
 * Schema: AFL
 * Name: AffiliateApplicationTypes
 * Description: Channels an affiliate application can arrive through, and their
 *              registered Proxy-ID prefixes. Registered prefixes: AFAW (Website Application).
 * Dependencies: (none)
 * Author: Andres Sosa
 * Created: 2026-11-03
 ******************************************************************************/

IF OBJECT_ID(N'AFL.AffiliateApplicationTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [AFL].[AffiliateApplicationTypes]
    (
        [AffiliateApplicationTypeID] [int] IDENTITY(1,1) NOT NULL,
        [Prefix] [varchar](4) NOT NULL,
        [AffiliateApplicationTypeName] [nvarchar](100) NOT NULL,
        [AffiliateApplicationTypeDescription] [nvarchar](2000) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_IsActive] DEFAULT (1),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_IsDeleted] DEFAULT (0),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL,
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL,
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AffiliateApplicationTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_AffiliateApplicationTypes] PRIMARY KEY CLUSTERED ([AffiliateApplicationTypeID]),
        CONSTRAINT [UQ_AffiliateApplicationTypes_Prefix] UNIQUE ([Prefix]),
        CONSTRAINT [CK_AffiliateApplicationTypes_Prefix] CHECK
            (DATALENGTH([Prefix]) = 4 AND [Prefix] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^A-Z0-9]%')
    );
END;
GO
