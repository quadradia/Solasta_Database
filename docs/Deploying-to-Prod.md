# Deploying a migration to Prod

Prod is SQL Server `SOLITMDB001`, database `SOL_MAIN`. Each change goes out through its own wrapper script in
`Scripts/deploy/Deploy_*.ps1`, never through `Deploy_Migrations.ps1` alone (it has no Prod guard and would run every
pending migration, including ones known to fail).

## What a wrapper does

A wrapper runs `Deploy_Migrations.ps1` with `-MigrationFilter` set to its exact migration file(s) and `-StopOnError`.
Around that it:

- checks the migrations it depends on are recorded in `dbo.SchemaVersion`, and stops if one is missing;
- with `-WhatIf`, lists what would run and changes nothing;
- for Prod, asks you to type `SOLITMDB001/SOL_MAIN` (or takes it from `-ConfirmTarget`);
- afterwards checks the migration is recorded and its objects exist.

Copy the newest wrapper to make one for a new migration, and change its plan and post-checks.

## Steps

1. **Merge first.** Run from the main checkout, on `main`, in sync with `origin/main`, with no uncommitted changes to
   the migration.
2. **Dev.** `.\Scripts\deploy\Deploy_<change>.ps1 -Environment Dev -WhatIf`, then without `-WhatIf`. It must finish
   with every post-check `[ok]`.
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
