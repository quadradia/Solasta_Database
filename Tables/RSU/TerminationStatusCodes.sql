/*******************************************************************************
 * Object Type: Table
 * Schema: RSU
 * Name: TerminationStatusCodes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TerminationStatusCodes' AND schema_id = SCHEMA_ID('RSU'))
BEGIN
CREATE TABLE [RSU].[TerminationStatusCodes](
	[TerminationStatusCodeID] [int] IDENTITY(1,1) NOT NULL,
	[TerminationStatusCodeName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[ModifiedById] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_TerminationStatusCodes] PRIMARY KEY CLUSTERED 
(
	[TerminationStatusCodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatusCodes_IsActive' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatusCodes] ADD  CONSTRAINT [DF_TerminationStatusCodes_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatusCodes_IsDeleted' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatusCodes] ADD  CONSTRAINT [DF_TerminationStatusCodes_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatusCodes_CreatedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatusCodes] ADD  CONSTRAINT [DF_TerminationStatusCodes_CreatedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [CreatedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatusCodes_CreatedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatusCodes] ADD  CONSTRAINT [DF_TerminationStatusCodes_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatusCodes_ModifiedById' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatusCodes] ADD  CONSTRAINT [DF_TerminationStatusCodes_ModifiedById]  DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A') FOR [ModifiedById]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_TerminationStatusCodes_ModifiedDate' AND type = 'D')
ALTER TABLE [RSU].[TerminationStatusCodes] ADD  CONSTRAINT [DF_TerminationStatusCodes_ModifiedDate]  DEFAULT (sysdatetimeoffset()) FOR [ModifiedDate]
GO
