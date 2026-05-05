# Proxy-ID Prefix Registry — SOL_MAIN Database

> **AUTHORITATIVE DOCUMENT**: This file is the single source of truth for all registered Proxy-ID prefixes in the SOL_MAIN database. Every prefix used in any `*Types` table must be registered here before the type row is seeded. Copilot must read this file when creating new entity types or Proxy-enabled tables.

---

## Format Reference

A Proxy-ID takes the form:

```
{Prefix}:{PartKey}:{GUID}
```

| Segment | Type | Length | Example |
|---------|------|--------|---------|
| `Prefix` | Uppercase alphanumeric | 4 chars | `MSTR` |
| `PartKey` | Hex-encoded year+month | 5 chars | `316BD` |
| `GUID` | `NEWID()` as string | 36 chars | `E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8` |

**Full example:** `MSTR:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8`

---

## Prefix Naming Rules

1. **Exactly 4 characters** — uppercase letters (A–Z) and digits (0–9) only. No hyphens, underscores, or spaces.
2. **Globally unique** — no two rows in any `*Types` table anywhere in the database may share the same prefix. Check this registry before registering a new prefix.
3. **Semantically meaningful** — abbreviate the entity subtype name, not the schema name. A developer reading the proxy should be able to guess the entity type from the prefix alone.
4. **Schema-namespaced guidance** — the first two characters *should* loosely reflect the schema domain (see table below) to help with collision avoidance and readability. This is a strong recommendation, not a hard constraint.
5. **Immutable once seeded** — after a prefix is seeded into a type table in any deployed environment, it cannot be changed. It becomes part of every proxy string ever generated for that type.

### Schema Namespace Guidance

| Schema | Recommended Prefix Start | Domain |
|--------|--------------------------|--------|
| `ACC` | `AC**` | Account, Dealer, Tenant management |
| `ACE` | `CE**` | Customer-facing entities (CRM) |
| `AFL` | `AF**` | Affiliate marketing |
| `AUD` | `AU**` | Audit records |
| `CME` | `CM**` | Commission & compensation |
| `FNE` | `FN**` | Financing & funding |
| `MAC` | `MA**` | Master catalog (Estimates, Quotes, POs) |
| `MAS` | `MS**` | Monitoring & alarm systems |
| `QAL` | `QL**` | Qualified leads |
| `RSU` | `RS**` | Resource & user management |
| `SEC` | `SC**` | Security & access control |

> **Note on legacy prefixes:** Prefixes registered before this convention was established (`MSTR`, `QUAD`) are grandfathered and do not follow the namespace guidance. All new registrations must follow these rules.

---

## Registered Prefixes

### ACC — Account & Tenant Management

| Prefix | TypeId | TypeName | Type Table | Description | Registered |
|--------|--------|----------|------------|-------------|------------|
| `MSTR` | 1 | Master Tenant | `ACC.DealerTenantTypes` | The master/root dealer tenant | 2026-03-13 |
| `QUAD` | 2 | Quadradia Tenant | `ACC.DealerTenantTypes` | Quadradia dealer tenant | 2026-03-13 |

### AFL — Affiliate Marketing

| Prefix | TypeId | TypeName | Type Table | Description | Registered |
|--------|--------|----------|------------|-------------|------------|
| `AFST` | 1 | Standard Affiliate | `AFL.AffiliateTypes` | General-purpose affiliate account | 2026-05-05 |
| `AFIN` | 2 | Influencer Affiliate | `AFL.AffiliateTypes` | Social media influencer affiliate | 2026-05-05 |
| `AFPR` | 3 | Partner Affiliate | `AFL.AffiliateTypes` | Business partner affiliate | 2026-05-05 |

### ACE — Customer Entities

| Prefix | TypeId | TypeName | Type Table | Description | Registered |
|--------|--------|----------|------------|-------------|------------|
| *(none yet — reserved namespace `CE**`)* | | | | | |

### MAC — Master Catalog

| Prefix | TypeId | TypeName | Type Table | Description | Registered |
|--------|--------|----------|------------|-------------|------------|
| *(none yet — reserved namespace `MA**`)* | | | | | |

### RSU — Resource & Users

| Prefix | TypeId | TypeName | Type Table | Description | Registered |
|--------|--------|----------|------------|-------------|------------|
| *(none yet — reserved namespace `RS**`)* | | | | | |

### QAL — Qualified Leads

| Prefix | TypeId | TypeName | Type Table | Description | Registered |
|--------|--------|----------|------------|-------------|------------|
| *(none yet — reserved namespace `QL**`)* | | | | | |

---

## How to Add a New Prefix

Follow this process every time a new entity type is introduced:

### Step 1 — Claim the prefix here
Add a row to the appropriate schema table above **before** writing any SQL. If no suitable schema section exists, add one. Verify the 4-character code does not already appear anywhere in this file.

### Step 2 — Add `Prefix VARCHAR(4) NOT NULL` to the `*Types` table
Type tables hold the prefix definition. Entity tables consume it. Never put `Prefix` directly on an entity table.

