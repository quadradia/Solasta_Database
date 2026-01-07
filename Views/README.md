# Views Directory

This directory contains view creation scripts organized by schema.

## Purpose

Views provide a virtual table based on the result of a SELECT statement. They are useful for simplifying complex queries, providing security through abstraction, and maintaining backward compatibility.

## Structure

```
Views/
├── dbo/
│   ├── vw_ActiveUsers.sql
│   └── vw_OrderSummary.sql
├── reporting/
│   ├── vw_SalesReport.sql
│   └── vw_InventoryStatus.sql
└── app/
    └── vw_UserPermissions.sql
```

## Template

```sql
/*******************************************************************************
 * Object Type: View
 * Schema: [SchemaName]
 * Name: [ViewName]
 * Description: [Brief description of what the view returns]
 * Dependencies: [List dependent tables/views]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing view if it exists
IF OBJECT_ID('[SchemaName].[ViewName]', 'V') IS NOT NULL
    DROP VIEW [SchemaName].[ViewName];
GO

CREATE VIEW [SchemaName].[ViewName]
AS
    SELECT 
        t1.[Id],
        t1.[Name],
        t1.[Description],
        t2.[RelatedField],
        t1.[CreatedDate]
    FROM 
        [SchemaName].[Table1] t1
        INNER JOIN [SchemaName].[Table2] t2 ON t1.[Id] = t2.[Table1Id]
    WHERE 
        t1.[IsActive] = 1;
GO

-- For PostgreSQL:
-- CREATE OR REPLACE VIEW [SchemaName].[ViewName] AS
--     SELECT ...;
```

## Best Practices

1. **Prefix with vw_** - Use a consistent naming convention (optional)
2. **Document dependencies** - List all tables/views used in the header
3. **Avoid SELECT *** - Explicitly list columns for maintainability
4. **Consider performance** - Complex views may need underlying indexes
5. **Use WITH SCHEMABINDING** - For indexed views (SQL Server)
6. **Test thoroughly** - Ensure view returns expected results
