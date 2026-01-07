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
