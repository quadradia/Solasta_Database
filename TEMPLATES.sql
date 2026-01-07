/*******************************************************************************
 * EXAMPLE DATABASE OBJECT TEMPLATE
 * 
 * This file provides a quick reference template that you can copy and modify
 * for creating new database objects. Choose the appropriate section below based
 * on the type of object you're creating.
 * 
 * For more detailed templates and examples, see the README.md file in each
 * object type directory.
 ******************************************************************************/

-- =============================================================================
-- TABLE TEMPLATE
-- =============================================================================
/*******************************************************************************
 * Object Type: Table
 * Schema: [SchemaName]
 * Name: [TableName]
 * Description: [Brief description of the table's purpose]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE TABLE [SchemaName].[TableName]
(
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [ModifiedDate] DATETIME2 NULL,
    
    CONSTRAINT PK_[TableName] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO


-- =============================================================================
-- VIEW TEMPLATE
-- =============================================================================
/*******************************************************************************
 * Object Type: View
 * Schema: [SchemaName]
 * Name: [ViewName]
 * Description: [Brief description]
 * Dependencies: [List dependent tables/views]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE VIEW [SchemaName].[ViewName]
AS
    SELECT 
        [Column1],
        [Column2],
        [Column3]
    FROM 
        [SchemaName].[TableName]
    WHERE 
        [IsActive] = 1;
GO


-- =============================================================================
-- STORED PROCEDURE TEMPLATE
-- =============================================================================
/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: [SchemaName]
 * Name: [ProcedureName]
 * Description: [Brief description]
 * Parameters: 
 *   @Param1 - [Description]
 *   @Result OUTPUT - [Description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE PROCEDURE [SchemaName].[ProcedureName]
    @Param1 INT,
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Procedure logic here
        SELECT @Result = COUNT(*) 
        FROM [SchemaName].[TableName]
        WHERE [Id] = @Param1;
        
        RETURN 0; -- Success
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -1; -- Error
    END CATCH
END
GO


-- =============================================================================
-- FUNCTION TEMPLATE (Scalar)
-- =============================================================================
/*******************************************************************************
 * Object Type: Scalar Function
 * Schema: [SchemaName]
 * Name: [FunctionName]
 * Description: [Brief description]
 * Parameters: @Param1 - [Description]
 * Returns: [Data type and description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE FUNCTION [SchemaName].[FunctionName]
(
    @Param1 INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
    
    -- Function logic here
    SELECT @Result = COUNT(*) 
    FROM [SchemaName].[TableName]
    WHERE [Id] = @Param1;
    
    RETURN ISNULL(@Result, 0);
END
GO


-- =============================================================================
-- FUNCTION TEMPLATE (Table-Valued)
-- =============================================================================
/*******************************************************************************
 * Object Type: Table-Valued Function
 * Schema: [SchemaName]
 * Name: [FunctionName]
 * Description: [Brief description]
 * Parameters: @Param1 - [Description]
 * Returns: Table with columns [list columns]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE FUNCTION [SchemaName].[FunctionName]
(
    @Param1 INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        [Id],
        [Name],
        [Description]
    FROM 
        [SchemaName].[TableName]
    WHERE 
        [Id] = @Param1
);
GO


-- =============================================================================
-- TRIGGER TEMPLATE
-- =============================================================================
/*******************************************************************************
 * Object Type: Trigger
 * Schema: [SchemaName]
 * Name: [TriggerName]
 * Type: [AFTER INSERT | AFTER UPDATE | AFTER DELETE]
 * Table: [SchemaName].[TableName]
 * Description: [Brief description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE TRIGGER [SchemaName].[TriggerName]
ON [SchemaName].[TableName]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Trigger logic here
    -- Use 'inserted' table for new values
    -- Use 'deleted' table for old values
END
GO


-- =============================================================================
-- INDEX TEMPLATE
-- =============================================================================
/*******************************************************************************
 * Object Type: Index
 * Schema: [SchemaName]
 * Name: [IndexName]
 * Table: [SchemaName].[TableName]
 * Description: [Brief description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE NONCLUSTERED INDEX [IndexName]
    ON [SchemaName].[TableName] ([Column1] ASC)
    INCLUDE ([Column2], [Column3]);
GO


-- =============================================================================
-- SEQUENCE TEMPLATE
-- =============================================================================
/*******************************************************************************
 * Object Type: Sequence
 * Schema: [SchemaName]
 * Name: [SequenceName]
 * Description: [Brief description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

CREATE SEQUENCE [SchemaName].[SequenceName]
    AS INT
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE
    CACHE 10;
GO


-- =============================================================================
-- DATA SCRIPT TEMPLATE (using MERGE)
-- =============================================================================
/*******************************************************************************
 * Object Type: Data Script
 * Schema: [SchemaName]
 * Table: [TableName]
 * Description: [Brief description]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    MERGE INTO [SchemaName].[TableName] AS target
    USING (
        VALUES 
            (1, N'Item One'),
            (2, N'Item Two'),
            (3, N'Item Three')
    ) AS source ([Id], [Name])
    ON target.[Id] = source.[Id]
    WHEN MATCHED THEN
        UPDATE SET target.[Name] = source.[Name]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Id], [Name])
        VALUES (source.[Id], source.[Name]);
    
    COMMIT TRANSACTION;
    PRINT 'Data loaded successfully';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH
GO
