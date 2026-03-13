<#
.SYNOPSIS
    Deploys the full SOL_MAIN database baseline to a target SQL Server instance.

.DESCRIPTION
    Executes all baseline database objects in correct deployment order:
      1. Bootstrap    - SchemaVersion table (00000000_0000_CreateSchemaVersionTable.sql)
      2. Migrations   - Baseline schema creation (20260313_0845_Baseline_Schemas.sql)
      3. Functions    - All 25 user-defined functions (must precede tables with computed columns)
      4. Tables       - All 90 table definitions (two passes for cross-schema FK resolution)
      5. Views        - All 37 view definitions
      6. Procedures   - All 130 stored procedures
      7. Triggers     - All 7 table triggers
      8. Finalize     - Records 20260313_0846_Baseline_ObjectsDeployed migration marker

    All scripts are idempotent (IF NOT EXISTS guards). Safe to re-run if interrupted.

.PARAMETER ServerInstance
    Target SQL Server instance name (e.g. "DESKTOP-GAHBRKG", "SOLITMDB001", "server\instance").

.PARAMETER Database
    Target database name (e.g. "SOL_MAIN").

.PARAMETER Username
    SQL Server login username. If omitted, Windows Integrated Authentication is used.

.PARAMETER Password
    SQL Server login password. Required when Username is specified.

.PARAMETER WhatIf
    Simulates the deployment without executing any SQL. Lists all files that would be run.

.PARAMETER StopOnError
    If specified, halts deployment at the first file that produces an error.
    Default behaviour: logs errors and continues.

.EXAMPLE
    # Deploy to local instance using Windows auth
    .\Deploy_Baseline.ps1 -ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN"

.EXAMPLE
    # Deploy to remote server using SQL auth
    .\Deploy_Baseline.ps1 -ServerInstance "SOLITMDB001" -Database "SOL_MAIN" `
                          -Username "deploy_user" -Password "StrongP@ss!"

.EXAMPLE
    # Preview all files that would be deployed (no SQL executed)
    .\Deploy_Baseline.ps1 -ServerInstance "SOLITMDB001" -Database "SOL_MAIN" -WhatIf

.NOTES
    Prerequisites:
      - SQL Server PowerShell module (SqlServer) or SQLPS must be installed.
        Install-Module -Name SqlServer -Force
      - Target database must already exist (CREATE DATABASE is out of scope).
      - Run as a user with db_owner or ddl_admin rights on the target database.

    Run order follows the DATABASE_CONSTITUTION.md deployment order:
      Schemas → Tables → Views → Functions → Procedures

    FK Dependencies:
      Tables are executed in two passes. The first pass creates all tables.
      The second pass applies any cross-schema FK constraints that may have
      failed on the first pass because the referenced table did not exist yet.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $false)]
    [string]$Username,

    [Parameter(Mandatory = $false)]
    [string]$Password,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [switch]$StopOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
$RepoRoot    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$MigrDir     = Join-Path $RepoRoot "Migrations"
$TablesDir   = Join-Path $RepoRoot "Tables"
$ViewsDir    = Join-Path $RepoRoot "Views"
$FunctionsDir= Join-Path $RepoRoot "Functions"
$ProcsDir    = Join-Path $RepoRoot "Procedures"
$TriggersDir = Join-Path $RepoRoot "Triggers"

# -----------------------------------------------------------------------------
# Counters
# -----------------------------------------------------------------------------
$script:PassCount  = 0
$script:FailCount  = 0
$script:SkipCount  = 0
$script:Errors     = [System.Collections.Generic.List[string]]::new()
$script:StartTime  = Get-Date

# -----------------------------------------------------------------------------
# Helper: Build Invoke-Sqlcmd common parameters
# -----------------------------------------------------------------------------
function Get-SqlParams {
    $p = @{
        ServerInstance  = $ServerInstance
        Database        = $Database
        OutputSqlErrors = $true
        Verbose         = $false
        QueryTimeout    = 300
    }
    if ($Username) {
        $p['Username'] = $Username
        $p['Password'] = $Password
    }
    return $p
}

# -----------------------------------------------------------------------------
# Helper: Execute a single SQL file
# -----------------------------------------------------------------------------
function Invoke-SqlFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$FilePath,
        [string]$Label = ''
    )

    $relPath = $FilePath.Replace($RepoRoot, '').TrimStart('\')
    $display = if ($Label) { $Label } else { $relPath }

    if ($WhatIf.IsPresent) {
        Write-Host "  [WHATIF] Would execute: $relPath" -ForegroundColor DarkCyan
        $script:SkipCount++
        return $true
    }

    try {
        $sqlParams = Get-SqlParams
        Invoke-Sqlcmd @sqlParams -InputFile $FilePath -ErrorAction Stop | Out-Null
        Write-Host "  [OK]   $display" -ForegroundColor Green
        $script:PassCount++
        return $true
    }
    catch {
        $errMsg = "FAILED: $display`n         $_"
        Write-Host "  [ERR]  $display" -ForegroundColor Red
        Write-Host "         $_" -ForegroundColor DarkRed
        $script:FailCount++
        $script:Errors.Add($errMsg)

        if ($StopOnError) {
            throw "Deployment halted at: $display`n$_"
        }
        return $false
    }
}

