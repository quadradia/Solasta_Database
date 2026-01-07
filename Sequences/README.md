# Sequences Directory

This directory contains sequence creation scripts organized by schema.

## Purpose

Sequences generate unique numeric values, typically used for generating primary key values or other sequential identifiers. They provide better performance and flexibility than identity columns in many scenarios.

## Structure

```
Sequences/
├── dbo/
│   ├── seq_OrderNumbers.sql
│   └── seq_InvoiceNumbers.sql
├── app/
│   └── seq_TransactionIds.sql
└── audit/
    └── seq_AuditIds.sql
```

## Template - SQL Server

```sql
/*******************************************************************************
 * Object Type: Sequence
 * Schema: [SchemaName]
 * Name: [SequenceName]
 * Description: [Brief description of what this sequence generates]
 * Start Value: [StartValue]
 * Increment: [IncrementValue]
 * Min/Max: [MinValue/MaxValue]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing sequence if it exists
IF EXISTS (
    SELECT 1 FROM sys.sequences 
    WHERE name = N'[SequenceName]' 
    AND schema_id = SCHEMA_ID(N'[SchemaName]')
)
    DROP SEQUENCE [SchemaName].[SequenceName];
GO

-- Create sequence
CREATE SEQUENCE [SchemaName].[SequenceName]
    AS BIGINT               -- Data type: TINYINT, SMALLINT, INT, BIGINT, DECIMAL, NUMERIC
    START WITH 1            -- Starting value
    INCREMENT BY 1          -- Increment value
    MINVALUE 1              -- Minimum value (optional)
    MAXVALUE 9999999999     -- Maximum value (optional)
    CYCLE                   -- or NO CYCLE - whether to restart after reaching max
    CACHE 50;               -- Number of values to cache (improves performance)
GO

-- Usage example:
-- Get next value:
-- SELECT NEXT VALUE FOR [SchemaName].[SequenceName];
--
-- Use in INSERT:
-- INSERT INTO [Table] ([Id], [Name])
-- VALUES (NEXT VALUE FOR [SchemaName].[SequenceName], 'Example');
--
-- Reset sequence:
-- ALTER SEQUENCE [SchemaName].[SequenceName] RESTART WITH 1;
```

## Template - PostgreSQL

```sql
/*******************************************************************************
 * Object Type: Sequence
 * Schema: [SchemaName]
 * Name: [SequenceName]
 * Description: [Brief description]
 ******************************************************************************/

-- Drop existing sequence if it exists
DROP SEQUENCE IF EXISTS [SchemaName].[SequenceName];

-- Create sequence
CREATE SEQUENCE [SchemaName].[SequenceName]
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START WITH 1
    CACHE 50
    CYCLE;  -- or NO CYCLE

-- Set ownership (optional - ties sequence to a table column)
-- ALTER SEQUENCE [SchemaName].[SequenceName] 
--     OWNED BY [SchemaName].[TableName].[ColumnName];

-- Usage example:
-- Get next value:
-- SELECT nextval('[SchemaName].[SequenceName]');
--
-- Get current value (without incrementing):
-- SELECT currval('[SchemaName].[SequenceName]');
--
-- Set current value:
-- SELECT setval('[SchemaName].[SequenceName]', 100);
```

## Common Patterns

### Invoice Numbers with Prefix

```sql
-- Sequence
CREATE SEQUENCE [dbo].[seq_InvoiceNumbers]
    AS INT
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE
    CACHE 10;
GO

-- Function to format invoice number
CREATE FUNCTION [dbo].[fn_GetNextInvoiceNumber]()
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @NextNumber INT;
    DECLARE @InvoiceNumber VARCHAR(20);
    
    SET @NextNumber = NEXT VALUE FOR [dbo].[seq_InvoiceNumbers];
    SET @InvoiceNumber = 'INV' + FORMAT(@NextNumber, '000000');
    
    RETURN @InvoiceNumber;
END
GO
```

### Yearly Reset Pattern

```sql
-- Sequence with yearly reset logic
CREATE SEQUENCE [dbo].[seq_YearlyOrderNumbers]
    AS INT
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE
    CACHE 20;
GO

-- Procedure to get next number with year prefix
CREATE PROCEDURE [dbo].[sp_GetNextYearlyOrderNumber]
    @OrderNumber VARCHAR(20) OUTPUT
AS
BEGIN
    DECLARE @Year INT = YEAR(GETUTCDATE());
    DECLARE @NextNumber INT;
    
    -- Check if year has changed and reset if needed
    IF NOT EXISTS (
        SELECT 1 FROM [config].[SequenceResets]
        WHERE [SequenceName] = 'seq_YearlyOrderNumbers'
        AND [Year] = @Year
    )
    BEGIN
        ALTER SEQUENCE [dbo].[seq_YearlyOrderNumbers] RESTART WITH 1;
        
        INSERT INTO [config].[SequenceResets] ([SequenceName], [Year], [ResetDate])
        VALUES ('seq_YearlyOrderNumbers', @Year, GETUTCDATE());
    END
    
    SET @NextNumber = NEXT VALUE FOR [dbo].[seq_YearlyOrderNumbers];
    SET @OrderNumber = CAST(@Year AS VARCHAR(4)) + '-' + FORMAT(@NextNumber, '00000');
END
GO
```

## Advantages Over Identity Columns

1. **Cross-table sequences** - Share sequence across multiple tables
2. **Controlled incrementing** - Get next value in application logic
3. **Range allocation** - Pre-allocate ranges for different purposes
4. **Easy reset** - Can reset sequence value without rebuilding table
5. **Gaps management** - Better control over gaps in sequences
6. **Performance** - Caching improves performance for high-volume inserts

## Best Practices

1. **Naming convention** - Use `seq_` prefix for clarity
2. **Appropriate caching** - Use CACHE for better performance (10-100 typical)
3. **Choose data type** - Select appropriate numeric type for expected range
4. **Document purpose** - Explain what the sequence is used for
5. **Consider CYCLE** - Usually NO CYCLE unless you want wraparound
6. **Monitor values** - Track current value to avoid reaching maximum
7. **Backup strategy** - Consider sequence values in backup/restore plans
8. **Concurrent access** - Sequences are designed for concurrent use
9. **Testing** - Test sequence behavior under load
10. **Migration** - Have a plan for converting from identity columns if needed
