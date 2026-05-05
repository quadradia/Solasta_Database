# Solasta Database — Copilot Constitution

> **Purpose**: These are binding rules that GitHub Copilot must follow at all times when generating, suggesting, or reviewing code in this repository. These rules are non-negotiable and take precedence over general coding patterns.

---

## Article I: Inviolable Principles

You MUST obey these principles in every code suggestion. No exceptions.

### 1. Single Source of Truth
- `Migrations/` is the ultimate source of truth for database evolution
- Schema files in object directories (Tables/, Views/, etc.) represent current state documentation
- When asked about database history, refer to migrations

### 2. Immutability of History
- NEVER suggest modifying an existing migration file
- ALWAYS create a new migration with a later timestamp for any change
- If a user asks to "fix" a migration, create a corrective migration instead

### 3. Idempotency
- Every script you generate MUST be safe to run multiple times
- ALWAYS include existence checks: `IF NOT EXISTS`, `IF OBJECT_ID(...) IS NOT NULL`
- Data scripts MUST use `MERGE` or conditional `INSERT` — never raw INSERT without checks

### 4. Atomicity
- Each migration represents exactly ONE cohesive logical change
- ALWAYS wrap migration changes in `BEGIN TRANSACTION` with `TRY...CATCH`
- If any part fails, the entire migration MUST roll back

### 5. Documentation First
- NEVER generate a SQL file without a complete header comment block
- ALWAYS include rollback instructions in migration files
- ALWAYS explain complex logic with inline comments

---

## Article II: Absolute Prohibitions

You must NEVER generate code that does any of the following:

### Security Violations
- ❌ Hard-coded passwords, credentials, API keys, or connection strings
- ❌ Hard-coded server names or database names
- ❌ Dynamic SQL without `sp_executesql` and parameterization
- ❌ Unsanitized user input in any SQL construction
- ❌ `GRANT CONTROL` or `GRANT DBO` permissions
- ❌ Personal identifiable information (PII) as sample data

### Code Quality Violations
- ❌ `SELECT *` in any production view, procedure, or function
- ❌ Deprecated data types: `TEXT`, `NTEXT`, `IMAGE`, `DATETIME` (use `DATETIME2`)
- ❌ Objects without schema qualification (always use `[schema].[Object]`)
- ❌ Missing `SET NOCOUNT ON` in stored procedures
- ❌ Procedures without `TRY...CATCH` error handling
- ❌ Data modifications without transaction wrapping
- ❌ Cursors without documented justification
- ❌ `NOLOCK` hints without documented justification
- ❌ Missing `NULL`/`NOT NULL` specification on columns

### Structural Violations
- ❌ Multiple unrelated changes in a single migration
- ❌ Multi-object files (one object per file, except related data inserts)
- ❌ Files placed in wrong directories (Tables go in Tables/, not Procedures/)
- ❌ Missing SchemaVersion check in migrations
- ❌ Missing SchemaVersion insert at end of migrations
- ❌ Migration files without rollback instructions

---

## Article III: Mandatory Code Patterns

### Every SQL File Must Begin With
```sql
/*******************************************************************************
 * Object Type: [Type]
 * Schema: [SchemaName]
 * Name: [ObjectName]
 * Description: [Purpose and behavior]
 * Dependencies: [List dependent objects]
 * Author: [Name]
 * Created: [YYYY-MM-DD]
 * Modified: [YYYY-MM-DD] - [Brief change description]
 ******************************************************************************/
```

### Every Migration Must Include
1. Header comment with migration name, author, date, description, dependencies
2. `BEGIN TRANSACTION` wrapper
3. `TRY...CATCH` block
4. SchemaVersion existence check (skip if already applied)
5. Existence checks for all DDL (`IF NOT EXISTS`, `IF OBJECT_ID`)
6. `INSERT INTO [dbo].[SchemaVersion]` on success
7. `ROLLBACK TRANSACTION` in CATCH block
8. Rollback script in trailing comment block

### Every Stored Procedure Must Include
1. Complete header with parameters, return values, usage example
2. `SET NOCOUNT ON`
3. `TRY...CATCH` error handling
4. Transaction wrapping for any data modifications
5. Return codes: `0` for success, `-1` for error

### Every Table Must Include
1. Explicit `NULL` or `NOT NULL` on all columns
2. Named primary key constraint: `PK_[TableName]`
3. Named foreign key constraints: `FK_[TableName]_[ReferencedTable]`
4. Named default constraints: `DF_[TableName]_[ColumnName]`
5. `GO` statement at end

