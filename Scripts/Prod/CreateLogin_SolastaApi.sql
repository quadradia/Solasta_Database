/*
Creates the SQL login and database user the production Solasta API (api.mysolasta.com on
QUADITMAPP001) uses to reach SOL_MAIN on SOLITMDB001.

Least privilege: read and write table data and execute procedures/functions. The login cannot
change schema, create objects, or touch other databases.

HOW TO RUN (SSMS, connected to SOLITMDB001 as an administrator):
  1. Replace <<SET A STRONG PASSWORD HERE>> below with a new random password (24+ characters).
     Do not save the file with the password in it, and do not commit it.
  2. Execute. Rerunning is safe: an existing login gets the new password, and existing users
     and role memberships are kept.
  3. Put the matching connection string on the API's app pool with
     deploy\Set-SolastaApiProdSecret.ps1 (in the API repo), for example:
       Server=SOLITMDB001;Database=SOL_MAIN;User Id=solasta-api;Password=...;TrustServerCertificate=True;Encrypt=True
*/
USE [master];
GO

DECLARE @Password NVARCHAR(128) = N'<<SET A STRONG PASSWORD HERE>>';
IF @Password LIKE N'<<%' THROW 50001, 'Set the password at the top of the script first.', 1;

DECLARE @Sql NVARCHAR(MAX);
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE [name] = N'solasta-api')
    SET @Sql = N'CREATE LOGIN [solasta-api] WITH PASSWORD = ' + QUOTENAME(@Password, '''') +
               N', DEFAULT_DATABASE = [SOL_MAIN], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
ELSE
    SET @Sql = N'ALTER LOGIN [solasta-api] WITH PASSWORD = ' + QUOTENAME(@Password, '''') + N';';
EXEC sys.sp_executesql @Sql;
PRINT 'Login [solasta-api] ready.';
GO

USE [SOL_MAIN];
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = N'solasta-api')
    CREATE USER [solasta-api] FOR LOGIN [solasta-api] WITH DEFAULT_SCHEMA = [dbo];
ELSE
    ALTER USER [solasta-api] WITH LOGIN = [solasta-api];   -- re-links an orphaned user after a restore

ALTER ROLE [db_datareader] ADD MEMBER [solasta-api];
ALTER ROLE [db_datawriter] ADD MEMBER [solasta-api];
-- ACC.spSessionContextCreate runs before every authenticated query; other SPROC wrappers and
-- scalar/table functions need EXECUTE too.
GRANT EXECUTE TO [solasta-api];
PRINT 'User [solasta-api] in SOL_MAIN: db_datareader, db_datawriter, EXECUTE.';
GO

-- Check
SELECT dp.[name] AS [user], r.[name] AS [role]
FROM sys.database_role_members AS m
JOIN sys.database_principals AS r ON r.principal_id = m.role_principal_id
JOIN sys.database_principals AS dp ON dp.principal_id = m.member_principal_id
WHERE dp.[name] = N'solasta-api';
GO
