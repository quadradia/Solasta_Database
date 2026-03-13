/*******************************************************************************
 * Object Type: Table
 * Schema: AUD
 * Name: AuditActionTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditActionTypes' AND schema_id = SCHEMA_ID('AUD'))
BEGIN
CREATE TABLE [AUD].[AuditActionTypes](
	[AuditActionTypeID] [varchar](20) NOT NULL,
	[AuditActionTypeName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_AuditActionTypes] PRIMARY KEY CLUSTERED 
(
	[AuditActionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO
