# Tables Directory

This directory contains table creation scripts organized by schema.

## Purpose

Tables are the primary data storage structures in the database. Each table should be in its own file within the appropriate schema subdirectory.

## Structure

```
Tables/
├── dbo/
│   ├── Users.sql
│   ├── Orders.sql
│   └── Products.sql
├── app/
│   └── Settings.sql
└── audit/
    └── AuditLog.sql
```

## Template

```sql
/*******************************************************************************
 * Object Type: Table
 * Schema: [SchemaName]
 * Name: [TableName]
 * Description: [Brief description of the table's purpose]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing table if needed (use with caution)
-- DROP TABLE IF EXISTS [SchemaName].[TableName];

CREATE TABLE [SchemaName].[TableName]
(
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [ModifiedDate] DATETIME2 NULL,
    
    -- Primary Key
    CONSTRAINT PK_[TableName] PRIMARY KEY CLUSTERED ([Id] ASC),
    
    -- Foreign Keys (if applicable)
    -- CONSTRAINT FK_[TableName]_[ReferencedTable] FOREIGN KEY ([ColumnName])
    --     REFERENCES [SchemaName].[ReferencedTable] ([ReferencedColumn]),
    
    -- Unique Constraints
    -- CONSTRAINT UQ_[TableName]_[ColumnName] UNIQUE ([ColumnName]),
    
    -- Check Constraints
    -- CONSTRAINT CK_[TableName]_[ColumnName] CHECK ([ColumnName] > 0)
);
GO

-- Create indexes (if not placing in separate Indexes folder)
-- CREATE NONCLUSTERED INDEX IX_[TableName]_[ColumnName]
--     ON [SchemaName].[TableName] ([ColumnName] ASC);
-- GO
```

## Best Practices

1. **One table per file** - Keep each table definition in its own file
2. **Include constraints** - Define primary keys, foreign keys, and check constraints
3. **Document columns** - Add comments for non-obvious column purposes
4. **Default values** - Specify appropriate defaults for columns
5. **Nullable columns** - Explicitly declare NULL or NOT NULL
6. **Idempotent scripts** - Include DROP IF EXISTS for re-runability
