/*
Migration: 20261117_2330_AddMAC_QuoteSigning
Author: Andres Sosa
Date: 2026-11-17
Description: Lead-to-quote phase 5, sending a quote for e-signature. Signing is built into Solasta (no DocuSign):
             staff send a quote, the customer gets an emailed link that expires with the quote (ValidUntil,
             30 days by default, as short as 24 hours for a promo), opens the Good Faith Estimate on the
             website, agrees to sign electronically (ESIGN consent) and types or draws a signature.
               MAC.QuoteSignatures (new)  one row per link sent: who it went to, when it expires, the unsigned
                                          PDF (DOC.Documents), and once signed the signer's name, email, time,
                                          IP address, user agent, consent text, signature image and the signed
                                          PDF with its SHA-256. Only the SHA-256 of the link token is stored.
                                          A quote has at most one signed row.
               ACE.trgAutoGen_Customers_CUD  recreated to read DealerTenantId. It still read DealerId, which
                                          ACE.Customers no longer has, so every customer insert failed. Signing
                                          turns the lead into an ACE.Customers row (ACE.Customers.LeadId).
               MAC.Estimates              FK_Estimates_Customers pointed at the legacy MAC.Customers while the API
                                          maps ACE.Customers. It is moved to ACE.Customers when every estimate's
                                          CustomerId exists there (always true for an empty table); otherwise it is
                                          left as it is and a message says so. Lead quotes do not use estimates.
Dependencies:
  20261024_1637_CreateDOCDocuments
  20261117_0340_AddQAL_LeadIntake
  20261117_2230_AddMAC_QuoteBuilder
Rollback:
  DROP TABLE [MAC].[QuoteSignatures];
  -- FK_Estimates_Customers: drop it and re-add it REFERENCES [MAC].[Customers] ([CustomerID]) if it was moved.
  -- trgAutoGen_Customers_CUD: keep the fixed version (the old one cannot work).
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261117_2330_AddMAC_QuoteSigning';
Expected impact: one new table; one trigger recreated; one foreign key possibly moved. No data changes.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261117_2330_AddMAC_QuoteSigning';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MAC.Quotes', N'U') IS NULL OR COL_LENGTH(N'MAC.Quotes', N'LeadId') IS NULL
       OR OBJECT_ID(N'DOC.Documents', N'U') IS NULL OR OBJECT_ID(N'ACE.Customers', N'U') IS NULL
        THROW 50001, 'Quote signing requires the quote builder (20261117_2230_AddMAC_QuoteBuilder), DOC.Documents and ACE.Customers.', 1;

    ---------------------------------------------------------------------------
    -- MAC.QuoteSignatures
    ---------------------------------------------------------------------------
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
        PRINT 'Created [MAC].[QuoteSignatures]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.QuoteSignatures') AND [name] = N'IX_QuoteSignatures_QuoteId')
        CREATE NONCLUSTERED INDEX [IX_QuoteSignatures_QuoteId] ON [MAC].[QuoteSignatures] ([QuoteId]) INCLUDE ([Status], [ExpiresAt]);

    -- A quote is signed once.
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE [object_id] = OBJECT_ID(N'MAC.QuoteSignatures') AND [name] = N'UX_QuoteSignatures_QuoteId_Signed')
        CREATE UNIQUE NONCLUSTERED INDEX [UX_QuoteSignatures_QuoteId_Signed]
            ON [MAC].[QuoteSignatures] ([QuoteId]) WHERE [Status] = 'Signed';

    ---------------------------------------------------------------------------
    -- ACE.trgAutoGen_Customers_CUD: DealerId -> DealerTenantId
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'[ACE].[trgAutoGen_Customers_CUD]', N'TR') IS NOT NULL
        DROP TRIGGER [ACE].[trgAutoGen_Customers_CUD];
    EXEC sys.sp_executesql N'CREATE TRIGGER [ACE].[trgAutoGen_Customers_CUD] ON [ACE].[Customers]
	AFTER INSERT, UPDATE
AS
BEGIN
    /**************
	 * INITIALIZE
	 **************/
    DECLARE @UserID UNIQUEIDENTIFIER, @UserGuidMasked VARCHAR(50), @DealerTenantId INT;
    SELECT @UserID = UserID, @UserGuidMasked = UserGuidMasked, @DealerTenantId = DealerTenantId
    FROM [ACC].[fxGetContextUserTable]();
    DECLARE @DeletedTable TABLE (PKID BIGINT NOT NULL);
    INSERT INTO @DeletedTable
        ( PKID )
    SELECT CustomerID
    FROM Deleted;

    /** Build Data Changes */
    DECLARE @DataTable TABLE (PKID BIGINT NOT NULL,
        AuditActionId BIGINT,
        AuditActionTypeId VARCHAR(20),
        ColumnName NVARCHAR(500),
        OldValue NVARCHAR(500),
        NewValue NVARCHAR(500));
    WITH
        RootCTE
        AS
        (
            SELECT
                PKID, InsertValues.ColumnName, InsertValues.ColumnNewValue
            FROM
                (SELECT
                    MFD.CustomerID AS PKID
			, CAST(CustomerID AS NVARCHAR(500)) AS CustomerID
			, CAST(CustomerTypeId AS NVARCHAR(500)) AS CustomerTypeId
			, CAST(MasterFileId AS NVARCHAR(500)) AS MasterFileId
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(CustomerAddressId AS NVARCHAR(500)) AS CustomerAddressId
			, CAST(LeadId AS NVARCHAR(500)) AS LeadId
			, CAST(LanguageId AS NVARCHAR(500)) AS LanguageId
			, CAST(Prefix AS NVARCHAR(500)) AS Prefix
			, CAST(FirstName AS NVARCHAR(500)) AS FirstName
			, CAST(MiddleName AS NVARCHAR(500)) AS MiddleName
			, CAST(LastName AS NVARCHAR(500)) AS LastName
			, CAST(Postfix AS NVARCHAR(500)) AS Postfix
			, CAST(BusinessName AS NVARCHAR(500)) AS BusinessName
			, CAST(Gender AS NVARCHAR(500)) AS Gender
			, CAST(PhoneHome AS NVARCHAR(500)) AS PhoneHome
			, CAST(PhoneWork AS NVARCHAR(500)) AS PhoneWork
			, CAST(PhoneMobile AS NVARCHAR(500)) AS PhoneMobile
			, CAST(Email AS NVARCHAR(500)) AS Email
			, CAST(DOB AS NVARCHAR(500)) AS DOB
			, CAST(SSN AS NVARCHAR(500)) AS SSN
			, CAST(Username AS NVARCHAR(500)) AS Username
			, CAST(Password AS NVARCHAR(500)) AS Password
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Inserted AS MFD WITH(NOLOCK)) AS st2
		UNPIVOT (
			ColumnNewValue FOR ColumnName IN (
			CustomerID
			, CustomerTypeId
			, MasterFileId
			, DealerTenantId
			, CustomerAddressId
			, LeadId
			, LanguageId
			, Prefix
			, FirstName
			, MiddleName
			, LastName
			, Postfix
			, BusinessName
			, Gender
			, PhoneHome
			, PhoneWork
			, PhoneMobile
			, Email
			, DOB
			, SSN
			, Username
			, Password
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        WithChangedCTE
        AS
        (
            SELECT
                PKID
			, InsertValues.ColumnName
			, InsertValues.ColumnOldValue
            FROM
                (SELECT
                    MFD.CustomerID AS PKID
			, CAST(CustomerID AS NVARCHAR(500)) AS CustomerID
			, CAST(CustomerTypeId AS NVARCHAR(500)) AS CustomerTypeId
			, CAST(MasterFileId AS NVARCHAR(500)) AS MasterFileId
			, CAST(DealerTenantId AS NVARCHAR(500)) AS DealerTenantId
			, CAST(CustomerAddressId AS NVARCHAR(500)) AS CustomerAddressId
			, CAST(LeadId AS NVARCHAR(500)) AS LeadId
			, CAST(LanguageId AS NVARCHAR(500)) AS LanguageId
			, CAST(Prefix AS NVARCHAR(500)) AS Prefix
			, CAST(FirstName AS NVARCHAR(500)) AS FirstName
			, CAST(MiddleName AS NVARCHAR(500)) AS MiddleName
			, CAST(LastName AS NVARCHAR(500)) AS LastName
			, CAST(Postfix AS NVARCHAR(500)) AS Postfix
			, CAST(BusinessName AS NVARCHAR(500)) AS BusinessName
			, CAST(Gender AS NVARCHAR(500)) AS Gender
			, CAST(PhoneHome AS NVARCHAR(500)) AS PhoneHome
			, CAST(PhoneWork AS NVARCHAR(500)) AS PhoneWork
			, CAST(PhoneMobile AS NVARCHAR(500)) AS PhoneMobile
			, CAST(Email AS NVARCHAR(500)) AS Email
			, CAST(DOB AS NVARCHAR(500)) AS DOB
			, CAST(SSN AS NVARCHAR(500)) AS SSN
			, CAST(Username AS NVARCHAR(500)) AS Username
			, CAST(Password AS NVARCHAR(500)) AS Password
			, CAST(IsActive AS NVARCHAR(500)) AS IsActive
			, CAST(IsDeleted AS NVARCHAR(500)) AS IsDeleted
                FROM
                    Deleted AS MFD) AS st2
		UNPIVOT (
			ColumnOldValue FOR ColumnName IN (
			CustomerID
			, CustomerTypeId
			, MasterFileId
			, DealerTenantId
			, CustomerAddressId
			, LeadId
			, LanguageId
			, Prefix
			, FirstName
			, MiddleName
			, LastName
			, Postfix
			, BusinessName
			, Gender
			, PhoneHome
			, PhoneWork
			, PhoneMobile
			, Email
			, DOB
			, SSN
			, Username
			, Password
			, IsActive
			, IsDeleted
			)
		) AS InsertValues
        )
	,
        ResultCTE
        AS
        (
            SELECT
                RTN.PKID
			, RTN.ColumnName
			, RTN.ColumnNewValue AS NewValue
			, RTO.ColumnOldValue AS OldValue
            FROM
                RootCTE AS RTN WITH(NOLOCK)
                LEFT OUTER JOIN WithChangedCTE AS RTO WITH(NOLOCK)
                ON
				(RTO.PKID = RTN.PKID)
                    AND (RTO.ColumnName = RTN.ColumnName)
            WHERE
			(RTO.ColumnOldValue IS NULL OR RTN.ColumnNewValue <> RTO.ColumnOldValue)
        )
    INSERT INTO @DataTable
        (PKID, ColumnName, OldValue, NewValue)
    SELECT
        RT.PKID
        , RT.ColumnName
        , RT.OldValue
        , RT.NewValue
    FROM
        ResultCTE AS RT WITH(NOLOCK);

    /** Determin Action */
    WITH
        DistinctCTE
        AS
        (
            SELECT DISTINCT
                RT.PKID
            FROM
                @DataTable AS RT
        )
	,
        DeletedActionCTE
        AS
        (
            SELECT
                RT.PKID
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''1'') AS IsDeleteAction
			, (SELECT CAST(''True'' AS BIT)
                FROM @DataTable
                WHERE PKID = RT.PKID AND ColumnName = ''IsDeleted'' AND NewValue = ''0'' AND OldValue = ''1'') AS IsUnDeleteAction
			, CASE
				WHEN DT.PKID IS NULL THEN CAST(''False'' AS BIT)
				ELSE CAST(''True'' AS BIT)
			  END AS IsUpdateAction
            FROM
                DistinctCTE AS RT
                LEFT OUTER JOIN @DeletedTable AS DT
                ON
				(DT.PKID = RT.PKID)
        )
	,
        DetermineActionTypeCTE
        AS
        (
            SELECT
                DT.PKID
			, CASE
				WHEN DACT.IsDeleteAction = ''True'' THEN ''DELETE''
				WHEN DACT.IsUnDeleteAction = ''True'' THEN ''UNDELETE''
				WHEN DACT.IsUpdateAction = ''True'' THEN ''UPDATE''
				ELSE ''INSERT''
			  END AS AuditActionTypeId
            FROM
                @DataTable AS DT
                LEFT OUTER JOIN DeletedActionCTE AS DACT WITH(NOLOCK)
                ON
				(DACT.PKID = DT.PKID)
        )
	UPDATE DT SET
		DT.AuditActionTypeId = DACT.AuditActionTypeId
	FROM
        @DataTable AS DT
        INNER JOIN DetermineActionTypeCTE AS DACT WITH(NOLOCK)
        ON
			(DACT.PKID = DT.PKID);

    /** CREATE THE AUDIT ACTIONS */
    DECLARE @AuditActionTable TABLE (AuditActionID BIGINT,
        PKID VARCHAR(50));
    INSERT INTO [AUD].[AuditActions]
        ([AuditActionTypeId], [SchemaName], [TableName], [PrimaryKeyIdentifier], [CreatedById])
    OUTPUT INSERTED.AuditActionID, INSERTED.PrimaryKeyIdentifier INTO @AuditActionTable
    SELECT DISTINCT
        DT.AuditActionTypeId
		, ''ACE''
		, ''Customers''
		, CAST(DT.PKID AS VARCHAR(50))
		, @UserID
    FROM
        @DataTable AS DT;

    /** CREATE THE AUDIT ACTION COLUMNS */
    INSERT INTO [AUD].[AuditActionColumns]
        ([AuditActionId], [ColumnName], [OldValue], [NewValue])
    SELECT DISTINCT
        AAT.AuditActionID
		, DT.ColumnName
		, DT.OldValue
		, DT.NewValue
    FROM
        @DataTable AS DT
        INNER JOIN @AuditActionTable AS AAT
        ON
			(AAT.PKID = DT.PKID)
END;';
    PRINT 'Recreated [ACE].[trgAutoGen_Customers_CUD]';

    ---------------------------------------------------------------------------
    -- MAC.Estimates.CustomerId -> ACE.Customers (only when every row already fits)
    ---------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.foreign_keys
               WHERE [name] = N'FK_Estimates_Customers' AND [parent_object_id] = OBJECT_ID(N'MAC.Estimates')
                 AND [referenced_object_id] = OBJECT_ID(N'MAC.Customers'))
    BEGIN
        IF EXISTS (SELECT 1 FROM [MAC].[Estimates] e
                   WHERE NOT EXISTS (SELECT 1 FROM [ACE].[Customers] c WHERE c.[CustomerID] = e.[CustomerId]))
            PRINT 'MAC.Estimates has rows whose CustomerId is not in ACE.Customers; FK_Estimates_Customers still references MAC.Customers.';
        ELSE
        BEGIN
            ALTER TABLE [MAC].[Estimates] DROP CONSTRAINT [FK_Estimates_Customers];
            ALTER TABLE [MAC].[Estimates] WITH CHECK ADD CONSTRAINT [FK_Estimates_Customers]
                FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]);
            PRINT 'FK_Estimates_Customers now references ACE.Customers.';
        END;
    END;
    ELSE IF OBJECT_ID(N'MAC.Estimates', N'U') IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys
                            WHERE [name] = N'FK_Estimates_Customers' AND [parent_object_id] = OBJECT_ID(N'MAC.Estimates'))
            AND NOT EXISTS (SELECT 1 FROM [MAC].[Estimates] e
                            WHERE NOT EXISTS (SELECT 1 FROM [ACE].[Customers] c WHERE c.[CustomerID] = e.[CustomerId]))
    BEGIN
        ALTER TABLE [MAC].[Estimates] WITH CHECK ADD CONSTRAINT [FK_Estimates_Customers]
            FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]);
        PRINT 'Added FK_Estimates_Customers referencing ACE.Customers.';
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Quote e-signature: MAC.QuoteSignatures, ACE customer audit trigger on DealerTenantId, estimates reference ACE.Customers',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
