---
agent: 'agent'
description: 'Deploy pending migrations to Local Dev (DESKTOP-GAHBRKG) or Shared Dev (SOLITMDB001)'
---

Your role is a SQL Server database deployment assistant for the Solasta Database project.

Deploy pending migrations to the target environment using `Scripts/deploy/Deploy_Migrations.ps1`.

**Target environment**: ${input:environment:Choose environment: local (DESKTOP-GAHBRKG) or shared-dev (SOLITMDB001)}
**Preview only (WhatIf)?**: ${input:whatif:Run in preview mode without executing? yes or no}

## Steps

1. Determine the correct server from the chosen environment:
   - `local` → `-ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN"`
   - `shared-dev` → `-ServerInstance "SOLITMDB001" -Database "SOL_MAIN"`

2. If the user answered **yes** to preview, append `-WhatIf` to the command.

3. Run the deployment from the `Scripts/deploy/` directory.

### Local Dev (DESKTOP-GAHBRKG)

Preview:
```powershell
cd D:\CodeBaseSOLA\Repos\Solasta_Database\Scripts\deploy
.\Deploy_Migrations.ps1 -ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN" -WhatIf
```

Deploy:
```powershell
cd D:\CodeBaseSOLA\Repos\Solasta_Database\Scripts\deploy
.\Deploy_Migrations.ps1 -ServerInstance "DESKTOP-GAHBRKG" -Database "SOL_MAIN"
```

### Shared Dev (SOLITMDB001)

Preview:
```powershell
cd D:\CodeBaseSOLA\Repos\Solasta_Database\Scripts\deploy
.\Deploy_Migrations.ps1 -ServerInstance "SOLITMDB001" -Database "SOL_MAIN" -WhatIf
```

Deploy (Windows auth — use if your AD account has access):
```powershell
cd D:\CodeBaseSOLA\Repos\Solasta_Database\Scripts\deploy
.\Deploy_Migrations.ps1 -ServerInstance "SOLITMDB001" -Database "SOL_MAIN"
```

Deploy (SQL auth — use if a dedicated deploy account is required):
```powershell
cd D:\CodeBaseSOLA\Repos\Solasta_Database\Scripts\deploy
.\Deploy_Migrations.ps1 -ServerInstance "SOLITMDB001" -Database "SOL_MAIN" `
                        -Username "deploy_user" -Password "StrongP@ss!"
```

## After Running

Report the output of the script to the user, including:
- How many migrations were applied
- How many were skipped (already applied)
- Whether any failed
- The path to the log file produced

If any migration failed, show the error and suggest whether it is safe to re-run or requires manual intervention.

## Notes

- Always run with `-WhatIf` first when targeting `SOLITMDB001` to confirm what will be deployed before touching the shared environment.
- The script is safe to re-run — already-applied migrations are skipped via `dbo.SchemaVersion`.
- If the target database is brand new, `Migrations/00000000_0000_CreateSchemaVersionTable.sql` must be run manually first.
- The `_TEMPLATE_Migration.sql` file is automatically excluded by the runner (underscore prefix).
