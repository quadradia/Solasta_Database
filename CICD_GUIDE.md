# CI/CD and Automation Guide

This document describes how to set up automated validation, testing, and deployment for the Solasta Database repository.

---

## Table of Contents
1. [GitHub Actions Workflows](#github-actions-workflows)
2. [Pre-commit Hooks](#pre-commit-hooks)
3. [Automated Testing](#automated-testing)
4. [Deployment Pipelines](#deployment-pipelines)
5. [Quality Gates](#quality-gates)

---

## GitHub Actions Workflows

### Workflow 1: Migration Validation

Create `.github/workflows/validate-migrations.yml`:

```yaml
name: Validate Migrations

on:
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'Migrations/**'
  push:
    branches: [ main, develop ]
    paths:
      - 'Migrations/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Validate migration file names
      run: |
        cd Migrations
        invalid_files=0
        for file in *.sql; do
          # Skip template files
          if [[ "$file" == "TEMPLATE_Migration.sql" ]] || [[ "$file" == "00000000_0000_CreateSchemaVersionTable.sql" ]]; then
            continue
          fi
          
          # Check naming convention: YYYYMMDD_HHMM_Description.sql
          if ! [[ "$file" =~ ^[0-9]{8}_[0-9]{4}_[A-Za-z0-9]+\.sql$ ]]; then
            echo "❌ Invalid migration filename: $file"
            echo "   Expected format: YYYYMMDD_HHMM_Description.sql"
            invalid_files=$((invalid_files + 1))
          else
            echo "✓ Valid filename: $file"
          fi
        done
        
        if [ $invalid_files -gt 0 ]; then
          echo ""
          echo "❌ $invalid_files migration file(s) have invalid names"
          exit 1
        fi
        echo ""
        echo "✓ All migration filenames are valid"
    
    - name: Validate migration content
      run: |
        cd Migrations
        invalid_files=0
        for file in *.sql; do
          # Skip template files
          if [[ "$file" == "TEMPLATE_Migration.sql" ]] || [[ "$file" == "00000000_0000_CreateSchemaVersionTable.sql" ]]; then
            continue
          fi
          
          echo "Validating: $file"
          
          # Check for required components
          if ! grep -q "Migration:" "$file"; then
            echo "  ❌ Missing migration header"
            invalid_files=$((invalid_files + 1))
          fi
          
          if ! grep -q "BEGIN TRANSACTION" "$file"; then
            echo "  ❌ Missing transaction wrapper"
            invalid_files=$((invalid_files + 1))
          fi
          
          if ! grep -q "SchemaVersion" "$file"; then
            echo "  ❌ Missing SchemaVersion check"
            invalid_files=$((invalid_files + 1))
          fi
          
          if ! grep -q "ROLLBACK" "$file"; then
            echo "  ❌ Missing rollback instructions"
            invalid_files=$((invalid_files + 1))
          fi
          
          echo "  ✓ Content validation passed"
        done
        
        if [ $invalid_files -gt 0 ]; then
          echo ""
          echo "❌ Migration content validation failed"
          exit 1
        fi
        echo ""
        echo "✓ All migrations have valid content"

    - name: Check for duplicate migration timestamps
      run: |
        cd Migrations
        duplicates=$(ls *.sql | grep -E '^[0-9]{8}_[0-9]{4}_' | cut -d'_' -f1,2 | sort | uniq -d)
        if [ ! -z "$duplicates" ]; then
          echo "❌ Duplicate migration timestamps found:"
          echo "$duplicates"
          exit 1
        fi
        echo "✓ No duplicate timestamps"
```

### Workflow 2: SQL Linting

Create `.github/workflows/sql-lint.yml`:

```yaml
name: SQL Lint

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  lint:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Install SQLFluff
      run: |
        pip install sqlfluff
    
    - name: Lint SQL files
      run: |
        sqlfluff lint --dialect tsql --ignore parsing Tables/**/*.sql Procedures/**/*.sql Views/**/*.sql Functions/**/*.sql Migrations/**/*.sql --format github-annotation || true
      continue-on-error: true
```

### Workflow 3: Database Schema Test

Create `.github/workflows/test-schema.yml`:

```yaml
name: Test Database Schema

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      sqlserver:
        image: mcr.microsoft.com/mssql/server:2022-latest
        env:
          ACCEPT_EULA: Y
          SA_PASSWORD: Test123!@#
          MSSQL_PID: Developer
        ports:
          - 1433:1433
        options: >-
          --health-cmd="/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Test123!@# -Q 'SELECT 1'"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Wait for SQL Server
      run: sleep 15
      
    - name: Create test database
      run: |
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'Test123!@#' -Q "CREATE DATABASE SolastaTest;"
    
    - name: Run migrations
      run: |
        cd Migrations
        for file in $(ls *.sql | sort); do
          if [[ "$file" == "TEMPLATE_Migration.sql" ]]; then
            continue
          fi
          echo "Applying migration: $file"
          /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'Test123!@#' -d SolastaTest -i "$file"
        done
    
    - name: Verify schema
      run: |
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'Test123!@#' -d SolastaTest -Q "SELECT * FROM [dbo].[SchemaVersion] ORDER BY [AppliedDate];"
```

---

## Pre-commit Hooks

### Setup Git Hooks

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running pre-commit validation..."

# Check for migration files
migration_files=$(git diff --cached --name-only --diff-filter=ACM | grep "^Migrations/.*\.sql$" | grep -v "TEMPLATE")

if [ ! -z "$migration_files" ]; then
    echo "Validating migration files..."
    
    for file in $migration_files; do
        echo "Checking: $file"
        
        # Validate filename format
        filename=$(basename "$file")
        if ! [[ "$filename" =~ ^[0-9]{8}_[0-9]{4}_[A-Za-z0-9]+\.sql$ ]]; then
            echo "❌ Invalid migration filename: $filename"
            echo "   Expected format: YYYYMMDD_HHMM_Description.sql"
            exit 1
        fi
        
        # Validate content
        if ! grep -q "Migration:" "$file"; then
            echo "❌ Missing migration header in: $filename"
            exit 1
        fi
        
        if ! grep -q "BEGIN TRANSACTION" "$file"; then
            echo "❌ Missing transaction wrapper in: $filename"
            exit 1
        fi
        
        if ! grep -q "SchemaVersion" "$file"; then
            echo "❌ Missing SchemaVersion check in: $filename"
            exit 1
        fi
        
        echo "✓ $filename validated"
    done
fi

echo "✓ Pre-commit validation passed"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### PowerShell Pre-commit Hook

Create `Scripts/pre-commit-hook.ps1`:

```powershell
# Run this from the repository root
$stagedFiles = git diff --cached --name-only --diff-filter=ACM

$migrationFiles = $stagedFiles | Where-Object { $_ -like "Migrations/*.sql" -and $_ -notlike "*TEMPLATE*" }

if ($migrationFiles.Count -eq 0) {
    Write-Host "✓ No migration files to validate" -ForegroundColor Green
    exit 0
}

Write-Host "Validating $($migrationFiles.Count) migration file(s)..." -ForegroundColor Cyan

$errors = 0

foreach ($file in $migrationFiles) {
    Write-Host "Checking: $file" -ForegroundColor Yellow
    
    $filename = Split-Path $file -Leaf
    
    # Check filename format
    if ($filename -notmatch '^\d{8}_\d{4}_.+\.sql$') {
        Write-Host "  ❌ Invalid filename format" -ForegroundColor Red
        $errors++
        continue
    }
    
    # Check content
    $content = Get-Content $file -Raw
    
    if ($content -notmatch 'Migration:') {
        Write-Host "  ❌ Missing migration header" -ForegroundColor Red
        $errors++
    }
    
    if ($content -notmatch 'BEGIN TRANSACTION') {
        Write-Host "  ❌ Missing transaction wrapper" -ForegroundColor Red
        $errors++
    }
    
    if ($content -notmatch 'SchemaVersion') {
        Write-Host "  ❌ Missing SchemaVersion check" -ForegroundColor Red
        $errors++
    }
    
    if ($errors -eq 0) {
        Write-Host "  ✓ Validated" -ForegroundColor Green
    }
}

if ($errors -gt 0) {
    Write-Host "`n❌ Pre-commit validation failed with $errors error(s)" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ All validations passed" -ForegroundColor Green
exit 0
```

---

## Automated Testing

### Unit Test Template

Create `Tests/test-procedures.sql`:

```sql
/*******************************************************************************
 * Unit Tests for Stored Procedures
 * Run these tests after migrations to verify functionality
 ******************************************************************************/

-- Test 1: Verify stored procedure exists
IF OBJECT_ID('[dbo].[sp_TestProcedure]', 'P') IS NULL
BEGIN
    RAISERROR('Test Failed: sp_TestProcedure does not exist', 16, 1);
END
ELSE
BEGIN
    PRINT '✓ Test Passed: sp_TestProcedure exists';
END
GO

-- Test 2: Verify procedure returns expected results
DECLARE @Result INT;
EXEC [dbo].[sp_TestProcedure] @Param1 = 1, @Result = @Result OUTPUT;

IF @Result IS NULL
BEGIN
    RAISERROR('Test Failed: sp_TestProcedure returned NULL', 16, 1);
END
ELSE
BEGIN
    PRINT '✓ Test Passed: sp_TestProcedure returned result';
END
GO

-- Test 3: Verify error handling
BEGIN TRY
    DECLARE @Result INT;
    EXEC [dbo].[sp_TestProcedure] @Param1 = -1, @Result = @Result OUTPUT;
    RAISERROR('Test Failed: Should have thrown an error', 16, 1);
END TRY
BEGIN CATCH
    PRINT '✓ Test Passed: Error handling works correctly';
END CATCH
GO
```

### Integration Test Template

Create `Tests/test-integration.sql`:

```sql
/*******************************************************************************
 * Integration Tests
 * Test complete workflows across multiple objects
 ******************************************************************************/

BEGIN TRANSACTION;

BEGIN TRY
    -- Setup test data
    INSERT INTO [dbo].[TestTable] ([Name]) VALUES ('Test Item');
    
    -- Execute workflow
    DECLARE @Result INT;
    EXEC [dbo].[sp_WorkflowProcedure] @ItemId = 1, @Result = @Result OUTPUT;
    
    -- Verify results
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ResultTable] WHERE [Id] = @Result)
    BEGIN
        RAISERROR('Integration test failed: Expected result not found', 16, 1);
    END
    
    PRINT '✓ Integration test passed';
    
    ROLLBACK TRANSACTION; -- Don't commit test data
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
END CATCH
GO
```

---

## Deployment Pipelines

### Development Environment

```yaml
# .github/workflows/deploy-dev.yml
name: Deploy to Development

on:
  push:
    branches: [ develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: development
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Run migrations
      uses: azure/sql-action@v2
      with:
        connection-string: ${{ secrets.DEV_SQL_CONNECTION_STRING }}
        path: './Migrations'
        
    - name: Run tests
      uses: azure/sql-action@v2
      with:
        connection-string: ${{ secrets.DEV_SQL_CONNECTION_STRING }}
        path: './Tests'
```

### Production Environment

```yaml
# .github/workflows/deploy-prod.yml
name: Deploy to Production

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Backup database
      run: |
        # Add backup script here
        echo "Creating backup..."
    
    - name: Run migrations
      uses: azure/sql-action@v2
      with:
        connection-string: ${{ secrets.PROD_SQL_CONNECTION_STRING }}
        path: './Migrations'
    
    - name: Verify deployment
      run: |
        # Add verification script here
        echo "Verifying deployment..."
    
    - name: Notify team
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: 'Production database deployment completed'
      if: always()
```

---

## Quality Gates

### SQL Code Quality Checks

Create `.github/workflows/quality-gates.yml`:

```yaml
name: Quality Gates

on:
  pull_request:
    branches: [ main, develop ]

jobs:
  quality:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Check for SELECT *
      run: |
        bad_files=$(grep -r "SELECT \*" --include="*.sql" Procedures/ Views/ Functions/ || true)
        if [ ! -z "$bad_files" ]; then
          echo "❌ Found SELECT * in production code:"
          echo "$bad_files"
          echo ""
          echo "Please use explicit column names instead."
          exit 1
        fi
        echo "✓ No SELECT * found"
    
    - name: Check for hardcoded credentials
      run: |
        suspicious=$(grep -ri "password\s*=\|pwd\s*=\|sa\s" --include="*.sql" . || true)
        if [ ! -z "$suspicious" ]; then
          echo "⚠️  Warning: Potential hardcoded credentials found"
          echo "$suspicious"
          exit 1
        fi
        echo "✓ No hardcoded credentials detected"
    
    - name: Verify header documentation
      run: |
        files_without_headers=0
        for file in $(find Tables Procedures Views Functions -name "*.sql" -type f); do
          if ! grep -q "Object Type:" "$file"; then
            echo "❌ Missing header: $file"
            files_without_headers=$((files_without_headers + 1))
          fi
        done
        
        if [ $files_without_headers -gt 0 ]; then
          echo ""
          echo "❌ $files_without_headers file(s) missing proper headers"
          exit 1
        fi
        echo "✓ All files have proper headers"
```

---

## VS Code Tasks

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Create New Migration",
      "type": "shell",
      "command": "powershell",
      "args": [
        "-File",
        "${workspaceFolder}/Scripts/db-helper.ps1",
        "-NewMigration"
      ],
      "problemMatcher": []
    },
    {
      "label": "Validate Migrations",
      "type": "shell",
      "command": "powershell",
      "args": [
        "-File",
        "${workspaceFolder}/Scripts/db-helper.ps1",
        "-Validate"
      ],
      "problemMatcher": []
    },
    {
      "label": "List All Migrations",
      "type": "shell",
      "command": "powershell",
      "args": [
        "-File",
        "${workspaceFolder}/Scripts/db-helper.ps1",
        "-ListMigrations"
      ],
      "problemMatcher": []
    }
  ]
}
```

---

## Monitoring and Alerts

### Post-Deployment Verification Script

Create `Scripts/verify-deployment.sql`:

```sql
/*******************************************************************************
 * Post-Deployment Verification Script
 * Run this after deploying to verify database health
 ******************************************************************************/

PRINT '=== Starting Post-Deployment Verification ===';
PRINT '';

-- Check SchemaVersion table
PRINT 'Checking SchemaVersion table...';
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SchemaVersion')
BEGIN
    RAISERROR('❌ SchemaVersion table not found!', 16, 1);
END
ELSE
BEGIN
    DECLARE @MigrationCount INT;
    SELECT @MigrationCount = COUNT(*) FROM [dbo].[SchemaVersion] WHERE [Success] = 1;
    PRINT '✓ SchemaVersion table exists';
    PRINT '  Applied migrations: ' + CAST(@MigrationCount AS NVARCHAR(10));
END
PRINT '';

-- Check for failed migrations
PRINT 'Checking for failed migrations...';
DECLARE @FailedCount INT;
SELECT @FailedCount = COUNT(*) FROM [dbo].[SchemaVersion] WHERE [Success] = 0;
IF @FailedCount > 0
BEGIN
    PRINT '⚠️  Found ' + CAST(@FailedCount AS NVARCHAR(10)) + ' failed migration(s)';
    SELECT [MigrationName], [Description], [AppliedDate]
    FROM [dbo].[SchemaVersion]
    WHERE [Success] = 0
    ORDER BY [AppliedDate] DESC;
END
ELSE
BEGIN
    PRINT '✓ No failed migrations';
END
PRINT '';

-- Check table counts
PRINT 'Checking table counts...';
PRINT '  User tables: ' + CAST((SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS NVARCHAR(10));
PRINT '  Views: ' + CAST((SELECT COUNT(*) FROM sys.views WHERE is_ms_shipped = 0) AS NVARCHAR(10));
PRINT '  Stored procedures: ' + CAST((SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) AS NVARCHAR(10));
PRINT '  Functions: ' + CAST((SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN', 'TF', 'IF') AND is_ms_shipped = 0) AS NVARCHAR(10));
PRINT '';

PRINT '=== Verification Complete ===';
```

---

**Last Updated**: March 9, 2026

**Note**: Adjust these configurations based on your specific deployment environment and security requirements.
