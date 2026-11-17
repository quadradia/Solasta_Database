/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: QuoteSignatures
 * Description: E-signature links for quotes (MAC.Quotes), one row per link emailed to the customer.
 *              Pending until signed or revoked; the link stops working at ExpiresAt, which is never later
 *              than the quote's ValidUntil. Once signed the row holds the signer's name, email, time, IP,
 *              user agent, the ESIGN consent text, the signature image and the signed PDF (DOC.Documents)
 *              with its SHA-256. Only the SHA-256 of the link token is stored. One signed row per quote.
 * Author: Andres Sosa
 * Created: 2026-11-17
 * Dependencies: ACC.DealerTenants, MAC.Quotes, DOC.Documents
 * Migrations: 20261117_2330_AddMAC_QuoteSigning
 * API mappings: Models/MAC/QuoteSignature.cs is written by hand; remove it when the
 *               AutoGenerator produces an equivalent.
 ******************************************************************************/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'MAC.QuoteSignatures', N'U') IS NULL
BEGIN
    CREATE TABLE [MAC].[QuoteSignatures]
    (
        [QuoteSignatureID] [bigint] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        [QuoteId] [bigint] NOT NULL,
        [Proxy] [varchar](100) NOT NULL,
        [PartKey] [varchar](6) NOT NULL,
        -- SHA-256 (hex) of the token in the emailed link. The token itself is never stored.
        [TokenHash] [char](64) NOT NULL,
        -- Pending (link usable until ExpiresAt), Signed, or Revoked (a newer link was sent, or the quote
        -- was revised, declined or signed another way).
        [Status] [varchar](10) NOT NULL CONSTRAINT [DF_QuoteSignatures_Status] DEFAULT ('Pending'),
        [SentToName] [nvarchar](150) NOT NULL,
        [SentToEmail] [nvarchar](256) NOT NULL,
        [SentDate] [datetimeoffset](7) NOT NULL,
        -- Never later than the quote's ValidUntil.
        [ExpiresAt] [datetimeoffset](7) NOT NULL,
        -- The Good Faith Estimate the customer was sent.
        [UnsignedDocumentId] [bigint] NULL,
        [FirstViewedDate] [datetimeoffset](7) NULL,
        [LastViewedDate] [datetimeoffset](7) NULL,
        [ViewCount] [int] NOT NULL CONSTRAINT [DF_QuoteSignatures_ViewCount] DEFAULT ((0)),
        -- Filled when the customer signs.
        [SignerName] [nvarchar](150) NULL,
        [SignerEmail] [nvarchar](256) NULL,
        [SignedDate] [datetimeoffset](7) NULL,
        [SignerIp] [varchar](45) NULL,
        [SignerUserAgent] [nvarchar](512) NULL,
        -- Typed (name rendered in a script font) or Drawn.
        [SignatureMethod] [varchar](10) NULL,
        -- PNG of the signature as it appears on the signed PDF.
        [SignatureImage] [varbinary](max) NULL,
        -- The ESIGN consent wording the customer agreed to, exactly as shown.
        [ConsentText] [nvarchar](2000) NULL,
        [SignedDocumentId] [bigint] NULL,
        -- SHA-256 (hex) of the final signed PDF, also in DOC.Documents.Sha256.
        [SignedPdfSha256] [char](64) NULL,
        [RevokedDate] [datetimeoffset](7) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_QuoteSignatures_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_QuoteSignatures_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteSignatures_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_QuoteSignatures_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteSignatures_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_QuoteSignatures_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_QuoteSignatures_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_QuoteSignatures] PRIMARY KEY CLUSTERED ([QuoteSignatureID] ASC),
        CONSTRAINT [FK_QuoteSignatures_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [FK_QuoteSignatures_Quotes] FOREIGN KEY ([QuoteId]) REFERENCES [MAC].[Quotes] ([QuoteID]),
        CONSTRAINT [FK_QuoteSignatures_UnsignedDocument] FOREIGN KEY ([UnsignedDocumentId]) REFERENCES [DOC].[Documents] ([DocumentID]),
        CONSTRAINT [FK_QuoteSignatures_SignedDocument] FOREIGN KEY ([SignedDocumentId]) REFERENCES [DOC].[Documents] ([DocumentID]),
        CONSTRAINT [UQ_QuoteSignatures_Proxy] UNIQUE ([Proxy]),
        CONSTRAINT [UQ_QuoteSignatures_TokenHash] UNIQUE ([TokenHash]),
        CONSTRAINT [CK_QuoteSignatures_Status] CHECK ([Status] IN ('Pending', 'Signed', 'Revoked')),
        CONSTRAINT [CK_QuoteSignatures_TokenHash] CHECK
            (DATALENGTH([TokenHash]) = 64 AND [TokenHash] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9a-f]%'),
        CONSTRAINT [CK_QuoteSignatures_SignedPdfSha256] CHECK ([SignedPdfSha256] IS NULL OR
            (DATALENGTH([SignedPdfSha256]) = 64 AND [SignedPdfSha256] COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9a-f]%')),
        CONSTRAINT [CK_QuoteSignatures_Expiry] CHECK ([ExpiresAt] > [SentDate]),
        CONSTRAINT [CK_QuoteSignatures_SignatureMethod] CHECK ([SignatureMethod] IS NULL OR [SignatureMethod] IN ('Typed', 'Drawn')),
        CONSTRAINT [CK_QuoteSignatures_Signed] CHECK ([Status] <> 'Signed' OR
            ([SignerName] IS NOT NULL AND [SignedDate] IS NOT NULL AND [SignatureMethod] IS NOT NULL
             AND [SignatureImage] IS NOT NULL AND [ConsentText] IS NOT NULL AND [SignedDocumentId] IS NOT NULL
             AND [SignedPdfSha256] IS NOT NULL)),
        CONSTRAINT [CK_QuoteSignatures_ViewCount] CHECK ([ViewCount] >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.QuoteSignatures') AND [name] = N'IX_QuoteSignatures_QuoteId')
    CREATE NONCLUSTERED INDEX [IX_QuoteSignatures_QuoteId] ON [MAC].[QuoteSignatures] ([QuoteId]) INCLUDE ([Status], [ExpiresAt]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE [object_id] = OBJECT_ID(N'MAC.QuoteSignatures') AND [name] = N'UX_QuoteSignatures_QuoteId_Signed')
    CREATE UNIQUE NONCLUSTERED INDEX [UX_QuoteSignatures_QuoteId_Signed]
        ON [MAC].[QuoteSignatures] ([QuoteId]) WHERE [Status] = 'Signed';
GO