---

## Article IV: Data Type Constitution

These data type rules are law. Do not deviate.

| Use This | Not This | Why |
|----------|----------|-----|
| `NVARCHAR` | `VARCHAR` | Unicode support required |
| `DATETIME2` | `DATETIME` | Higher precision, wider range |
| `DECIMAL(19,4)` | `FLOAT` for money | Exact precision for currency |
| `BIT` | `INT` for flags | Proper boolean representation |
| `INT IDENTITY(1,1)` | `UNIQUEIDENTIFIER` for PKs | Unless justified by design |
| `NVARCHAR(MAX)` | `TEXT`, `NTEXT` | Deprecated types forbidden |
| `VARBINARY(MAX)` | `IMAGE` | Deprecated type forbidden |

---

## Article V: Naming Law

### File Names — Enforce Exactly
| Object | Pattern | Example |
|--------|---------|---------|
| Migration | `YYYYMMDD_HHMM_Description.sql` | `20260309_1445_AddUsersTable.sql` |
| Table | `TableName.sql` | `Users.sql` |
| View | `vw_ViewName.sql` | `vw_ActiveUsers.sql` |
| Procedure | `sp_ProcName.sql` | `sp_GetUserById.sql` |
| Function | `fn_FuncName.sql` | `fn_CalculateDiscount.sql` |
| Trigger | `tr_TableName_Event.sql` | `tr_Users_AfterInsert.sql` |
| Seed Data | `TableName_data.sql` | `Countries_data.sql` |

### SQL Object Names — Enforce Exactly
| Object | Pattern | Example |
|--------|---------|---------|
| Table | `[schema].[TableName]` | `[dbo].[Users]` |
| Primary Key | `PK_[TableName]` | `PK_Users` |
| Foreign Key | `FK_[ChildTable]_[ParentTable]` | `FK_Orders_Users` |
| Unique | `UQ_[TableName]_[Column]` | `UQ_Users_Email` |
| Check | `CK_[TableName]_[Column]` | `CK_Orders_Total` |
| Default | `DF_[TableName]_[Column]` | `DF_Users_CreatedDate` |
| Index | `IX_[TableName]_[Columns]` | `IX_Users_LastName` |
| View | `[schema].[vw_Name]` | `[reporting].[vw_MonthlySales]` |
| Procedure | `[schema].[sp_Name]` | `[app].[sp_GetUser]` |
| Function | `[schema].[fn_Name]` | `[dbo].[fn_GetAge]` |
| Trigger | `[schema].[tr_Table_Event]` | `[dbo].[tr_Users_AfterInsert]` |

### Column Names — Enforce Always
- PascalCase: `FirstName`, `CreatedDate`, `IsActive`
- Primary keys: `Id` or `[TableName]Id`
- Foreign keys: Singularize the referenced table name, then append `Id`
  - Rule: remove a trailing `s` (or apply standard English singularization) from the table name, then append `Id`
  - Examples: `PoliticalTimeZones` → `PoliticalTimeZoneId` | `DealerTenantTypes` → `DealerTenantTypeId` | `Users` → `UserId`
  - Override only when the singular form is irregular or ambiguous — document the deviation in a comment
- Never abbreviate unless universally understood

---

## Article VI: File Placement Law

### Directory Mapping — No Exceptions
| Object Type | Directory | Subdirectory |
|------------|-----------|-------------|
| Schema definitions | `Schemas/` | `[schema]/` |
| Table definitions | `Tables/` | `[schema]/` |
| View definitions | `Views/` | `[schema]/` |
| Stored procedures | `Procedures/` | `[schema]/` |
| Functions | `Functions/` | `[schema]/` |
| Triggers | `Triggers/` | `[schema]/` |
| Indexes | `Indexes/` | `[schema]/` |
| Constraints | `Constraints/` | `[schema]/` |
| Sequences | `Sequences/` | `[schema]/` |
| User-defined types | `Types/` | `[schema]/` |
| Permissions | `Grants/` | `[schema]/` |
| Seed/reference data | `Data/` | `[schema]/` |
| Migrations | `Migrations/` | (flat) |
| Scripts | `Scripts/` | `deploy/` or `Rollback/` |

### Schema Subdirectories — Only These Five
| Schema | Purpose |
|--------|---------|
| `dbo` | Core business entities |
| `app` | Application-specific functionality |
| `config` | System configuration and settings |
| `audit` | Audit logging and tracking |
| `reporting` | Reporting views and procedures |

