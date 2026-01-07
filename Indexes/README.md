# Indexes Directory

This directory contains index creation scripts organized by schema.

## Purpose

Indexes improve query performance by creating efficient data lookup structures. While indexes can be defined inline with table creation, separating them allows for easier maintenance and tuning.

## Structure

```
Indexes/
├── dbo/
│   ├── IX_Users_Email.sql
│   ├── IX_Orders_CustomerId.sql
│   └── IX_Products_CategoryId.sql
└── app/
    └── IX_Settings_Key.sql
```

## Template

```sql
/*******************************************************************************
 * Object Type: Index
 * Schema: [SchemaName]
 * Name: [IndexName]
 * Table: [SchemaName].[TableName]
 * Type: [CLUSTERED | NONCLUSTERED | UNIQUE | FULLTEXT]
 * Description: [Brief description of the index purpose]
 * Columns: [List indexed columns]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing index if it exists
IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = N'[IndexName]' 
    AND object_id = OBJECT_ID(N'[SchemaName].[TableName]')
)
    DROP INDEX [IndexName] ON [SchemaName].[TableName];
GO

-- Create index
CREATE NONCLUSTERED INDEX [IndexName]
    ON [SchemaName].[TableName] 
    (
        [Column1] ASC,
        [Column2] DESC
    )
    INCLUDE ([Column3], [Column4])  -- Covering columns
    WITH (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        SORT_IN_TEMPDB = OFF,
        DROP_EXISTING = OFF,
        ONLINE = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    );
GO

-- For PostgreSQL:
-- DROP INDEX IF EXISTS [SchemaName].[IndexName];
-- CREATE INDEX [IndexName] 
--     ON [SchemaName].[TableName] ([Column1], [Column2]);
```

## Index Types

### Clustered Index
- Determines physical order of data
- One per table
- Usually on primary key

### Nonclustered Index
- Separate structure from data
- Multiple per table
- Speeds up queries on indexed columns

### Unique Index
- Enforces uniqueness
- Can be clustered or nonclustered

### Filtered Index
- Indexes subset of rows
- Reduces index size and maintenance

```sql
CREATE NONCLUSTERED INDEX [IndexName]
    ON [SchemaName].[TableName] ([Column1])
    WHERE [Column2] = 'ActiveValue';
```

### Columnstore Index
- Optimized for data warehousing
- Dramatically improves aggregate query performance

```sql
CREATE NONCLUSTERED COLUMNSTORE INDEX [IndexName]
    ON [SchemaName].[TableName] 
    (
        [Column1], 
        [Column2], 
        [Column3]
    );
```

## Best Practices

1. **Naming convention** - Use `IX_TableName_ColumnNames` format
2. **Analyze queries** - Create indexes based on actual query patterns
3. **Consider covering indexes** - Use INCLUDE for frequently accessed columns
4. **Monitor fragmentation** - Rebuild or reorganize fragmented indexes
5. **Balance reads/writes** - Too many indexes slow down INSERT/UPDATE/DELETE
6. **Statistics** - Keep statistics up to date for query optimizer
7. **Filtered indexes** - Use for partial data (e.g., active records only)
8. **Avoid over-indexing** - Each index has maintenance overhead
9. **Test impact** - Measure query performance before and after
10. **Document rationale** - Explain why the index was created
