<#
.SYNOPSIS
    Creates (or repairs) a dedicated, least-privilege SQL login for the deploy and migration scripts, so the saved
    Prod login no longer has to be sa.

.DESCRIPTION
    Run it once per server, as an administrator (Windows auth, or -AdminCredential / -AdminCredentialName). It:

      1. Creates the SQL login (default solasta_deploy) with the password policy on and no server roles. If the
         login already exists it is left alone, unless you pass -ResetPassword.
      2. In SOL_MAIN, maps a user to it with these rights, and nothing more:
           db_ddladmin     create / alter / drop tables, procedures, functions, views, types, triggers, schemas;
                           sp_rename, SET IDENTITY_INSERT, DBCC CHECKIDENT (what the migrations use)
           db_datareader   pre/post-checks and seed lookups
           db_datawriter   seed rows and the dbo.SchemaVersion record
           EXECUTE         migrations that call existing procedures
           VIEW DEFINITION the wrappers' checks against sys.tables / sys.triggers
      3. In GBDC_IDENTITY, maps a user to it with db_datareader and db_datawriter only. Those migrations change
         IdentityServer configuration rows (clients, scopes, roles); dbo.SchemaVersion already exists there.

    It does NOT grant: any server role, db_owner, CONTROL, ALTER ANY USER / ROLE, GRANT rights, or IMPERSONATE.
    So the login cannot create logins, change server settings, read other databases, or give itself more rights.

    Known gap, on purpose: a migration that creates a NEW schema with "AUTHORIZATION [dbo]" (one per new module,
    e.g. 20261120_0400_CreateMCH_MerchantServices) needs IMPERSONATE on dbo, which is as strong as db_owner. Those
    migrations fail with this login ("Cannot find the user 'dbo'... or you do not have permission"). Run that one
    migration with an admin login, prompted with -Credential (Get-Credential), then go back to -CredentialName Prod.

    The new login's password is asked for with a hidden prompt and sent to SQL Server as a query parameter. It is
    never printed, logged, or written to disk by this script. Save it afterwards with Save-DeployCredential.ps1.

    Not covered: the Identity Server applies its own EF Core migrations at startup with its own connection string,
    and Deploy_Baseline.ps1 (building an empty database) is an admin job. Neither uses this login.

.PARAMETER ServerInstance
    SQL Server instance, e.g. SOLITMDB001.

.PARAMETER LoginName
    Name of the deploy login. Default solasta_deploy.

.PARAMETER MainDatabase
    Default SOL_MAIN.

.PARAMETER IdentityDatabase
    Default GBDC_IDENTITY. Pass an empty string to skip it (e.g. on a Dev server without the identity database).

.PARAMETER AdminCredential
    An admin SQL login to make the change with, from (Get-Credential). Omit both admin parameters to use Windows auth.

.PARAMETER AdminCredentialName
    Load the admin login saved with Save-DeployCredential.ps1 under this name (today, Prod is sa).

.PARAMETER ResetPassword
    The login already exists: set a new password on it (and unlock it). Without this, an existing login's password
    is not touched and you are not asked for one.

.PARAMETER WhatIf
    Show what would change, without changing anything. Asks for no password.

.EXAMPLE
    # 1. Preview, using the sa login currently saved as Prod
    .\Scripts\deploy\New-DeployLogin.ps1 -ServerInstance SOLITMDB001 -AdminCredentialName Prod -WhatIf

.EXAMPLE
    # 2. Create it (asks for the new login's password, hidden), then re-save Prod as the new login
    .\Scripts\deploy\New-DeployLogin.ps1 -ServerInstance SOLITMDB001 -AdminCredentialName Prod
    .\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod

.NOTES
    Uses System.Data.SqlClient, so it needs no SQL module.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{2,63}$')]
    [string]$LoginName = 'solasta_deploy',

    [ValidatePattern('^[A-Za-z0-9_]+$')]
    [string]$MainDatabase = 'SOL_MAIN',

    [ValidatePattern('^$|^[A-Za-z0-9_]+$')]
    [string]$IdentityDatabase = 'GBDC_IDENTITY',

    [System.Management.Automation.PSCredential]$AdminCredential,

    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$AdminCredentialName,

    [switch]$ResetPassword,

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($AdminCredentialName) {
    if ($AdminCredential) { throw 'Use -AdminCredential or -AdminCredentialName, not both.' }
    $savedPath = Join-Path $env:APPDATA "Solasta\DeployCredentials\$AdminCredentialName.xml"
    if (-not (Test-Path $savedPath)) { throw "No saved login '$AdminCredentialName' at $savedPath." }
    $AdminCredential = Import-Clixml -Path $savedPath
}
if ($AdminCredential -and $AdminCredential.UserName -eq $LoginName) {
    throw "The admin login is $LoginName itself. Use an admin login (sa, or Windows auth) to create or repair it."
}

