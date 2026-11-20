# Deploying migrations

There are two targets:

| | Server | Database | Login |
|---|---|---|---|
| **Dev** (local) | `DESKTOP-GAHBRKG` | `SOL_MAIN` | Windows auth (your account) |
| **Prod** | `SOLITMDB001` | `SOL_MAIN` | SQL login, see [The Prod login](#the-prod-login) |

A migration always goes to Dev first, then the AutoGenerator (AGC) and the API are built against Dev, and only after
the PRs are merged does it go to Prod.

Each change goes out through its own wrapper script in `Scripts/deploy/Deploy_*.ps1`. Never run
`Deploy_Migrations.ps1` on its own against Prod: it would run every pending migration, including old ones that are
known to fail (such as `20260506_1200`), and it has no Prod guard. On Dev it is only for catching up (below).

You need the `SqlServer` PowerShell module (`Install-Module SqlServer`) for `Invoke-Sqlcmd`.

## What a wrapper does

A wrapper runs `Deploy_Migrations.ps1` with `-MigrationFilter` set to its exact migration file(s) and `-StopOnError`.
Around that it:

- checks the migrations it depends on are recorded in `dbo.SchemaVersion`, and stops if one is missing;
- with `-WhatIf`, lists what would run and changes nothing;
- for Prod, asks you to type `SOLITMDB001/SOL_MAIN` (or takes it from `-ConfirmTarget`);
- afterwards checks the migration is recorded and its objects exist.

Copy the newest wrapper to make one for a new migration, and change its plan and post-checks.

## Deploying to local Dev

1. **Get the migration.** Work from a branch or worktree that has the new `Migrations/YYYYMMDD_HHMM_*.sql` and its
   `Scripts/deploy/Deploy_*.ps1` wrapper. To test a branch that isn't merged without disturbing your main checkout:
   ```powershell
   cd D:\CodeBaseSOLA\Repos\Solasta_Database
   git fetch origin <branch>
   git worktree add ..\Solasta_Database-<feature> origin/<branch>
   cd ..\Solasta_Database-<feature>
   ```
2. **Preview.** It connects with Windows auth to `DESKTOP-GAHBRKG` / `SOL_MAIN`, checks the prerequisites in
   `dbo.SchemaVersion` and lists what would run. Nothing changes.
   ```powershell
   .\Scripts\deploy\Deploy_<change>.ps1 -Environment Dev -WhatIf
   ```
3. **Run.** The same command without `-WhatIf`. Dev asks for no confirmation. Every post-check must be `[ok]`.
   ```powershell
   .\Scripts\deploy\Deploy_<change>.ps1 -Environment Dev
   ```
   Add `-ServerInstance <name>` for another local instance (for example a test copy).
4. **Regenerate code.** If the change adds or alters tables, views, types or procedures the API uses, run the AGC
   against Dev (`RQI.POC.AutoGenConsole.exe --profile solasta --dry-run`, then without `--dry-run`; a new schema must
   first be added to the profile's `schemas.tables`) and build and test the API. See the AGC repository's CLAUDE.md.
5. **Clean up.** After the PR merges, `git worktree remove ..\Solasta_Database-<feature>` and `git pull` in the main
   checkout.

Migrations run in one transaction with `XACT_ABORT ON`, so one that fails part-way rolls back and is not recorded
in `SchemaVersion`. Fix it on the branch and
run the wrapper again; a migration that is already recorded is skipped, so a rerun is safe.

If you only need a migration's SQL checked against a copy of the data, restore a backup of `SOL_MAIN` under another
name (for example `SOL_TEST`) and pass `-Database SOL_TEST` to the wrapper. Drop that copy when you're done.

### Catching Dev up on everything pending

To bring Dev up to date with every migration in `main` (for example after a while away), use the generic runner,
on Dev only:

```powershell
.\Scripts\deploy\Deploy_Migrations.ps1 -ServerInstance DESKTOP-GAHBRKG -Database SOL_MAIN -WhatIf
.\Scripts\deploy\Deploy_Migrations.ps1 -ServerInstance DESKTOP-GAHBRKG -Database SOL_MAIN -StopOnError
```

Read the `-WhatIf` list first: old migrations that are known to fail will show as pending. To run one migration
with it, pass its exact file name to `-MigrationFilter`; a wildcard such as `20261120*` also picks up every other
migration from that day.

### Building an empty Dev database

On a new machine, create an empty `SOL_MAIN`, then run the baseline (the `SchemaVersion` table, schemas and every
object as of March 2026), then catch up as above:

```powershell
sqlcmd -S DESKTOP-GAHBRKG -E -Q "CREATE DATABASE [SOL_MAIN]"
.\Scripts\deploy\Deploy_Baseline.ps1 -ServerInstance DESKTOP-GAHBRKG -Database SOL_MAIN -StopOnError
```

### Troubleshooting

| Message | What to do |
|---|---|
| `Invoke-Sqlcmd` is not recognized | `Install-Module SqlServer -Scope CurrentUser` |
| Cannot query SchemaVersion table | The database has no baseline; see *Building an empty Dev database*. |
| Stopping: prerequisites are not applied | Deploy the listed migrations first (their own wrappers). |
| No saved login 'Prod' | `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod` |
| Login failed (Prod) | The saved password is out of date: rerun `Save-DeployCredential.ps1 -Name Prod`. |
| A migration is skipped but never applied | `Deploy_Migrations.ps1` skips any name already in `dbo.SchemaVersion`, even a failed row (`Success = 0`). Wrappers count only `Success = 1`. On Dev, delete the failed row before using the generic runner again. |

## Deploying to Prod

1. **Merge first.** Run from the main checkout, on `main`, in sync with `origin/main`, with no uncommitted changes to
   the migration.
2. **Dev.** It must already be on Dev with every post-check `[ok]` (see above).
3. **Backup.** Confirm a current, restorable backup or snapshot of `SOL_MAIN` exists.
4. **Prod preview.**
   ```powershell
   .\Scripts\deploy\Deploy_<change>.ps1 -Environment Prod -ServerInstance SOLITMDB001 -Database SOL_MAIN -CredentialName Prod -WhatIf
   ```
   It must list only the migration(s) you mean to deploy, and no missing prerequisites.
5. **Prod run.** The same command without `-WhatIf`. Type `SOLITMDB001/SOL_MAIN` at the prompt.
6. **Check.** Read the post-checks. The run's log is `Scripts/deploy/migrations_run_<timestamp>.log`; keep Prod logs
   in `Scripts/deploy/logs` (git-ignored).
7. **Then the apps.** Deploy the API (and admin) versions that use the change only after the migration is on Prod.

## The Prod login

Never put a password on a command line, in a file in this repository, or in chat.

- **Saved login (recommended):** run `.\Scripts\deploy\Save-DeployCredential.ps1 -Name Prod` once and enter the SQL
  login. It is saved to `%APPDATA%\Solasta\DeployCredentials\Prod.xml`, encrypted with Windows DPAPI so only your
  Windows account on that computer can read it. Wrappers load it with `-CredentialName Prod` and decrypt it in
  memory. Rerun it after the password changes.
- **Prompt:** `-Credential (Get-Credential)` instead of `-CredentialName`.
- The scripts do not read environment variables such as `SQLCMDPASSWORD`. Don't keep the password in one: every
  process running as you inherits it.

## When Claude runs it

Claude runs the wrapper through a Remote Control session on your PC, which uses your saved `Prod` login. It never
reads or prints the password. Before touching Prod it shows you the exact command and the `-WhatIf` result, and it
runs the real deploy only after you reply with an explicit go for that change. Your go is also what lets it pass
`-ConfirmTarget 'SOLITMDB001/SOL_MAIN'` in place of typing at the prompt. If anything fails it stops and reports;
it does not retry or roll back on its own.
