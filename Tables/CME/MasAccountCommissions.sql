/*******************************************************************************
 * Object Type: Table
 * Schema: CME
 * Name: MasAccountCommissions
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MasAccountCommissions' AND schema_id = SCHEMA_ID('CME'))
BEGIN
CREATE TABLE [CME].[MasAccountCommissions](
	[MasAccountCommissionID] [uniqueidentifier] NOT NULL,
	[MasAccountCommissionTypeId] [varchar](20) NOT NULL,
	[MasterFileId] [bigint] NOT NULL,
	[MasterFileAccountId] [varchar](50) NULL,
	[LeadId] [bigint] NULL,
	[MasAccountId] [bigint] NULL,
	[UserResourceId] [int] NOT NULL,
	[SeasonId] [int] NOT NULL,
	[Position] [smallint] NOT NULL,
	[Percentage] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[DEX_ROW] [bigint] IDENTITY(1,1) NOT NULL,
	[DEX_ROW_TS] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_MasAccountCommissions] PRIMARY KEY CLUSTERED 
(
	[MasAccountCommissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_MasAccountCommissionID' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_MasAccountCommissionID]  DEFAULT (newsequentialid()) FOR [MasAccountCommissionID]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_Position' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_Position]  DEFAULT ((1)) FOR [Position]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_Percentage' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_Percentage]  DEFAULT ((100)) FOR [Percentage]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_IsActive' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_IsDeleted' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_ModifiedDate' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_ModifiedById' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_CreatedDate' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_CreatedById' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_MasAccountCommissions_DEX_ROW_TS' AND type = 'D')
ALTER TABLE [CME].[MasAccountCommissions] ADD  CONSTRAINT [DF_MasAccountCommissions_DEX_ROW_TS]  DEFAULT (sysdatetimeoffset()) FOR [DEX_ROW_TS]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_Leads')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_Leads] FOREIGN KEY([LeadId])
REFERENCES [QAL].[Leads] ([LeadID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_MasAccountCommissionTypes')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_MasAccountCommissionTypes] FOREIGN KEY([MasAccountCommissionTypeId])
REFERENCES [CME].[MasAccountCommissionTypes] ([MasAccountCommissionTypeID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_MasAccounts')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_MasAccounts] FOREIGN KEY([MasAccountId])
REFERENCES [MAS].[MasAccounts] ([MasAccountID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_MasterFileAccounts')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_MasterFileAccounts] FOREIGN KEY([MasterFileAccountId])
REFERENCES [ACE].[MasterFileAccounts] ([MasterFileAccountID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_MasterFiles')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_MasterFiles] FOREIGN KEY([MasterFileId])
REFERENCES [ACE].[MasterFiles] ([MasterFileID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_Seasons')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_Seasons] FOREIGN KEY([SeasonId])
REFERENCES [RSU].[Seasons] ([SeasonID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_MasAccountCommissions_UserResources')
ALTER TABLE [CME].[MasAccountCommissions]  WITH CHECK ADD  CONSTRAINT [FK_MasAccountCommissions_UserResources] FOREIGN KEY([UserResourceId])
REFERENCES [RSU].[UserResources] ([UserResourceID])
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_Leads]
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_MasAccountCommissionTypes]
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_MasAccounts]
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_MasterFileAccounts]
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_MasterFiles]
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_Seasons]
GO

ALTER TABLE [CME].[MasAccountCommissions] CHECK CONSTRAINT [FK_MasAccountCommissions_UserResources]
GO
