/*
Migration: 20261120_2240_AddMSG_BrowserCalls
Author: Andres Sosa
Date: 2026-11-20
Description: Staff can call a contact from the admin app in the browser (Twilio Voice SDK, computer microphone)
             instead of having Twilio ring their own phone first.
               MSG.Calls.StaffVia      'Phone' (Twilio rang StaffPhone, staff pressed 1) or 'Browser' (the admin app
                                       was the staff side). Existing rows are 'Phone'.
               MSG.Calls.StaffClient   the Twilio Client identity of the browser that placed a 'Browser' call.
               MSG.Calls.StaffPhone    now NULL for 'Browser' calls; still required (E.164) for 'Phone' calls.
               ACC.Users.CanCallFromOwnPhone
                                       1 lets that user choose to have Twilio ring their own phone (the 'Phone' way);
                                       everyone else calls from the browser. Off for every user; turn it on per user.
Dependencies:
  20261120_2100_AddMSG_Calls
Rollback:
  ALTER TABLE [ACC].[Users] DROP CONSTRAINT [DF_Users_CanCallFromOwnPhone];
  ALTER TABLE [ACC].[Users] DROP COLUMN [CanCallFromOwnPhone];
  DELETE FROM [MSG].[Calls] WHERE [StaffVia] = 'Browser';
  ALTER TABLE [MSG].[Calls] DROP CONSTRAINT [CK_Calls_Phones];
  ALTER TABLE [MSG].[Calls] DROP CONSTRAINT [CK_Calls_StaffVia];
  ALTER TABLE [MSG].[Calls] DROP CONSTRAINT [DF_Calls_StaffVia];
  ALTER TABLE [MSG].[Calls] DROP COLUMN [StaffVia], [StaffClient];
  ALTER TABLE [MSG].[Calls] ALTER COLUMN [StaffPhone] [varchar](20) NOT NULL;
  ALTER TABLE [MSG].[Calls] ADD CONSTRAINT [CK_Calls_Phones]
      CHECK ([StaffPhone] LIKE '+[1-9]%' AND [ContactPhone] LIKE '+[1-9]%' AND [CallerId] LIKE '+[1-9]%');
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_2240_AddMSG_BrowserCalls';
Expected impact: two new columns on MSG.Calls (existing rows become StaffVia 'Phone'), StaffPhone nullable,
                 CK_Calls_Phones rewritten, and one new column on ACC.Users (0 for every existing user). No other data
                 changes.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_2240_AddMSG_BrowserCalls';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MSG.Calls', N'U') IS NULL
        THROW 50001, 'Browser calls require MSG.Calls (20261120_2100_AddMSG_Calls).', 1;

    IF COL_LENGTH(N'MSG.Calls', N'StaffVia') IS NULL
    BEGIN
        ALTER TABLE [MSG].[Calls] ADD [StaffVia] [varchar](10) NOT NULL
            CONSTRAINT [DF_Calls_StaffVia] DEFAULT ('Phone') WITH VALUES;
        PRINT 'Added [MSG].[Calls].[StaffVia]';
    END;

    IF COL_LENGTH(N'MSG.Calls', N'StaffClient') IS NULL
    BEGIN
        ALTER TABLE [MSG].[Calls] ADD [StaffClient] [varchar](121) NULL;
        PRINT 'Added [MSG].[Calls].[StaffClient]';
    END;

    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Calls_Phones' AND [parent_object_id] = OBJECT_ID(N'MSG.Calls')
                 AND [definition] NOT LIKE '%StaffVia%')
        ALTER TABLE [MSG].[Calls] DROP CONSTRAINT [CK_Calls_Phones];

    IF EXISTS (SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(N'MSG.Calls') AND [name] = N'StaffPhone' AND [is_nullable] = 0)
        ALTER TABLE [MSG].[Calls] ALTER COLUMN [StaffPhone] [varchar](20) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Calls_StaffVia' AND [parent_object_id] = OBJECT_ID(N'MSG.Calls'))
        EXEC (N'ALTER TABLE [MSG].[Calls] ADD CONSTRAINT [CK_Calls_StaffVia] CHECK ([StaffVia] IN (''Phone'', ''Browser''))');

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Calls_Phones' AND [parent_object_id] = OBJECT_ID(N'MSG.Calls'))
        EXEC (N'ALTER TABLE [MSG].[Calls] ADD CONSTRAINT [CK_Calls_Phones] CHECK (
            [ContactPhone] LIKE ''+[1-9]%'' AND [CallerId] LIKE ''+[1-9]%''
            AND (([StaffVia] = ''Phone'' AND [StaffPhone] LIKE ''+[1-9]%'')
              OR ([StaffVia] = ''Browser'' AND [StaffPhone] IS NULL AND [StaffClient] IS NOT NULL)))');

    IF COL_LENGTH(N'ACC.Users', N'CanCallFromOwnPhone') IS NULL
    BEGIN
        ALTER TABLE [ACC].[Users] ADD [CanCallFromOwnPhone] [bit] NOT NULL
            CONSTRAINT [DF_Users_CanCallFromOwnPhone] DEFAULT (0) WITH VALUES;
        PRINT 'Added [ACC].[Users].[CanCallFromOwnPhone]';
    END;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Browser calls: MSG.Calls.StaffVia and StaffClient, ACC.Users.CanCallFromOwnPhone',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
