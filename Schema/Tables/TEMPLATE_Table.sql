/*
Table: TableName
Description: Brief description of what this table stores
Author: Your Name
Date: YYYY-MM-DD
Dependencies: List any foreign key dependencies or related tables
*/

-- Create table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TableName' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[TableName] (
        -- Primary Key
        [Id] INT IDENTITY(1,1) NOT NULL,
        
        -- Business columns
        [Name] NVARCHAR(255) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        
        -- Audit columns
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [CreatedBy] NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
        [ModifiedDate] DATETIME2 NULL,
        [ModifiedBy] NVARCHAR(128) NULL,
        
        -- Constraints
        CONSTRAINT PK_TableName PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    
    -- Create indexes
    CREATE INDEX IX_TableName_Name ON [dbo].[TableName]([Name]);
    CREATE INDEX IX_TableName_IsActive ON [dbo].[TableName]([IsActive]);
    
    -- Add foreign key constraints if needed
    -- ALTER TABLE [dbo].[TableName]
    -- ADD CONSTRAINT FK_TableName_OtherTable FOREIGN KEY ([OtherTableId])
    --     REFERENCES [dbo].[OtherTable]([Id]);
    
    PRINT 'Table TableName created successfully';
END
GO

-- Add comments/extended properties for documentation
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Brief description of what this table stores',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'TableName';
GO
