/*******************************************************************************
 * Object Type: Table
 * Schema: AUD
 * Name: AuditActions
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditActions' AND schema_id = SCHEMA_ID('AUD'))
BEGIN
CREATE TABLE [AUD].[AuditActions](
	[AuditActionID] [bigint] IDENTITY(1,1) NOT NULL,
	[AuditActionTypeId] [varchar](20) NOT NULL,
	[SchemaName] [varchar](50) NOT NULL,
	[TableName] [varchar](500) NOT NULL,
	[PrimaryKeyIdentifier] [varchar](50) NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[CreatedById] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_AuditActions] PRIMARY KEY CLUSTERED 
(
	[AuditActionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AuditActions_AuditActionTypeID' AND type = 'D')
ALTER TABLE [AUD].[AuditActions] ADD  CONSTRAINT [DF_AuditActions_AuditActionTypeID]  DEFAULT ('INSERT') FOR [AuditActionTypeId]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AuditActions_CreatedDate' AND type = 'D')
ALTER TABLE [AUD].[AuditActions] ADD  CONSTRAINT [DF_AuditActions_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AuditActions_AuditActionTypes')
ALTER TABLE [AUD].[AuditActions]  WITH CHECK ADD  CONSTRAINT [FK_AuditActions_AuditActionTypes] FOREIGN KEY([AuditActionTypeId])
REFERENCES [AUD].[AuditActionTypes] ([AuditActionTypeID])
GO

ALTER TABLE [AUD].[AuditActions] CHECK CONSTRAINT [FK_AuditActions_AuditActionTypes]
GO
