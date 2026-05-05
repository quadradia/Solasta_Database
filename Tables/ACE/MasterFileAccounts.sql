/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: MasterFileAccounts
 * Description:
 * Author:
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'MasterFileAccounts' AND schema_id = SCHEMA_ID('ACE'))
BEGIN
	CREATE TABLE [ACE].[MasterFileAccounts]
	(
		[MasterFileAccountID] [varchar](50) NOT NULL,
		[MasterFileId] [bigint] NOT NULL,
		[DealerTenantId] [int] NOT NULL,
		[CustomerTypeId] [varchar](20) NOT NULL,
		[LeadId] [bigint] NULL,
		[Lead2Id] [bigint] NULL,
		[AccountId] [bigint] NULL,
		[AccountTypeId] [smallint] NULL,
		[CustomerId] [bigint] NULL,
		[Customer2Id] [bigint] NULL,
		[MonthlyContractId] [uniqueidentifier] NULL,
		[InstallFeeContractId] [uniqueidentifier] NULL,
		[BillingDay] [smallint] NULL,
		[EffectiveDate] [datetimeoffset](7) NOT NULL,
		[ContractLockDate] [datetimeoffset](7) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[ModifiedDate] [datetimeoffset](7) NOT NULL,
		[ModifiedById] [uniqueidentifier] NOT NULL,
		[CreatedDate] [datetimeoffset](7) NOT NULL,
		[CreatedById] [uniqueidentifier] NOT NULL,
		[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
		[DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
		CONSTRAINT [PK_MasterFileAccounts] PRIMARY KEY CLUSTERED
(
	[MasterFileAccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	)

END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_CustomerTypeId' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_CustomerTypeId]  DEFAULT ('LEAD') FOR [CustomerTypeId]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_EffectiveDate' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_EffectiveDate]  DEFAULT (sysdatetimeoffset()) FOR [EffectiveDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_IsActive' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_IsDeleted' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_ModifiedDate' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_ModifiedById' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_CreatedDate' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_CreatedById' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE name = 'DF_MasterFileAccounts_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [ACE].[MasterFileAccounts] ADD  CONSTRAINT [DF_MasterFileAccounts_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_Accounts')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_Accounts] FOREIGN KEY([AccountId])
REFERENCES [MAC].[Accounts] ([AccountID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_AccountTypes')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_AccountTypes] FOREIGN KEY([AccountTypeId])
REFERENCES [MAC].[AccountTypes] ([AccountTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_Customers')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_Customers] FOREIGN KEY([CustomerId])
REFERENCES [ACE].[Customers] ([CustomerID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_CustomerTypes')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_CustomerTypes] FOREIGN KEY([CustomerTypeId])
REFERENCES [ACE].[CustomerTypes] ([CustomerTypeID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_DealerTenants')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_DealerTenants] FOREIGN KEY([DealerTenantId])
REFERENCES [ACC].[DealerTenants] ([DealerTenantID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_Leads')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_Leads] FOREIGN KEY([LeadId])
REFERENCES [QAL].[Leads] ([LeadID])
GO

IF NOT EXISTS (SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_MasterFiles')
ALTER TABLE [ACE].[MasterFileAccounts]  WITH CHECK ADD  CONSTRAINT [FK_MasterFileAccounts_MasterFiles] FOREIGN KEY([MasterFileId])
REFERENCES [ACE].[MasterFiles] ([MasterFileID])
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_Accounts]
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_AccountTypes]
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_Customers]
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_CustomerTypes]
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_DealerTenants]
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_Leads]
GO

ALTER TABLE [ACE].[MasterFileAccounts] CHECK CONSTRAINT [FK_MasterFileAccounts_MasterFiles]
GO
