# Solasta Database Constitution

## Preamble

This document establishes the fundamental principles and governing rules for the Solasta Database repository. All contributors, database administrators, and automated systems must adhere to these principles to maintain consistency, reliability, and quality.

---

## Article I: Core Principles

### Section 1: Single Source of Truth
- The `Migrations/` directory is the **ultimate source of truth** for how the database evolved over time
- Schema files in object type directories serve as **current state documentation**
- When discrepancies exist, migrations take precedence

### Section 2: Immutability of History
- Once a migration has been **deployed to any environment beyond local development**, it shall **never be modified**
- All changes require a **new migration** with a later timestamp
- Exception: Migrations not yet deployed may be amended with team approval

### Section 3: Idempotency
- All scripts must be **safe to run multiple times** without causing errors or unintended side effects
- Use existence checks: `IF NOT EXISTS`, `IF OBJECT_ID(...) IS NOT NULL`
- Data scripts must use `MERGE` or conditional `INSERT` statements

### Section 4: Atomicity
- Each migration represents a **single, cohesive logical change**
- All changes within a migration must be wrapped in a **transaction**
- If any part fails, the entire migration must roll back

### Section 5: Documentation First
- **No code without documentation**
- Every file must have a complete header comment block
- Migrations must include rollback instructions
- Complex logic must be explained with inline comments

---

## Article II: Organizational Structure

### Section 1: Hierarchical Organization
The repository shall maintain a strict two-level hierarchy:
```
[Object Type] → [Schema] → [File]
```

### Section 2: Standard Schemas
The following schemas are established for specific purposes:

| Schema | Purpose | Examples |
|--------|---------|----------|
| `dbo` | Default schema, core business entities | Users, Orders, Products |
| `app` | Application-specific functionality | Settings, Configurations |
| `config` | System configuration and settings | FeatureFlags, AppSettings |
| `audit` | Audit logging and tracking | AuditLog, ChangeHistory |
| `reporting` | Reporting views and procedures | Sales reports, Analytics |