### When Creating Any Object, Always Create Two Files
1. **Migration file** in `Migrations/YYYYMMDD_HHMM_Description.sql`
2. **Schema file** in `[ObjectType]/[schema]/ObjectName.sql`

---

## Article VII: Deployment Order Constitution

When generating deployment scripts or suggesting execution order, ALWAYS follow this sequence:

```
1.  Schemas
2.  Types (User-defined)
3.  Tables
4.  Indexes
5.  Constraints (Foreign keys, checks)
6.  Sequences
7.  Views
8.  Functions
9.  Procedures
10. Triggers
11. Grants (Permissions)
12. Data (Seed/Reference)
```

Never suggest executing objects out of this dependency order.

---

## Article VIII: Audit Column Requirements

### Standard Audit Columns — Include in Most Tables
```sql
[CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
[CreatedBy] NVARCHAR(50) NULL,
[ModifiedDate] DATETIME2 NULL,
[ModifiedBy] NVARCHAR(50) NULL
```

### Soft Delete Columns — When Physical Deletion is Inappropriate
```sql
[IsDeleted] BIT NOT NULL DEFAULT 0,
[DeletedDate] DATETIME2 NULL,
[DeletedBy] NVARCHAR(50) NULL
```

When a user asks to create a business entity table, ALWAYS include audit columns unless explicitly told not to.

---

## Article IX: Error Handling Constitution

### Stored Procedures — Mandatory Pattern
```sql
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Business logic here

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -1;
    END CATCH
END
```

### Migrations — Mandatory Pattern
```sql
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = 'YYYYMMDD_HHMM_Description';

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion]
               WHERE [MigrationName] = @MigrationName)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Migration logic with existence checks

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (@MigrationName, 'Description');

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    RAISERROR(ERROR_MESSAGE(), 16, 1);
END CATCH
GO
```

---

## Article X: Response Protocol

When asked to create or modify database objects, you MUST follow this response protocol:

### Step 1: Determine Placement
- Identify object type → directory
- Identify schema → subdirectory
- Generate migration timestamp (UTC)

### Step 2: Generate Migration File
- Full migration with all constitutional requirements
- Place in `Migrations/YYYYMMDD_HHMM_Description.sql`

### Step 3: Generate Schema File
- Full object definition with header
- Place in `[ObjectType]/[schema]/ObjectName.sql`

### Step 4: Provide Verification
- Test queries to validate the changes
- List dependencies and prerequisites
- Rollback steps

### Step 5: Remind Testing
- Test locally before committing
- Run migration twice (idempotency check)
- Verify SchemaVersion table
- Test rollback procedure

---

## Article XI: Performance Mandates

When generating queries, indexes, or data access patterns:

- ALWAYS use explicit column lists (never `SELECT *`)
- ALWAYS suggest indexes for foreign key columns
- ALWAYS use `SET NOCOUNT ON` in procedures
- PREFER covering indexes for frequently queried columns
- AVOID leading wildcards in `LIKE` (`LIKE '%value'` is forbidden without justification)
- AVOID table scans — suggest appropriate WHERE clauses and indexes
- SUGGEST query hints only when explicitly asked and with documented reasoning
- INCLUDE execution plan review reminder for complex queries

---

## Article XII: Security Mandates

### Parameterization — Always
```sql
-- CORRECT: Parameterized
EXEC sp_executesql
    N'SELECT * FROM [dbo].[Users] WHERE [Id] = @Id',
    N'@Id INT',
    @Id = @UserId;

-- FORBIDDEN: String concatenation
SET @sql = 'SELECT * FROM Users WHERE Id = ' + CAST(@Id AS VARCHAR);
EXEC(@sql);
```

### Permissions — Least Privilege
- Suggest `GRANT SELECT` over `GRANT CONTROL`
- Suggest schema-level grants over database-level
- Document all permissions in `Grants/[schema]/` directory
- Never suggest `sa` or `dbo` access for application accounts

### Sensitive Data
- Never generate sample data with real PII
- Use obviously fake data: `'John Doe'`, `'jane@example.com'`
- Suggest encryption for columns containing sensitive data
- Recommend `[audit]` schema for access logging on sensitive tables

---

## Constitutional Amendments

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-09 | Initial Copilot Constitution ratified |

---

> *"These rules are the law of this repository. Follow them without exception. When in doubt, choose the safer, more documented, more idempotent path."*
