<#
.SYNOPSIS
    Runs all pending migrations against a target SQL Server database.

.DESCRIPTION
    Scans the Migrations/ folder for .sql files ordered chronologically by filename
    (YYYYMMDD_HHMM prefix). Skips any migration already recorded in dbo.SchemaVersion.
    Executes pending migrations in order, records each in SchemaVersion, and
    produces a summary report.

    Each migration script is self-protecting: it checks SchemaVersion at the top
    and rolls itself back if already applied. This script adds a second safety layer
    by pre-filtering using a SELECT against SchemaVersion before executing.

.PARAMETER ServerInstance
    Target SQL Server instance (e.g. "DESKTOP-GAHBRKG", "SOLITMDB001", "server\instance").

.PARAMETER Database
    Target database name (e.g. "SOL_MAIN").

.PARAMETER Username
    SQL Server login username. Omit to use Windows Integrated Authentication.

.PARAMETER Password
    SQL Server login password. Required when Username is specified.

.PARAMETER MigrationFilter
    Optional wildcard filter to run only matching migrations.
    Example: "20260504*" runs only migrations from 2026-05-04.

.PARAMETER WhatIf
    Lists pending migrations without executing them.

.PARAMETER StopOnError
    Halts at the first failed migration. Default: logs error and continues.

.EXAMPLE
    # Run all pending migrations using Windows auth
    .\Deploy_Migrations.ps1 -ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN"

.EXAMPLE
    # Run all pending migrations using SQL auth
    .\Deploy_Migrations.ps1 -ServerInstance "SOLITMDB001" -Database "SOL_MAIN" `
                            -Username "deploy_user" -Password "StrongP@ss!"

.EXAMPLE
    # Preview what would run without executing
    .\Deploy_Migrations.ps1 -ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN" -WhatIf

.EXAMPLE
    # Run only AFL migrations from 2026-05-04
    .\Deploy_Migrations.ps1 -ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN" `
                            -MigrationFilter "20260504*"

.NOTES
    Prerequisites:
      - SqlServer PowerShell module must be installed:
          Install-Module -Name SqlServer -Force
      - dbo.SchemaVersion table must exist (run 00000000_0000_CreateSchemaVersionTable.sql first).
      - Run as a user with db_owner or ddl_admin rights on the target database.

    Migration naming convention:
      YYYYMMDD_HHMM_Description.sql  (UTC time in filename)
      Files are sorted by filename — the timestamp prefix IS the execution order.

    Safe to re-run: already-applied migrations are skipped.
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
    [string]$MigrationFilter = '*.sql',

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [switch]$StopOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# -------------------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------------------
$RepoRoot      = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$MigrationsDir = Join-Path $RepoRoot 'Migrations'
$LogFile       = Join-Path $PSScriptRoot "migrations_run_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# -------------------------------------------------------------------------------
# Counters
# -------------------------------------------------------------------------------
$script:Applied  = 0
$script:Skipped  = 0
$script:Failed   = 0
$script:Errors   = [System.Collections.Generic.List[string]]::new()
$script:StartTime = Get-Date

# -------------------------------------------------------------------------------
# Logging
# -------------------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Color = 'White')
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $line
}

# -------------------------------------------------------------------------------
# Build Invoke-Sqlcmd parameter hashtable
# -------------------------------------------------------------------------------
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

# -------------------------------------------------------------------------------
# Retrieve the set of already-applied migration names from SchemaVersion
# -------------------------------------------------------------------------------
function Get-AppliedMigrations {
    try {
        $sqlParams = Get-SqlParams
        $rows = Invoke-Sqlcmd @sqlParams `
            -Query "SELECT [MigrationName] FROM [dbo].[SchemaVersion];" `
            -ErrorAction Stop
        return @($rows | ForEach-Object { $_.MigrationName })
    }
    catch {
        Write-Log "ERROR: Cannot query SchemaVersion table. Has the bootstrap migration been run?" 'Red'
        Write-Log "       Run: Migrations\00000000_0000_CreateSchemaVersionTable.sql" 'DarkRed'
        throw
    }
}

# -------------------------------------------------------------------------------
# Execute a single migration file
# -------------------------------------------------------------------------------
function Invoke-Migration {
    param([System.IO.FileInfo]$File)

    $migrationName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $relPath       = $File.FullName.Replace($RepoRoot, '').TrimStart('\')

    if ($WhatIf) {
        Write-Log "  [PENDING] $relPath" 'DarkCyan'
        return
    }

    Write-Log "  --> Running: $relPath" 'Cyan'
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $sqlParams = Get-SqlParams
        Invoke-Sqlcmd @sqlParams -InputFile $File.FullName -ErrorAction Stop | Out-Null
        $sw.Stop()
        Write-Log "  [OK]  $migrationName  ($($sw.ElapsedMilliseconds) ms)" 'Green'
        $script:Applied++
    }
    catch {
        $sw.Stop()
        $errMsg = "FAILED: $migrationName`n        $_"
        Write-Log "  [ERR] $migrationName" 'Red'
        Write-Log "        $_" 'DarkRed'
        $script:Failed++
        $script:Errors.Add($errMsg)

        if ($StopOnError) {
            throw "Deployment halted at: $migrationName`n$_"
        }
    }
}

