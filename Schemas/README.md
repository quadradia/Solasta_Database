# Schemas Directory

This directory contains schema creation scripts organized by schema name.

## Purpose

Schemas are used to logically group database objects and manage permissions. Each schema should have its own subdirectory containing a `schema.sql` file.

## SOL_MAIN Database Schemas

The following schemas are deployed in the SOL_MAIN database. All schemas are created by migration `20260313_0845_Baseline_Schemas`.

| Schema | Full Name | Description | Key Tables |
|---|---|---|---|
| `dbo` | Default | SQL Server default schema. Holds cross-cutting infrastructure objects (e.g., `SchemaVersion`). | `SchemaVersion` |
| `ACC` | Access / Account Management | Tenant and user management. `ACC.Dealers` is the **tenant table** — all multi-tenant data keys back to a `DealerId`. Also owns roles and user–role assignments. | `Dealers`, `Users`, `Roles`, `UserRoles`, `DealerTenants`, `DealerTenantTypes` |
| `ACE` | Account / Customer Entities | Customer profiles and master file accounts linked to customers. Extends MAC customer data with operational records. | `Customers`, `CustomerAddresses`, `CustomerTypes`, `MasterFiles`, `MasterFileAccounts` |
| `AFL` | Affiliate Marketing | Token-based affiliate attribution tracking. Tracks affiliates, campaigns, ad placements, link clicks, and lead conversions. See [AffiliateProgram.md](../Tables/QAL/AffiliateProgram.md). | `Affiliates`, `AffiliateCampaigns`, `CampaignPlacements`, `TokenClicks`, `LeadAttributions`, `MediaPlatforms` |
| `AUD` | Audit | Audit logging framework. Records field-level changes to audited tables via action type and column mappings. | `AuditActions`, `AuditActionTypes`, `AuditActionColumns` |
| `CME` | Commission Management | Commission rates and types associated with monitoring accounts. | `MasAccountCommissions`, `MasAccountCommissionTypes` |
| `CNS` | Consignment / Grouping Utilities | Utility schema for consignment and grouping operations. Primarily functions and procedures; no core tables. | — |
| `FNE` | Financing / Funding | Funding sources and their types used in account financing. | `FundingSources`, `FundingSourceTypes` |
| `GEN` | General / Shared Reference | Shared reference data and metadata used across schemas. | `StoredProcedureReturnTypes` |
| `MAC` | Master Configuration | Master reference and configuration data: address types, account types, customer/quote/estimate records, purchase orders, geographic/political lookups. | `Accounts`, `Customers`, `Estimates`, `Quotes`, `PurchaseOrders`, `AddressTypes`, `PoliticalStates`, `PoliticalCountries` |
| `MAS` | Monitoring Automation System | Alarm/monitoring account management. Stores MAS account details, panel types, monitoring station configurations, and premise addresses. | `MasAccounts`, `MonitoringStations`, `PremiseAddresses`, `MasAccountPanelTypes`, `MasAccountTemplates` |
| `QAL` | Qualified Leads | Lead ingestion and qualification pipeline. Captures inbound lead records, their addresses, sources, and disposition status. | `Leads`, `LeadAddresses`, `LeadSources`, `LeadDispositions` |
| `RSU` | Resource / User Workforce | Workforce and field-team management. Covers user resources, recruiting, team rosters, location assignments, seasons, and terminations. | `UserResources`, `UserRecruits`, `Teams`, `TeamLocations`, `Seasons`, `Terminations`, `UserTypes` |
| `SEC` | Security | Table-level and row-level access control. Defines access levels and maps them to specific tables. | `AccessLevels`, `TableAccessLevels` |
| `UTL` | Utility | Reusable helper functions and procedures shared across schemas. No standalone tables. | — |

## Directory Structure

```
Schemas/
├── dbo/              # Default SQL Server schema
├── app/              # (reserved)
├── config/           # (reserved)
├── audit/            # (reserved)
└── reporting/        # (reserved)
```

> **Note:** The `ACC`, `ACE`, `AFL`, `AUD`, `CME`, `CNS`, `FNE`, `GEN`, `MAC`, `MAS`, `QAL`, `RSU`, `SEC`, and `UTL` schema creation scripts live in the baseline migration (`Migrations/20260313_0845_Baseline_Schemas.sql`) rather than individual files in this directory.

## Template

```sql
/*******************************************************************************
 * Object Type: Schema
 * Name: [SchemaName]
 * Description: [Brief description of what this schema contains]
 * Author: [Author name]
 * Created: [YYYY-MM-DD]
 ******************************************************************************/

-- Create schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'[SchemaName]')
BEGIN
    EXEC('CREATE SCHEMA [SchemaName]');
END
GO

-- For PostgreSQL:
-- CREATE SCHEMA IF NOT EXISTS [SchemaName];
```

## Usage

1. Create a subdirectory for your schema (e.g., `myschema/`)
2. Create a `schema.sql` file in that directory
3. Define the schema creation logic
4. Execute schema scripts before any other database objects
