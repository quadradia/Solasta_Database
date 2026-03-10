---
agent: 'agent'
description: 'Create an audit or maintenance trigger for a SQL Server table'
---

Your role is a SQL Server database developer following the Solasta Database conventions.

Create a trigger using the following specification:

**Table name**: ${input:tableName:Enter the table to attach the trigger to (e.g. Users)}
**Table schema**: ${input:tableSchema:Enter the table schema (dbo, app)}
**Trigger type**: ${input:triggerType:Enter 'audit' to log changes to audit.AuditLog, or 'modified-date' to auto-maintain ModifiedDate/ModifiedBy}

## Requirements

Generate two files:

### 1. Migration file → `Migrations/<timestamp>_Create_tr_<tableName>_<triggerType>.sql`

### 2. Schema file → `Triggers/<tableSchema>/tr_<tableName>_<triggerType>.sql`

The trigger file must include:
- Full header comment block (Object Type, Schema, Name, Description, Fires On, Author, Created)
- `IF OBJECT_ID` drop-and-recreate pattern for idempotency
- `SET NOCOUNT ON`
- `GO` after each statement

**For 'audit' triggers:**
- Fire `AFTER INSERT, UPDATE, DELETE`
- Use the `INSERTED` and `DELETED` pseudo-tables to capture before/after values
- Log to `[audit].[AuditLog]` table with: `TableName`, `Action` (INSERT/UPDATE/DELETE), `PrimaryKeyValue`, `OldValues` (JSON), `NewValues` (JSON), `ChangedDate` (GETUTCDATE()), `ChangedBy` (SYSTEM_USER)
- Use `FOR JSON AUTO` to capture row data as JSON

**For 'modified-date' triggers:**
- Fire `AFTER UPDATE` only
- Set `ModifiedDate = GETUTCDATE()` and `ModifiedBy = SYSTEM_USER` on rows in `INSERTED`
- Keep it lightweight — no additional logging

After generating, provide test DML statements to verify the trigger fires correctly.
