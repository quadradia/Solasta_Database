/*
Migration: 20261030_2152_AlignDealerTenantAuditIdsWithUserIds
Author: Database Team
Date: 2026-10-30
Description: Changes ACC.DealerTenants.CreatedById and ModifiedById from INT
             to UNIQUEIDENTIFIER to match ACC.Users and the application model.
             Existing zero placeholder values are replaced with the standard
             system audit user ID. Nonzero legacy IDs require explicit mapping.
Dependencies: ACC.DealerTenants, dbo.SchemaVersion
Rollback: Reverses the type change if all audit IDs still use the system ID.
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) =
        N'20261030_2152_AlignDealerTenantAuditIdsWithUserIds';

    IF EXISTS (
        SELECT 1
        FROM [dbo].[SchemaVersion]
        WHERE [MigrationName] = @MigrationName
    )
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'ACC.DealerTenants', N'U') IS NULL
        THROW 50001, 'ACC.DealerTenants must exist before this migration.', 1;

    DECLARE @CreatedByType SYSNAME;
    DECLARE @ModifiedByType SYSNAME;

    SELECT @CreatedByType = TYPE_NAME([user_type_id])
    FROM sys.columns
    WHERE [object_id] = OBJECT_ID(N'ACC.DealerTenants')
      AND [name] = N'CreatedById';

    SELECT @ModifiedByType = TYPE_NAME([user_type_id])
    FROM sys.columns
    WHERE [object_id] = OBJECT_ID(N'ACC.DealerTenants')
      AND [name] = N'ModifiedById';

    IF @CreatedByType IS NULL OR @ModifiedByType IS NULL
        THROW 50002, 'ACC.DealerTenants audit columns are missing.', 1;

    IF @CreatedByType = N'int' AND @ModifiedByType = N'int'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM [ACC].[DealerTenants]
            WHERE [CreatedById] <> 0 OR [ModifiedById] <> 0
        )
            THROW 50003, 'Nonzero legacy audit IDs cannot be mapped automatically. Map them to user GUIDs before retrying.', 1;

        IF COL_LENGTH(N'ACC.DealerTenants', N'CreatedById_Guid') IS NOT NULL
           OR COL_LENGTH(N'ACC.DealerTenants', N'ModifiedById_Guid') IS NOT NULL
            THROW 50004, 'Temporary audit columns already exist. Inspect ACC.DealerTenants before retrying.', 1;

        IF OBJECT_ID(N'ACC.DF_Tenants_CreatedById', N'D') IS NOT NULL
            ALTER TABLE [ACC].[DealerTenants]
                DROP CONSTRAINT [DF_Tenants_CreatedById];

        IF OBJECT_ID(N'ACC.DF_Tenants_ModifiedById', N'D') IS NOT NULL
            ALTER TABLE [ACC].[DealerTenants]
                DROP CONSTRAINT [DF_Tenants_ModifiedById];

        ALTER TABLE [ACC].[DealerTenants]
            ADD [CreatedById_Guid] UNIQUEIDENTIFIER NULL,
                [ModifiedById_Guid] UNIQUEIDENTIFIER NULL;

        EXEC sys.sp_executesql N'
            UPDATE [ACC].[DealerTenants]
            SET [CreatedById_Guid] = ''E6872B58-52B2-415C-A32B-45805F95A70A'',
                [ModifiedById_Guid] = ''E6872B58-52B2-415C-A32B-45805F95A70A'';';

        ALTER TABLE [ACC].[DealerTenants]
            DROP COLUMN [CreatedById], [ModifiedById];

        EXEC sys.sp_rename
            N'ACC.DealerTenants.CreatedById_Guid', N'CreatedById', N'COLUMN';
        EXEC sys.sp_rename
            N'ACC.DealerTenants.ModifiedById_Guid', N'ModifiedById', N'COLUMN';

        EXEC sys.sp_executesql N'
            ALTER TABLE [ACC].[DealerTenants]
                ALTER COLUMN [CreatedById] UNIQUEIDENTIFIER NOT NULL;
            ALTER TABLE [ACC].[DealerTenants]
                ALTER COLUMN [ModifiedById] UNIQUEIDENTIFIER NOT NULL;
            ALTER TABLE [ACC].[DealerTenants]
                ADD CONSTRAINT [DF_Tenants_CreatedById]
                    DEFAULT (''E6872B58-52B2-415C-A32B-45805F95A70A'') FOR [CreatedById],
                    CONSTRAINT [DF_Tenants_ModifiedById]
                    DEFAULT (''E6872B58-52B2-415C-A32B-45805F95A70A'') FOR [ModifiedById];';
    END
    ELSE IF @CreatedByType <> N'uniqueidentifier'
         OR @ModifiedByType <> N'uniqueidentifier'
        THROW 50005, 'ACC.DealerTenants audit columns must both be INT or both be UNIQUEIDENTIFIER.', 1;

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description])
    VALUES (
        @MigrationName,
        N'Changes ACC.DealerTenants audit user IDs to UNIQUEIDENTIFIER.'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- This rollback is safe only while every audit value is the system audit ID.
BEGIN TRANSACTION;
BEGIN TRY
    IF EXISTS (
        SELECT 1
        FROM [ACC].[DealerTenants]
        WHERE [CreatedById] <> 'E6872B58-52B2-415C-A32B-45805F95A70A'
           OR [ModifiedById] <> 'E6872B58-52B2-415C-A32B-45805F95A70A'
    )
        THROW 50006, 'Audit IDs must be mapped back to their original INT values before rollback.', 1;

    IF OBJECT_ID(N'ACC.DF_Tenants_CreatedById', N'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants]
            DROP CONSTRAINT [DF_Tenants_CreatedById];

    IF OBJECT_ID(N'ACC.DF_Tenants_ModifiedById', N'D') IS NOT NULL
        ALTER TABLE [ACC].[DealerTenants]
            DROP CONSTRAINT [DF_Tenants_ModifiedById];

    ALTER TABLE [ACC].[DealerTenants]
        ADD [CreatedById_Int] INT NULL,
            [ModifiedById_Int] INT NULL;

    EXEC sys.sp_executesql N'
        UPDATE [ACC].[DealerTenants]
        SET [CreatedById_Int] = 0,
            [ModifiedById_Int] = 0;';

    ALTER TABLE [ACC].[DealerTenants]
        DROP COLUMN [CreatedById], [ModifiedById];

    EXEC sys.sp_rename
        N'ACC.DealerTenants.CreatedById_Int', N'CreatedById', N'COLUMN';
    EXEC sys.sp_rename
        N'ACC.DealerTenants.ModifiedById_Int', N'ModifiedById', N'COLUMN';

    EXEC sys.sp_executesql N'
        ALTER TABLE [ACC].[DealerTenants]
            ALTER COLUMN [CreatedById] INT NOT NULL;
        ALTER TABLE [ACC].[DealerTenants]
            ALTER COLUMN [ModifiedById] INT NOT NULL;
        ALTER TABLE [ACC].[DealerTenants]
            ADD CONSTRAINT [DF_Tenants_CreatedById] DEFAULT ((0)) FOR [CreatedById],
                CONSTRAINT [DF_Tenants_ModifiedById] DEFAULT ((0)) FOR [ModifiedById];';

    DELETE FROM [dbo].[SchemaVersion]
    WHERE [MigrationName] = N'20261030_2152_AlignDealerTenantAuditIdsWithUserIds';

    COMMIT TRANSACTION;
    PRINT 'Rollback complete.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
*/
