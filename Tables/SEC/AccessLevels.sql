/*******************************************************************************
 * Object Type: Table
 * Schema: SEC
 * Name: AccessLevels
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AccessLevels' AND schema_id = SCHEMA_ID('SEC'))
BEGIN
CREATE TABLE [SEC].[AccessLevels](
	[AccessLevelID] [tinyint] NOT NULL,
	[Name] [varchar](50) NOT NULL,
 CONSTRAINT [PK_AccessLevels] PRIMARY KEY CLUSTERED 
(
	[AccessLevelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO
