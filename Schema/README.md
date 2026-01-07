# Schema Objects

This directory contains the current state definitions of all database schema objects. These files serve as documentation and can be used to recreate objects.

## Purpose

The schema files represent the **current state** of database objects, while the `Migrations/` folder contains the **history of changes**. Think of it this way:

- **Migrations** = Version history (how we got here)
- **Schema** = Current state (what we have now)

## Directory Structure

- **Tables/** - Complete CREATE TABLE statements for all tables
- **Views/** - CREATE OR ALTER statements for views
- **StoredProcedures/** - CREATE OR ALTER statements for stored procedures
- **Functions/** - CREATE OR ALTER statements for functions (scalar and table-valued)

## When to Update These Files

### Tables
Update table schema files when:
- Creating a new table (create a migration + schema file)
- Altering a table structure (create a migration, update schema file)

The table schema file should always reflect the current table structure after all migrations.

### Views, Stored Procedures, Functions
Update these files when:
- Creating a new object (add the file)
- Modifying an existing object (update the file)

These files can typically be re-run to update the object (using CREATE OR ALTER or DROP/CREATE).

## Example Workflow

### Adding a New Table
1. Create migration: `Migrations/20260107_1500_CreateProductsTable.sql`
2. Create schema file: `Schema/Tables/Products.sql`
3. Both files contain the CREATE TABLE statement
4. Commit both files together

### Modifying a Table
1. Create migration: `Migrations/20260107_1600_AddDescriptionToProducts.sql`
   - Contains: `ALTER TABLE Products ADD Description NVARCHAR(MAX)`
2. Update schema file: `Schema/Tables/Products.sql`
   - Update CREATE TABLE to include Description column
3. Commit both files together

### Updating a Stored Procedure
1. Update the file: `Schema/StoredProcedures/usp_GetProducts.sql`
2. Execute it in the database (it will CREATE OR ALTER)
3. Commit the file
4. No migration needed (unless changing signature in a breaking way)

## Templates

Use the TEMPLATE files as starting points:
- `TEMPLATE_Table.sql` - For new tables
- `TEMPLATE_View.sql` - For new views
- `TEMPLATE_StoredProcedure.sql` - For new stored procedures
- `TEMPLATE_Function.sql` - For new functions

## Best Practices

1. **Keep files synchronized** - Schema files should match the database after migrations
2. **Include documentation** - Use comments and extended properties
3. **Use consistent formatting** - Follow the template structure
4. **Test scripts** - Ensure schema files can be executed successfully
5. **One object per file** - Don't combine multiple objects in one file

## Notes

- Schema files are for documentation and reference
- They can be used to recreate the database from scratch
- Always create migrations for structural changes
- Schema files should be the "source of truth" for current state
