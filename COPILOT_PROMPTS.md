# Database Development Prompts & Helper Scripts

This file contains ready-to-use prompts and helper scripts to accelerate database development with GitHub Copilot.

---

## Table of Contents
1. [Copilot Prompts for Common Tasks](#copilot-prompts-for-common-tasks)
2. [Code Snippets & Templates](#code-snippets--templates)
3. [Diagnostic Queries](#diagnostic-queries)
4. [Validation Scripts](#validation-scripts)
5. [Performance Tuning](#performance-tuning)
6. [Migration Helpers](#migration-helpers)

---

## Copilot Prompts for Common Tasks

### Creating Tables

**Prompt:**
```
Create a table in the dbo schema called Products with the following columns:
- ProductId (primary key, identity)
- ProductName (required, max 200 chars)
- Description (optional)
- Price (decimal, 2 decimal places)
- CategoryId (foreign key to Categories table)
- IsActive (bit, default true)
- Include standard audit columns (CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)

Also create:
1. A migration file for this table
2. The table schema file
3. An index on ProductName and CategoryId
```

**Prompt:**
```
Create an Orders table with proper relationships to Users and Products tables.
Include:
- Composite foreign keys
- Check constraint for order total > 0
- Default values for dates
- Soft delete capability
Generate both migration and schema files.
```

### Creating Stored Procedures

**Prompt:**
```
Create a stored procedure called sp_CreateOrder that:
- Takes UserId, ProductId array, and quantities as parameters
- Validates user exists
- Validates all products exist and are active
- Calculates total price
- Creates order header and order lines
- Returns the new OrderId
- Uses transactions with proper error handling
- Includes rollback on any failure
Include complete header documentation and usage examples.
```

**Prompt:**
```
Create CRUD stored procedures for the Products table:
- sp_GetProductById
- sp_GetAllProducts (with pagination)
- sp_CreateProduct
- sp_UpdateProduct
- sp_DeleteProduct (soft delete)
Include proper error handling and return codes.
```

### Creating Views

**Prompt:**
```
Create a view called vw_OrderSummary in the reporting schema that:
- Joins Orders, Users, and Products
- Shows order details with customer information
- Calculates order totals
- Filters out deleted records
- Includes proper documentation
Create both migration and schema files.
```

**Prompt:**
```
Create a materialized view pattern for sales analytics that:
- Aggregates daily sales by product category
- Includes year, month, day breakdowns
- Shows quantity sold and revenue
- Can be refreshed via stored procedure
```

### Data Seeding

**Prompt:**
```
Create a data seed script for Categories table with:
- Electronics
- Clothing
- Books
- Home & Garden
- Sports
Use MERGE statement for idempotency.
Include in Data/dbo/ folder.
```

**Prompt:**
```
Generate a migration that seeds lookup data for:
- OrderStatus (Pending, Processing, Shipped, Delivered, Cancelled)
- PaymentMethod (Credit Card, Debit Card, PayPal, Bank Transfer)
Ensure idempotent execution.
```

### Creating Functions

**Prompt:**
```
Create a scalar function called fn_CalculateOrderTotal that:
- Takes OrderId as parameter
- Returns total amount as DECIMAL(18,2)
- Sums all order line items
- Returns 0 if order not found
Include proper error handling.
```

**Prompt:**
```
Create a table-valued function called fn_GetUserOrders that:
- Takes UserId and DateRange as parameters
- Returns all orders with line items
- Filters by date range
- Includes product details
- Returns empty set if user not found
```

### Creating Triggers

**Prompt:**
```
Create an audit trigger for the Users table that:
- Fires on INSERT, UPDATE, DELETE
- Logs changes to audit.AuditLog table
- Captures old and new values
- Records timestamp and user
- Uses JSON for change tracking
```

**Prompt:**
```
Create a trigger that maintains ModifiedDate:
- Fires on UPDATE only
- Automatically sets ModifiedDate to GETUTCDATE()
- Sets ModifiedBy to SYSTEM_USER
- Apply to all tables with these columns
```

### Creating Indexes

**Prompt:**
```
Analyze the Products table and create appropriate indexes for:
- Lookups by ProductName
- Filtering by CategoryId
- Sorting by Price
- Date range queries on CreatedDate
Use covering indexes where beneficial.
```

**Prompt:**
```
Create a migration that adds indexes to improve query performance for:
- User login (Username lookup)
- Order history (UserId + OrderDate)
- Product search (Name + Category + Price)
Include analysis of expected usage patterns.
```

---

## Code Snippets & Templates

### Quick Table Template
```sql
-- Paste this and modify:
CREATE TABLE [dbo].[TableName]
(
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [CreatedBy] NVARCHAR(50) NULL,
    [ModifiedDate] DATETIME2 NULL,
    [ModifiedBy] NVARCHAR(50) NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT PK_TableName PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
```

### Quick Procedure Template
```sql
CREATE PROCEDURE [dbo].[sp_ProcName]
    @Param1 INT,
    @Param2 NVARCHAR(100),
    @ResultOut INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMsg NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Your logic here
        
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ErrorMsg = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
        RETURN -1;
    END CATCH
END
GO
```

### Quick Migration Template
```sql
/*
Migration: YYYYMMDD_HHMM_Description
Author: Your Name
Date: YYYY-MM-DD
Description: What this does
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = 'YYYYMMDD_HHMM_Description';
    
    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName)
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Your changes here
    
    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Description');
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    RAISERROR (ERROR_MESSAGE(), 16, 1);
END CATCH
GO

/*
ROLLBACK:
-- Specific undo steps here
*/
```

---

## Diagnostic Queries

### Check Applied Migrations
```sql
-- See all applied migrations in order
SELECT 
    [MigrationName],
    [Description],
    [AppliedDate],
    [AppliedBy],
    [Success],
    [ExecutionTimeMs]
FROM 
    [dbo].[SchemaVersion]
ORDER BY 
    [AppliedDate] DESC;
```

### Find Missing Indexes
```sql
-- Identify missing indexes based on queries
SELECT 
    OBJECT_NAME(d.object_id) AS TableName,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.avg_user_impact,
    s.avg_total_user_cost,
    s.user_seeks,
    s.user_scans
FROM 
    sys.dm_db_missing_index_details d
    INNER JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
    INNER JOIN sys.dm_db_missing_index_group_stats s ON g.index_group_handle = s.group_handle
WHERE 
    d.database_id = DB_ID()
ORDER BY 
    s.avg_user_impact * s.avg_total_user_cost * (s.user_seeks + s.user_scans) DESC;
```

### Find Unused Indexes
```sql
-- Identify unused indexes consuming space
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    p.rows AS RowCounts
FROM 
    sys.indexes i
    LEFT JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
    LEFT JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE 
    OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.index_id > 0
    AND (s.user_seeks + s.user_scans + s.user_lookups) = 0
ORDER BY 
    p.rows DESC;
```

### Check Table Sizes
```sql
-- See space used by each table
SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
    sys.tables t
    INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    LEFT JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    SUM(a.total_pages) DESC;
```

### Find Blocking Queries
```sql
-- Identify blocking chains
SELECT 
    t1.resource_type AS [Lock Type],
    DB_NAME(t1.resource_database_id) AS [Database],
    t1.resource_associated_entity_id AS [Blocked Object],
    t1.request_mode AS [Lock Requested],
    t1.request_session_id AS [Waiting Session],
    t2.wait_duration_ms AS [Wait Duration (ms)],
    (SELECT TEXT FROM sys.dm_exec_requests r
     CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) 
     WHERE r.session_id = t1.request_session_id) AS [Waiting Query],
    t2.blocking_session_id AS [Blocking Session],
    (SELECT TEXT FROM sys.sysprocesses p
     CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) 
     WHERE p.spid = t2.blocking_session_id) AS [Blocking Query]
FROM 
    sys.dm_tran_locks t1
    INNER JOIN sys.dm_os_waiting_tasks t2 ON t1.lock_owner_address = t2.resource_address;
```

### Check Foreign Key Relationships
```sql
-- Document all foreign key relationships
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS SchemaName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM 
    sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY 
    SchemaName, TableName, ForeignKeyName;
```

---

## Validation Scripts

### Validate Migration Integrity
```sql
-- Check for migrations in SchemaVersion that don't have files
SELECT 
    [MigrationName]
FROM 
    [dbo].[SchemaVersion]
WHERE 
    [Success] = 1
ORDER BY 
    [AppliedDate];

-- Compare with actual files in Migrations/ folder
```

### Check Schema Consistency
```sql
-- Verify all tables have primary keys
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName
FROM 
    sys.tables t
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM sys.key_constraints k 
        WHERE k.parent_object_id = t.object_id 
          AND k.type = 'PK'
    )
    AND t.is_ms_shipped = 0
ORDER BY 
    SchemaName, TableName;
```

### Check Naming Conventions
```sql
-- Find tables without standard audit columns
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    CASE WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = t.object_id AND name = 'CreatedDate') THEN 'Yes' ELSE 'No' END AS HasCreatedDate,
    CASE WHEN EXISTS (SELECT 1 FROM sys.columns WHERE object_id = t.object_id AND name = 'ModifiedDate') THEN 'Yes' ELSE 'No' END AS HasModifiedDate
FROM 
    sys.tables t
WHERE 
    t.is_ms_shipped = 0
ORDER BY 
    SchemaName, TableName;
```

---

## Performance Tuning

### Analyze Query Performance
```sql
-- Find most expensive queries
SELECT TOP 25
    total_worker_time / execution_count AS AvgCPU,
    total_elapsed_time / execution_count AS AvgDuration,
    total_logical_reads / execution_count AS AvgReads,
    execution_count,
    SUBSTRING(text, (statement_start_offset / 2) + 1,
        ((CASE statement_end_offset
            WHEN -1 THEN DATALENGTH(text)
            ELSE statement_end_offset
        END - statement_start_offset) / 2) + 1) AS QueryText
FROM 
    sys.dm_exec_query_stats
    CROSS APPLY sys.dm_exec_sql_text(sql_handle)
ORDER BY 
    AvgCPU DESC;
```

### Update Statistics
```sql
-- Update all statistics for better query plans
EXEC sp_MSforeachtable 'UPDATE STATISTICS ? WITH FULLSCAN';
```

### Rebuild Fragmented Indexes
```sql
-- Find and rebuild fragmented indexes
SELECT 
    OBJECT_SCHEMA_NAME(ips.object_id) AS SchemaName,
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    'ALTER INDEX [' + i.name + '] ON [' + 
        OBJECT_SCHEMA_NAME(ips.object_id) + '].[' + 
        OBJECT_NAME(ips.object_id) + '] REBUILD;' AS RebuildCommand
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE 
    ips.avg_fragmentation_in_percent > 30
    AND ips.page_count > 1000
ORDER BY 
    ips.avg_fragmentation_in_percent DESC;
```

---

## Migration Helpers

### Generate Migration Timestamp
```powershell
# PowerShell: Get current UTC timestamp for migration naming
Get-Date -Format "yyyyMMdd_HHmm"
```

```bash
# Bash: Get current UTC timestamp
date -u +"%Y%m%d_%H%M"
```

### Create Migration Template File
```powershell
# PowerShell: Create new migration file
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$description = Read-Host "Enter migration description (PascalCase)"
$filename = "Migrations/${timestamp}_${description}.sql"
Copy-Item "Migrations/TEMPLATE_Migration.sql" $filename
Write-Host "Created: $filename"
```

### Validate All Migrations Run Successfully
```sql
-- Check for any failed migrations
SELECT 
    [MigrationName],
    [Description],
    [AppliedDate],
    [Success]
FROM 
    [dbo].[SchemaVersion]
WHERE 
    [Success] = 0
ORDER BY 
    [AppliedDate] DESC;
```

### Generate Rollback Plan
```sql
-- Get rollback scripts for recent migrations
SELECT 
    [MigrationName],
    [AppliedDate],
    'See migration file for ROLLBACK section' AS RollbackInstructions
FROM 
    [dbo].[SchemaVersion]
WHERE 
    [AppliedDate] > DATEADD(DAY, -7, GETUTCDATE())
    AND [Success] = 1
ORDER BY 
    [AppliedDate] DESC;
```

---

## GitHub Copilot Chat Shortcuts

### Quick Commands to Use in Copilot Chat

```
/explain - Explain this SQL code
/fix - Fix issues in this code
/optimize - Suggest performance improvements
/doc - Generate documentation for this object
/test - Generate test cases for this procedure
```

### Smart Questions to Ask Copilot

**For Tables:**
```
What indexes should I add to this table for optimal performance?
What are potential concurrency issues with this table design?
Should this table be partitioned? Why or why not?
What data type would be best for storing [specific data]?
```

**For Procedures:**
```
What security vulnerabilities exist in this procedure?
How can I improve error handling in this procedure?
What transaction isolation level should I use here?
Is this procedure prone to deadlocks? How can I prevent them?
```

**For Queries:**
```
How can I optimize this query's execution plan?
What indexes would benefit this query?
Can this be rewritten using window functions?
What's the estimated impact on tempdb?
```

**For Migrations:**
```
What's the safest way to add a NOT NULL column to a large table?
How can I make this migration reversible?
What's the best approach to rename this column without downtime?
How should I handle data backfill in this migration?
```

---

## Automated Checks

### Pre-Commit Validation Script
```powershell
# Save as: Scripts/validate-migration.ps1
# Run before committing migrations

param(
    [string]$MigrationFile
)

Write-Host "Validating migration file: $MigrationFile"

$content = Get-Content $MigrationFile -Raw

# Check for header
if ($content -notmatch "/\*\s*Migration:") {
    Write-Error "Missing migration header comment"
    exit 1
}

# Check for transaction wrapper
if ($content -notmatch "BEGIN TRANSACTION") {
    Write-Error "Missing transaction wrapper"
    exit 1
}

# Check for version check
if ($content -notmatch "SchemaVersion") {
    Write-Error "Missing SchemaVersion check"
    exit 1
}

# Check for rollback section
if ($content -notmatch "ROLLBACK") {
    Write-Error "Missing rollback instructions"
    exit 1
}

Write-Host "✓ Migration file validation passed" -ForegroundColor Green
```

### Check Naming Conventions
```powershell
# Save as: Scripts/check-naming.ps1
# Validate file naming conventions

Get-ChildItem -Path "Migrations/*.sql" | ForEach-Object {
    if ($_.Name -notmatch '^\d{8}_\d{4}_.+\.sql$') {
        Write-Warning "Invalid migration name: $($_.Name)"
        Write-Host "Expected format: YYYYMMDD_HHMM_Description.sql"
    }
}
```

---

## Best Practices Checklist

### Before Creating a Migration
- [ ] Have you tested the change locally?
- [ ] Is the change idempotent?
- [ ] Have you included rollback instructions?
- [ ] Does it check SchemaVersion table?
- [ ] Is it wrapped in a transaction?
- [ ] Have you considered performance impact?
- [ ] Are there any dependencies?
- [ ] Have you documented the change?

### Before Creating a Stored Procedure
- [ ] Uses SET NOCOUNT ON?
- [ ] Has proper error handling?
- [ ] Uses transactions for DML?
- [ ] Has parameter validation?
- [ ] Returns meaningful status codes?
- [ ] Includes usage examples?
- [ ] No SQL injection vulnerabilities?
- [ ] Properly documented?

### Before Creating a Table
- [ ] Has primary key?
- [ ] All columns have NULL/NOT NULL specified?
- [ ] Has appropriate indexes?
- [ ] Includes audit columns if needed?
- [ ] Foreign keys properly defined?
- [ ] Check constraints where needed?
- [ ] Proper data types chosen?
- [ ] Table documented?

---

## Additional Resources

### Useful SQL Server DMVs
- `sys.dm_exec_query_stats` - Query performance statistics
- `sys.dm_db_index_usage_stats` - Index usage
- `sys.dm_db_index_physical_stats` - Index fragmentation
- `sys.dm_os_waiting_tasks` - Current waits
- `sys.dm_exec_requests` - Currently executing requests

### Performance Tools
- SQL Server Execution Plans (Ctrl+M in SSMS)
- SQL Server Profiler
- Database Engine Tuning Advisor
- Extended Events

### Documentation Links
- [SQL Server Best Practices](https://docs.microsoft.com/sql/sql-server/)
- [T-SQL Reference](https://docs.microsoft.com/sql/t-sql/)
- [Database Design Guidelines](https://docs.microsoft.com/sql/relational-databases/)

---

**Last Updated**: March 9, 2026
**Maintained By**: Database Team
