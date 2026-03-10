<#
.SYNOPSIS
    Helper script for Solasta Database development tasks

.DESCRIPTION
    Provides utilities for creating migrations, validating scripts, and managing database objects

.EXAMPLE
    .\db-helper.ps1 -NewMigration -Description "CreateUsersTable"
    .\db-helper.ps1 -Validate
    .\db-helper.ps1 -GenerateTimestamp
#>

param(
    [Parameter(ParameterSetName='NewMigration')]
    [switch]$NewMigration,
    
    [Parameter(ParameterSetName='NewTable')]
    [switch]$NewTable,
    
    [Parameter(ParameterSetName='NewProcedure')]
    [switch]$NewProcedure,
    
    [Parameter(ParameterSetName='NewView')]
    [switch]$NewView,
    
    [Parameter(ParameterSetName='Validate')]
    [switch]$Validate,
    
    [Parameter(ParameterSetName='GenerateTimestamp')]
    [switch]$GenerateTimestamp,
    
    [Parameter(ParameterSetName='ListMigrations')]
    [switch]$ListMigrations,
    
    [Parameter(ParameterSetName='NewMigration', Mandatory=$false)]
    [Parameter(ParameterSetName='NewTable', Mandatory=$false)]
    [Parameter(ParameterSetName='NewProcedure', Mandatory=$false)]
    [Parameter(ParameterSetName='NewView', Mandatory=$false)]
    [string]$Description,
    
    [Parameter(ParameterSetName='NewTable', Mandatory=$false)]
    [Parameter(ParameterSetName='NewProcedure', Mandatory=$false)]
    [Parameter(ParameterSetName='NewView', Mandatory=$false)]
    [ValidateSet('dbo', 'app', 'config', 'audit', 'reporting')]
    [string]$Schema = 'dbo',
    
    [Parameter(ParameterSetName='NewTable', Mandatory=$false)]
    [Parameter(ParameterSetName='NewProcedure', Mandatory=$false)]
    [Parameter(ParameterSetName='NewView', Mandatory=$false)]
    [string]$ObjectName,
    
    [Parameter(ParameterSetName='Validate')]
    [string]$MigrationFile
)

