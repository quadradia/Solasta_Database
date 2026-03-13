/*******************************************************************************
 * Object Type: Table
 * Schema: MAC
 * Name: Accounts
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Accounts' AND schema_id = SCHEMA_ID('MAC'))
BEGIN
CREATE TABLE [MAC].[Accounts](
	[AccountID] [bigint] IDENTITY(30000,1) NOT NULL,
	[AccountTypeId] [smallint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Accounts] PRIMARY KEY CLUSTERED 
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_AccountTypeId' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_AccountTypeId]  DEFAULT ((1)) FOR [AccountTypeId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_IsActive' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_IsDeleted' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_ModifiedDate' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_ModifiedById' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_CreatedDate' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_CreatedById' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Accounts_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [MAC].[Accounts] ADD  CONSTRAINT [DF_Accounts_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Accounts_AccountTypes')
ALTER TABLE [MAC].[Accounts]  WITH CHECK ADD  CONSTRAINT [FK_Accounts_AccountTypes] FOREIGN KEY([AccountTypeId])
REFERENCES [MAC].[AccountTypes] ([AccountTypeID])
GO

ALTER TABLE [MAC].[Accounts] CHECK CONSTRAINT [FK_Accounts_AccountTypes]
GO
