<#
.SYNOPSIS
    Applies 20261120_0100_AddINE_PartVariants (part variants: colors/options the customer picks) and
    20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice (converting a stocked item to colors, and who picked a
    quote line's color), first to local Dev and then to Prod.

.DESCRIPTION
    Runs only these migrations, in order, through Deploy_Migrations.ps1 with -MigrationFilter set to its exact file name and
    -StopOnError, so older migrations that are still pending and known to fail (e.g. 20260506_1200) are never touched.

    It adds ParentStockItemId, VariantName and PriceAdder to INE.StockItems, the new empty table
    INE.StockItemVariantAttributes, StockItemId / VariantName / VariantPriceAdder to MAC.QuoteLines, new variant
    guard triggers, and alters spMovementPost, spAllocationCreate, spStockCountPost and three INE views.
    Existing rows are not changed. The second adds INE.spStockItemConvertToVariants, alters two INE triggers and adds
    VariantChosenBy, VariantChosenDate and VariantChosenSignatureId to MAC.QuoteLines.

    Before running, the script checks its prerequisites in dbo.SchemaVersion and stops if one is missing.
    After running, it checks that the migration is recorded and that the new columns and table exist.
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

.PARAMETER CredentialName
    Load the SQL login saved with Save-DeployCredential.ps1 under this name (DPAPI, your Windows account only),
    instead of -Credential.

.PARAMETER ConfirmTarget
    For Prod, the 'server/database' text you would otherwise type at the prompt. It must match exactly; use it only
    when you have already decided to run against that database (for example when you ask Claude to run it).

.PARAMETER WhatIf
    Show the checks and what would run, without changing anything.

.EXAMPLE
    # 1. Local Dev
    .\Deploy_20261120_INE_PartVariants.ps1 -Environment Dev -WhatIf
    .\Deploy_20261120_INE_PartVariants.ps1 -Environment Dev

.EXAMPLE
    # 2. Prod: preview, then run
    .\Deploy_20261120_INE_PartVariants.ps1 -Environment Prod -ServerInstance "SOLITMDB001" -Credential (Get-Credential) -WhatIf
    .\Deploy_20261120_INE_PartVariants.ps1 -Environment Prod -ServerInstance "SOLITMDB001" -Credential (Get-Credential)

.NOTES
    Needs Invoke-Sqlcmd (SqlServer or SQLPS module), as Deploy_Migrations.ps1 does.
    Deploy the database before the API (solasta-lighting-est-api) that maps the new columns: EF selects them on
    every stock item and quote line read and fails while they are missing.
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
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$CredentialName,

    [Parameter(Mandatory = $false)]
    [string]$ConfirmTarget,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ServerInstance) {
    if ($Environment -eq 'Prod') { throw 'Prod needs -ServerInstance.' }
    $ServerInstance = 'DESKTOP-GAHBRKG'
}

if ($CredentialName) {
    if ($Credential) { throw 'Use -Credential or -CredentialName, not both.' }
    $savedPath = Join-Path $env:APPDATA "Solasta\DeployCredentials\$CredentialName.xml"
    if (-not (Test-Path $savedPath)) { throw "No saved login '$CredentialName'. Run .\Save-DeployCredential.ps1 -Name $CredentialName first." }
    $Credential = Import-Clixml -Path $savedPath
}

$DeployScript = Join-Path $PSScriptRoot 'Deploy_Migrations.ps1'

# The migrations to run, in order, each with the migrations it depends on.
$Plan = @(
    [pscustomobject]@{
        Name     = '20261120_0100_AddINE_PartVariants'
        Requires = @('20261117_1900_AddINE_AuditAndTenantGuards', '20261117_2230_AddMAC_QuoteBuilder')
    },
    [pscustomobject]@{
        Name     = '20261120_0300_AddINE_ConvertToVariantsAndQuoteColorChoice'
        Requires = @('20261120_0100_AddINE_PartVariants', '20261117_2330_AddMAC_QuoteSigning')
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
Write-Host "=== INE part variants: $Environment ($ServerInstance / $Database) ===" -ForegroundColor Cyan

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
    Write-Host 'Nothing to do: the migration is already applied.' -ForegroundColor Green
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
    if ($ConfirmTarget) {
        $typed = $ConfirmTarget
        Write-Host "Confirmed by -ConfirmTarget '$ConfirmTarget'." -ForegroundColor Yellow
    } else {
        $typed = Read-Host "Type '$expected' to continue"
    }
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
    CASE WHEN COL_LENGTH(N'INE.StockItems', N'ParentStockItemId') IS NOT NULL
          AND COL_LENGTH(N'INE.StockItems', N'VariantName') IS NOT NULL
          AND COL_LENGTH(N'INE.StockItems', N'PriceAdder') IS NOT NULL THEN 1 ELSE 0 END AS StockItemColumns,
    CASE WHEN OBJECT_ID(N'INE.StockItemVariantAttributes', N'U') IS NOT NULL THEN 1 ELSE 0 END AS AttributesTable,
    CASE WHEN COL_LENGTH(N'MAC.QuoteLines', N'StockItemId') IS NOT NULL
          AND COL_LENGTH(N'MAC.QuoteLines', N'VariantName') IS NOT NULL
          AND COL_LENGTH(N'MAC.QuoteLines', N'VariantPriceAdder') IS NOT NULL
          AND COL_LENGTH(N'MAC.QuoteLines', N'VariantChosenBy') IS NOT NULL THEN 1 ELSE 0 END AS QuoteLineColumns,
    CASE WHEN OBJECT_ID(N'INE.spStockItemConvertToVariants', N'P') IS NOT NULL THEN 1 ELSE 0 END AS ConvertProcedure,
    (SELECT COUNT(*) FROM sys.triggers WHERE name IN ('tr_StockItems_VariantGuard', 'tr_PurchaseOrderLines_VariantGuard',
        'tr_StockCountLines_VariantGuard', 'tr_StockLevels_VariantGuard', 'tr_StockItemVariantAttributes_TenantGuard',
        'trgAutoGen_StockItemVariantAttributes_CUD')) AS VariantTriggers;
"@
foreach ($c in @('StockItemColumns', 'AttributesTable', 'QuoteLineColumns', 'ConvertProcedure')) {
    if ($check.$c -eq 1) {
        Write-Host "  [ok]   $c" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $c missing" -ForegroundColor Red
        $ok = $false
    }
}
if ($check.VariantTriggers -eq 6) {
    Write-Host '  [ok]   variant triggers: 6 of 6' -ForegroundColor Green
} else {
    Write-Host "  [FAIL] variant triggers: $($check.VariantTriggers) of 6" -ForegroundColor Red
    $ok = $false
}

Write-Host ''
if ($ok) {
    Write-Host "Done: $Environment is up to date." -ForegroundColor Green
    exit 0
}
Write-Host "Finished with problems on $Environment. Check the messages above before going on." -ForegroundColor Red
exit 1
