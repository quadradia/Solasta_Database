# Data Directory

This directory contains seed data and static reference data scripts organized by schema.

## Purpose

The Data directory stores scripts for inserting seed data, lookup tables, and reference data that the application needs to function. This data is typically version-controlled and deployed with the database schema.

## Structure

```
Data/
├── dbo/
│   ├── Countries_data.sql
│   ├── States_data.sql
│   └── Roles_data.sql
├── config/
│   ├── AppSettings_data.sql
│   └── Features_data.sql
└── app/
    └── DefaultCategories_data.sql
```

## Template

```sql
/*******************************************************************************
 * Object Type: Data Script (Seed/Reference Data)
 * Schema: [SchemaName]
 * Table: [TableName]
 * Description: [Brief description of the data being loaded]
 * Data Type: [Seed Data | Reference Data | Lookup Data | Configuration]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- Set options for better error handling
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- Clear existing data if this is a refresh (use with caution)
    -- DELETE FROM [SchemaName].[TableName];
    
    -- Method 1: Individual INSERT statements
    -- Good for small datasets or when you need explicit control
    
    IF NOT EXISTS (SELECT 1 FROM [SchemaName].[TableName] WHERE [Id] = 1)
    BEGIN
        INSERT INTO [SchemaName].[TableName] ([Id], [Name], [Code], [IsActive])
        VALUES (1, N'Item One', N'ITEM1', 1);
    END
    
    IF NOT EXISTS (SELECT 1 FROM [SchemaName].[TableName] WHERE [Id] = 2)
    BEGIN
        INSERT INTO [SchemaName].[TableName] ([Id], [Name], [Code], [IsActive])
        VALUES (2, N'Item Two', N'ITEM2', 1);
    END
    
    -- Method 2: Bulk INSERT with MERGE
    -- Best for larger datasets and maintaining idempotency
    
    MERGE INTO [SchemaName].[TableName] AS target
    USING (
        VALUES 
            (1, N'Item One', N'ITEM1', 1),
            (2, N'Item Two', N'ITEM2', 1),
            (3, N'Item Three', N'ITEM3', 1)
    ) AS source ([Id], [Name], [Code], [IsActive])
    ON target.[Id] = source.[Id]
    WHEN MATCHED THEN
        UPDATE SET 
            target.[Name] = source.[Name],
            target.[Code] = source.[Code],
            target.[IsActive] = source.[IsActive]
    WHEN NOT MATCHED BY TARGET THEN
        INSERT ([Id], [Name], [Code], [IsActive])
        VALUES (source.[Id], source.[Name], source.[Code], source.[IsActive]);
    -- WHEN NOT MATCHED BY SOURCE THEN
    --     DELETE;  -- Uncomment if you want to remove obsolete records
    
    COMMIT TRANSACTION;
    PRINT 'Successfully loaded data into [SchemaName].[TableName]';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH
GO
```

## Template - PostgreSQL

```sql
/*******************************************************************************
 * Object Type: Data Script
 * Schema: [SchemaName]
 * Table: [TableName]
 * Description: [Brief description]
 ******************************************************************************/

BEGIN;

-- Method: INSERT with ON CONFLICT (Upsert)
INSERT INTO [SchemaName].[TableName] (id, name, code, is_active)
VALUES 
    (1, 'Item One', 'ITEM1', true),
    (2, 'Item Two', 'ITEM2', true),
    (3, 'Item Three', 'ITEM3', true)
ON CONFLICT (id) 
DO UPDATE SET
    name = EXCLUDED.name,
    code = EXCLUDED.code,
    is_active = EXCLUDED.is_active;

COMMIT;
```

## Common Data Types

### Lookup/Reference Data

```sql
-- Countries
MERGE INTO [dbo].[Countries] AS target
USING (
    VALUES 
        (1, N'United States', N'US', N'USA'),
        (2, N'Canada', N'CA', N'CAN'),
        (3, N'United Kingdom', N'GB', N'GBR')
) AS source ([Id], [Name], [Code2], [Code3])
ON target.[Id] = source.[Id]
WHEN MATCHED THEN UPDATE SET 
    target.[Name] = source.[Name],
    target.[Code2] = source.[Code2],
    target.[Code3] = source.[Code3]
WHEN NOT MATCHED THEN INSERT ([Id], [Name], [Code2], [Code3])
    VALUES (source.[Id], source.[Name], source.[Code2], source.[Code3]);
GO
```

