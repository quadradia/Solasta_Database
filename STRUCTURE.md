# Database Structure Organization

This repository follows a standardized structure for organizing database objects by type and schema.

## Directory Structure

```
Solasta_Database/
├── Schemas/              # Schema definitions
│   └── <SchemaName>/
│       └── schema.sql    # Schema creation script
├── Tables/               # Table definitions
│   └── <SchemaName>/
│       └── <TableName>.sql
├── Views/                # View definitions
│   └── <SchemaName>/
│       └── <ViewName>.sql
├── Functions/            # User-defined functions
│   └── <SchemaName>/
│       └── <FunctionName>.sql
├── Procedures/           # Stored procedures
│   └── <SchemaName>/
│       └── <ProcedureName>.sql
├── Triggers/             # Trigger definitions
│   └── <SchemaName>/
│       └── <TriggerName>.sql
├── Indexes/              # Index definitions
│   └── <SchemaName>/
│       └── <IndexName>.sql
├── Constraints/          # Constraint definitions
│   └── <SchemaName>/
│       └── <ConstraintName>.sql
├── Sequences/            # Sequence definitions
│   └── <SchemaName>/
│       └── <SequenceName>.sql
├── Types/                # User-defined types
│   └── <SchemaName>/
│       └── <TypeName>.sql
├── Grants/               # Permission grants
│   └── <SchemaName>/
│       └── <GrantName>.sql
├── Data/                 # Static/seed data
│   └── <SchemaName>/
│       └── <TableName>_data.sql
└── Scripts/              # Utility and deployment scripts
    ├── deploy/           # Deployment scripts
    └── rollback/         # Rollback scripts
```

## Naming Conventions

### File Naming
- Use PascalCase or snake_case consistently
- Include schema name when beneficial for clarity
- Use descriptive names that reflect the object's purpose

### SQL Object Naming
- **Schemas**: `SchemaName`
- **Tables**: `SchemaName.TableName`
- **Views**: `SchemaName.vw_ViewName` or `SchemaName.ViewName`
- **Functions**: `SchemaName.fn_FunctionName` or `SchemaName.FunctionName`
- **Procedures**: `SchemaName.sp_ProcedureName` or `SchemaName.ProcedureName`
- **Triggers**: `SchemaName.tr_TriggerName` or `SchemaName.TriggerName`

## File Templates

Each SQL file should follow this structure:

```sql
/*******************************************************************************
 * Object Type: [Table|View|Function|Procedure|Trigger|etc.]
 * Schema: [SchemaName]
 * Name: [ObjectName]
 * Description: [Brief description of the object's purpose]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD]
 ******************************************************************************/

-- Drop existing object if needed (use appropriate DROP statement)
-- DROP [OBJECT_TYPE] IF EXISTS [SchemaName].[ObjectName];

-- Create object
CREATE [OBJECT_TYPE] [SchemaName].[ObjectName]
...
GO  -- Use GO or appropriate delimiter for your DBMS
```

## Usage Guidelines

### Creating New Objects
1. Identify the object type (Table, View, Function, etc.)
2. Determine the schema the object belongs to
3. Navigate to the appropriate folder: `<ObjectType>/<SchemaName>/`
4. Create a new `.sql` file with a descriptive name
5. Use the file template above
6. Include appropriate DROP statements for idempotency

### Deploying Scripts
1. Execute schema creation scripts first (`Schemas/`)
2. Execute in dependency order:
   - Types
   - Tables
   - Indexes
   - Constraints
   - Sequences
   - Views
   - Functions
   - Procedures
   - Triggers
   - Grants
   - Data (seed data)

### Best Practices
- **Idempotent Scripts**: Each script should be runnable multiple times
- **Dependencies**: Document dependencies in script headers
- **Testing**: Test scripts in a development environment first
- **Version Control**: Commit related changes together
- **Documentation**: Keep inline comments clear and concise
- **Transactions**: Wrap DDL in transactions where supported

## Common Schemas

Typical schema organization might include:
- `dbo` - Default schema (SQL Server)
- `public` - Default schema (PostgreSQL)
- `app` - Application-specific objects
- `config` - Configuration tables
- `audit` - Audit logging objects
- `reporting` - Reporting views and procedures
- `security` - Security-related objects

## Deployment Scripts

The `Scripts/` folder contains:
- **deploy/**: Scripts for deploying changes (numbered for order)
- **rollback/**: Scripts for rolling back changes

Example:
```
Scripts/
├── deploy/
│   ├── 001_initial_schema.sql
│   ├── 002_add_user_tables.sql
│   └── 003_add_audit_triggers.sql
└── rollback/
    ├── 001_initial_schema.sql
    ├── 002_add_user_tables.sql
    └── 003_add_audit_triggers.sql
```

## Contributing

When adding new database objects:
1. Follow the directory structure
2. Use consistent naming conventions
3. Include proper documentation in file headers
4. Test scripts before committing
5. Update this documentation if adding new patterns
