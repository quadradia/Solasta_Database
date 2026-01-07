# Types Directory

This directory contains user-defined type scripts organized by schema.

## Purpose

User-defined types (UDTs) allow you to create custom data types based on existing system types. They promote consistency and reusability across the database.

## Structure

```
Types/
├── dbo/
│   ├── EmailAddress.sql
│   ├── PhoneNumber.sql
│   └── tvp_BulkInsertType.sql
└── app/
    └── StatusType.sql
```

## Template - Alias Type (SQL Server)

```sql
/*******************************************************************************
 * Object Type: User-Defined Type (Alias)
 * Schema: [SchemaName]
 * Name: [TypeName]
 * Base Type: [BaseDataType]
 * Description: [Brief description of the type's purpose]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing type if it exists
IF EXISTS (
    SELECT 1 FROM sys.types 
    WHERE name = N'[TypeName]' 
    AND schema_id = SCHEMA_ID(N'[SchemaName]')
)
    DROP TYPE [SchemaName].[TypeName];
GO

-- Create alias type
CREATE TYPE [SchemaName].[TypeName]
FROM VARCHAR(100) NOT NULL;
GO

-- Usage example:
-- DECLARE @Email [SchemaName].[TypeName];
-- SET @Email = 'user@example.com';
--
-- In table definition:
-- CREATE TABLE Users (
--     Email [SchemaName].[TypeName]
-- );
```

## Template - Table Type (SQL Server)

Table-valued types are commonly used for passing structured data to stored procedures.

```sql
/*******************************************************************************
 * Object Type: User-Defined Table Type
 * Schema: [SchemaName]
 * Name: [TypeName]
 * Description: [Brief description of the table type structure]
 * Typical Usage: [Description of when/how this type is used]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing type if it exists
IF EXISTS (
    SELECT 1 FROM sys.table_types 
    WHERE name = N'[TypeName]' 
    AND schema_id = SCHEMA_ID(N'[SchemaName]')
)
    DROP TYPE [SchemaName].[TypeName];
GO

-- Create table type
CREATE TYPE [SchemaName].[TypeName] AS TABLE
(
    [Id] INT NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Value] DECIMAL(18,2) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    
    PRIMARY KEY ([Id]),
    UNIQUE ([Name])
);
GO

-- Usage example in stored procedure:
/*
CREATE PROCEDURE [SchemaName].[sp_BulkInsertData]
    @Data [SchemaName].[TypeName] READONLY
AS
BEGIN
    INSERT INTO [SchemaName].[TargetTable] 
    ([Id], [Name], [Value], [IsActive])
    SELECT 
        [Id], 
        [Name], 
        [Value], 
        [IsActive]
    FROM @Data;
END
GO

-- Calling the procedure:
DECLARE @MyData [SchemaName].[TypeName];

INSERT INTO @MyData ([Id], [Name], [Value], [IsActive])
VALUES 
    (1, 'Item1', 10.50, 1),
    (2, 'Item2', 20.75, 1),
    (3, 'Item3', 15.00, 0);

EXEC [SchemaName].[sp_BulkInsertData] @Data = @MyData;
*/
```

## Template - Domain Type (PostgreSQL)

```sql
/*******************************************************************************
 * Object Type: Domain (User-Defined Type)
 * Schema: [SchemaName]
 * Name: [TypeName]
 * Base Type: [BaseDataType]
 * Description: [Brief description]
 ******************************************************************************/

-- Drop existing domain if it exists
DROP DOMAIN IF EXISTS [SchemaName].[TypeName];

-- Create domain with constraints
CREATE DOMAIN [SchemaName].[TypeName] AS VARCHAR(255)
    CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
    NOT NULL;

-- Usage example:
-- CREATE TABLE users (
--     email [SchemaName].[TypeName]
-- );
```

## Template - Composite Type (PostgreSQL)

```sql
/*******************************************************************************
 * Object Type: Composite Type
 * Schema: [SchemaName]
 * Name: [TypeName]
 * Description: [Brief description]
 ******************************************************************************/

-- Drop existing type if it exists
DROP TYPE IF EXISTS [SchemaName].[TypeName];

-- Create composite type
CREATE TYPE [SchemaName].[TypeName] AS (
    id INTEGER,
    name VARCHAR(100),
    created_date TIMESTAMP
);

-- Usage example:
-- CREATE TABLE items (
--     info [SchemaName].[TypeName]
-- );
--
-- INSERT INTO items (info) 
-- VALUES (ROW(1, 'Item Name', NOW()));
```

## Common Examples

### Email Address Type

```sql
CREATE TYPE [dbo].[EmailAddress]
FROM VARCHAR(320) NOT NULL;
GO

-- Add rule (optional, for additional validation in older SQL Server versions)
-- CREATE RULE EmailRule AS @value LIKE '%_@_%._%';
-- sp_bindrule 'EmailRule', '[dbo].[EmailAddress]';
```

### Phone Number Type

```sql
CREATE TYPE [dbo].[PhoneNumber]
FROM VARCHAR(20) NOT NULL;
GO
```

### Money Amount Type

```sql
CREATE TYPE [dbo].[MoneyAmount]
FROM DECIMAL(18,2) NOT NULL;
GO
```

### Bulk Insert Type

```sql
CREATE TYPE [dbo].[tvp_IdList] AS TABLE
(
    [Id] INT NOT NULL PRIMARY KEY
);
GO

-- Usage for IN clause alternative:
/*
CREATE PROCEDURE [dbo].[sp_GetItemsByIds]
    @Ids [dbo].[tvp_IdList] READONLY
AS
BEGIN
    SELECT t.*
    FROM [dbo].[Items] t
    INNER JOIN @Ids ids ON t.[Id] = ids.[Id];
END
GO
*/
```

## Best Practices

1. **Naming conventions**:
   - Alias types: `[TypeName]` (e.g., `EmailAddress`)
   - Table types: `tvp_[TypeName]` (e.g., `tvp_UserList`)

2. **Document constraints** - Clearly specify validation rules

3. **Consider reusability** - Only create types that will be used multiple times

4. **Keep simple** - Complex types can be harder to maintain

5. **Performance** - Table types are readonly in procedures (cannot UPDATE/DELETE)

6. **Compatibility** - Be aware of portability issues across database systems

7. **Versioning** - Cannot alter types; must drop and recreate (impacts dependent objects)

8. **Testing** - Test type behavior in all contexts where it will be used

9. **Documentation** - Maintain a list of where types are used

10. **Default values** - Consider appropriate defaults for alias types
