<#
.SYNOPSIS
    Applies 20261128_1500_AddMAC_CameraCategory (Camera product category, camera products and per-line quote discounts), first to local Dev and then to Prod.

.DESCRIPTION
    Runs only this migration, through Deploy_Migrations.ps1 with -MigrationFilter set to its exact file name and
    -StopOnError, so older migrations that are still pending and known to fail (e.g. 20260506_1200) are never touched.

    It lets MAC.Products.Category and MAC.QuoteLines.LineType be 'Camera', adds MAC.QuoteLines.ItemDiscount, and seeds
    the Solasta Lighting tenant's camera products (RLN16-410, MC-HEAD-01, NVL-FIBR-60, NVL-INSTL-01), the Reolink
    vendor and the camera parts' stock items (category CAMERA). No existing row changes.

    Before running, the script checks its prerequisites in dbo.SchemaVersion and stops if one is missing.
    After running, it checks that the migration is recorded, the ItemDiscount column exists and the four camera
    products exist.
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
    .\Deploy_20261128_1500_MAC_CameraCategory.ps1 -Environment Dev

.EXAMPLE
    # 2. Prod: preview, then run
    .\Deploy_20261128_1500_MAC_CameraCategory.ps1 -Environment Prod -ServerInstance "SOLITMDB001" -Credential (Get-Credential) -WhatIf
    .\Deploy_20261128_1500_MAC_CameraCategory.ps1 -Environment Prod -ServerInstance "SOLITMDB001" -Credential (Get-Credential)

.NOTES
    Needs Invoke-Sqlcmd (SqlServer or SQLPS module), as Deploy_Migrations.ps1 does.
    Run this before deploying the API version that quotes cameras (it reads MAC.QuoteLines.ItemDiscount).
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
        Name     = '20261128_1500_AddMAC_CameraCategory'
        Requires = @('20261117_2230_AddMAC_QuoteBuilder', '20261120_0100_AddINE_PartVariants', '20261121_1500_AddPublicEstimatesForMcp')
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
Write-Host "=== Camera category: $Environment ($ServerInstance / $Database) ===" -ForegroundColor Cyan

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
SELECT CASE WHEN COL_LENGTH(N'MAC.QuoteLines', N'ItemDiscount') IS NULL THEN 0 ELSE 1 END AS HasItemDiscount,
       (SELECT COUNT(*) FROM [MAC].[Products] p INNER JOIN [ACC].[DealerTenants] t ON t.[DealerTenantID] = p.[DealerTenantId]
         WHERE t.[Proxy] = 'SOLA:3176D:198205F5-C1E1-4D80-8BFB-C7C6688BFDB6' AND p.[Category] = 'Camera'
           AND p.[Sku] IN ('RLN16-410', 'MC-HEAD-01', 'NVL-FIBR-60', 'NVL-INSTL-01')) AS CameraProducts;
"@
if ($check.HasItemDiscount -eq 1) {
    Write-Host '  [ok]   MAC.QuoteLines.ItemDiscount exists' -ForegroundColor Green
} else {
    Write-Host '  [FAIL] MAC.QuoteLines.ItemDiscount is missing' -ForegroundColor Red
    $ok = $false
}
if ($check.CameraProducts -eq 4) {
    Write-Host '  [ok]   the four camera products exist' -ForegroundColor Green
} else {
    Write-Host "  [FAIL] found $($check.CameraProducts) of the 4 camera products" -ForegroundColor Red
    $ok = $false
}

Write-Host ''
if ($ok) {
    Write-Host "Done: $Environment is up to date." -ForegroundColor Green
    exit 0
}
Write-Host "Finished with problems on $Environment. Check the messages above before going on." -ForegroundColor Red
exit 1
