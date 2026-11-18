<#
.SYNOPSIS
    Applies the two migrations SOL_MAIN is missing for the INE tenant guards and quote signing, first to local
    Dev and then to Prod.

.DESCRIPTION
    Runs, in this order and only these two:
      1. 20261117_1900_AddINE_AuditAndTenantGuards   INE audit (trgAutoGen_*_CUD) and tenant guard triggers,
                                                     spMovementPost fix
      2. 20261117_2330_AddMAC_QuoteSigning           MAC.QuoteSignatures, ACE.trgAutoGen_Customers_CUD fix,
                                                     FK_Estimates_Customers move

    Each one goes through Deploy_Migrations.ps1 with -MigrationFilter set to its exact file name and -StopOnError,
    so the older migrations that are still pending and known to fail (e.g. 20260506_1200) are never touched.

    Before running, the script checks the prerequisites in dbo.SchemaVersion and stops if one is missing.
    After running, it checks that both migrations are recorded and that their objects exist.
    Prod asks you to type the server and database name before anything runs.

.PARAMETER Environment
    Dev (local, Windows auth against DESKTOP-GAHBRKG by default) or Prod.

.PARAMETER ServerInstance
    SQL Server instance. Defaults to DESKTOP-GAHBRKG for Dev. Required for Prod.

.PARAMETER Database
    Target database. Default SOL_MAIN.

.PARAMETER Credential
    SQL login to use instead of Windows auth. Pass (Get-Credential) to be prompted; never put a password on the
    command line or in this file.

.PARAMETER WhatIf
    Show the checks and what would run, without changing anything.

.EXAMPLE
    # 1. Local Dev, preview then run (Windows auth)
    .\Deploy_20261117_INE_QuoteSigning.ps1 -Environment Dev -WhatIf
    .\Deploy_20261117_INE_QuoteSigning.ps1 -Environment Dev

.EXAMPLE
    # 2. Prod, after Dev succeeded, during a quiet window
    .\Deploy_20261117_INE_QuoteSigning.ps1 -Environment Prod -ServerInstance "SOLITMDB001" -Credential (Get-Credential) -WhatIf
    .\Deploy_20261117_INE_QuoteSigning.ps1 -Environment Prod -ServerInstance "SOLITMDB001" -Credential (Get-Credential)

.NOTES
    Needs Invoke-Sqlcmd (SqlServer or SQLPS module), as Deploy_Migrations.ps1 does.
    Deploy the API (solasta-lighting-est-api, TableTriggers already lists the INE triggers) after Prod succeeds;
    the API's quote signing endpoints need MAC.QuoteSignatures.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Dev', 'Prod')]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$Database = 'SOL_MAIN',

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ServerInstance) {
    if ($Environment -eq 'Prod') { throw 'Prod needs -ServerInstance.' }
    $ServerInstance = 'DESKTOP-GAHBRKG'
}

$DeployScript = Join-Path $PSScriptRoot 'Deploy_Migrations.ps1'

# The migrations to run, in order, each with the migrations it depends on.
$Plan = @(
    [pscustomobject]@{
        Name     = '20261117_1900_AddINE_AuditAndTenantGuards'
        Requires = @('20261117_1810_CreateINE_InventoryEngineProcedures')
    },
    [pscustomobject]@{
        Name     = '20261117_2330_AddMAC_QuoteSigning'
        Requires = @('20261024_1637_CreateDOCDocuments', '20261117_0340_AddQAL_LeadIntake', '20261117_2230_AddMAC_QuoteBuilder')
    }
)

function Get-SqlParams {
    $p = @{ ServerInstance = $ServerInstance; Database = $Database; QueryTimeout = 120 }
    if ($Credential) {
        $p['Username'] = $Credential.UserName
        $p['Password'] = $Credential.GetNetworkCredential().Password
    }
    return $p
}

function Invoke-Query([string]$Query) {
    $sqlParams = Get-SqlParams
    return Invoke-Sqlcmd @sqlParams -Query $Query
}

function Get-Applied {
    return @(Invoke-Query 'SELECT [MigrationName] FROM [dbo].[SchemaVersion] WHERE [Success] = 1;' |
        ForEach-Object { $_.MigrationName })
}

Write-Host ''
Write-Host "=== INE tenant guards + quote signing: $Environment ($ServerInstance / $Database) ===" -ForegroundColor Cyan

