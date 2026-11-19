<#
.SYNOPSIS
    Saves a SQL login for the deploy scripts, encrypted for your Windows account on this computer only.

.DESCRIPTION
    Prompts for the login with Get-Credential and writes it with Export-Clixml to
    %APPDATA%\Solasta\DeployCredentials\<Name>.xml. Windows DPAPI encrypts the password: only your Windows account,
    on this computer, can read it back. It is never stored in plain text, in an environment variable, or in this
    repository.

    The deploy scripts load it with -CredentialName <Name>, so they can run without a password prompt (for example
    from a Remote Control session started on your computer). Rerun this after the password changes; delete the file
    to forget it.

.PARAMETER Name
    A name for the login, such as Prod. Letters, digits, '-' and '_' only.

.EXAMPLE
    .\Save-DeployCredential.ps1 -Name Prod
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$Name
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$folder = Join-Path $env:APPDATA 'Solasta\DeployCredentials'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$path = Join-Path $folder "$Name.xml"

$credential = Get-Credential -Message "SQL login for '$Name' (saved encrypted for $env:USERNAME on $env:COMPUTERNAME)"
if (-not $credential) { Write-Host 'Canceled. Nothing saved.' -ForegroundColor Yellow; exit 1 }
$credential | Export-Clixml -Path $path

Write-Host "Saved '$Name' for $($credential.UserName) to $path" -ForegroundColor Green
Write-Host "Use it with: -CredentialName $Name" -ForegroundColor Green
