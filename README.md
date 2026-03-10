# Solasta Database

Welcome to the Solasta Database repository! This repository contains all database objects organized in a structured, maintainable format.

## Overview

This database repository follows a standardized organization pattern where all database objects (tables, views, stored procedures, functions, triggers, etc.) are organized by:
1. **Object Type** - Each type has its own top-level directory
2. **Schema** - Within each type, objects are further organized by schema

## Directory Structure

```
Solasta_Database/
├── Schemas/          # Schema definitions
├── Tables/           # Table definitions
├── Views/            # View definitions
├── Functions/        # User-defined functions
├── Procedures/       # Stored procedures (SPROCs)
├── Triggers/         # Trigger definitions
├── Indexes/          # Index definitions
├── Constraints/      # Constraint definitions
├── Sequences/        # Sequence definitions
├── Types/            # User-defined types
├── Grants/           # Permission grants
├── Data/             # Static/seed data
└── Scripts/          # Deployment and utility scripts
    ├── deploy/       # Deployment scripts
    └── rollback/     # Rollback scripts
```

## Quick Start

### For New Users

1. Read the [STRUCTURE.md](STRUCTURE.md) file for detailed information about the repository organization
2. Review the README.md file in each directory for specific guidance and templates
3. Follow the naming conventions and templates provided

### Adding New Database Objects

1. Identify the object type (Table, View, Procedure, etc.)
2. Navigate to the appropriate directory (e.g., `Tables/`, `Procedures/`)
3. Choose or create the appropriate schema subdirectory
4. Create a new `.sql` file using the template from that directory's README
5. Follow the naming conventions and include proper documentation

### Example Workflow

```bash
# Adding a new table to the 'app' schema
cd Tables/app/
# Create Users.sql with table definition

# Adding a stored procedure to the 'dbo' schema
cd Procedures/dbo/
# Create sp_GetUserById.sql with procedure definition

# Adding seed data for a lookup table
cd Data/dbo/
# Create Countries_data.sql with seed data
```

## 🚀 Development Resources

**New to this project?** Start with the **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** - your comprehensive index to all resources, workflows, and tools.

### Essential Documentation
- **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** - 📖 Complete resource index with workflows, troubleshooting, and training path
- **[DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md)** - ⚖️ Core principles and governance (14 articles)
- **[QUICKSTART.md](QUICKSTART.md)** - ⚡ Step-by-step guides for common tasks
- **[STRUCTURE.md](STRUCTURE.md)** - 🏗️ Repository organization and file templates

### AI & Automation Tools
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** - 🤖 GitHub Copilot configuration for this project
- **[COPILOT_PROMPTS.md](COPILOT_PROMPTS.md)** - 💬 Ready-to-use prompts, snippets, and helper queries
- **[Scripts/db-helper.ps1](Scripts/db-helper.ps1)** - 🔧 PowerShell automation for migrations and object creation
- **[.vscode/mssql.code-snippets](.vscode/mssql.code-snippets)** - ⚡ 15 VS Code snippets (type prefix + Tab)

### CI/CD & Quality
- **[CICD_GUIDE.md](CICD_GUIDE.md)** - 🔄 GitHub Actions workflows and automation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - 🤝 Contribution standards and PR process
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 📋 Quick lookup and cheat sheets

### Templates
- **[TEMPLATES.sql](TEMPLATES.sql)** - 📝 Complete template library for all object types
- **[Migrations/TEMPLATE_Migration.sql](Migrations/TEMPLATE_Migration.sql)** - 🔄 Migration file template

## Common Schemas

This repository includes the following default schemas:

- **dbo** - Default schema (SQL Server) / public (PostgreSQL)
- **app** - Application-specific objects
- **config** - Configuration tables and settings
- **audit** - Audit logging objects
- **reporting** - Reporting views and procedures

You can add additional schemas as needed for your database.

## Documentation

- **[STRUCTURE.md](STRUCTURE.md)** - Comprehensive guide to the repository structure, naming conventions, and best practices
- **Directory READMEs** - Each object type directory contains a README with templates and examples:
  - [Schemas/README.md](Schemas/README.md)
  - [Tables/README.md](Tables/README.md)
  - [Views/README.md](Views/README.md)
  - [Functions/README.md](Functions/README.md)
  - [Procedures/README.md](Procedures/README.md)
  - [Triggers/README.md](Triggers/README.md)
  - [Indexes/README.md](Indexes/README.md)
  - [Constraints/README.md](Constraints/README.md)
  - [Sequences/README.md](Sequences/README.md)
  - [Types/README.md](Types/README.md)
  - [Grants/README.md](Grants/README.md)
  - [Data/README.md](Data/README.md)
  - [Scripts/README.md](Scripts/README.md)

## Deployment

### Recommended Deployment Order

When deploying database objects, follow this order to respect dependencies:

1. **Schemas** - Create all schemas first
2. **Types** - User-defined types
3. **Tables** - Table structures
4. **Indexes** - Table indexes (if not in table definitions)
5. **Constraints** - Foreign keys and constraints
6. **Sequences** - Sequence objects
7. **Views** - View definitions
8. **Functions** - User-defined functions
9. **Procedures** - Stored procedures
10. **Triggers** - Trigger definitions
11. **Grants** - Permissions and security
12. **Data** - Seed and reference data

### Using Deployment Scripts

For complex deployments, use numbered scripts in the `Scripts/deploy/` directory:

```bash
# Execute deployment scripts in order
sqlcmd -S server -d database -i Scripts/deploy/001_initial_schema.sql
sqlcmd -S server -d database -i Scripts/deploy/002_add_tables.sql
# ... etc
```