# --- Pre-checks -----------------------------------------------------------------------------------------------
$applied = Get-Applied
$pending = @()
$missing = @()
$sequence = @($Plan | ForEach-Object { $_.Name })
foreach ($step in $Plan) {
    if ($applied -contains $step.Name) {
        Write-Host "  [done]    $($step.Name)" -ForegroundColor DarkGray
        continue
    }
    $pending += $step
    Write-Host "  [pending] $($step.Name)" -ForegroundColor Yellow
    foreach ($req in $step.Requires) {
        # A requirement that is itself in this plan is satisfied by running the plan in order.
        if (($applied -notcontains $req) -and ($sequence -notcontains $req)) { $missing += "$($step.Name) needs $req" }
    }
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'Stopping: prerequisites are not applied:' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

if ($pending.Count -eq 0) {
    Write-Host 'Nothing to do: both migrations are already applied.' -ForegroundColor Green
    exit 0
}

if ($WhatIf) {
    Write-Host ''
    Write-Host "WhatIf: would run $($pending.Count) migration(s) above, in that order. Nothing changed." -ForegroundColor Cyan
    exit 0
}

# --- Prod confirmation ----------------------------------------------------------------------------------------
if ($Environment -eq 'Prod') {
    Write-Host ''
    Write-Host 'This changes PRODUCTION. Run it in Dev first. Take a backup or snapshot of the database before you go on.' -ForegroundColor Red
    $expected = "$ServerInstance/$Database"
    $typed = Read-Host "Type '$expected' to continue"
    if ($typed -ne $expected) {
        Write-Host 'Not confirmed. Nothing changed.' -ForegroundColor Yellow
        exit 1
    }
}

# --- Run ------------------------------------------------------------------------------------------------------
$deployArgs = @{ ServerInstance = $ServerInstance; Database = $Database; StopOnError = $true }
if ($Credential) {
    $deployArgs['Username'] = $Credential.UserName
    $deployArgs['Password'] = $Credential.GetNetworkCredential().Password
}

foreach ($step in $pending) {
    Write-Host ''
    Write-Host "--> $($step.Name)" -ForegroundColor Cyan
    & $DeployScript @deployArgs -MigrationFilter "$($step.Name).sql"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Stopped: $($step.Name) failed. See the log in $PSScriptRoot. Later steps were not run." -ForegroundColor Red
        exit 1
    }
}

# --- Post-checks ----------------------------------------------------------------------------------------------
Write-Host ''
Write-Host 'Checking the result...' -ForegroundColor Cyan
$applied = Get-Applied
$ok = $true
foreach ($step in $Plan) {
    if ($applied -contains $step.Name) {
        Write-Host "  [ok]   recorded: $($step.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] not recorded: $($step.Name)" -ForegroundColor Red
        $ok = $false
    }
}

$check = Invoke-Query @"
SELECT
    CASE WHEN OBJECT_ID('MAC.QuoteSignatures', 'U') IS NULL THEN 0 ELSE 1 END AS HasQuoteSignatures,
    (SELECT COUNT(*) FROM sys.triggers t
       WHERE t.parent_class = 1 AND OBJECT_SCHEMA_NAME(t.parent_id) = 'INE'
         AND (t.name LIKE 'tr[_]%[_]TenantGuard' OR t.name LIKE 'trgAutoGen[_]%[_]CUD')) AS IneGuardAndAuditTriggers;
"@
if ($check.HasQuoteSignatures -eq 1) {
    Write-Host '  [ok]   MAC.QuoteSignatures exists' -ForegroundColor Green
} else {
    Write-Host '  [FAIL] MAC.QuoteSignatures is missing' -ForegroundColor Red
    $ok = $false
}
# 9 tenant guards + 6 audit triggers
if ($check.IneGuardAndAuditTriggers -ge 15) {
    Write-Host "  [ok]   INE tenant guard and audit triggers: $($check.IneGuardAndAuditTriggers)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] INE tenant guard and audit triggers: $($check.IneGuardAndAuditTriggers) (expected 15)" -ForegroundColor Red
    $ok = $false
}

Write-Host ''
if ($ok) {
    Write-Host "Done: $Environment is up to date." -ForegroundColor Green
    exit 0
}
Write-Host "Finished with problems on $Environment. Check the messages above before going on." -ForegroundColor Red
exit 1
