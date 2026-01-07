# Grants Directory

This directory contains permission grant scripts organized by schema.

## Purpose

Grant scripts define database permissions for users and roles, controlling access to database objects. Organizing grants by schema helps manage security systematically.

## Structure

```
Grants/
├── dbo/
│   ├── grant_app_user_permissions.sql
│   └── grant_reporting_role_permissions.sql
├── app/
│   └── grant_developers_permissions.sql
└── audit/
    └── grant_auditor_permissions.sql
```

## Template

```sql
/*******************************************************************************
 * Object Type: Grant Script
 * Schema: [SchemaName]
 * Target: [UserName/RoleName]
 * Description: [Brief description of permissions being granted]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- SQL Server syntax
USE [DatabaseName];
GO

-- Create role if it doesn't exist (SQL Server 2016+)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'[RoleName]')
BEGIN
    CREATE ROLE [RoleName];
END
GO

-- Grant schema-level permissions
GRANT SELECT ON SCHEMA::[SchemaName] TO [RoleName];
GRANT INSERT ON SCHEMA::[SchemaName] TO [RoleName];
GRANT UPDATE ON SCHEMA::[SchemaName] TO [RoleName];
-- GRANT DELETE ON SCHEMA::[SchemaName] TO [RoleName];
-- GRANT EXECUTE ON SCHEMA::[SchemaName] TO [RoleName];
GO

-- Grant object-level permissions
GRANT SELECT ON [SchemaName].[TableName] TO [RoleName];
GRANT INSERT ON [SchemaName].[TableName] TO [RoleName];
GRANT UPDATE ON [SchemaName].[TableName] TO [RoleName];
GRANT DELETE ON [SchemaName].[TableName] TO [RoleName];
GO

-- Grant procedure execution permissions
GRANT EXECUTE ON [SchemaName].[ProcedureName] TO [RoleName];
GO

-- Grant function execution permissions
GRANT EXECUTE ON [SchemaName].[FunctionName] TO [RoleName];
GO

-- Grant view permissions
GRANT SELECT ON [SchemaName].[ViewName] TO [RoleName];
GO

-- Add user to role
-- ALTER ROLE [RoleName] ADD MEMBER [UserName];
-- GO
```

## Template - PostgreSQL

```sql
/*******************************************************************************
 * Object Type: Grant Script
 * Schema: [SchemaName]
 * Target: [UserName/RoleName]
 * Description: [Brief description]
 ******************************************************************************/

-- Create role if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '[RoleName]') THEN
        CREATE ROLE [RoleName];
    END IF;
END
$$;

-- Grant schema usage
GRANT USAGE ON SCHEMA [SchemaName] TO [RoleName];

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA [SchemaName] TO [RoleName];
-- Grant permissions to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA [SchemaName] 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO [RoleName];

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA [SchemaName] TO [RoleName];
ALTER DEFAULT PRIVILEGES IN SCHEMA [SchemaName] 
    GRANT USAGE, SELECT ON SEQUENCES TO [RoleName];

-- Grant function permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA [SchemaName] TO [RoleName];
ALTER DEFAULT PRIVILEGES IN SCHEMA [SchemaName] 
    GRANT EXECUTE ON FUNCTIONS TO [RoleName];

-- Add user to role
-- GRANT [RoleName] TO [UserName];
```

## Common Permission Sets

### Read-Only Access

```sql
-- SQL Server
GRANT SELECT ON SCHEMA::[SchemaName] TO [ReadOnlyRole];
GRANT EXECUTE ON [SchemaName].[ReadOnlyProcedure] TO [ReadOnlyRole];
GO

-- PostgreSQL
GRANT USAGE ON SCHEMA [SchemaName] TO [ReadOnlyRole];
GRANT SELECT ON ALL TABLES IN SCHEMA [SchemaName] TO [ReadOnlyRole];
```

### Read-Write Access

