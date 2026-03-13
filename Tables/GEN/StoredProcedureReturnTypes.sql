/*******************************************************************************
 * Object Type: Table
 * Schema: GEN
 * Name: StoredProcedureReturnTypes
 * Description: 
 * Author: 
 * Created: 2026-03-13
 ******************************************************************************/

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StoredProcedureReturnTypes' AND schema_id = SCHEMA_ID('GEN'))
BEGIN
CREATE TABLE [GEN].[StoredProcedureReturnTypes](
	[StoredProcedureReturnTypeID] [int] IDENTITY(1,1) NOT NULL,
	[SchemaName] [varchar](50) NOT NULL,
	[SPROCName] [varchar](50) NOT NULL,
	[CSharpReturnType] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_StoredProcedureReturnTypes] PRIMARY KEY CLUSTERED 
(
	[StoredProcedureReturnTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

END
GO
