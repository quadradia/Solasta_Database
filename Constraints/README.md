# Constraints Directory

This directory contains constraint definition scripts organized by schema.

## Purpose

Constraints enforce data integrity rules at the database level. While constraints can be defined inline with table creation, separating them allows for easier maintenance and modification.

## Structure

```
Constraints/
├── dbo/
│   ├── FK_Orders_CustomerId.sql
│   ├── CK_Users_Email.sql
│   └── DF_Products_CreatedDate.sql
└── app/
    └── UQ_Settings_Key.sql
```

## Constraint Types

### Foreign Key Constraints

```sql
/*******************************************************************************
 * Object Type: Foreign Key Constraint
 * Schema: [SchemaName]
 * Name: FK_[ChildTable]_[ParentTable]
 * Child Table: [SchemaName].[ChildTable]
 * Parent Table: [SchemaName].[ParentTable]
 * Description: [Brief description]
 ******************************************************************************/

-- Drop existing constraint if it exists
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = N'FK_[ChildTable]_[ParentTable]'
)
    ALTER TABLE [SchemaName].[ChildTable] 
    DROP CONSTRAINT FK_[ChildTable]_[ParentTable];
GO

-- Create foreign key constraint
ALTER TABLE [SchemaName].[ChildTable]
    ADD CONSTRAINT FK_[ChildTable]_[ParentTable]
    FOREIGN KEY ([ColumnName])
    REFERENCES [SchemaName].[ParentTable] ([ColumnName])
    ON DELETE CASCADE  -- or NO ACTION, SET NULL, SET DEFAULT
    ON UPDATE CASCADE; -- or NO ACTION, SET NULL, SET DEFAULT
GO
```

### Check Constraints

```sql
/*******************************************************************************
 * Object Type: Check Constraint
 * Schema: [SchemaName]
 * Name: CK_[TableName]_[ColumnName]
 * Table: [SchemaName].[TableName]
 * Description: [Brief description of the validation rule]
 ******************************************************************************/

-- Drop existing constraint if it exists
IF EXISTS (
    SELECT 1 FROM sys.check_constraints 
    WHERE name = N'CK_[TableName]_[ColumnName]'
)
    ALTER TABLE [SchemaName].[TableName] 
    DROP CONSTRAINT CK_[TableName]_[ColumnName];
GO

-- Create check constraint
ALTER TABLE [SchemaName].[TableName]
    ADD CONSTRAINT CK_[TableName]_[ColumnName]
    CHECK ([ColumnName] > 0 AND [ColumnName] <= 100);
GO

-- Examples:
-- CHECK ([Email] LIKE '%_@_%._%')
-- CHECK ([Status] IN ('Active', 'Inactive', 'Pending'))
-- CHECK ([EndDate] >= [StartDate])
-- CHECK (LEN([PhoneNumber]) = 10)
```

### Unique Constraints

```sql
/*******************************************************************************
 * Object Type: Unique Constraint
 * Schema: [SchemaName]
 * Name: UQ_[TableName]_[ColumnName]
 * Table: [SchemaName].[TableName]
 * Description: [Brief description]
 ******************************************************************************/

-- Drop existing constraint if it exists
IF EXISTS (
    SELECT 1 FROM sys.key_constraints 
    WHERE name = N'UQ_[TableName]_[ColumnName]'
)
    ALTER TABLE [SchemaName].[TableName] 
    DROP CONSTRAINT UQ_[TableName]_[ColumnName];
GO

-- Create unique constraint
ALTER TABLE [SchemaName].[TableName]
    ADD CONSTRAINT UQ_[TableName]_[ColumnName]
    UNIQUE ([Column1], [Column2]);
GO
```

### Default Constraints

```sql
/*******************************************************************************
 * Object Type: Default Constraint
 * Schema: [SchemaName]
 * Name: DF_[TableName]_[ColumnName]
 * Table: [SchemaName].[TableName]
 * Column: [ColumnName]
 * Description: [Brief description of the default value]
 ******************************************************************************/

-- Drop existing constraint if it exists
IF EXISTS (
    SELECT 1 FROM sys.default_constraints 
    WHERE name = N'DF_[TableName]_[ColumnName]'
)
    ALTER TABLE [SchemaName].[TableName] 
    DROP CONSTRAINT DF_[TableName]_[ColumnName];
GO

-- Create default constraint
ALTER TABLE [SchemaName].[TableName]
    ADD CONSTRAINT DF_[TableName]_[ColumnName]
    DEFAULT (GETUTCDATE()) FOR [ColumnName];
GO

-- Examples:
-- DEFAULT (0) FOR [Quantity]
-- DEFAULT (NEWID()) FOR [UniqueId]
-- DEFAULT ('Active') FOR [Status]
-- DEFAULT (SUSER_SNAME()) FOR [CreatedBy]
```

## Best Practices

1. **Naming conventions**:
   - Foreign Keys: `FK_ChildTable_ParentTable`
   - Check Constraints: `CK_TableName_ColumnName`
   - Unique Constraints: `UQ_TableName_ColumnName`
   - Default Constraints: `DF_TableName_ColumnName`

2. **Document business rules** - Explain why the constraint exists

3. **Consider performance** - Constraints are checked on every modification

4. **Use appropriate actions** - Choose correct ON DELETE/ON UPDATE behavior

5. **Test edge cases** - Ensure constraints work for all scenarios

6. **Avoid complex checks** - Very complex rules may be better in triggers or application

7. **Enable constraints** - Ensure constraints are not disabled unintentionally

8. **Cascading actions** - Use CASCADE carefully to avoid unintended data loss