# -----------------------------------------------------------------------------
# Helper: Execute all .sql files under a directory, sorted alphabetically
# -----------------------------------------------------------------------------
function Invoke-SqlDirectory {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Directory,
        [string]$SectionLabel
    )

    $files = Get-ChildItem $Directory -Recurse -Filter *.sql | Sort-Object FullName
    if ($files.Count -eq 0) {
        Write-Host "  (no files found in $Directory)" -ForegroundColor DarkYellow
        return
    }

    Write-Host "  $($files.Count) file(s) found" -ForegroundColor DarkGray
    foreach ($f in $files) {
        Invoke-SqlFile -FilePath $f.FullName
    }
}

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host '  Solasta Database - Baseline Deployment' -ForegroundColor Cyan
Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host "  Server   : $ServerInstance"
Write-Host "  Database : $Database"
$authMode = if ($Username) { 'SQL Auth (' + $Username + ')' } else { 'Windows Integrated' }
Write-Host "  Auth     : $authMode"
Write-Host "  WhatIf   : $($WhatIf.IsPresent)"
Write-Host "  Started  : $($script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# Validate prerequisites
# -----------------------------------------------------------------------------
if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Invoke-Sqlcmd not found." -ForegroundColor Red
    Write-Host "        Install the SqlServer module:  Install-Module -Name SqlServer -Force" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $RepoRoot)) {
    Write-Host "[ERROR] Repository root not found: $RepoRoot" -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------------------------
# STEP 1: Bootstrap SchemaVersion table
# -----------------------------------------------------------------------------
Write-Host "STEP 1/8  Bootstrap - SchemaVersion table" -ForegroundColor Yellow
$bootstrapFile = Join-Path $MigrDir "00000000_0000_CreateSchemaVersionTable.sql"
if (Test-Path $bootstrapFile) {
    Invoke-SqlFile -FilePath $bootstrapFile -Label "00000000_0000_CreateSchemaVersionTable.sql"
} else {
    Write-Host "  [WARN] Bootstrap file not found: $bootstrapFile" -ForegroundColor DarkYellow
    Write-Host "         Proceeding -- SchemaVersion table may already exist." -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 2: Create schemas
# -----------------------------------------------------------------------------
Write-Host "STEP 2/8  Migration - Create schemas" -ForegroundColor Yellow
$schemasFile = Join-Path $MigrDir "20260313_0845_Baseline_Schemas.sql"
if (Test-Path $schemasFile) {
    Invoke-SqlFile -FilePath $schemasFile -Label "20260313_0845_Baseline_Schemas.sql"
} else {
    Write-Host "  [WARN] Schemas migration file not found: $schemasFile" -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 3: Functions (must run before Tables -- some tables have computed columns
#          that directly reference UTL functions; functions must exist first)
# -----------------------------------------------------------------------------
Write-Host "STEP 3/8  Functions" -ForegroundColor Yellow
Invoke-SqlDirectory -Directory $FunctionsDir -SectionLabel "Functions"
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 4: Tables (Pass 1 -- creates all tables)
# -----------------------------------------------------------------------------
Write-Host "STEP 4/8  Tables (Pass 1 -- CREATE TABLE + same-schema FKs)" -ForegroundColor Yellow
Invoke-SqlDirectory -Directory $TablesDir -SectionLabel "Tables Pass 1"
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 5: Tables (Pass 2 -- applies cross-schema FKs that may have failed pass 1)
# -----------------------------------------------------------------------------
Write-Host "STEP 5/8  Tables (Pass 2 -- cross-schema FK resolution)" -ForegroundColor Yellow
$tableFiles = Get-ChildItem $TablesDir -Recurse -Filter *.sql | Sort-Object FullName
if ($tableFiles.Count -gt 0) {
    Write-Host "  $($tableFiles.Count) file(s) (re-run, no-op for already-created objects)" -ForegroundColor DarkGray
    foreach ($f in $tableFiles) {
        Invoke-SqlFile -FilePath $f.FullName
    }
} else {
    Write-Host "  (no table files found)" -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 6: Views
# -----------------------------------------------------------------------------
Write-Host "STEP 6/8  Views" -ForegroundColor Yellow
Invoke-SqlDirectory -Directory $ViewsDir -SectionLabel "Views"
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 7: Stored Procedures
# -----------------------------------------------------------------------------
Write-Host "STEP 7/8  Stored Procedures" -ForegroundColor Yellow
Invoke-SqlDirectory -Directory $ProcsDir -SectionLabel "Procedures"
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 8: Triggers
# -----------------------------------------------------------------------------
Write-Host "STEP 8/8  Triggers" -ForegroundColor Yellow
Invoke-SqlDirectory -Directory $TriggersDir -SectionLabel "Triggers"
Write-Host ""

# -----------------------------------------------------------------------------
# FINALIZE: Record baseline migration marker (only if all previous steps passed)
# -----------------------------------------------------------------------------
$markerFile = Join-Path $MigrDir "20260313_0846_Baseline_ObjectsDeployed.sql"

if ($script:FailCount -eq 0) {
    Write-Host "FINALIZE  Recording baseline migration marker" -ForegroundColor Yellow
    if (Test-Path $markerFile) {
        Invoke-SqlFile -FilePath $markerFile -Label "20260313_0846_Baseline_ObjectsDeployed.sql"
    } else {
        Write-Host "  [WARN] Marker migration file not found: $markerFile" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "FINALIZE  Skipping migration marker -- deployment completed with errors." -ForegroundColor DarkYellow
    Write-Host "          Resolve errors and re-run to apply the marker migration." -ForegroundColor DarkYellow
}
Write-Host ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
$elapsed = [math]::Round(((Get-Date) - $script:StartTime).TotalSeconds, 1)

Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host '  Deployment Summary' -ForegroundColor Cyan
Write-Host '===========================================================' -ForegroundColor Cyan
Write-Host ("  Passed : {0,4}" -f $script:PassCount) -ForegroundColor Green
$failColor = if ($script:FailCount -gt 0) { 'Red' } else { 'Green' }
Write-Host ("  Failed : {0,4}" -f $script:FailCount) -ForegroundColor $failColor
if ($WhatIf.IsPresent) {
    Write-Host ("  Skipped: {0,4}  (WhatIf mode)" -f $script:SkipCount) -ForegroundColor DarkCyan
}
Write-Host "  Elapsed: ${elapsed}s"
Write-Host '===========================================================' -ForegroundColor Cyan

if ($script:Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failed files:" -ForegroundColor Red
    foreach ($e in $script:Errors) {
        Write-Host "    - $e" -ForegroundColor Red
    }
}

Write-Host ""

if ($script:FailCount -gt 0) {
    Write-Host "  DEPLOYMENT COMPLETED WITH ERRORS." -ForegroundColor Red
    Write-Host "  Review failed files above, fix the issues, and re-run." -ForegroundColor Yellow
    Write-Host "  All scripts are idempotent -- safe to re-run from scratch." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "  DEPLOYMENT SUCCESSFUL." -ForegroundColor Green
    exit 0
}