# --- Connection -----------------------------------------------------------------------------------------------
function New-Connection([string]$Database) {
    $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $b['Data Source'] = $ServerInstance
    $b['Initial Catalog'] = $Database
    $b['Application Name'] = 'New-DeployLogin.ps1'
    if ($AdminCredential) {
        $AdminCredential.Password.MakeReadOnly()
        $conn = New-Object System.Data.SqlClient.SqlConnection($b.ConnectionString,
            (New-Object System.Data.SqlClient.SqlCredential($AdminCredential.UserName, $AdminCredential.Password)))
    } else {
        $b['Integrated Security'] = $true
        $conn = New-Object System.Data.SqlClient.SqlConnection($b.ConnectionString)
    }
    $conn.add_InfoMessage({ param($s, $e) foreach ($err in $e.Errors) { Write-Host "    $($err.Message)" -ForegroundColor DarkGray } })
    $conn.Open()
    return $conn
}

function Invoke-Sql($Conn, [string]$Sql, [hashtable]$Params = @{}) {
    $cmd = $Conn.CreateCommand()
    $cmd.CommandText = $Sql
    $cmd.CommandTimeout = 60
    foreach ($k in $Params.Keys) { [void]$cmd.Parameters.AddWithValue("@$k", $Params[$k]) }
    $r = $cmd.ExecuteScalar()
    $cmd.Parameters.Clear()
    return $r
}

