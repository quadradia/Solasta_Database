# Development Resources Index

This file serves as a central guide to all development resources, tools, and documentation available for the Solasta Database project.

---

## 📚 Documentation

### Getting Started
| Document | Purpose | When to Use |
|----------|---------|-------------|
| [README.md](README.md) | Repository overview and quick start | First time using the repository |
| [QUICKSTART.md](QUICKSTART.md) | Step-by-step guide for common tasks | Making your first database change |
| [STRUCTURE.md](STRUCTURE.md) | Detailed structure and organization | Understanding the repository layout |
| [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md) | Core principles and standards | Understanding project rules and philosophy |

### Reference Documentation
| Document | Purpose | When to Use |
|----------|---------|-------------|
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick lookup for common tasks | Need a quick reminder of file patterns |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines | Preparing to submit changes |
| [TEMPLATES.sql](TEMPLATES.sql) | SQL code templates | Creating new database objects |
| [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md) | Ready-to-use Copilot prompts | Working with GitHub Copilot |

### Advanced Topics
| Document | Purpose | When to Use |
|----------|---------|-------------|
| [CICD_GUIDE.md](CICD_GUIDE.md) | CI/CD and automation setup | Setting up automated workflows |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | GitHub Copilot configuration | Customizing Copilot for this project |

---

## 🛠️ Tools and Scripts

### PowerShell Helper Script
**Location**: `Scripts/db-helper.ps1`

**Capabilities**:
- Create new migration files
- Create new table/procedure/view files
- Validate migration files
- List all migrations
- Generate timestamps

**Usage Examples**:
```powershell
# Create a new migration
.\Scripts\db-helper.ps1 -NewMigration -Description "CreateUsersTable"

# Create a new table in dbo schema
.\Scripts\db-helper.ps1 -NewTable -Schema dbo -ObjectName Users

# Validate all migrations
.\Scripts\db-helper.ps1 -Validate

# List all migrations
.\Scripts\db-helper.ps1 -ListMigrations

# Generate UTC timestamp
.\Scripts\db-helper.ps1 -GenerateTimestamp
```

### VS Code Snippets
**Location**: `.vscode/mssql.code-snippets`

**Available Snippets**:
- `sql-table` - Complete table template
- `sql-proc` - Stored procedure template
- `sql-view` - View template
- `sql-migration` - Migration template
- `sql-func-scalar` - Scalar function
- `sql-func-table` - Table-valued function
- `sql-trigger` - Trigger template
- `sql-index` - Index definition
- `sql-merge` - MERGE statement
- `sql-try` - Try-catch block
- `sql-audit` - Audit columns
- `sql-softdelete` - Soft delete columns
- `sql-fk` - Foreign key constraint
- `sql-check` - Check constraint

**How to Use**:
1. Open a `.sql` file in VS Code
2. Type the prefix (e.g., `sql-table`)
3. Press Tab to expand the snippet
4. Fill in the placeholders

---

## 📁 Directory Structure Quick Reference

```
Solasta_Database/
├── .github/
│   └── copilot-instructions.md    # GitHub Copilot configuration
├── .vscode/
│   └── mssql.code-snippets        # VS Code SQL snippets
├── Migrations/                     # Version-controlled migrations
│   ├── 00000000_0000_CreateSchemaVersionTable.sql
│   ├── TEMPLATE_Migration.sql     # Migration template
│   └── [Timestamp]_[Description].sql
├── Tables/                         # Table definitions
│   ├── dbo/
│   ├── app/
│   ├── config/
│   ├── audit/
│   └── reporting/
├── Views/                          # View definitions
├── Procedures/                     # Stored procedures
├── Functions/                      # User-defined functions
├── Triggers/                       # Trigger definitions
├── Indexes/                        # Index definitions
├── Constraints/                    # Constraint definitions
├── Sequences/                      # Sequence objects
├── Types/                          # User-defined types
├── Grants/                         # Permission grants
├── Data/                           # Seed/reference data
├── Schemas/                        # Schema definitions
├── Scripts/
│   ├── db-helper.ps1              # PowerShell helper script
│   ├── Deployment/                # Deployment helpers
│   └── Rollback/                  # Rollback helpers
├── Tests/                          # Test scripts (future)
├── README.md                       # Main documentation
├── STRUCTURE.md                    # Structure guide
├── QUICKSTART.md                   # Quick start guide
├── QUICK_REFERENCE.md              # Quick reference
├── CONTRIBUTING.md                 # Contribution guidelines
├── TEMPLATES.sql                   # SQL templates
├── DATABASE_CONSTITUTION.md        # Core principles
├── COPILOT_PROMPTS.md             # Copilot prompts
├── CICD_GUIDE.md                  # CI/CD guide
└── DEVELOPMENT_GUIDE.md           # This file
```