## Best Practices

1. **Idempotent Scripts** - All scripts should be safe to run multiple times
2. **Documentation** - Include headers with metadata in all SQL files
3. **Testing** - Test all scripts in a development environment first
4. **Version Control** - Commit related changes together with clear commit messages
5. **Dependencies** - Document dependencies in script headers
6. **Naming Conventions** - Follow established naming patterns
7. **Code Review** - Have database changes reviewed before deployment

## Contributing

When contributing to this repository:

1. Follow the established directory structure
2. Use the templates provided in each directory's README
3. Include proper documentation in file headers
4. Test your scripts thoroughly
5. Ensure scripts are idempotent (can run multiple times)
6. Follow naming conventions
7. Update documentation when adding new patterns

## Support

For questions or issues with the database structure:

1. Review the documentation in [STRUCTURE.md](STRUCTURE.md)
2. Check the relevant directory's README
3. Contact the database team

## License

[Add your license information here]
# Solasta Database Source Control

This repository is for designing and source controlling all database changes to the Solasta Lighting backend MS SQL Database.

## Repository Structure

```
Solasta_Database/
├── Schema/                      # Database schema objects
│   ├── Tables/                  # Table definitions
│   ├── Views/                   # View definitions
│   ├── StoredProcedures/        # Stored procedure definitions
│   └── Functions/               # Function definitions (scalar and table-valued)
├── Migrations/                  # Versioned migration scripts
├── Scripts/                     # Utility scripts
│   ├── Deployment/              # Deployment helper scripts
│   └── Rollback/                # Rollback scripts for migrations
└── README.md                    # This file
```

## Naming Conventions

### Migration Scripts
- **Format**: `YYYYMMDD_HHMM_DescriptionOfChange.sql`
- **Example**: `20260107_1430_CreateUserTable.sql`
- Each migration should be idempotent where possible
- Include both UP and DOWN (rollback) logic when applicable

### Schema Objects
- **Tables**: `TableName.sql` (PascalCase)
- **Views**: `vw_ViewName.sql` (prefix with `vw_`)
- **Stored Procedures**: `sp_ProcedureName.sql` or `usp_ProcedureName.sql`
- **Functions**: `fn_FunctionName.sql` (prefix with `fn_`)

## Migration Guidelines

### Creating a New Migration

1. **Create the migration file** in the `Migrations/` folder following the naming convention
2. **Include metadata** at the top of each migration:
   ```sql
   /*
   Migration: YYYYMMDD_HHMM_DescriptionOfChange
   Author: Your Name
   Date: YYYY-MM-DD
   Description: Brief description of what this migration does
   Dependencies: List any dependent migrations
   */
   ```

3. **Write idempotent scripts** using IF EXISTS/IF NOT EXISTS checks:
   ```sql
   IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TableName')
   BEGIN
       CREATE TABLE TableName (...)
   END
   ```

4. **Include rollback logic** when possible as comments or in a separate rollback script

### Migration Best Practices

- **One logical change per migration** - Don't mix unrelated changes
- **Test locally first** - Always test migrations on a local database
- **Use transactions** - Wrap DDL statements in transactions where supported
- **Add appropriate indexes** - Consider performance implications
- **Document breaking changes** - Clearly mark any breaking changes
- **Backward compatibility** - Strive for backward-compatible changes when possible

## Deployment Process

1. **Review Changes**: All database changes must be reviewed via Pull Request
2. **Approval**: Changes require approval from database administrators
3. **Testing**: Test migrations on development environment first
4. **Staging**: Deploy to staging environment
5. **Production**: Deploy to production during maintenance window

### Manual Deployment Steps

```sql
-- 1. Backup the database
BACKUP DATABASE [SolastaDB] TO DISK = 'path_to_backup'

-- 2. Run migration scripts in order
-- Execute each migration file in chronological order

-- 3. Verify deployment
-- Run verification queries to ensure changes applied correctly

-- 4. Update schema version tracking
-- Record the migration in the schema version table
```

## Schema Version Tracking

The database includes a schema version tracking table that records all applied migrations. This ensures migrations are applied in order and not repeated.

See `Migrations/00000000_0000_CreateSchemaVersionTable.sql` for the version tracking table definition.

## Working with Schema Objects

### Tables
Store complete CREATE TABLE statements in `Schema/Tables/`. When modifying a table:
1. Create a migration script in `Migrations/` with the ALTER statement
2. Update the table definition file in `Schema/Tables/` to reflect the new structure

### Views, Stored Procedures, and Functions
Store CREATE OR ALTER (or DROP/CREATE) statements for these objects. These can be re-run to update the objects.

## Rollback Procedures

If a migration needs to be rolled back:
1. Check if a rollback script exists in `Scripts/Rollback/`
2. Review the migration script for any DOWN/rollback logic
3. Create and test a rollback script if one doesn't exist
4. Execute rollback during maintenance window
5. Update schema version table to reflect rollback

## Contributing

1. Create a feature branch for your database changes
2. Add migration scripts following the naming conventions
3. Update schema object files as needed
4. Test changes locally
5. Create a Pull Request with detailed description
6. Address review comments
7. Merge after approval

## Tools and Resources

- **SQL Server Management Studio (SSMS)**: Primary tool for development
- **Azure Data Studio**: Alternative cross-platform tool
- **sqlcmd**: Command-line tool for script execution
- **Git**: Version control system

## Support

For questions or issues with database changes, please contact the Solasta Lighting development team.