### Section 3: Object Type Directories
Each object type shall have its own top-level directory:
- **Tables/** - Table definitions
- **Views/** - View definitions
- **Procedures/** - Stored procedures
- **Functions/** - User-defined functions
- **Triggers/** - Trigger definitions
- **Indexes/** - Index definitions (if separate from tables)
- **Constraints/** - Constraint definitions (if separate from tables)
- **Sequences/** - Sequence objects
- **Types/** - User-defined types
- **Grants/** - Permission grants
- **Data/** - Seed and reference data
- **Schemas/** - Schema definitions
- **Scripts/** - Utility and deployment scripts
- **Migrations/** - Version-controlled migration scripts

### Section 4: One Object, One File
- Each database object shall reside in **exactly one file**
- File names must **clearly reflect** the object name
- No multi-object files except for related data inserts

---

## Article III: Naming Conventions

### Section 1: File Naming Standards

| Object Type | Pattern | Example |
|------------|---------|---------|
| Migration | `YYYYMMDD_HHMM_Description.sql` | `20260107_1430_CreateUsersTable.sql` |
| Table | `TableName.sql` | `Users.sql` |
| View | `ViewName.sql` | `vw_ActiveUsers.sql` |
| Procedure | `ProcedureName.sql` | `sp_GetUserById.sql` |
| Function | `FunctionName.sql` | `fn_CalculateDiscount.sql` |
| Trigger | `TriggerName.sql` | `tr_Users_AfterInsert.sql` |
| Data | `TableName_data.sql` | `Countries_data.sql` |

### Section 2: SQL Object Naming Standards

| Object Type | Pattern | Example |
|------------|---------|---------|
| Table | `[schema].[TableName]` | `[dbo].[Users]` |
| Primary Key | `PK_[TableName]` | `PK_Users` |
| Foreign Key | `FK_[TableName]_[RefTable]` | `FK_Orders_Users` |
| Unique Constraint | `UQ_[TableName]_[Column]` | `UQ_Users_Email` |
| Check Constraint | `CK_[TableName]_[Column]` | `CK_Orders_Total` |
| Default Constraint | `DF_[TableName]_[Column]` | `DF_Users_CreatedDate` |
| Index | `IX_[TableName]_[Columns]` | `IX_Users_Email` |
| View | `[schema].[vw_ViewName]` | `[reporting].[vw_Sales]` |
| Procedure | `[schema].[sp_ProcName]` | `[dbo].[sp_GetUser]` |
| Function | `[schema].[fn_FuncName]` | `[dbo].[fn_GetAge]` |
| Trigger | `[schema].[tr_TableName_Event]` | `[dbo].[tr_Users_Insert]` |

### Section 3: Column Naming Standards
- Use **PascalCase** for column names
- Use **descriptive, meaningful** names
- Avoid abbreviations unless widely understood
- Primary keys: prefer `[TableName]Id` or simply `Id`
- Foreign keys: prefer `[ReferencedTable]Id`

---

## Article IV: Migration Standards

### Section 1: Migration File Structure
Every migration must contain:

1. **Header Comment Block**
   - Migration name
   - Author
   - Date
   - Detailed description
   - Dependencies
   - Expected impact

2. **Version Check**
   - Query `SchemaVersion` table
   - Exit if already applied

3. **Transaction Wrapper**
   - BEGIN TRANSACTION
   - TRY...CATCH block
   - COMMIT on success
   - ROLLBACK on error

4. **Migration Logic**
   - Actual DDL/DML statements
   - With existence checks

5. **Version Recording**
   - INSERT into `SchemaVersion` table

6. **Rollback Instructions**
   - Comment block with undo steps

### Section 2: Migration Timestamp Format
- Use **UTC time** for timestamps
- Format: `YYYYMMDD_HHMM`
- Example: `20260309_1445`

### Section 3: Migration Execution Order
Migrations must be executed in **chronological order** based on their timestamp.

### Section 4: Migration Testing
Before committing, every migration must be:
- ✅ Tested in local development environment
- ✅ Run at least twice to verify idempotency
- ✅ Verified in `SchemaVersion` table
- ✅ Tested for rollback capability
- ✅ Performance tested with realistic data volumes

---

## Article V: Code Quality Standards

### Section 1: Mandatory Practices

**SHALL DO:**
- ✅ Use explicit column names (never SELECT *)
- ✅ Qualify all object references with schema
- ✅ Use square brackets for all identifiers
- ✅ Include SET NOCOUNT ON in procedures
- ✅ Implement proper error handling
- ✅ Wrap data modifications in transactions
- ✅ Use parameterized queries
- ✅ Document all parameters and return values
- ✅ Include usage examples in procedure headers

**SHALL NOT DO:**
- ❌ Hard-code server or database names
- ❌ Store credentials in scripts
- ❌ Use deprecated data types (TEXT, NTEXT, IMAGE)
- ❌ Use cursors without justification
- ❌ Create dynamic SQL without sanitization
- ❌ Use NOLOCK hint without understanding implications
- ❌ Mix DDL and DML in procedures without reason
- ❌ Commit incomplete or untested code

### Section 2: Data Type Standards
- **Unicode text**: Use `NVARCHAR` instead of `VARCHAR`
- **Dates**: Use `DATETIME2` instead of `DATETIME`
- **Currency**: Use `DECIMAL(19,4)` or `MONEY` (context-dependent)
- **Flags**: Use `BIT` for boolean values
- **IDs**: Use `INT` or `BIGINT` for identity columns

### Section 3: Performance Standards
- Create **appropriate indexes** for foreign keys and commonly queried columns
- Avoid **leading wildcards** in LIKE clauses (`LIKE '%value'`)
- Use **covering indexes** for frequently run queries
- Consider **table partitioning** for very large tables
- Document **expected performance** in complex queries

### Section 4: Table Column Ordering Standards

**All table definitions — both in schema files and in the physical database — MUST follow this column order:**

| Position | Group | Description |
|----------|-------|-------------|
| 1 | **Primary Key** | Identity/PK column(s) always first |
| 2 | **Foreign Keys** | All FK columns immediately after the PK, grouped together |
| 3 | **Business Columns** | Payload/domain-specific columns |
| 4 | **Audit Columns** | Always last — see required set below |

**Required audit column order (bottom of every table):**
```sql
[IsActive]      [bit]               NOT NULL,
[IsDeleted]     [bit]               NOT NULL,
[ModifiedDate]  [datetimeoffset](7) NOT NULL,
[ModifiedById]  [int]               NOT NULL,  -- or uniqueidentifier per schema convention
[CreatedDate]   [datetimeoffset](7) NOT NULL,
[CreatedById]   [int]               NOT NULL,  -- or uniqueidentifier per schema convention
[DEX_ROW_TS]    [datetimeoffset](7) NOT NULL
```

**Special case — `DEX_ROW` surrogate identity:**

Some tables have no natural identity column (e.g., junction/mapping tables with a composite PK). In those cases a `DEX_ROW` column is added as a surrogate row identifier:

```sql
[DEX_ROW]  [bigint]  IDENTITY(1,1)  NOT NULL
```

Rules for `DEX_ROW`:
- **Only present** on tables that have **no other `IDENTITY` column**
- **Type**: `BIGINT IDENTITY(1,1) NOT NULL` — never `INT`, never nullable
- **Position**: The absolute **last column** in the table, placed after `DEX_ROW_TS`
- **Never add `DEX_ROW`** to a table that already has an identity PK column

Full audit tail for a table **without** an identity PK:
```sql
[IsActive]      [bit]               NOT NULL,
[IsDeleted]     [bit]               NOT NULL,
[ModifiedDate]  [datetimeoffset](7) NOT NULL,
[ModifiedById]  [int]               NOT NULL,
[CreatedDate]   [datetimeoffset](7) NOT NULL,
[CreatedById]   [int]               NOT NULL,
[DEX_ROW_TS]    [datetimeoffset](7) NOT NULL,
[DEX_ROW]       [bigint]            IDENTITY(1,1) NOT NULL   -- surrogate identity, last column
```

**Rules:**
- ❌ **Never** add FK columns after business or audit columns
- ❌ **Never** use `ALTER TABLE ... ADD` to append a column that is logically a FK — this physically places it at the end; a table recreation migration is required to restore proper order
- ❌ **Never** add `DEX_ROW` to a table that already has an `IDENTITY` column
- ❌ **Never** declare `DEX_ROW` as `INT` — it must be `BIGINT`
- ✅ When a column added via `ALTER TABLE` violates the ordering standard, a follow-up migration **must** recreate the table in the correct order before the change is committed to any shared environment
- ✅ The schema file (e.g., `Tables/schema/TableName.sql`) must always reflect the correct constitutional column order, regardless of how the live database currently looks

---

## Article VI: Security and Permissions

### Section 1: Principle of Least Privilege
- Grant only **necessary permissions**
- Use **schema-level** permissions where appropriate
- Document all **permission grants** in `Grants/` directory
- Never grant **CONTROL** or **DBO** rights unnecessarily

### Section 2: Sensitive Data Protection
- **Never commit**:
  - Passwords or credentials
  - Connection strings with secrets
  - Personal identifiable information (PII)
  - API keys or tokens
  
- **Always**:
  - Use SQL Server authentication sparingly
  - Prefer Windows/Azure AD authentication
  - Encrypt sensitive data at rest
  - Audit access to sensitive tables

### Section 3: SQL Injection Prevention
- Use **parameterized queries** in all stored procedures
- If dynamic SQL is necessary:
  - Use `sp_executesql` with parameters
  - Validate and sanitize all inputs
  - Document security considerations

---

## Article VII: Testing and Validation

### Section 1: Local Testing Requirements
Before any pull request:
- ✅ Create a test database
- ✅ Run all migrations in order
- ✅ Verify SchemaVersion table
- ✅ Test new objects with sample data
- ✅ Run migrations a second time (idempotency check)
- ✅ Test rollback procedures
- ✅ Check for performance issues

### Section 2: Code Review Requirements
Pull requests must include:
- Clear description of changes
- List of migrations included
- Impact assessment
- Rollback strategy
- Testing evidence
- Performance considerations

### Section 3: Deployment Validation
After deployment to any environment:
- ✅ Verify SchemaVersion table updated
- ✅ Confirm objects exist as expected
- ✅ Run smoke tests
- ✅ Check application logs for errors
- ✅ Monitor performance metrics

---

## Article VIII: Documentation Standards

### Section 1: File Header Template
Every SQL file must begin with:
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

### Section 2: Inline Comments
- Explain **WHY**, not just **WHAT**
- Document **complex logic** and business rules
- Clarify **non-obvious** column purposes
- Note **performance considerations**
- Reference **related tickets** or requirements

### Section 3: README Maintenance
Each directory must maintain:
- Updated README.md with current templates
- Examples of proper usage
- Common patterns
- Anti-patterns to avoid

---

## Article IX: Version Control Practices

### Section 1: Branch Strategy
- Create **feature branches** for all changes
- Use descriptive branch names: `feature/add-user-authentication`
- Never commit directly to `main` or `master`
- Keep branches focused and short-lived

### Section 2: Commit Messages
Format:
```
[Type]: Brief description

Detailed explanation of what changed and why.

- Migration: YYYYMMDD_HHMM_Description
- Affects: [List affected objects]
```

Types:
- `feat`: New feature or object
- `fix`: Bug fix or correction
- `refactor`: Code restructuring
- `docs`: Documentation only
- `perf`: Performance improvement

### Section 3: Pull Request Process
1. Create PR with comprehensive description
2. Request review from database team
3. Address all review comments
4. Obtain approval from at least one reviewer
5. Ensure CI/CD passes (if configured)
6. Merge using squash or merge commit

---

## Article X: Deployment Standards

### Section 1: Deployment Order
Execute in this specific order:
1. Schemas
2. Types
3. Tables
4. Indexes
5. Constraints
6. Sequences
7. Views
8. Functions
9. Procedures
10. Triggers
11. Grants
12. Data

### Section 2: Pre-Deployment Checklist
- [ ] Database backup completed
- [ ] Maintenance window scheduled
- [ ] Stakeholders notified
- [ ] Rollback plan prepared
- [ ] Migration scripts tested in staging
- [ ] Performance impact assessed
- [ ] Dependencies verified

### Section 3: Deployment Execution
1. **Backup** production database
2. **Verify** SchemaVersion table current state
3. **Execute** migrations in chronological order
4. **Verify** each migration success in SchemaVersion
5. **Test** critical paths
6. **Monitor** application behavior
7. **Document** deployment in changelog

### Section 4: Rollback Procedures
If deployment fails:
1. **Stop** immediately
2. **Assess** partial completion state
3. **Execute** rollback scripts in reverse order
4. **Restore** from backup if necessary
5. **Document** failure and lessons learned
6. **Fix** issues before retry

---

## Article XI: Audit and Compliance

### Section 1: Audit Trail Requirements
- All migrations recorded in `SchemaVersion` table with:
  - Migration name
  - Description
  - Applied date (UTC)
  - Applied by (system/user)
  - Success status
  - Execution time

### Section 2: Change Tracking
Tables that store business-critical data should include:
```sql
[CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
[CreatedBy] NVARCHAR(50) NULL,
[ModifiedDate] DATETIME2 NULL,
[ModifiedBy] NVARCHAR(50) NULL
```

### Section 3: Soft Deletes
For data that should never be physically deleted:
```sql
[IsDeleted] BIT NOT NULL DEFAULT 0,
[DeletedDate] DATETIME2 NULL,
[DeletedBy] NVARCHAR(50) NULL
```

---

## Article XII: Emergency Procedures

### Section 1: Hotfix Process
In production emergencies:
1. Create hotfix branch immediately
2. Make minimal necessary changes
3. Create migration with clear emergency notation
4. Test in staging if possible
5. Deploy with DBA supervision
6. Document incident thoroughly
7. Schedule proper fix in next release

### Section 2: Data Recovery
For accidental data loss:
1. **STOP** all write operations immediately
2. Assess scope of loss from backups
3. Restore to point-in-time if available
4. Document recovery procedure
5. Conduct post-mortem analysis

---

## Article XIII: Continuous Improvement

### Section 1: Retrospectives
Conduct regular reviews:
- Monthly review of deployment processes
- Quarterly review of standards
- Annual review of this Constitution
- Post-mortem for all production incidents

### Section 2: Amendment Process
This Constitution may be amended by:
1. Proposal from any team member
2. Discussion with database team
3. Approval from majority of senior DBAs
4. Documentation of change rationale
5. Update with version history

### Section 3: Training
All new team members must:
- Read this Constitution
- Review all documentation
- Complete training on migration system
- Make supervised changes before independence
- Receive mentorship from experienced DBA

---

## Article XIV: Enforcement

### Section 1: Automated Validation
Implement CI/CD checks for:
- File naming conventions
- Header comment presence
- SchemaVersion table updates
- Idempotency patterns
- Transaction wrappers

### Section 2: Code Review Standards
Reviewers must verify:
- Compliance with all constitutional principles
- Proper testing completed
- Documentation adequacy
- Security considerations
- Performance implications

### Section 3: Violations
Non-compliance results in:
- PR rejection (automatic for critical violations)
- Required corrections before merge
- Documentation in review comments

---

## Article XV: Proxy-ID Architectural Standard

### Section 1: Purpose and Scope

The Proxy-ID pattern is a **mandatory architectural standard** for entity tables requiring globally unique, typed, and partitioned identifiers. It produces human-readable composite keys in the format:

```
{Prefix}:{PartKey}:{GUID}
```

This pattern is applied **incrementally** — not retrofitted to all tables at once. Every new entity table that requires a typed unique identifier MUST implement it. Existing tables are onboarded as features evolve.

### Section 2: Inviolable Rules

1. **Prefix Column on Type Tables**: Every `*Types` table for a Proxy-enabled entity MUST have `[Prefix] VARCHAR(4) NOT NULL` with a `UNIQUE` constraint.

2. **No Proxy/PartKey on Type Tables**: Type tables define prefixes. They do NOT have `Proxy` or `PartKey` columns. Only entity tables carry these columns.

3. **PartKey is VARCHAR(6), Never INT**: The `PartKey` column on entity tables is a 5-character hexadecimal string (e.g., `316BD`). Declaring it as `INT` is a constitutional violation.

4. **Prefix Registry is Authoritative**: Before seeding any new prefix value, the prefix MUST be registered in `.github/ProxyID-PrefixRegistry.md`. No prefix may exist in the database without a corresponding registry entry.

5. **Prefixes are Immutable Once Deployed**: A prefix code that has been seeded into any deployed environment may never be changed. It becomes part of all proxy strings for that entity type forever.

6. **GUID Appended by INSERT Callers**: The function `MAC.fxGeneratePrefixProxy` returns `Prefix:PartKey:` (with trailing colon). The calling procedure or statement appends `CAST(NEWID() AS NVARCHAR(36))`. The generation function never appends the GUID.

7. **Infrastructure Objects are Prerequisites**: All five infrastructure objects (`UTL.fxGetPartKey`, `MAC.vwTableTypesAndPrefixes`, `MAC.fxGeneratePrefixParts`, `MAC.fxGeneratePrefixProxy`, `MAC.fxGetPrefixTypeIdFromProxy`) must exist and be current before any entity table can generate proxies.

### Section 3: Column Standard

| Column | Location | Type | Constraint |
|--------|----------|------|------------|
| `Prefix` | `*Types` tables | `VARCHAR(4) NOT NULL` | `UNIQUE` |
| `Proxy` | Entity tables | `VARCHAR(100) NOT NULL` | `UNIQUE` |
| `PartKey` | Entity tables | `VARCHAR(6) NOT NULL` | Indexed |

### Section 4: Prefix Naming Standard

- 4 uppercase alphanumeric characters (A–Z, 0–9), no special characters
- Globally unique across the entire database
- Semantically meaningful — abbreviates the entity subtype
- First two characters should align with the schema domain (see registry)
- See `.github/ProxyID-PrefixRegistry.md` for full naming rules and the authoritative prefix table

### Section 5: New Entity Checklist

When adding a new Proxy-enabled entity, all six steps are REQUIRED:

1. ☐ Claim a unique prefix and register it in `.github/ProxyID-PrefixRegistry.md`
2. ☐ Add `Prefix VARCHAR(4) NOT NULL` + UNIQUE constraint to the `*Types` table
3. ☐ Add a `UNION` block for the type table to `MAC.vwTableTypesAndPrefixes`
4. ☐ Add an `ELSE IF` branch to `MAC.fxGeneratePrefixParts`
5. ☐ Add `Proxy VARCHAR(100) NOT NULL` and `PartKey VARCHAR(6) NOT NULL` to the entity table
6. ☐ Seed initial type rows with correct prefix values in a data migration
- Repeated violations: additional training

---

## Appendix A: Quick Reference

### Common Commands
```sql
-- Check applied migrations
SELECT * FROM [dbo].[SchemaVersion] ORDER BY [AppliedDate] DESC;

-- Backup database
BACKUP DATABASE [SolastaDB] TO DISK = 'path.bak' WITH COMPRESSION;

-- Check object existence
SELECT name FROM sys.objects WHERE name = 'ObjectName';

-- Check dependencies
EXEC sp_depends 'schema.ObjectName';
```

### Emergency Contacts
- Database Team Lead: [Contact info]
- On-Call DBA: [Contact info]
- DevOps Team: [Contact info]

### Useful Links
- [STRUCTURE.md](./STRUCTURE.md) - Repository structure guide
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Contribution guidelines
- [QUICKSTART.md](./QUICKSTART.md) - Quick start guide
- [TEMPLATES.sql](./TEMPLATES.sql) - Code templates

---

## Appendix B: Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-03-09 | GitHub Copilot | Initial constitution created |

---

**Adopted**: March 9, 2026

**Authority**: Solasta Database Team

**Status**: Active and Enforceable

---

*"In Database We Trust, Through Migrations We Evolve"*
