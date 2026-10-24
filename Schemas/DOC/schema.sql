/*******************************************************************************
 * Object Type: Schema
 * Schema: DOC
 * Name: DOC
 * Description: Document management for signed contracts, engineering files
 *              (including DXF), and other document formats.
 * Dependencies: None
 * Author: Database Team
 * Created: 2026-10-24
 ******************************************************************************/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = N'DOC')
BEGIN
    EXEC sys.sp_executesql N'CREATE SCHEMA [DOC] AUTHORIZATION [dbo];';
END;
GO
