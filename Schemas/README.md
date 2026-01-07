# Schemas Directory

This directory contains schema creation scripts organized by schema name.

## Purpose

Schemas are used to logically group database objects and manage permissions. Each schema should have its own subdirectory containing a `schema.sql` file.

## Structure

```
Schemas/
├── dbo/              # Default schema (SQL Server)
├── app/              # Application-specific objects
├── config/           # Configuration tables and objects
├── audit/            # Audit logging objects
└── reporting/        # Reporting views and procedures
```

## Template

```sql
/*******************************************************************************
 * Object Type: Schema
 * Name: [SchemaName]
 * Description: [Brief description of what this schema contains]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Create schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'[SchemaName]')
BEGIN
    EXEC('CREATE SCHEMA [SchemaName]');
END
GO

-- For PostgreSQL:
-- CREATE SCHEMA IF NOT EXISTS [SchemaName];
```

## Usage

1. Create a subdirectory for your schema (e.g., `myschema/`)
2. Create a `schema.sql` file in that directory
3. Define the schema creation logic
4. Execute schema scripts before any other database objects