```sql
-- SQL Server
GRANT SELECT, INSERT, UPDATE ON SCHEMA::[SchemaName] TO [ReadWriteRole];
GRANT EXECUTE ON SCHEMA::[SchemaName] TO [ReadWriteRole];
GO

-- PostgreSQL
GRANT USAGE ON SCHEMA [SchemaName] TO [ReadWriteRole];
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA [SchemaName] TO [ReadWriteRole];
GRANT USAGE ON ALL SEQUENCES IN SCHEMA [SchemaName] TO [ReadWriteRole];
```

### Full Access (excluding DELETE)

```sql
-- SQL Server
GRANT SELECT, INSERT, UPDATE, EXECUTE ON SCHEMA::[SchemaName] TO [PowerUserRole];
GO

-- PostgreSQL
GRANT ALL PRIVILEGES ON SCHEMA [SchemaName] TO [PowerUserRole];
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA [SchemaName] TO [PowerUserRole];
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA [SchemaName] TO [PowerUserRole];
```

### Application Role

```sql
/*******************************************************************************
 * Application Role: Standard application access
 ******************************************************************************/

-- Create application role
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'AppRole')
BEGIN
    CREATE ROLE AppRole;
END
GO

-- Grant necessary permissions for application tables
GRANT SELECT, INSERT, UPDATE ON SCHEMA::[app] TO AppRole;
GRANT SELECT ON SCHEMA::[config] TO AppRole;  -- Read-only config
GRANT EXECUTE ON SCHEMA::[app] TO AppRole;     -- Execute stored procedures
GO

-- Deny delete on sensitive tables
DENY DELETE ON [app].[AuditLog] TO AppRole;
GO
```

### Reporting Role

```sql
/*******************************************************************************
 * Reporting Role: Read-only access to reporting objects
 ******************************************************************************/

CREATE ROLE ReportingRole;
GO

-- Read-only access to reporting schema
GRANT SELECT ON SCHEMA::[reporting] TO ReportingRole;

-- Access to specific views in other schemas
GRANT SELECT ON [dbo].[vw_SalesData] TO ReportingRole;
GRANT SELECT ON [dbo].[vw_CustomerData] TO ReportingRole;

-- Execute specific reporting procedures
GRANT EXECUTE ON [reporting].[sp_GenerateReport] TO ReportingRole;
GO
```

## Permission Hierarchy

```
Database-level permissions
├── Schema-level permissions
│   ├── Table permissions (SELECT, INSERT, UPDATE, DELETE)
│   ├── View permissions (SELECT)
│   ├── Procedure permissions (EXECUTE)
│   ├── Function permissions (EXECUTE)
│   └── Type permissions (EXECUTE, REFERENCES)
└── Column-level permissions (SELECT, UPDATE)
```

## Revoking Permissions

```sql
-- Revoke schema-level permission
REVOKE SELECT ON SCHEMA::[SchemaName] FROM [RoleName];
GO

-- Revoke object-level permission
REVOKE INSERT ON [SchemaName].[TableName] FROM [RoleName];
GO

-- Deny explicit permission (overrides grants)
DENY DELETE ON [SchemaName].[SensitiveTable] TO [RoleName];
GO
```

## Best Practices

1. **Use roles** - Grant permissions to roles, not individual users
2. **Principle of least privilege** - Grant minimum necessary permissions
3. **Schema-level grants** - Use schema-level grants when appropriate
4. **Document rationale** - Explain why specific permissions are granted
5. **Regular audits** - Periodically review and audit permissions
6. **Separate environments** - Different permissions for dev/test/prod
7. **Application accounts** - Use dedicated accounts with limited permissions
8. **Avoid sa/postgres** - Don't use superuser accounts for applications
9. **Test thoroughly** - Verify permissions work as expected
10. **Version control** - Track permission changes in source control
11. **Deployment scripts** - Include grants in deployment automation
12. **Monitoring** - Monitor for permission-related errors in production