# -------------------------------------------------------------------------------
# Verify Invoke-Sqlcmd is available (SqlServer module or SQLPS from SQL Server install)
# -------------------------------------------------------------------------------
$hasSqlServer = Get-Module -ListAvailable -Name SqlServer
$hasSqlPS     = Get-Module -ListAvailable -Name SQLPS

if ($hasSqlServer) {
    Import-Module SqlServer -ErrorAction Stop
}
elseif ($hasSqlPS) {
    # SQLPS ships with SQL Server; suppress the noisy push-location behaviour
    Push-Location
    Import-Module SQLPS -DisableNameChecking -ErrorAction Stop
    Pop-Location
}
else {
    Write-Host "ERROR: Neither the SqlServer nor SQLPS PowerShell module is available." -ForegroundColor Red
    Write-Host "       Install the SqlServer module with:" -ForegroundColor Yellow
    Write-Host "         Install-Module -Name SqlServer -Force -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Invoke-Sqlcmd is not available after importing the SQL module." -ForegroundColor Red
    exit 1
}

# -------------------------------------------------------------------------------
# Header
# -------------------------------------------------------------------------------
Write-Log ''
Write-Log '==========================================================='
Write-Log '  Solasta Database - Migration Runner'
Write-Log '==========================================================='
Write-Log "  Server    : $ServerInstance"
Write-Log "  Database  : $Database"
$authMode = if ($Username) { "SQL Auth ($Username)" } else { 'Windows Integrated' }
Write-Log "  Auth      : $authMode"
Write-Log "  Filter    : $MigrationFilter"
if ($WhatIf) { Write-Log "  Mode      : WHATIF (no SQL will be executed)" 'Yellow' }
Write-Log '-----------------------------------------------------------'

# -------------------------------------------------------------------------------
# Discover migration files
# -------------------------------------------------------------------------------
if (-not (Test-Path $MigrationsDir)) {
    Write-Log "ERROR: Migrations directory not found: $MigrationsDir" 'Red'
    exit 1
}

# Sort alphabetically — the YYYYMMDD_HHMM prefix guarantees chronological order
$allFiles = Get-ChildItem -Path $MigrationsDir -Filter $MigrationFilter |
            Where-Object { $_.Extension -eq '.sql' -and $_.Name -notlike '_*' } |
            Sort-Object Name

if ($allFiles.Count -eq 0) {
    Write-Log "No migration files found matching filter '$MigrationFilter'." 'Yellow'
    exit 0
}

Write-Log "Found $($allFiles.Count) migration file(s) in Migrations/"

# -------------------------------------------------------------------------------
# Determine pending migrations
# -------------------------------------------------------------------------------
$appliedMigrationNames = Get-AppliedMigrations
$pending  = $allFiles | Where-Object {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $name -notin $appliedMigrationNames
}

$alreadyApplied = $allFiles.Count - @($pending).Count
if ($alreadyApplied -gt 0) {
    Write-Log "  Skipping $alreadyApplied already-applied migration(s)." 'DarkGray'
    $script:Skipped = $alreadyApplied
}

if (@($pending).Count -eq 0) {
    Write-Log ''
    Write-Log 'All migrations are up to date. Nothing to run.' 'Green'
    exit 0
}

Write-Log "  $(@($pending).Count) pending migration(s) to run:"
$pending | ForEach-Object { Write-Log "    - $($_.Name)" 'DarkCyan' }
Write-Log '-----------------------------------------------------------'

# -------------------------------------------------------------------------------
# Execute pending migrations in order
# -------------------------------------------------------------------------------
foreach ($file in $pending) {
    Invoke-Migration -File $file
}

# -------------------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------------------
$elapsed = (Get-Date) - $script:StartTime
Write-Log '==========================================================='
Write-Log '  Migration Run Summary'
Write-Log '==========================================================='
Write-Log "  Applied  : $($script:Applied)"  'Green'
Write-Log "  Skipped  : $($script:Skipped)"  'DarkGray'
Write-Log "  Failed   : $($script:Failed)"   $(if ($script:Failed -gt 0) { 'Red' } else { 'White' })
Write-Log "  Duration : $($elapsed.ToString('mm\:ss\.fff'))"
Write-Log "  Log file : $LogFile"

if ($script:Errors.Count -gt 0) {
    Write-Log ''
    Write-Log 'Errors encountered:' 'Red'
    $script:Errors | ForEach-Object { Write-Log "  $_" 'DarkRed' }
}

Write-Log '==========================================================='

if ($WhatIf) {
    Write-Log "WHATIF mode: no migrations were executed." 'Yellow'
    exit 0
}

exit $(if ($script:Failed -gt 0) { 1 } else { 0 })