```sql
-- In the *Types table DDL:
[Prefix] [varchar](4) NOT NULL,
CONSTRAINT [UQ_MyEntityTypes_Prefix] UNIQUE ([Prefix])
```

### Step 3 — Seed the prefix value in a data migration
```sql
-- In the data migration:
MERGE INTO [schema].[MyEntityTypes] AS target
USING (VALUES (1, 'AFLT', 'Standard Affiliate', '...')) 
      AS source ([Id], [Prefix], [Name], [Description])
ON target.[Id] = source.[Id]
WHEN MATCHED THEN UPDATE SET target.[Prefix] = source.[Prefix], target.[Name] = source.[Name]
WHEN NOT MATCHED THEN INSERT ([Prefix], [Name], [Description]) VALUES (source.[Prefix], source.[Name], source.[Description]);
```

### Step 4 — Register in `MAC.vwTableTypesAndPrefixes`
Add a `UNION` block to [Views/MAC/vwTableTypesAndPrefixes.sql](../Views/MAC/vwTableTypesAndPrefixes.sql):

```sql
UNION
SELECT
    [MyEntityTypeID]          AS [Id]
    , [Prefix]
    , [Name]
    , [Description]
    , 'AFL'                   AS [Schema]
    , 'MyEntityTypes'         AS [TableName]
    , 'MyEntity'              AS [TypeName]
FROM [AFL].[MyEntityTypes]
WHERE (IsDeleted = 0)
```

### Step 5 — Add branch to `MAC.fxGeneratePrefixParts`
Add an `ELSE IF` block to [Functions/MAC/fxGeneratePrefixParts.sql](../Functions/MAC/fxGeneratePrefixParts.sql):

```sql
ELSE IF (@TypeName = 'MyEntity')
BEGIN
    SELECT @Prefix = Prefix FROM [AFL].[MyEntityTypes] AS T WITH (NOLOCK)
    WHERE (T.MyEntityTypeID = @TypeId);
END
```

### Step 6 — Add `Proxy` and `PartKey` columns to the entity table
```sql
[MyEntityTypeId] [int]          NOT NULL,  -- FK to *Types table
[Proxy]          [varchar](100) NOT NULL,
[PartKey]        [varchar](6)   NOT NULL,
```

### Step 7 — Generate the proxy in INSERT stored procedures
```sql
DECLARE @Proxy VARCHAR(100) = (
    SELECT [MAC].[fxGeneratePrefixProxy]('MyEntity', @MyEntityTypeId)
) + CAST(NEWID() AS NVARCHAR(36));
-- Store both Proxy and the PartKey segment
DECLARE @PartKey VARCHAR(6) = LEFT(PARSENAME(REPLACE(@Proxy, ':', '.'), 2), 6);
```

---

## Infrastructure Objects

These objects must exist before any entity can use the Proxy-ID pattern:

| Object | Schema | Type | File | Purpose |
|--------|--------|------|------|---------|
| `fxGetPartKey` | `UTL` | Scalar Function | `Functions/UTL/fxGetPartKey.sql` | Returns hex year+month PartKey |
| `vwTableTypesAndPrefixes` | `MAC` | View | `Views/MAC/vwTableTypesAndPrefixes.sql` | Central prefix registry view |
| `fxGeneratePrefixParts` | `MAC` | TVF | `Functions/MAC/fxGeneratePrefixParts.sql` | Returns (Prefix, PartKey) for a TypeName+TypeId |
| `fxGeneratePrefixProxy` | `MAC` | Scalar Function | `Functions/MAC/fxGeneratePrefixProxy.sql` | Returns `Prefix:PartKey:` prefix string |
| `fxGetPrefixTypeIdFromProxy` | `MAC` | TVF | `Functions/MAC/fxGetPrefixTypeIdFromProxy.sql` | Parses a proxy back to its components |

**Status:** All five objects are pending creation in Phase 1 (Migration `20260505_1000_AddProxyIdFoundation`).

---

## Column Standards

| Column | Type | Nullable | Constraint | Notes |
|--------|------|----------|------------|-------|
| `Prefix` (on `*Types` tables) | `VARCHAR(4)` | NOT NULL | `UQ_*Types_Prefix` | Source of truth for prefix code |
| `Proxy` (on entity tables) | `VARCHAR(100)` | NOT NULL | `UQ_*_Proxy` | Full `Prefix:PartKey:GUID` string |
| `PartKey` (on entity tables) | `VARCHAR(6)` | NOT NULL | — | Duplicate of middle segment; enables indexed filtering |

> **PartKey must be VARCHAR(6), not INT.** The hex value (e.g., `316BD`) cannot be stored as an integer.

---

## Anti-Patterns (Never Do These)

❌ Do not put a `Proxy` or `PartKey` column on a `*Types` table — type tables define prefixes, not proxies  
❌ Do not store `PartKey` as `INT` — it is a hex string  
❌ Do not hardcode prefix strings in stored procedures — always call `MAC.fxGeneratePrefixProxy`  
❌ Do not reuse a prefix code across different entity types  
❌ Do not register a prefix without adding it to this file first  
❌ Do not change a prefix that has already been seeded in any deployed environment  
