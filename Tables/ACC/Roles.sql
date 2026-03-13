/*******************************************************************************
 * Object Type: Table
 * Schema: ACC
 * Name: Roles
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles' AND schema_id = SCHEMA_ID('ACC'))
BEGIN
CREATE TABLE [ACC].[Roles](
	[RoleID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
	[SecurityLevel] [int] NOT NULL,
 CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'DF_Roles_RoleID' AND type = 'D')
ALTER TABLE [ACC].[Roles] ADD  CONSTRAINT [DF_Roles_RoleID]  DEFAULT (newsequentialid()) FOR [RoleID]
GO
