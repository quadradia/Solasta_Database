/*******************************************************************************
 * Object Type: Table
 * Schema: AUD
 * Name: AuditActionColumns
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditActionColumns' AND schema_id = SCHEMA_ID('AUD'))
BEGIN
CREATE TABLE [AUD].[AuditActionColumns](
	[AuditActionColumnID] [bigint] IDENTITY(1,1) NOT NULL,
	[AuditActionId] [bigint] NOT NULL,
	[ColumnName] [nvarchar](500) NOT NULL,
	[OldValue] [nvarchar](500) NULL,
	[NewValue] [nvarchar](500) NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_AuditActionColumns] PRIMARY KEY CLUSTERED 
(
	[AuditActionColumnID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_AuditActionColumns_CreatedDate' AND type = 'D')
ALTER TABLE [AUD].[AuditActionColumns] ADD  CONSTRAINT [DF_AuditActionColumns_CreatedDate]  DEFAULT (sysdatetimeoffset()) FOR [CreatedDate]
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_AuditActionColumns_AuditActions')
ALTER TABLE [AUD].[AuditActionColumns]  WITH CHECK ADD  CONSTRAINT [FK_AuditActionColumns_AuditActions] FOREIGN KEY([AuditActionId])
REFERENCES [AUD].[AuditActions] ([AuditActionID])
GO

ALTER TABLE [AUD].[AuditActionColumns] CHECK CONSTRAINT [FK_AuditActionColumns_AuditActions]
GO
