/*
Migration: 20260417_1300_CreateRSU_GetUserRecruitCreateFromResourceIdResult
Author: Andres Sosa
Date: 2026-04-17
Description: Creates the User-Defined Table Type RSU.uddt_GetUserRecruitCreateFromResourceIdResult,
             which mirrors the full result set returned by RSU.spUserRecruitCreateFromResourceId.
Dependencies: 20260417_1200_CreateRSU_GetUserTypeGroupsByDealerIdResult
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260417_1300_CreateRSU_GetUserRecruitCreateFromResourceIdResult';

    -- Check if already applied
    IF EXISTS (
        SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName
    )
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- Drop existing type if present (types cannot be altered)
    IF EXISTS (
        SELECT 1
FROM sys.table_types
WHERE name = N'uddt_GetUserRecruitCreateFromResourceIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
    )
    BEGIN
    EXEC(N'DROP TYPE [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult];');
END

    -- Create the type (must use EXEC inside a transaction)
    EXEC(N'
    CREATE TYPE [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult] AS TABLE
    (
        [Id]                        INT                 NOT NULL,
        [UserResourceId]            INT                 NOT NULL,
        [UserTypeId]                SMALLINT            NOT NULL,
        [ReportsToId]               INT                 NULL,
        [UserRecruitAddressId]      INT                 NULL,
        [DealerId]                  INT                 NOT NULL,
        [SeasonId]                  INT                 NOT NULL,
        [OwnerApprovalId]           INT                 NULL,
        [TeamId]                    INT                 NULL,
        [PayScaleId]                INT                 NULL,
        [SchoolId]                  SMALLINT            NULL,
        [ShackingUpId]              INT                 NULL,
        [UserRecruitCohabbitTypeId] INT                 NULL,
        [AlternatePayScheduleId]    INT                 NULL,
        [Location]                  NVARCHAR(50)        NULL,
        [OwnerApprovalDate]         DATETIMEOFFSET(7)   NULL,
        [ManagerApprovalDate]       DATETIMEOFFSET(7)   NULL,
        [EmergencyName]             NVARCHAR(50)        NULL,
        [EmergencyPhone]            VARCHAR(20)         NULL,
        [EmergencyRelationship]     NVARCHAR(50)        NULL,
        [IsRecruiter]               BIT                 NOT NULL,
        [PreviousSummer]            NVARCHAR(200)       NULL,
        [SignatureDate]             DATETIMEOFFSET(7)   NULL,
        [HireDate]                  DATETIMEOFFSET(7)   NULL,
        [GPExemptions]              INT                 NULL,
        [GPW4Allowances]            TINYINT             NULL,
        [GPW9Name]                  NVARCHAR(50)        NULL,
        [GPW9BusinessName]          NVARCHAR(100)       NULL,
        [GPW9TIN]                   VARCHAR(50)         NULL,
        [SocialSecCardStatusID]     INT                 NOT NULL,
        [DriversLicenseStatusID]    INT                 NOT NULL,
        [W4StatusID]                INT                 NOT NULL,
        [I9StatusID]                INT                 NOT NULL,
        [W9StatusID]                INT                 NOT NULL,
        [SocialSecCardNotes]        NVARCHAR(250)       NULL,
        [DriversLicenseNotes]       NVARCHAR(250)       NULL,
        [W4Notes]                   NVARCHAR(250)       NULL,
        [I9Notes]                   NVARCHAR(250)       NULL,
        [W9Notes]                   NVARCHAR(250)       NULL,
        [EIN]                       NVARCHAR(50)        NULL,
        [SUTA]                      NVARCHAR(50)        NULL,
        [WorkersComp]               NVARCHAR(MAX)       NULL,
        [FedFilingStatus]           NVARCHAR(50)        NULL,
        [EICFilingStatus]           NVARCHAR(50)        NULL,
        [TaxWitholdingState]        NVARCHAR(5)         NULL,
        [StateFilingStatus]         NVARCHAR(50)        NULL,
        [GPDependents]              INT                 NULL,
        [CriminalOffense]           BIT                 NULL,
        [Offense]                   NVARCHAR(MAX)       NULL,
        [OffenseExplanation]        NVARCHAR(MAX)       NULL,
        [Rent]                      MONEY               NULL,
        [Pet]                       MONEY               NULL,
        [Utilities]                 MONEY               NULL,
        [Fuel]                      MONEY               NULL,
        [Furniture]                 MONEY               NULL,
        [CellPhoneCredit]           MONEY               NULL,
        [GasCredit]                 MONEY               NULL,
        [RentExempt]                BIT                 NOT NULL,
        [IsServiceTech]             BIT                 NOT NULL,
        [StateId]                   VARCHAR(4)          NULL,
        [CountryId]                 NVARCHAR(10)        NULL,
        [StreetAddress]             NVARCHAR(50)        NULL,
        [StreetAddress2]            NVARCHAR(50)        NULL,
        [City]                      NVARCHAR(50)        NULL,
        [PostalCode]                NVARCHAR(10)        NULL,
        [CBxSocialSecCard]          BIT                 NULL,
        [CBxDriversLicense]         BIT                 NULL,
        [CBxW4]                     BIT                 NULL,
        [CBxI9]                     BIT                 NULL,
        [CBxW9]                     BIT                 NULL,
        [PersonalMultiple]          INT                 NULL,
        [IsActive]                  BIT                 NOT NULL,
        [IsDeleted]                 BIT                 NOT NULL,
        [CreatedById]               UNIQUEIDENTIFIER    NOT NULL,
        [CreatedDate]               DATETIMEOFFSET(7)   NOT NULL,
        [ModifiedById]              UNIQUEIDENTIFIER    NOT NULL,
        [ModifiedDate]              DATETIMEOFFSET(7)   NOT NULL,

        PRIMARY KEY ([Id])
    );
    ');

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (
        @MigrationName,
        'Creates RSU.uddt_GetUserRecruitCreateFromResourceIdResult table type mirroring spUserRecruitCreateFromResourceId result set'
    );

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH
GO

/*
ROLLBACK SCRIPT:
IF EXISTS (
    SELECT 1 FROM sys.table_types
    WHERE name = N'uddt_GetUserRecruitCreateFromResourceIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult];

DELETE FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = '20260417_1300_CreateRSU_GetUserRecruitCreateFromResourceIdResult';
*/