# Helper function to get UTC timestamp
function Get-MigrationTimestamp {
    return (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmm")
}

# Helper function to get current date in YYYY-MM-DD format
function Get-CurrentDate {
    return Get-Date -Format "yyyy-MM-dd"
}

# Create new migration file
function New-MigrationFile {
    param([string]$Description)
    
    if ([string]::IsNullOrWhiteSpace($Description)) {
        $Description = Read-Host "Enter migration description (PascalCase, no spaces)"
    }
    
    $timestamp = Get-MigrationTimestamp
    $filename = "${timestamp}_${Description}.sql"
    $filepath = Join-Path "Migrations" $filename
    
    if (Test-Path $filepath) {
        Write-Error "Migration file already exists: $filepath"
        return
    }
    
    $templatePath = Join-Path "Migrations" "TEMPLATE_Migration.sql"
    
    if (!(Test-Path $templatePath)) {
        Write-Error "Template file not found: $templatePath"
        return
    }
    
    # Copy template and replace placeholders
    $content = Get-Content $templatePath -Raw
    $content = $content -replace 'YYYYMMDD_HHMM_DescriptionOfChange', "${timestamp}_${Description}"
    $content = $content -replace 'Your Name', $env:USERNAME
    $content = $content -replace 'YYYY-MM-DD', (Get-CurrentDate)
    
    Set-Content -Path $filepath -Value $content
    
    Write-Host "✓ Created migration file: $filepath" -ForegroundColor Green
    Write-Host "  Timestamp: $timestamp" -ForegroundColor Cyan
    Write-Host "  Next steps:" -ForegroundColor Yellow
    Write-Host "    1. Edit the migration file and add your changes"
    Write-Host "    2. Test the migration locally"
    Write-Host "    3. Commit the changes"
}

# Create new table file
function New-TableFile {
    param(
        [string]$Schema,
        [string]$ObjectName
    )
    
    if ([string]::IsNullOrWhiteSpace($ObjectName)) {
        $ObjectName = Read-Host "Enter table name (PascalCase)"
    }
    
    $directory = Join-Path "Tables" $Schema
    $filepath = Join-Path $directory "${ObjectName}.sql"
    
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if (Test-Path $filepath) {
        Write-Error "Table file already exists: $filepath"
        return
    }
    
    $template = @"
/*******************************************************************************
 * Object Type: Table
 * Schema: $Schema
 * Name: $ObjectName
 * Description: TODO: Add description
 * Author: $env:USERNAME
 * Created: $(Get-CurrentDate)
 ******************************************************************************/

CREATE TABLE [$Schema].[$ObjectName]
(
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [CreatedBy] NVARCHAR(50) NULL,
    [ModifiedDate] DATETIME2 NULL,
    [ModifiedBy] NVARCHAR(50) NULL,
    
    CONSTRAINT PK_$ObjectName PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
"@
    
    Set-Content -Path $filepath -Value $template
    
    Write-Host "✓ Created table file: $filepath" -ForegroundColor Green
    Write-Host "  Remember to:" -ForegroundColor Yellow
    Write-Host "    1. Create a migration for this table"
    Write-Host "    2. Customize the columns"
    Write-Host "    3. Add appropriate indexes and constraints"
}

# Create new stored procedure file
function New-ProcedureFile {
    param(
        [string]$Schema,
        [string]$ObjectName
    )
    
    if ([string]::IsNullOrWhiteSpace($ObjectName)) {
        $ObjectName = Read-Host "Enter procedure name (sp_ProcedureName)"
    }
    
    $directory = Join-Path "Procedures" $Schema
    $filepath = Join-Path $directory "${ObjectName}.sql"
    
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if (Test-Path $filepath) {
        Write-Error "Procedure file already exists: $filepath"
        return
    }
    
    $template = @"
/*******************************************************************************
 * Object Type: Stored Procedure
 * Schema: $Schema
 * Name: $ObjectName
 * Description: TODO: Add description
 * Parameters: 
 *   @Param1 - TODO: Add parameter description
 * Returns: TODO: Add return description
 * Author: $env:USERNAME
 * Created: $(Get-CurrentDate)
 * Example:
 *   EXEC [$Schema].[$ObjectName] @Param1 = 1;
 ******************************************************************************/

IF OBJECT_ID('[$Schema].[$ObjectName]', 'P') IS NOT NULL
    DROP PROCEDURE [$Schema].[$ObjectName];
GO

CREATE PROCEDURE [$Schema].[$ObjectName]
    @Param1 INT,
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- TODO: Add procedure logic
        
        COMMIT TRANSACTION;
        RETURN 0; -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -1; -- Error
    END CATCH
END
GO
"@
    
    Set-Content -Path $filepath -Value $template
    
    Write-Host "✓ Created procedure file: $filepath" -ForegroundColor Green
}

# Create new view file
function New-ViewFile {
    param(
        [string]$Schema,
        [string]$ObjectName
    )
    
    if ([string]::IsNullOrWhiteSpace($ObjectName)) {
        $ObjectName = Read-Host "Enter view name (vw_ViewName)"
    }
    
    $directory = Join-Path "Views" $Schema
    $filepath = Join-Path $directory "${ObjectName}.sql"
    
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if (Test-Path $filepath) {
        Write-Error "View file already exists: $filepath"
        return
    }
    
    $template = @"
/*******************************************************************************
 * Object Type: View
 * Schema: $Schema
 * Name: $ObjectName
 * Description: TODO: Add description
 * Dependencies: TODO: List dependent tables/views
 * Author: $env:USERNAME
 * Created: $(Get-CurrentDate)
 ******************************************************************************/

IF OBJECT_ID('[$Schema].[$ObjectName]', 'V') IS NOT NULL
    DROP VIEW [$Schema].[$ObjectName];
GO

CREATE VIEW [$Schema].[$ObjectName]
AS
    SELECT 
        [Id],
        [Name],
        [Description]
    FROM 
        [$Schema].[TableName]
    WHERE 
        [IsActive] = 1;
GO
"@
    
    Set-Content -Path $filepath -Value $template
    
    Write-Host "✓ Created view file: $filepath" -ForegroundColor Green
}

# Validate migration file
function Test-MigrationFile {
    param([string]$FilePath)
    
    Write-Host "Validating: $FilePath" -ForegroundColor Cyan
    
    if (!(Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    $content = Get-Content $FilePath -Raw
    $errors = @()
    
    # Check for header
    if ($content -notmatch '/\*\s*Migration:') {
        $errors += "Missing migration header comment"
    }
    
    # Check for transaction wrapper
    if ($content -notmatch 'BEGIN TRANSACTION') {
        $errors += "Missing BEGIN TRANSACTION"
    }
    
    # Check for try-catch
    if ($content -notmatch 'BEGIN TRY') {
        $errors += "Missing TRY...CATCH block"
    }
    
    # Check for SchemaVersion check
    if ($content -notmatch 'SchemaVersion') {
        $errors += "Missing SchemaVersion table check"
    }
    
    # Check for rollback section
    if ($content -notmatch 'ROLLBACK') {
        $errors += "Missing rollback instructions"
    }
    
    # Check filename format
    if ($FilePath -match 'Migrations\\(.+)\.sql$') {
        $filename = $matches[1]
        if ($filename -notmatch '^\d{8}_\d{4}_.+$') {
            $errors += "Invalid filename format. Expected: YYYYMMDD_HHMM_Description.sql"
        }
    }
    
    if ($errors.Count -eq 0) {
        Write-Host "✓ Validation passed" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Validation failed:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        return $false
    }
}

# Validate all migration files
function Test-AllMigrations {
    Write-Host "Validating all migration files..." -ForegroundColor Cyan
    
    $migrationFiles = Get-ChildItem -Path "Migrations" -Filter "*.sql" -Exclude "TEMPLATE_Migration.sql", "00000000_0000_CreateSchemaVersionTable.sql"
    
    $totalFiles = $migrationFiles.Count
    $passedFiles = 0
    $failedFiles = @()
    
    foreach ($file in $migrationFiles) {
        if (Test-MigrationFile -FilePath $file.FullName) {
            $passedFiles++
        } else {
            $failedFiles += $file.Name
        }
    }
    
    Write-Host "`nValidation Summary:" -ForegroundColor Cyan
    Write-Host "  Total files: $totalFiles" -ForegroundColor White
    Write-Host "  Passed: $passedFiles" -ForegroundColor Green
    Write-Host "  Failed: $($failedFiles.Count)" -ForegroundColor $(if ($failedFiles.Count -eq 0) { 'Green' } else { 'Red' })
    
    if ($failedFiles.Count -gt 0) {
        Write-Host "`nFailed files:" -ForegroundColor Yellow
        foreach ($file in $failedFiles) {
            Write-Host "  - $file" -ForegroundColor Red
        }
    }
}

# List all migrations
function Get-MigrationList {
    Write-Host "Migration Files:" -ForegroundColor Cyan
    
    $migrationFiles = Get-ChildItem -Path "Migrations" -Filter "*.sql" -Exclude "TEMPLATE_Migration.sql", "00000000_0000_CreateSchemaVersionTable.sql" | 
        Sort-Object Name
    
    foreach ($file in $migrationFiles) {
        # Extract migration name from file
        if ($file.Name -match '^(\d{8}_\d{4})_(.+)\.sql$') {
            $timestamp = $matches[1]
            $description = $matches[2]
            
            # Parse the timestamp
            if ($timestamp -match '^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})$') {
                $year = $matches[1]
                $month = $matches[2]
                $day = $matches[3]
                $hour = $matches[4]
                $minute = $matches[5]
                
                $dateStr = "$year-$month-$day $hour:$minute UTC"
                Write-Host "  $timestamp" -ForegroundColor Yellow -NoNewline
                Write-Host " | " -NoNewline
                Write-Host "$description" -ForegroundColor Green -NoNewline
                Write-Host " | $dateStr" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "`nTotal migrations: $($migrationFiles.Count)" -ForegroundColor Cyan
}

# Main execution
try {
    switch ($PSCmdlet.ParameterSetName) {
        'NewMigration' {
            New-MigrationFile -Description $Description
        }
        'NewTable' {
            New-TableFile -Schema $Schema -ObjectName $ObjectName
        }
        'NewProcedure' {
            New-ProcedureFile -Schema $Schema -ObjectName $ObjectName
        }
        'NewView' {
            New-ViewFile -Schema $Schema -ObjectName $ObjectName
        }
        'Validate' {
            if ($MigrationFile) {
                Test-MigrationFile -FilePath $MigrationFile
            } else {
                Test-AllMigrations
            }
        }
        'GenerateTimestamp' {
            $timestamp = Get-MigrationTimestamp
            Write-Host $timestamp -ForegroundColor Green
            Write-Host "Copied to clipboard" -ForegroundColor Cyan
            Set-Clipboard -Value $timestamp
        }
        'ListMigrations' {
            Get-MigrationList
        }
        default {
            Write-Host "Solasta Database Helper Script" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "  .\db-helper.ps1 -NewMigration [-Description 'CreateUsersTable']"
            Write-Host "  .\db-helper.ps1 -NewTable [-Schema dbo] [-ObjectName Users]"
            Write-Host "  .\db-helper.ps1 -NewProcedure [-Schema dbo] [-ObjectName sp_GetUser]"
            Write-Host "  .\db-helper.ps1 -NewView [-Schema reporting] [-ObjectName vw_Sales]"
            Write-Host "  .\db-helper.ps1 -Validate [-MigrationFile 'path\to\migration.sql']"
            Write-Host "  .\db-helper.ps1 -ListMigrations"
            Write-Host "  .\db-helper.ps1 -GenerateTimestamp"
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  .\db-helper.ps1 -NewMigration -Description 'AddEmailToUsers'"
            Write-Host "  .\db-helper.ps1 -NewTable -Schema dbo -ObjectName Products"
            Write-Host "  .\db-helper.ps1 -Validate"
            Write-Host "  .\db-helper.ps1 -ListMigrations"
        }
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
