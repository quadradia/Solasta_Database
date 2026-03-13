/*******************************************************************************
 * Object Type: Table
 * Schema: SEC
 * Name: TableAccessLevels
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TableAccessLevels' AND schema_id = SCHEMA_ID('SEC'))
BEGIN
CREATE TABLE [SEC].[TableAccessLevels](
	[TableAccessLevelID] [int] IDENTITY(1,1) NOT NULL,
	[RoleId] [uniqueidentifier] NOT NULL,
	[SchemaName] [varchar](50) NULL,
	[TableName] [varchar](100) NULL,
	[CreateAccessLevelId] [tinyint] NOT NULL,
	[ReadAccessLevelId] [tinyint] NOT NULL,
	[UpdateAccessLevelId] [tinyint] NOT NULL,
	[DeleteAccessLevelId] [tinyint] NOT NULL,
 CONSTRAINT [PK_TableAccessLevels] PRIMARY KEY CLUSTERED 
(
	[TableAccessLevelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TableAccessLevels_AccessLevels')
ALTER TABLE [SEC].[TableAccessLevels]  WITH CHECK ADD  CONSTRAINT [FK_TableAccessLevels_AccessLevels] FOREIGN KEY([CreateAccessLevelId])
REFERENCES [SEC].[AccessLevels] ([AccessLevelID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TableAccessLevels_AccessLevels1')
ALTER TABLE [SEC].[TableAccessLevels]  WITH CHECK ADD  CONSTRAINT [FK_TableAccessLevels_AccessLevels1] FOREIGN KEY([ReadAccessLevelId])
REFERENCES [SEC].[AccessLevels] ([AccessLevelID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TableAccessLevels_AccessLevels2')
ALTER TABLE [SEC].[TableAccessLevels]  WITH CHECK ADD  CONSTRAINT [FK_TableAccessLevels_AccessLevels2] FOREIGN KEY([UpdateAccessLevelId])
REFERENCES [SEC].[AccessLevels] ([AccessLevelID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TableAccessLevels_AccessLevels3')
ALTER TABLE [SEC].[TableAccessLevels]  WITH CHECK ADD  CONSTRAINT [FK_TableAccessLevels_AccessLevels3] FOREIGN KEY([DeleteAccessLevelId])
REFERENCES [SEC].[AccessLevels] ([AccessLevelID])
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TableAccessLevels_Roles')
ALTER TABLE [SEC].[TableAccessLevels]  WITH CHECK ADD  CONSTRAINT [FK_TableAccessLevels_Roles] FOREIGN KEY([RoleId])
REFERENCES [ACC].[Roles] ([RoleID])
GO

ALTER TABLE [SEC].[TableAccessLevels] CHECK CONSTRAINT [FK_TableAccessLevels_AccessLevels]
GO

ALTER TABLE [SEC].[TableAccessLevels] CHECK CONSTRAINT [FK_TableAccessLevels_AccessLevels1]
GO

ALTER TABLE [SEC].[TableAccessLevels] CHECK CONSTRAINT [FK_TableAccessLevels_AccessLevels2]
GO

ALTER TABLE [SEC].[TableAccessLevels] CHECK CONSTRAINT [FK_TableAccessLevels_AccessLevels3]
GO

ALTER TABLE [SEC].[TableAccessLevels] CHECK CONSTRAINT [FK_TableAccessLevels_Roles]
GO