---

## 🎯 Common Workflows

### Creating a New Table

**Steps**:
1. **Create migration file**:
   ```powershell
   .\Scripts\db-helper.ps1 -NewMigration -Description "CreateProductsTable"
   ```

2. **Create table schema file**:
   ```powershell
   .\Scripts\db-helper.ps1 -NewTable -Schema dbo -ObjectName Products
   ```

3. **Edit both files** with your table definition

4. **Test locally** - Run migration on local database

5. **Validate**:
   ```powershell
   .\Scripts\db-helper.ps1 -Validate
   ```

6. **Commit and push** to create Pull Request

**Resources**:
- [Tables/README.md](Tables/README.md) - Table template and guidelines
- [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md#creating-tables) - Copilot prompts for tables
- [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md#article-iii-naming-conventions) - Naming conventions

---

### Creating a Stored Procedure

**Steps**:
1. **Create procedure file**:
   ```powershell
   .\Scripts\db-helper.ps1 -NewProcedure -Schema dbo -ObjectName sp_GetProduct
   ```

2. **Edit the procedure** with your logic

3. **Test locally**

4. **Optional: Create migration** if this is a new procedure that needs version tracking

5. **Validate and commit**

**Resources**:
- [Procedures/README.md](Procedures/README.md) - Procedure template
- [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md#creating-stored-procedures) - Copilot prompts
- VS Code snippet: `sql-proc`

---

### Modifying an Existing Table

**Steps**:
1. **Create migration file**:
   ```powershell
   .\Scripts\db-helper.ps1 -NewMigration -Description "AddEmailToUsers"
   ```

2. **Edit migration** with ALTER TABLE statements

3. **Update table schema file** in `Tables/[schema]/[TableName].sql` to reflect new structure

4. **Test migration locally** twice (for idempotency)

5. **Validate and commit**

**Important**: Never modify existing migrations - always create a new one!

**Resources**:
- [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md#section-2-immutability-of-history) - Immutability principle
- [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md#migration-helpers) - Migration helpers

---

### Creating a View

**Steps**:
1. **Create view file**:
   ```powershell
   .\Scripts\db-helper.ps1 -NewView -Schema reporting -ObjectName vw_ProductSales
   ```

2. **Edit the view** with your SELECT statement

3. **Test the view** locally

4. **Optional: Create migration** for version tracking

5. **Commit changes**

**Resources**:
- [Views/README.md](Views/README.md) - View template
- VS Code snippet: `sql-view`

---

### Seeding Reference Data

**Steps**:
1. **Create data file** in `Data/[schema]/[TableName]_data.sql`

2. **Use MERGE statement** for idempotency (see `sql-merge` snippet)

3. **Optional: Create migration** if this needs to be deployed

4. **Test locally**

5. **Commit changes**

**Resources**:
- [Data/README.md](Data/README.md) - Data seeding guidelines
- VS Code snippet: `sql-merge`
- [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md#data-seeding) - Data seeding prompts

---

## 🤖 GitHub Copilot Integration

### Using Copilot Chat

**Best Prompts**:

```
Create a Users table in the dbo schema with email, password hash, and audit columns

Generate a stored procedure to get user by email with proper error handling

Create a view that joins Orders and Users tables, filtering active records only

Generate a migration to add an index on Users.Email column

Create seed data for a Countries lookup table using MERGE statement
```

### Copilot Instructions

The file `.github/copilot-instructions.md` configures Copilot to:
- Follow repository naming conventions
- Generate proper headers
- Use correct file structure
- Apply best practices automatically
- Suggest migrations when appropriate

### Quick Tips
- Type `sql-` and Tab to see all available snippets
- Use `/explain` in Copilot Chat to understand SQL code
- Use `/fix` to get suggestions for fixing issues
- Use `/optimize` for performance improvements

---

## ✅ Quality Checklists

### Before Committing
- [ ] Migration has proper naming: `YYYYMMDD_HHMM_Description.sql`
- [ ] Migration includes header comment
- [ ] Migration wrapped in transaction with TRY...CATCH
- [ ] Migration checks SchemaVersion table
- [ ] Migration includes rollback instructions
- [ ] Schema files updated (if applicable)
- [ ] Tested locally at least twice
- [ ] No hardcoded credentials or sensitive data
- [ ] Follows naming conventions
- [ ] Includes proper documentation

### Before Pull Request
- [ ] All tests pass locally
- [ ] Validated using `.\Scripts\db-helper.ps1 -Validate`
- [ ] Clear description of changes
- [ ] Breaking changes documented
- [ ] Dependencies noted
- [ ] Rollback strategy described

### Before Production Deployment
- [ ] Tested in staging environment
- [ ] Database backup created
- [ ] Maintenance window scheduled
- [ ] Rollback plan ready
- [ ] Team notified
- [ ] Performance impact assessed

---

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### Migration Already Applied Error
**Problem**: Migration marked as applied but changes not in database

**Solution**:
```sql
-- Check SchemaVersion table
SELECT * FROM [dbo].[SchemaVersion] 
WHERE [MigrationName] = 'YourMigration';

-- If needed, delete the record to re-run
DELETE FROM [dbo].[SchemaVersion] 
WHERE [MigrationName] = 'YourMigration';
```

#### Duplicate Migration Timestamps
**Problem**: Two developers created migrations at the same time

**Solution**:
1. Rename one migration file with a later timestamp
2. Update the migration name inside the file
3. Test both migrations in order

#### Invalid File Name Error
**Problem**: Migration file doesn't follow naming convention

**Solution**: Rename to `YYYYMMDD_HHMM_Description.sql` format

#### Missing Template Files
**Problem**: Template files not found

**Solution**: Check that you're in the repository root directory

---

## 📖 Learning Resources

### SQL Server Documentation
- [T-SQL Reference](https://docs.microsoft.com/sql/t-sql/)
- [Database Design Best Practices](https://docs.microsoft.com/sql/relational-databases/)
- [SQL Server Performance Tuning](https://docs.microsoft.com/sql/relational-databases/performance/)

### Best Practices
- [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md) - Project standards
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

### Templates and Examples
- [TEMPLATES.sql](TEMPLATES.sql) - Code templates
- Directory README files - Specific examples for each object type

---

## 🎓 Training Path for New Team Members

### Day 1: Understanding the Structure
1. Read [README.md](README.md)
2. Read [STRUCTURE.md](STRUCTURE.md)
3. Read [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md)
4. Explore the directory structure

### Day 2: Making Your First Change
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Follow along with creating a simple table
3. Create a migration locally
4. Test the migration
5. Review [CONTRIBUTING.md](CONTRIBUTING.md)

### Day 3: Tools and Automation
1. Explore [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md)
2. Try using `db-helper.ps1` script
3. Set up VS Code snippets
4. Practice with different object types

### Week 2: Advanced Topics
1. Review [CICD_GUIDE.md](CICD_GUIDE.md)
2. Learn about quality gates
3. Practice writing complex migrations
4. Review existing procedures and views

---

## 📞 Getting Help

### First Steps
1. Check this guide
2. Check the specific README for the object type
3. Review [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
4. Ask GitHub Copilot

### Where to Look

| Question Type | Resource |
|--------------|----------|
| "How do I create a...?" | [QUICKSTART.md](QUICKSTART.md) or [QUICK_REFERENCE.md](QUICK_REFERENCE.md) |
| "Where does this go?" | [STRUCTURE.md](STRUCTURE.md) |
| "What's the naming convention?" | [DATABASE_CONSTITUTION.md](DATABASE_CONSTITUTION.md) |
| "How do I use Copilot for...?" | [COPILOT_PROMPTS.md](COPILOT_PROMPTS.md) |
| "How do I set up CI/CD?" | [CICD_GUIDE.md](CICD_GUIDE.md) |
| "What's the template for...?" | [TEMPLATES.sql](TEMPLATES.sql) or object type README |

---

## 🚀 Quick Command Reference

### PowerShell Helper
```powershell
# Create new migration
.\Scripts\db-helper.ps1 -NewMigration -Description "YourDescription"

# Create new table
.\Scripts\db-helper.ps1 -NewTable -Schema dbo -ObjectName TableName

# Create new procedure
.\Scripts\db-helper.ps1 -NewProcedure -Schema dbo -ObjectName sp_ProcName

# Validate migrations
.\Scripts\db-helper.ps1 -Validate

# List migrations
.\Scripts\db-helper.ps1 -ListMigrations

# Get timestamp
.\Scripts\db-helper.ps1 -GenerateTimestamp
```

### VS Code Snippets
| Prefix | Creates |
|--------|---------|
| `sql-table` | Table template |
| `sql-proc` | Stored procedure template |
| `sql-view` | View template |
| `sql-migration` | Migration template |
| `sql-func-scalar` | Scalar function |
| `sql-func-table` | Table-valued function |
| `sql-merge` | MERGE statement |
| `sql-try` | Try-catch block |

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-09 | Initial development guide created |

---

**Remember**: When in doubt, follow the patterns you see in existing files and ask GitHub Copilot for help!

**Happy Database Development! 🎉**