# --- T-SQL ----------------------------------------------------------------------------------------------------
# The login name is validated above and also passed through QUOTENAME; the password only ever travels as @Password.
$LoginSql = @'
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE [name] = @Login)
BEGIN
    DECLARE @create NVARCHAR(MAX) = N'CREATE LOGIN ' + QUOTENAME(@Login)
        + N' WITH PASSWORD = N''' + REPLACE(@Password, N'''', N'''''') + N''''
        + N', DEFAULT_DATABASE = ' + QUOTENAME(@MainDb)
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC (@create);
    PRINT 'Created login ' + @Login + '.';
END
ELSE IF @Reset = 1
BEGIN
    DECLARE @alter NVARCHAR(MAX) = N'ALTER LOGIN ' + QUOTENAME(@Login)
        + N' WITH PASSWORD = N''' + REPLACE(@Password, N'''', N'''''') + N''' UNLOCK;';
    EXEC (@alter);
    PRINT 'Reset the password of login ' + @Login + '.';
END
ELSE
    PRINT 'Login ' + @Login + ' already exists; password not changed.';

DECLARE @enable NVARCHAR(MAX) = N'ALTER LOGIN ' + QUOTENAME(@Login) + N' ENABLE;';
EXEC (@enable);
'@

# Run in each database. Roles are the fixed database roles; ALTER ROLE ... ADD MEMBER is a no-op for a member.
function Get-UserSql([string[]]$Roles, [string[]]$Grants) {
    $lines = @(
        "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = @Login)",
        "BEGIN",
        "    DECLARE @u NVARCHAR(MAX) = N'CREATE USER ' + QUOTENAME(@Login) + N' FOR LOGIN ' + QUOTENAME(@Login) + N' WITH DEFAULT_SCHEMA = [dbo];';",
        "    EXEC (@u);",
        "    PRINT 'Created user ' + @Login + ' in ' + DB_NAME() + '.';",
        "END",
        "ELSE",
        "BEGIN",
        "    -- Re-link the user if the login was dropped and recreated (orphaned user).",
        "    DECLARE @l NVARCHAR(MAX) = N'ALTER USER ' + QUOTENAME(@Login) + N' WITH LOGIN = ' + QUOTENAME(@Login) + N', DEFAULT_SCHEMA = [dbo];';",
        "    EXEC (@l);",
        "END",
        "DECLARE @s NVARCHAR(MAX);"
    )
    foreach ($role in $Roles) {
        $lines += "SET @s = N'ALTER ROLE [$role] ADD MEMBER ' + QUOTENAME(@Login) + N';'; EXEC (@s);"
    }
    foreach ($grant in $Grants) {
        $lines += "SET @s = N'GRANT $grant TO ' + QUOTENAME(@Login) + N';'; EXEC (@s);"
    }
    return ($lines -join "`n")
}

$MainRoles      = @('db_ddladmin', 'db_datareader', 'db_datawriter')
$MainGrants     = @('EXECUTE', 'VIEW DEFINITION')
$IdentityRoles  = @('db_datareader', 'db_datawriter')
$IdentityGrants = @()

# --- Plan -----------------------------------------------------------------------------------------------------
$adminText = if ($AdminCredential) { "SQL login $($AdminCredential.UserName)" } else { 'Windows auth' }
Write-Host ''
Write-Host "=== Deploy login $LoginName on $ServerInstance (as $adminText) ===" -ForegroundColor Cyan
Write-Host "  Server   : login $LoginName, no server roles, default database $MainDatabase, password policy on"
Write-Host "  $($MainDatabase.PadRight(9)): $(($MainRoles + $MainGrants) -join ', ')"
if ($IdentityDatabase) {
    Write-Host "  $($IdentityDatabase.PadRight(9)): $(($IdentityRoles + $IdentityGrants) -join ', ')"
}

$master = New-Connection 'master'
try {
    $exists = [int](Invoke-Sql $master 'SELECT COUNT(*) FROM sys.server_principals WHERE [name] = @Login;' @{ Login = $LoginName })
    $isSysadmin = [int](Invoke-Sql $master "SELECT ISNULL(IS_SRVROLEMEMBER('sysadmin', @Login), 0);" @{ Login = $LoginName }) -eq 1
    foreach ($db in @($MainDatabase, $IdentityDatabase) | Where-Object { $_ }) {
        if ([int](Invoke-Sql $master 'SELECT CASE WHEN DB_ID(@Db) IS NULL THEN 0 ELSE 1 END;' @{ Db = $db }) -ne 1) {
            throw "Database $db not found on $ServerInstance."
        }
        $trusty = [int](Invoke-Sql $master 'SELECT CAST(is_trustworthy_on AS INT) FROM sys.databases WHERE [name] = @Db;' @{ Db = $db })
        if ($trusty -eq 1) {
            Write-Host "  Note: $db has TRUSTWORTHY ON. Not changed here, but it is worth turning off if nothing needs it." -ForegroundColor Yellow
        }
    }

    if ($exists) {
        Write-Host "  The login already exists$(if ($ResetPassword) { '; its password will be reset' } else { '; its password stays as it is' })." -ForegroundColor DarkGray
    }
    if ($isSysadmin) {
        Write-Host "  Warning: $LoginName is in the sysadmin server role. This script does not remove it; do that by hand:" -ForegroundColor Yellow
        Write-Host "    ALTER SERVER ROLE [sysadmin] DROP MEMBER [$LoginName];" -ForegroundColor Yellow
    }

    if ($WhatIf) {
        Write-Host ''
        Write-Host 'WhatIf: nothing changed and no password was asked for.' -ForegroundColor Cyan
        exit 0
    }

    # --- Password (hidden; never printed or stored) ---------------------------------------------------------------
    $password = $null
    if (-not $exists -or $ResetPassword) {
        $new = Get-Credential -UserName $LoginName -Message "New password for SQL login $LoginName on $ServerInstance (use a long random one from your password manager)"
        if (-not $new) { Write-Host 'Canceled. Nothing changed.' -ForegroundColor Yellow; exit 1 }
        $password = $new.GetNetworkCredential().Password
        if ($password.Length -lt 16) { throw 'Use a password of at least 16 characters. Nothing changed.' }
    }

    Write-Host ''
    Write-Host '--> Server login' -ForegroundColor Cyan
    [void](Invoke-Sql $master $LoginSql @{
        Login    = $LoginName
        Password = $(if ($password) { $password } else { [DBNull]::Value })
        MainDb   = $MainDatabase
        Reset    = [int][bool]$ResetPassword
    })
    $password = $null
}
finally {
    $master.Close()
}

$targets = @(@{ Db = $MainDatabase; Roles = $MainRoles; Grants = $MainGrants })
if ($IdentityDatabase) { $targets += @{ Db = $IdentityDatabase; Roles = $IdentityRoles; Grants = $IdentityGrants } }

foreach ($t in $targets) {
    Write-Host "--> $($t.Db)" -ForegroundColor Cyan
    $conn = New-Connection $t.Db
    try {
        [void](Invoke-Sql $conn (Get-UserSql $t.Roles $t.Grants) @{ Login = $LoginName })

        # Post-check: exactly the roles above, and never db_owner.
        $owner = [int](Invoke-Sql $conn "SELECT ISNULL(IS_ROLEMEMBER('db_owner', @Login), 0);" @{ Login = $LoginName })
        $missing = @($t.Roles | Where-Object { [int](Invoke-Sql $conn 'SELECT ISNULL(IS_ROLEMEMBER(@Role, @Login), 0);' @{ Role = $_; Login = $LoginName }) -ne 1 })
        if ($missing.Count -gt 0) { throw "In $($t.Db), $LoginName is not in: $($missing -join ', ')" }
        if ($owner -eq 1) {
            Write-Host "  Warning: $LoginName is in db_owner in $($t.Db), from before. Remove it by hand:" -ForegroundColor Yellow
            Write-Host "    ALTER ROLE [db_owner] DROP MEMBER [$LoginName];" -ForegroundColor Yellow
        } else {
            Write-Host "  [ok] $($t.Db): $(($t.Roles + $t.Grants) -join ', ')" -ForegroundColor Green
        }
    }
    finally {
        $conn.Close()
    }
}

Write-Host ''
Write-Host "Done. Next, re-save the Prod login as $LoginName (the password you just typed):" -ForegroundColor Green
Write-Host '    .\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod' -ForegroundColor Green
Write-Host 'Then check it with a wrapper preview, e.g.:' -ForegroundColor Green
Write-Host "    .\Scripts\deploy\Deploy_<change>.ps1 -Environment Prod -ServerInstance $ServerInstance -CredentialName Prod -WhatIf" -ForegroundColor Green
exit 0