### Configuration Data

```sql
-- Application settings
MERGE INTO [config].[AppSettings] AS target
USING (
    VALUES 
        (N'MaxLoginAttempts', N'5', N'INT', N'Maximum failed login attempts before lockout'),
        (N'SessionTimeout', N'30', N'INT', N'Session timeout in minutes'),
        (N'EnableFeatureX', N'true', N'BOOL', N'Enable feature X flag')
) AS source ([Key], [Value], [DataType], [Description])
ON target.[Key] = source.[Key]
WHEN MATCHED THEN UPDATE SET 
    target.[Value] = source.[Value],
    target.[DataType] = source.[DataType],
    target.[Description] = source.[Description]
WHEN NOT MATCHED THEN INSERT ([Key], [Value], [DataType], [Description])
    VALUES (source.[Key], source.[Value], source.[DataType], source.[Description]);
GO
```

### Default Roles

```sql
-- User roles
SET IDENTITY_INSERT [dbo].[Roles] ON;
GO

MERGE INTO [dbo].[Roles] AS target
USING (
    VALUES 
        (1, N'Administrator', N'Full system access'),
        (2, N'Manager', N'Manage users and content'),
        (3, N'User', N'Standard user access'),
        (4, N'Guest', N'Limited read-only access')
) AS source ([Id], [Name], [Description])
ON target.[Id] = source.[Id]
WHEN MATCHED THEN UPDATE SET 
    target.[Name] = source.[Name],
    target.[Description] = source.[Description]
WHEN NOT MATCHED THEN INSERT ([Id], [Name], [Description])
    VALUES (source.[Id], source.[Name], source.[Description]);
GO

SET IDENTITY_INSERT [dbo].[Roles] OFF;
GO
```

### Enum/Status Values

```sql
-- Order statuses
MERGE INTO [dbo].[OrderStatuses] AS target
USING (
    VALUES 
        (1, N'Pending', N'Order is pending processing', 1),
        (2, N'Processing', N'Order is being processed', 2),
        (3, N'Shipped', N'Order has been shipped', 3),
        (4, N'Delivered', N'Order has been delivered', 4),
        (5, N'Cancelled', N'Order has been cancelled', 99)
) AS source ([Id], [Name], [Description], [SortOrder])
ON target.[Id] = source.[Id]
WHEN MATCHED THEN UPDATE SET 
    target.[Name] = source.[Name],
    target.[Description] = source.[Description],
    target.[SortOrder] = source.[SortOrder]
WHEN NOT MATCHED THEN INSERT ([Id], [Name], [Description], [SortOrder])
    VALUES (source.[Id], source.[Name], source.[Description], source.[SortOrder]);
GO
```

## Loading Data from Files

### SQL Server - BULK INSERT

```sql
-- Load from CSV file
BULK INSERT [SchemaName].[TableName]
FROM 'C:\Data\datafile.csv'
WITH (
    FIRSTROW = 2,              -- Skip header row
    FIELDTERMINATOR = ',',     -- CSV field delimiter
    ROWTERMINATOR = '\n',      -- Line delimiter
    TABLOCK,                   -- Table lock for better performance
    CHECK_CONSTRAINTS          -- Enforce constraints during load
);
GO
```

### PostgreSQL - COPY

```sql
-- Load from CSV file
COPY [SchemaName].[TableName] (column1, column2, column3)
FROM '/path/to/datafile.csv'
WITH (FORMAT CSV, HEADER true);
```

## Best Practices

1. **Idempotent scripts** - Use MERGE or INSERT...ON CONFLICT for re-runability
2. **Explicit IDs** - Use SET IDENTITY_INSERT when controlling identity values
3. **Transactions** - Wrap data loads in transactions for atomicity
4. **Error handling** - Include proper error handling and rollback logic
5. **Documentation** - Clearly document the source and purpose of data
6. **Validation** - Verify data after loading
7. **Small batches** - Break large datasets into manageable chunks
8. **Performance** - Use TABLOCK or disable indexes for large loads
9. **Dependencies** - Load data in proper order (respect foreign keys)
10. **Testing** - Test data scripts in non-production first
11. **Versioning** - Track changes to reference data
12. **Separability** - Keep volatile data separate from stable reference data
