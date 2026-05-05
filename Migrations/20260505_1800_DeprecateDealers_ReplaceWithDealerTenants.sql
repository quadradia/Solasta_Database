/*
Migration: 20260505_1800_DeprecateDealers_ReplaceWithDealerTenants
Author: Andres Sosa
Date: 2026-05-05
Description:
    Deprecates ACC.Dealers and replaces all references with ACC.DealerTenants.
    - Adds DealerPrefix, SquareMedLogoPath, DealerRootSettingsJson to ACC.DealerTenants
    - Renames FK column DealerId -> DealerTenantId in 21 child tables
    - Retargets all 22 FK constraints from ACC.Dealers to ACC.DealerTenants.DealerTenantID
      (FNE.FundingSources had a duplicate FK; only one is recreated)
    - Drops ACC.Dealers (no data)
    - Updates ACC.fxGetContextUserTable, CNS.fxGroupMasterDealersTo2000
    - Updates views: vwGen_UserResources, vwGen_UserRecruits, vwGen_Seasons,
      vwGen_TeamLocations, vwUserResourceFullSearchDataSet
    - Updates procedures: spUserResourceNewDefaultPlusUser, spUserResourceAvatarGetJson,
      spUserResourceSearchFull_JSON
Dependencies: 20260505_1700_ReorderColumns_DealerTenants
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1800_DeprecateDealers_ReplaceWithDealerTenants';

    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- ================================================================
    -- STEP 1: Add missing Dealers columns to ACC.DealerTenants
    -- ================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.DealerTenants') AND name = 'DealerPrefix')
        ALTER TABLE [ACC].[DealerTenants] ADD [DealerPrefix] [char](3) NOT NULL
            CONSTRAINT [DF_DealerTenants_DealerPrefix] DEFAULT ('NNN');

    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.DealerTenants') AND name = 'SquareMedLogoPath')
        ALTER TABLE [ACC].[DealerTenants] ADD [SquareMedLogoPath] [nvarchar](max) NOT NULL
            CONSTRAINT [DF_DealerTenants_SquareMedLogoPath] DEFAULT ('N%C3%BAvol9Head.png');

    IF NOT EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.DealerTenants') AND name = 'DealerRootSettingsJson')
        ALTER TABLE [ACC].[DealerTenants] ADD [DealerRootSettingsJson] [nvarchar](max) NOT NULL
            CONSTRAINT [DF_DealerTenants_DealerRootSettingsJson] DEFAULT (N'{}');

    -- ================================================================
    -- STEP 2: Drop dependent views (reference DealerId from child tables)
    -- ================================================================
    IF OBJECT_ID('RSU.vwGen_UserResources', 'V') IS NOT NULL DROP VIEW [RSU].[vwGen_UserResources];
    IF OBJECT_ID('RSU.vwGen_UserRecruits', 'V') IS NOT NULL DROP VIEW [RSU].[vwGen_UserRecruits];
    IF OBJECT_ID('RSU.vwGen_Seasons', 'V') IS NOT NULL DROP VIEW [RSU].[vwGen_Seasons];
    IF OBJECT_ID('RSU.vwGen_TeamLocations', 'V') IS NOT NULL DROP VIEW [RSU].[vwGen_TeamLocations];
    IF OBJECT_ID('RSU.vwUserResourceFullSearchDataSet', 'V') IS NOT NULL DROP VIEW [RSU].[vwUserResourceFullSearchDataSet];

    -- ================================================================
    -- STEP 3: Drop schema-bound functions that reference ACC.Users.DealerId
    -- ================================================================
    IF OBJECT_ID('ACC.fxGetContextUserTable', 'TF') IS NOT NULL DROP FUNCTION [ACC].[fxGetContextUserTable];
    IF OBJECT_ID('UTL.fxValidateRequestByDealerId', 'TF') IS NOT NULL DROP FUNCTION [UTL].[fxValidateRequestByDealerId];

    -- ================================================================
    -- STEP 4: Drop all FK constraints pointing to ACC.Dealers
    -- ================================================================
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Users_Dealers')
        ALTER TABLE [ACC].[Users] DROP CONSTRAINT [FK_Users_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_Dealers')
        ALTER TABLE [ACE].[CustomerAddresses] DROP CONSTRAINT [FK_Addresses_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Customers_Dealers')
        ALTER TABLE [ACE].[Customers] DROP CONSTRAINT [FK_Customers_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_Dealers')
        ALTER TABLE [ACE].[MasterFileAccounts] DROP CONSTRAINT [FK_MasterFileAccounts_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_MasterFiles_Dealers')
        ALTER TABLE [ACE].[MasterFiles] DROP CONSTRAINT [FK_MasterFiles_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_AffiliateCampaigns_Dealers')
        ALTER TABLE [AFL].[AffiliateCampaigns] DROP CONSTRAINT [FK_AffiliateCampaigns_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Affiliates_Dealers')
        ALTER TABLE [AFL].[Affiliates] DROP CONSTRAINT [FK_Affiliates_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_CampaignPlacements_Dealers')
        ALTER TABLE [AFL].[CampaignPlacements] DROP CONSTRAINT [FK_CampaignPlacements_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadAttributions_Dealers')
        ALTER TABLE [AFL].[LeadAttributions] DROP CONSTRAINT [FK_LeadAttributions_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_TokenClicks_Dealers')
        ALTER TABLE [AFL].[TokenClicks] DROP CONSTRAINT [FK_TokenClicks_Dealers];
    -- FundingSources had a duplicate FK — drop both
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_FundingSources_Dealers')
        ALTER TABLE [FNE].[FundingSources] DROP CONSTRAINT [FK_FundingSources_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_FundingSources_Dealers1')
        ALTER TABLE [FNE].[FundingSources] DROP CONSTRAINT [FK_FundingSources_Dealers1];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_MasAccountTemplates_Dealers')
        ALTER TABLE [MAS].[MasAccountTemplates] DROP CONSTRAINT [FK_MasAccountTemplates_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_Dealers')
        ALTER TABLE [MAS].[PremiseAddresses] DROP CONSTRAINT [FK_PremiseAddresses_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Address_Dealers')
        ALTER TABLE [QAL].[LeadAddresses] DROP CONSTRAINT [FK_Address_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadDispositions_Dealers')
        ALTER TABLE [QAL].[LeadDispositions] DROP CONSTRAINT [FK_LeadDispositions_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Leads_Dealers')
        ALTER TABLE [QAL].[Leads] DROP CONSTRAINT [FK_Leads_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadSources_Dealers')
        ALTER TABLE [QAL].[LeadSources] DROP CONSTRAINT [FK_LeadSources_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Season_Dealers')
        ALTER TABLE [RSU].[Seasons] DROP CONSTRAINT [FK_Season_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_TeamLocations_Dealers')
        ALTER TABLE [RSU].[TeamLocations] DROP CONSTRAINT [FK_TeamLocations_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_UserRecruits_Dealers')
        ALTER TABLE [RSU].[UserRecruits] DROP CONSTRAINT [FK_UserRecruits_Dealers];
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_UserResources_Dealers')
        ALTER TABLE [RSU].[UserResources] DROP CONSTRAINT [FK_UserResources_Dealers];

    -- ================================================================
    -- STEP 5: Rename DealerId -> DealerTenantId in all 21 child tables
    -- ================================================================
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACC.Users') AND name = 'DealerId')
        EXEC sp_rename 'ACC.Users.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACE.CustomerAddresses') AND name = 'DealerId')
        EXEC sp_rename 'ACE.CustomerAddresses.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACE.Customers') AND name = 'DealerId')
        EXEC sp_rename 'ACE.Customers.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACE.MasterFileAccounts') AND name = 'DealerId')
        EXEC sp_rename 'ACE.MasterFileAccounts.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('ACE.MasterFiles') AND name = 'DealerId')
        EXEC sp_rename 'ACE.MasterFiles.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.AffiliateCampaigns') AND name = 'DealerId')
        EXEC sp_rename 'AFL.AffiliateCampaigns.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.Affiliates') AND name = 'DealerId')
        EXEC sp_rename 'AFL.Affiliates.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.CampaignPlacements') AND name = 'DealerId')
        EXEC sp_rename 'AFL.CampaignPlacements.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.LeadAttributions') AND name = 'DealerId')
        EXEC sp_rename 'AFL.LeadAttributions.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('AFL.TokenClicks') AND name = 'DealerId')
        EXEC sp_rename 'AFL.TokenClicks.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('FNE.FundingSources') AND name = 'DealerId')
        EXEC sp_rename 'FNE.FundingSources.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAS.MasAccountTemplates') AND name = 'DealerId')
        EXEC sp_rename 'MAS.MasAccountTemplates.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('MAS.PremiseAddresses') AND name = 'DealerId')
        EXEC sp_rename 'MAS.PremiseAddresses.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('QAL.LeadAddresses') AND name = 'DealerId')
        EXEC sp_rename 'QAL.LeadAddresses.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('QAL.LeadDispositions') AND name = 'DealerId')
        EXEC sp_rename 'QAL.LeadDispositions.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('QAL.Leads') AND name = 'DealerId')
        EXEC sp_rename 'QAL.Leads.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('QAL.LeadSources') AND name = 'DealerId')
        EXEC sp_rename 'QAL.LeadSources.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('RSU.Seasons') AND name = 'DealerId')
        EXEC sp_rename 'RSU.Seasons.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('RSU.TeamLocations') AND name = 'DealerId')
        EXEC sp_rename 'RSU.TeamLocations.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('RSU.UserRecruits') AND name = 'DealerId')
        EXEC sp_rename 'RSU.UserRecruits.DealerId', 'DealerTenantId', 'COLUMN';
    IF EXISTS (SELECT 1
FROM sys.columns
WHERE object_id = OBJECT_ID('RSU.UserResources') AND name = 'DealerId')
        EXEC sp_rename 'RSU.UserResources.DealerId', 'DealerTenantId', 'COLUMN';

    -- ================================================================
    -- STEP 6: Add new FK constraints pointing to ACC.DealerTenants
    -- ================================================================
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Users_DealerTenants')
        ALTER TABLE [ACC].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Addresses_DealerTenants')
        ALTER TABLE [ACE].[CustomerAddresses] WITH CHECK ADD CONSTRAINT [FK_Addresses_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Customers_DealerTenants')
        ALTER TABLE [ACE].[Customers] WITH CHECK ADD CONSTRAINT [FK_Customers_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_MasterFileAccounts_DealerTenants')
        ALTER TABLE [ACE].[MasterFileAccounts] WITH CHECK ADD CONSTRAINT [FK_MasterFileAccounts_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_MasterFiles_DealerTenants')
        ALTER TABLE [ACE].[MasterFiles] WITH CHECK ADD CONSTRAINT [FK_MasterFiles_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_AffiliateCampaigns_DealerTenants')
        ALTER TABLE [AFL].[AffiliateCampaigns] WITH CHECK ADD CONSTRAINT [FK_AffiliateCampaigns_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Affiliates_DealerTenants')
        ALTER TABLE [AFL].[Affiliates] WITH CHECK ADD CONSTRAINT [FK_Affiliates_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_CampaignPlacements_DealerTenants')
        ALTER TABLE [AFL].[CampaignPlacements] WITH CHECK ADD CONSTRAINT [FK_CampaignPlacements_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadAttributions_DealerTenants')
        ALTER TABLE [AFL].[LeadAttributions] WITH CHECK ADD CONSTRAINT [FK_LeadAttributions_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_TokenClicks_DealerTenants')
        ALTER TABLE [AFL].[TokenClicks] WITH CHECK ADD CONSTRAINT [FK_TokenClicks_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    -- FundingSources: was two FKs; recreate as one
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_FundingSources_DealerTenants')
        ALTER TABLE [FNE].[FundingSources] WITH CHECK ADD CONSTRAINT [FK_FundingSources_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_MasAccountTemplates_DealerTenants')
        ALTER TABLE [MAS].[MasAccountTemplates] WITH CHECK ADD CONSTRAINT [FK_MasAccountTemplates_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_PremiseAddresses_DealerTenants')
        ALTER TABLE [MAS].[PremiseAddresses] WITH CHECK ADD CONSTRAINT [FK_PremiseAddresses_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Address_DealerTenants')
        ALTER TABLE [QAL].[LeadAddresses] WITH CHECK ADD CONSTRAINT [FK_Address_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadDispositions_DealerTenants')
        ALTER TABLE [QAL].[LeadDispositions] WITH CHECK ADD CONSTRAINT [FK_LeadDispositions_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Leads_DealerTenants')
        ALTER TABLE [QAL].[Leads] WITH CHECK ADD CONSTRAINT [FK_Leads_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_LeadSources_DealerTenants')
        ALTER TABLE [QAL].[LeadSources] WITH CHECK ADD CONSTRAINT [FK_LeadSources_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Season_DealerTenants')
        ALTER TABLE [RSU].[Seasons] WITH CHECK ADD CONSTRAINT [FK_Season_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_TeamLocations_DealerTenants')
        ALTER TABLE [RSU].[TeamLocations] WITH CHECK ADD CONSTRAINT [FK_TeamLocations_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_UserRecruits_DealerTenants')
        ALTER TABLE [RSU].[UserRecruits] WITH CHECK ADD CONSTRAINT [FK_UserRecruits_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);
    IF NOT EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_UserResources_DealerTenants')
        ALTER TABLE [RSU].[UserResources] WITH CHECK ADD CONSTRAINT [FK_UserResources_DealerTenants]
            FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]);

    -- ================================================================
    -- STEP 7: Drop ACC.Dealers (no data; drop its own FK first)
    -- ================================================================
    IF EXISTS (SELECT 1
FROM sys.foreign_keys
WHERE name = 'FK_Dealers_PoliticalTimeZones')
        ALTER TABLE [ACC].[Dealers] DROP CONSTRAINT [FK_Dealers_PoliticalTimeZones];
    IF OBJECT_ID('ACC.Dealers', 'U') IS NOT NULL
        DROP TABLE [ACC].[Dealers];

    -- ================================================================
    -- STEP 8: Recreate ACC.fxGetContextUserTable (DealerId -> DealerTenantId)
    -- ================================================================
    EXEC sp_executesql N'
CREATE FUNCTION [ACC].[fxGetContextUserTable]
()
RETURNS
@ReturnList TABLE
(
    UserID          UNIQUEIDENTIFIER NOT NULL
    , HRUserId      INT NULL
    , GPEmployeeID  NVARCHAR(25) NULL
    , UserGuidMasked VARCHAR(50) NOT NULL
    , FirstName     NVARCHAR(MAX) NOT NULL
    , LastName      NVARCHAR(MAX) NOT NULL
    , Email         NVARCHAR(MAX) NULL
    , Username      NVARCHAR(256) NULL
    , PhoneNumber   NVARCHAR(MAX) NULL
    , DealerTenantId INT NULL
)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
        , @UserGuidMasked VARCHAR(50);

    IF (@UserID IS NULL) BEGIN
        SET @UserID = ''E6872B58-52B2-415C-A32B-45805F95A70A'';
    END

    SET @UserGuidMasked = ''XXXXXXX-XXXX-XXXX-XXXX-'' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12);

    INSERT INTO @ReturnList ( UserID, FirstName, LastName, UserGuidMasked )
    VALUES (@UserID, '''', '''', @UserGuidMasked);

    UPDATE RL SET
        RL.DealerTenantId  = URS.DealerTenantId
        , RL.HRUserId      = URS.HRUserId
        , RL.GPEmployeeID  = URS.GPEmployeeID
        , RL.FirstName     = URS.FirstName
        , RL.LastName      = URS.LastName
        , RL.Email         = URS.Email
        , RL.Username      = URS.Username
        , RL.PhoneNumber   = URS.PhoneNumber
    FROM
        @ReturnList AS RL
        INNER JOIN [ACC].[Users] AS URS WITH(NOLOCK)
        ON (URS.UserID = RL.UserID);

    RETURN;
END';

    -- ================================================================
    -- STEP 9: Update CNS.fxGroupMasterDealersTo2000 return column
    -- ================================================================
    EXEC sp_executesql N'
CREATE OR ALTER FUNCTION [CNS].[fxGroupMasterDealersTo2000]
(
    @CurrentDealerID INT
)
RETURNS
@ReturnList TABLE
(
    DealerTenantId INT NOT NULL
)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @RJHDealerID    INT = 3042
        , @KLDealerID       INT = 3050
        , @TargetDealerID   INT = 2000;

    IF (@CurrentDealerID = @TargetDealerID OR @CurrentDealerID = @RJHDealerID OR @CurrentDealerID = @KLDealerID) BEGIN
        INSERT INTO @ReturnList ( DealerTenantId ) VALUES ( @TargetDealerID ), ( @RJHDealerID ), ( @KLDealerID ), ( 0 );
    END ELSE BEGIN
        INSERT INTO @ReturnList ( DealerTenantId ) VALUES ( @CurrentDealerID ), ( 0 );
    END;

    RETURN;
END';

    -- ================================================================
    -- STEP 9b: Recreate UTL.fxValidateRequestByDealerId (DealerId -> DealerTenantId)
    -- ================================================================
    EXEC sp_executesql N'
CREATE FUNCTION [UTL].[fxValidateRequestByDealerId]
(
    @DealerId INT
)
RETURNS
@ReturnList TABLE
(
    UserId UNIQUEIDENTIFIER
    , RoleId UNIQUEIDENTIFIER
    , UserIdMasked VARCHAR(50)
    , DealerTenantId INT
    , FirstName VARCHAR(50)
    , LastName VARCHAR(50)
    , Email VARCHAR(MAX)
    , RoleName VARCHAR(50)
)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
        , @UserIdMasked VARCHAR(50);

    SET @UserIdMasked = (SELECT ''XXXXXXX-XXXX-XXXX-XXXX-'' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))

    INSERT INTO @ReturnList
        (UserId, RoleId, UserIdMasked, DealerTenantId, FirstName, LastName, Email, RoleName)
    SELECT
        U.UserId
        , UR.RoleId
        , @UserIdMasked
        , U.DealerTenantId
        , U.FirstName
        , U.LastName
        , U.Email
        , R.Name
    FROM
        [ACC].[Users] AS U WITH (NOLOCK)
        INNER JOIN [ACC].[UserRoles] AS UR WITH (NOLOCK)
        ON (UR.UserId = U.UserID)
        INNER JOIN [ACC].[Roles] AS R WITH (NOLOCK)
        ON (R.RoleID = UR.RoleId)
    WHERE
        (U.DealerTenantId = @DealerId);

    RETURN;
END';

    -- ================================================================
    -- STEP 10: Recreate views with DealerTenantId
    -- ================================================================

    -- vwGen_UserResources
    EXEC sp_executesql N'
CREATE VIEW [RSU].[vwGen_UserResources]
AS
    SELECT
        [RSU].[UserResources].[UserResourceID]
        , [RSU].[UserResources].[DealerTenantId]
        , [RSU].[UserResources].[UserId]
        , [RSU].[UserResources].[UserEmployeeTypeId]
        , [RSU].[UserResources].[UserResourceAddressId]
        , [RSU].[UserResources].[RecruitedById]
        , [RSU].[UserResources].[GPEmployeeId]
        , [RSU].[UserResources].[RecruitedByDate]
        , [RSU].[UserResources].[FullName]
        , [RSU].[UserResources].[PublicFullName]
        , [RSU].[UserResources].[SSN]
        , [RSU].[UserResources].[FirstName]
        , [RSU].[UserResources].[MiddleName]
        , [RSU].[UserResources].[LastName]
        , [RSU].[UserResources].[PreferredName]
        , [RSU].[UserResources].[CompanyName]
        , [RSU].[UserResources].[MaritalStatus]
        , [RSU].[UserResources].[SpouseName]
        , [RSU].[UserResources].[UserName]
        , [RSU].[UserResources].[Password]
        , [RSU].[UserResources].[BirthDate]
        , [RSU].[UserResources].[HomeTown]
        , [RSU].[UserResources].[BirthCity]
        , [RSU].[UserResources].[BirthState]
        , [RSU].[UserResources].[BirthCountry]
        , [RSU].[UserResources].[Sex]
        , [RSU].[UserResources].[ShirtSize]
        , [RSU].[UserResources].[HatSize]
        , [RSU].[UserResources].[DLNumber]
        , [RSU].[UserResources].[DLState]
        , [RSU].[UserResources].[DLCountry]
        , [RSU].[UserResources].[DLExpiresOn]
        , [RSU].[UserResources].[DLExpiration]
        , [RSU].[UserResources].[Height]
        , [RSU].[UserResources].[Weight]
        , [RSU].[UserResources].[EyeColor]
        , [RSU].[UserResources].[HairColor]
        , [RSU].[UserResources].[PhoneHome]
        , [RSU].[UserResources].[PhoneCell]
        , [RSU].[UserResources].[PhoneCellCarrierID]
        , [RSU].[UserResources].[PhoneFax]
        , [RSU].[UserResources].[Email]
        , [RSU].[UserResources].[CorporateEmail]
        , [RSU].[UserResources].[TreeLevel]
        , [RSU].[UserResources].[HasVerifiedAddress]
        , [RSU].[UserResources].[RightToWorkExpirationDate]
        , [RSU].[UserResources].[RightToWorkNotes]
        , [RSU].[UserResources].[RightToWorkStatusID]
        , [RSU].[UserResources].[IsLocked]
        , [RSU].[UserResources].[IsActive]
        , [RSU].[UserResources].[ModifiedDate]
        , [RSU].[UserResources].[ModifiedById]
        , [RSU].[UserResources].[CreatedDate]
        , [RSU].[UserResources].[CreatedById]
    FROM
        [RSU].[UserResources]
        INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel(''Read'', ''RSU'',''UserResources'') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
        ON
            ((AL.ReadAccessId = 2) OR ([RSU].[UserResources].CreatedById = AL.UserId))
            AND ([RSU].[UserResources].IsDeleted = ''FALSE'')
';

    -- vwGen_UserRecruits
    EXEC sp_executesql N'
CREATE VIEW [RSU].[vwGen_UserRecruits]
AS
    SELECT
        [RSU].[UserRecruits].[UserRecruitID]
        , [RSU].[UserRecruits].[UserResourceId]
        , [RSU].[UserRecruits].[UserTypeId]
        , [RSU].[UserRecruits].[ReportsToId]
        , [RSU].[UserRecruits].[UserRecruitAddressId]
        , [RSU].[UserRecruits].[DealerTenantId]
        , [RSU].[UserRecruits].[SeasonId]
        , [RSU].[UserRecruits].[OwnerApprovalId]
        , [RSU].[UserRecruits].[TeamId]
        , [RSU].[UserRecruits].[PayScaleId]
        , [RSU].[UserRecruits].[SchoolId]
        , [RSU].[UserRecruits].[ShackingUpId]
        , [RSU].[UserRecruits].[UserRecruitCohabbitTypeId]
        , [RSU].[UserRecruits].[AlternatePayScheduleId]
        , [RSU].[UserRecruits].[Location]
        , [RSU].[UserRecruits].[OwnerApprovalDate]
        , [RSU].[UserRecruits].[ManagerApprovalDate]
        , [RSU].[UserRecruits].[EmergencyName]
        , [RSU].[UserRecruits].[EmergencyPhone]
        , [RSU].[UserRecruits].[EmergencyRelationship]
        , [RSU].[UserRecruits].[IsRecruiter]
        , [RSU].[UserRecruits].[PreviousSummer]
        , [RSU].[UserRecruits].[SignatureDate]
        , [RSU].[UserRecruits].[HireDate]
        , [RSU].[UserRecruits].[GPExemptions]
        , [RSU].[UserRecruits].[GPW4Allowances]
        , [RSU].[UserRecruits].[GPW9Name]
        , [RSU].[UserRecruits].[GPW9BusinessName]
        , [RSU].[UserRecruits].[GPW9TIN]
        , [RSU].[UserRecruits].[SocialSecCardStatusID]
        , [RSU].[UserRecruits].[DriversLicenseStatusID]
        , [RSU].[UserRecruits].[W4StatusID]
        , [RSU].[UserRecruits].[I9StatusID]
        , [RSU].[UserRecruits].[W9StatusID]
        , [RSU].[UserRecruits].[SocialSecCardNotes]
        , [RSU].[UserRecruits].[DriversLicenseNotes]
        , [RSU].[UserRecruits].[W4Notes]
        , [RSU].[UserRecruits].[I9Notes]
        , [RSU].[UserRecruits].[W9Notes]
        , [RSU].[UserRecruits].[EIN]
        , [RSU].[UserRecruits].[SUTA]
        , [RSU].[UserRecruits].[WorkersComp]
        , [RSU].[UserRecruits].[FedFilingStatus]
        , [RSU].[UserRecruits].[EICFilingStatus]
        , [RSU].[UserRecruits].[TaxWitholdingState]
        , [RSU].[UserRecruits].[StateFilingStatus]
        , [RSU].[UserRecruits].[GPDependents]
        , [RSU].[UserRecruits].[CriminalOffense]
        , [RSU].[UserRecruits].[Offense]
        , [RSU].[UserRecruits].[OffenseExplanation]
        , [RSU].[UserRecruits].[Rent]
        , [RSU].[UserRecruits].[Pet]
        , [RSU].[UserRecruits].[Utilities]
        , [RSU].[UserRecruits].[Fuel]
        , [RSU].[UserRecruits].[Furniture]
        , [RSU].[UserRecruits].[CellPhoneCredit]
        , [RSU].[UserRecruits].[GasCredit]
        , [RSU].[UserRecruits].[RentExempt]
        , [RSU].[UserRecruits].[IsServiceTech]
        , [RSU].[UserRecruits].[StateId]
        , [RSU].[UserRecruits].[CountryId]
        , [RSU].[UserRecruits].[StreetAddress]
        , [RSU].[UserRecruits].[StreetAddress2]
        , [RSU].[UserRecruits].[City]
        , [RSU].[UserRecruits].[PostalCode]
        , [RSU].[UserRecruits].[CBxSocialSecCard]
        , [RSU].[UserRecruits].[CBxDriversLicense]
        , [RSU].[UserRecruits].[CBxW4]
        , [RSU].[UserRecruits].[CBxI9]
        , [RSU].[UserRecruits].[CBxW9]
        , [RSU].[UserRecruits].[PersonalMultiple]
        , [RSU].[UserRecruits].[IsActive]
        , [RSU].[UserRecruits].[CreatedById]
        , [RSU].[UserRecruits].[CreatedDate]
        , [RSU].[UserRecruits].[ModifiedById]
        , [RSU].[UserRecruits].[ModifiedDate]
    FROM
        [RSU].[UserRecruits]
        INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel(''Read'', ''RSU'',''UserRecruits'') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
        ON
            ((AL.ReadAccessId = 2))
            AND ([RSU].[UserRecruits].IsDeleted = ''FALSE'')
';

    -- vwGen_Seasons
    EXEC sp_executesql N'
CREATE VIEW [RSU].[vwGen_Seasons]
AS
    SELECT
        [RSU].[Seasons].[SeasonID]
        , [RSU].[Seasons].[PreSeasonID]
        , [RSU].[Seasons].[DealerTenantId]
        , [RSU].[Seasons].[SeasonName]
        , [RSU].[Seasons].[StartDate]
        , [RSU].[Seasons].[EndDate]
        , [RSU].[Seasons].[ShowInHiringManager]
        , [RSU].[Seasons].[IsCurrent]
        , [RSU].[Seasons].[IsVisibleToRecruits]
        , [RSU].[Seasons].[IsInsideSales]
        , [RSU].[Seasons].[IsPreseason]
        , [RSU].[Seasons].[IsSummer]
        , [RSU].[Seasons].[IsExtended]
        , [RSU].[Seasons].[IsYearRound]
        , [RSU].[Seasons].[IsContractor]
        , [RSU].[Seasons].[IsDealer]
        , [RSU].[Seasons].[IsCurbNSign]
        , [RSU].[Seasons].[ExcellentCreditScoreThreshold]
        , [RSU].[Seasons].[PassCreditScoreThreshold]
        , [RSU].[Seasons].[SubCreditScoreThreshold]
        , [RSU].[Seasons].[IsActive]
        , [RSU].[Seasons].[ModifiedDate]
        , [RSU].[Seasons].[ModifiedById]
        , [RSU].[Seasons].[CreatedDate]
        , [RSU].[Seasons].[CreatedById]
    FROM
        [RSU].[Seasons]
        INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel(''Read'', ''RSU'',''Seasons'') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
        ON
            ((AL.ReadAccessId = 2) OR ([RSU].[Seasons].CreatedById = AL.UserId))
            AND ([RSU].[Seasons].IsDeleted = ''FALSE'')
';

    -- vwGen_TeamLocations
    EXEC sp_executesql N'
CREATE VIEW [RSU].[vwGen_TeamLocations]
AS
    SELECT
        [RSU].[TeamLocations].[TeamLocationID]
        , [RSU].[TeamLocations].[DealerTenantId]
        , [RSU].[TeamLocations].[CreatedFromTeamLocationId]
        , [RSU].[TeamLocations].[SeasonId]
        , [RSU].[TeamLocations].[PoliticalStateId]
        , [RSU].[TeamLocations].[PoliticalTimeZoneId]
        , [RSU].[TeamLocations].[GpSalesTerritoryId]
        , [RSU].[TeamLocations].[IvOfficeId]
        , [RSU].[TeamLocations].[AeOfficeId]
        , [RSU].[TeamLocations].[MarketId]
        , [RSU].[TeamLocations].[TeamLocationName]
        , [RSU].[TeamLocations].[Description]
        , [RSU].[TeamLocations].[City]
        , [RSU].[TeamLocations].[SiteCodeID]
        , [RSU].[TeamLocations].[IsActive]
        , [RSU].[TeamLocations].[ModifiedDate]
        , [RSU].[TeamLocations].[ModifiedById]
        , [RSU].[TeamLocations].[CreatedDate]
        , [RSU].[TeamLocations].[CreatedById]
    FROM
        [RSU].[TeamLocations]
        INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel(''Read'', ''RSU'',''TeamLocations'') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
        ON
            ((AL.ReadAccessId = 2) OR ([RSU].[TeamLocations].CreatedById = AL.UserId))
            AND ([RSU].[TeamLocations].IsDeleted = ''FALSE'')
';

    -- vwUserResourceFullSearchDataSet
    EXEC sp_executesql N'
CREATE VIEW [RSU].[vwUserResourceFullSearchDataSet]
AS
    SELECT
        RSU.UserResourceID AS ID
        , RSU.DealerTenantId
        , RSU.UserId
        , RSU.UserResourceAddressId
        , RSU.UserEmployeeTypeId
        , UET.UserEmployeeTypeName
        , RSU.RecruitedById
        , RSU.GPEmployeeId AS [CompanyId]
        , CAST(RSU.RecruitedByDate AS DATETIME) AS [RecruitedOn]
        , RSU.FullName
        , RSU.PublicFullName
        , ISNULL(RSU.SSN, '''') AS SSN
        , RSU.FirstName
        , ISNULL(RSU.MiddleName, '''') AS [MiddleName]
        , RSU.LastName
        , RSU.PreferredName
        , ISNULL(RSU.CompanyName, '''') AS [CompanyName]
        , CASE
            WHEN RSU.MaritalStatus = 1 THEN ''Married''
            WHEN RSU.MaritalStatus IS NULL THEN ''Undefined''
            ELSE ''Single''
          END AS [MaritalStatus]
        , ISNULL(RSU.SpouseName, '''') AS [SpouseName]
        , U.UserName
        , RSU.[Password]
        , RSU.BirthDate
        , RSU.HomeTown
        , RSU.BirthCity
        , RSU.BirthState
        , RSU.BirthCountry
        , CASE
            WHEN RSU.Sex = 1 THEN ''Male''
            WHEN RSU.Sex = 0 THEN ''Female''
            ELSE ''''
          END AS [Sex]
        , RSU.ShirtSize
        , RSU.HatSize
        , RSU.DLNumber
        , RSU.DLState
        , RSU.DLCountry
        , RSU.DLExpiresOn
        , RSU.DLExpiration
        , RSU.Height
        , RSU.[Weight]
        , RSU.EyeColor
        , RSU.HairColor
        , UTL.fxRemovePhoneDecorations(RSU.PhoneHome) AS [PhoneHome]
        , UTL.fxRemovePhoneDecorations(RSU.PhoneCell) AS [PhoneCell]
        , UTL.fxRemovePhoneDecorations(RSU.PhoneFax) AS [PhoneFax]
        , RSU.Email
        , URA.StreetAddress
        , URA.City
        , URA.PoliticalStateId
        , URA.PostalCode
        , RSU.CorporateEmail
        , RSU.TreeLevel
        , RSU.HasVerifiedAddress
        , CAST(RSU.RightToWorkExpirationDate AS DATE) AS [RightToWorkExpirationDate]
        , RSU.RightToWorkNotes
        , RSU.RightToWorkStatusID
        , RSU.IsLocked
        , RSU.IsActive
    FROM
        [RSU].[UserResources] AS RSU WITH(NOLOCK)
        INNER JOIN [RSU].[UserEmployeeTypes] AS UET WITH(NOLOCK)
        ON
            (UET.UserEmployeeTypeID = RSU.UserEmployeeTypeId)
            AND (RSU.IsDeleted = ''False'')
        LEFT OUTER JOIN [ACC].[Users] AS U WITH(NOLOCK)
        ON (U.UserID = RSU.UserId)
        LEFT OUTER JOIN [RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
        ON (URA.UserResourceAddressID = RSU.UserResourceAddressId)
';

    -- ================================================================
    -- STEP 11: Update stored procedures
    -- ================================================================

    -- spUserResourceNewDefaultPlusUser
    EXEC sp_executesql N'
CREATE OR ALTER PROCEDURE [RSU].[spUserResourceNewDefaultPlusUser]
(
    @DealerId INT
    , @SeasonId INT
    , @FirstName NVARCHAR(50)
    , @MiddleName NVARCHAR(50) = NULL
    , @LastName NVARCHAR(50)
    , @Email NVARCHAR(256)
    , @PhoneNumber NVARCHAR(15)
    , @RoleId UNIQUEIDENTIFIER = NULL
    , @UserTypeID SMALLINT = 1
    , @UserEmployeeTypeId VARCHAR(20)
    , @UserID UNIQUEIDENTIFIER OUTPUT
    , @UserResourceID INT OUTPUT
    , @UserRecruitID INT OUTPUT
    , @ShowOutput BIT = ''True''
)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @LanguageId NVARCHAR(50) = ''en''
        , @DealerName NVARCHAR(100)
        , @PasswordHash NVARCHAR(MAX) = ''AGYHF9mURPPLzuj4tmmgapy1APJ0PYHZb225Emn52RGpHahbTaTYVta7Li1xhGAZlw==''
        , @SecurityStamp NVARCHAR(MAX) = ''ea342a9a-bad3-4e9a-9fb2-3f5e20a0c424''

    BEGIN TRY
        SET @UserID = NEWID();

        SELECT @DealerName = DealerTenantName FROM [ACC].[DealerTenants] WHERE DealerTenantID = @DealerId;

        IF(EXISTS(SELECT TOP 1 1 FROM [ACC].[Users] WHERE (Email = @Email AND DealerTenantId = @DealerId))) BEGIN
            RAISERROR (N''[30200]:This user already exists with email "%s" for dealer "%s (%d)"''
                , 18
                , 1
                , @Email
                , @DealerName
                , @DealerId);
        END

        INSERT INTO [ACC].[Users] (
            [UserID]
            , [DealerTenantId]
            , [LanguageId]
            , [FirstName]
            , [LastName]
            , [Email]
            , [EmailConfirmed]
            , [Username]
            , [PasswordHash]
            , [SecurityStamp]
            , [PhoneNumber]
            , [PhoneNumberConfirmed]
            , [TwoFactorEnabled]
            , [LockoutEnabled]
            , [AccessFailedCount]
        ) VALUES (
            @UserID,
            @DealerId,
            @LanguageId,
            @FirstName,
            @LastName,
            @Email,
            ''False'',
            @Email,
            @PasswordHash,
            @SecurityStamp,
            @PhoneNumber,
            ''False'',
            ''False'',
            ''False'',
            0
        );

        IF (@RoleId IS NOT NULL) BEGIN
            INSERT INTO [ACC].[UserRoles] ([UserId], [RoleId]) VALUES (@UserID, @RoleId);
        END

        DECLARE @UserResourceAddressID INT;
        INSERT INTO [RSU].[UserResourceAddresses] (
            [PoliticalStateId]
            , [PoliticalCountryId]
            , [PoliticalTimeZoneId]
            , [StreetAddress]
            , [StreetAddress2]
            , [City]
            , [PostalCode]
            , [PlusFour]
        ) VALUES (
            ''UT'',
            N''USA'',
            7,
            N'''',
            N'''',
            N'''',
            N'''',
            N''''
        );
        SET @UserResourceAddressID = SCOPE_IDENTITY();

        DECLARE @GPEmployeeId NVARCHAR(25) = [UTL].fxCreateGpEmployeeNumberNxN(@FirstName, @LastName, @DealerId, 3, 3);
        INSERT INTO [RSU].[UserResources] (
            [DealerTenantId]
            , [UserId]
            , [UserEmployeeTypeId]
            , [UserResourceAddressId]
            , [GPEmployeeId]
            , [RecruitedByDate]
            , [FullName]
            , [PublicFullName]
            , [FirstName]
            , [MiddleName]
            , [LastName]
            , [PreferredName]
            , [UserName]
            , [Password]
            , [Sex]
            , [PhoneCell]
            , [Email]
            , [CorporateEmail]
            , [HasVerifiedAddress]
            , [IsLocked]
        ) VALUES (
            @DealerId,
            @UserID,
            @UserEmployeeTypeId,
            @UserResourceAddressID,
            @GPEmployeeId,
            SYSDATETIMEOFFSET(),
            @FirstName + N'' '' + @LastName,
            @FirstName + N'' '' + @LastName,
            @FirstName,
            @MiddleName,
            @LastName,
            @FirstName + N'' '' + @LastName,
            @Email,
            ''Nuvol9CRM'',
            0,
            @PhoneNumber,
            @Email,
            @Email,
            ''False'',
            ''False''
        );
        SET @UserResourceID = SCOPE_IDENTITY();

        UPDATE [ACC].[Users] SET HRUserId = @UserResourceID WHERE UserID = @UserID;

        DECLARE @UserRecruitAddressId INT;
        INSERT INTO [RSU].[UserRecruitAddresses] (
            [PoliticalStateId]
            , [PoliticalCountryId]
            , [PoliticalTimeZoneId]
            , [StreetAddress]
            , [StreetAddress2]
            , [City]
            , [PostalCode]
            , [PlusFour]
        ) SELECT TOP 1
            URA.PoliticalStateId
            , URA.PoliticalCountryId
            , URA.PoliticalTimeZoneId
            , URA.StreetAddress
            , URA.StreetAddress2
            , URA.City
            , URA.PostalCode
            , URA.PlusFour
        FROM [RSU].[UserResourceAddresses] AS URA WITH (NOLOCK)
        WHERE (URA.UserResourceAddressID = @UserResourceAddressID);
        SET @UserRecruitAddressId = SCOPE_IDENTITY();

        INSERT INTO [RSU].[UserRecruits] (
            [UserResourceId]
            , [UserTypeId]
            , [UserRecruitAddressId]
            , [DealerTenantId]
            , [SeasonId]
            , [IsRecruiter]
            , [SocialSecCardStatusID]
            , [DriversLicenseStatusID]
            , [W4StatusID]
            , [I9StatusID]
            , [W9StatusID]
            , [SocialSecCardNotes]
            , [DriversLicenseNotes]
            , [RentExempt]
            , [IsServiceTech]
            , [StateId]
            , [CountryId]
            , [StreetAddress]
            , [StreetAddress2]
            , [City]
            , [PostalCode]
        )
        SELECT
            @UserResourceID
            , @UserTypeID
            , @UserRecruitAddressId
            , @DealerId
            , @SeasonId
            , ''FALSE''
            , 0
            , 0
            , 0
            , 0
            , 0
            , N''[Missing]''
            , N''[Missing]''
            , ''FALSE''
            , ''FALSE''
            , URA.PoliticalStateId
            , URA.PoliticalCountryId
            , URA.StreetAddress
            , URA.StreetAddress2
            , URA.City
            , URA.PostalCode
        FROM [RSU].[UserResourceAddresses] AS URA WITH (NOLOCK)
        WHERE (URA.UserResourceAddressID = @UserResourceAddressID);
        SET @UserRecruitID = SCOPE_IDENTITY();

        UPDATE ACC.Users SET GPEmployeeID = @GPEmployeeId WHERE (UserID = @UserID);

        IF (@ShowOutput = 1) BEGIN
            SELECT * FROM [RSU].[vwUserResourceFullSearchDataSet] WHERE Id = @UserResourceID;
        END;

    END TRY
    BEGIN CATCH
        EXEC GEN.spExceptionsThrown;
        RETURN;
    END CATCH
END';

    -- spUserResourceAvatarGetJson
    EXEC sp_executesql N'
CREATE OR ALTER PROCEDURE [RSU].[spUserResourceAvatarGetJson]
(
    @UserResourceID INT
)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @DealerTenantId INT;
    SELECT @DealerTenantId = DealerTenantId FROM [ACC].[fxGetContextUserTable]();

    BEGIN TRY
        IF (NOT EXISTS(SELECT TOP(1) 1 FROM [RSU].[UserResources]
            WHERE UserResourceID = @UserResourceID
            AND DealerTenantId IN (SELECT DealerTenantId FROM [CNS].[fxGroupMasterDealersTo2000](@DealerTenantId)))) BEGIN
            RAISERROR(N''[30050]:SECURITY VIOLATION:  You do not have access to these resources.'', 18, 1);
            RETURN -1;
        END

        DECLARE @DefaultTable TABLE (
            [UserResourceImageID] [INT] NOT NULL
            , [UserResourceId] [INT] NOT NULL
            , [ImageTypeId] [VARCHAR](20) NOT NULL
            , [Size] [INT] NOT NULL
            , [FileName] [NVARCHAR](500) NOT NULL
            , [Image] [NVARCHAR](MAX) NOT NULL
            , [IsActive] [BIT] NOT NULL
            , [IsDeleted] [BIT] NOT NULL
            , [ModifiedDate] [DATETIMEOFFSET](7) NOT NULL
            , [ModifiedById] [UNIQUEIDENTIFIER] NOT NULL
            , [CreatedDate] [DATETIMEOFFSET](7) NOT NULL
            , [CreatedById] [UNIQUEIDENTIFIER] NOT NULL);
        INSERT INTO @DefaultTable (
            [UserResourceImageID], [UserResourceId], [ImageTypeId], [Size],
            [FileName], [Image], [IsActive], [IsDeleted],
            [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
        VALUES (
            0, @UserResourceId, ''AVATAR'', 156000,
            ''avatar.jpeg'', ''/img/avatar.jpeg'', ''True'', ''False'',
            SYSDATETIMEOFFSET(), ''E6872B58-52B2-415C-A32B-45805F95A70A'',
            SYSDATETIMEOFFSET(), ''E6872B58-52B2-415C-A32B-45805F95A70A''
        );

        DECLARE @Result NVARCHAR(MAX), @UserResource NVARCHAR(MAX);
        SELECT @UserResource = (SELECT * FROM [ACC].[fxGetUserInfoByUserResourceIdJSONTABLE](@UserResourceID) FOR JSON PATH, INCLUDE_NULL_VALUES);
        SET @UserResource = SUBSTRING(@UserResource, 2, LEN(@UserResource) - 2);
        SELECT @Result = (
            SELECT TOP (1)
                ISNULL(URI.UserResourceImageID, RT.UserResourceImageID) AS id
                , URI.UserResourceId AS userResourceId
                , JSON_QUERY(@UserResource, ''$'') AS userResource
                , ISNULL(URI.ImageTypeId, RT.ImageTypeId) AS imageTypeId
                , ISNULL(URI.Size, RT.Size) AS size
                , ISNULL(URI.[FileName], RT.[FileName]) AS [fileName]
                , ISNULL(URI.IsActive, RT.IsActive) AS isActive
                , ISNULL(URI.IsDeleted, RT.IsDeleted) AS isDeleted
                , ISNULL(URI.ModifiedDate, RT.ModifiedDate) AS modifiedDate
                , ISNULL(URI.ModifiedById, RT.ModifiedById) AS modifiedById
                , JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URI.ModifiedById), ''$'') AS modifiedBy
                , ISNULL(URI.CreatedDate, RT.CreatedDate) AS createdDate
                , ISNULL(URI.CreatedById, RT.CreatedById) AS createdById
                , JSON_QUERY([ACC].[fxGetUserInfoByUserIdJSONObject](URI.CreatedById), ''$'') AS createdBy
                , ISNULL(URI.[Image], RT.[Image]) AS [image]
            FROM
                @DefaultTable AS RT
                LEFT OUTER JOIN [RSU].[UserResourceImages] AS URI WITH(NOLOCK)
                ON (URI.UserResourceId = RT.UserResourceId)
            WHERE
                (RT.UserResourceId = @UserResourceID)
                AND (URI.IsDeleted = ''False'' OR (URI.IsDeleted IS NULL AND RT.IsDeleted = ''False''))
                AND (URI.IsActive = ''True'' OR (URI.IsActive IS NULL AND RT.IsActive = ''True''))
            ORDER BY URI.UserResourceImageID
            FOR JSON PATH, INCLUDE_NULL_VALUES);

        SET @Result = SUBSTRING(@Result, 2, LEN(@Result) - 2);
        SELECT @Result AS JsonOutPutMethod;

    END TRY
    BEGIN CATCH
        EXEC GEN.spExceptionsThrown;
        RETURN -1;
    END CATCH
END';

    -- spUserResourceSearchFull_JSON
    EXEC sp_executesql N'
CREATE OR ALTER PROCEDURE [RSU].[spUserResourceSearchFull_JSON]
(
    @JsonInput NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @DealerTenantId INT;
    SELECT @DealerTenantId = DealerTenantId FROM [ACC].[fxGetContextUserTable]();

    DECLARE @PhoneNumber VARCHAR(20) = NULL
        , @FirstName NVARCHAR(50) = NULL
        , @LastName NVARCHAR(50) = NULL
        , @Email NVARCHAR(100) = NULL
        , @Street NVARCHAR(50) = NULL
        , @UserResourceId INT = NULL;

    SELECT
        @PhoneNumber = [UTL].[fxRemovePhoneDecorations](PhoneNumber)
        , @FirstName = FirstName
        , @LastName = LastName
        , @Email = Email
        , @Street = Street
        , @UserResourceId = UserResourceId
    FROM OPENJSON(@JsonInput, ''$.args'')
    WITH (
        PhoneNumber VARCHAR(20) ''$.phoneNumber''
        , FirstName NVARCHAR(50) ''$.firstName''
        , LastName NVARCHAR(50) ''$.lastName''
        , Email NVARCHAR(100) ''$.email''
        , Street NVARCHAR(50) ''$.street''
        , UserResourceId INT ''$.userResourceId''
    );

    IF (LTRIM(RTRIM(@PhoneNumber)) = '''') SET @PhoneNumber = NULL;
    IF (LTRIM(RTRIM(@FirstName)) = '''') SET @FirstName = NULL;
    IF (LTRIM(RTRIM(@LastName)) = '''') SET @LastName = NULL;
    IF (LTRIM(RTRIM(@Email)) = '''') SET @Email = NULL;
    IF (LTRIM(RTRIM(@Street)) = '''') SET @Street = NULL;

    DECLARE @OffsetValue INT = 0
        , @TotalRows INT
        , @PageSize INT
        , @PageNumber INT
        , @Pages INT;
    SELECT
        @TotalRows = TotalRows
        , @PageSize = PageSize
        , @PageNumber = PageNumber
        , @Pages = Pages
    FROM OPENJSON(@JsonInput, ''$.pagingInfo'')
    WITH (
        TotalRows INT ''$.totalRows''
        , PageSize INT ''$.pageSize''
        , PageNumber INT ''$.pageNumber''
        , Pages INT ''$.pages''
    );

    PRINT ''@PageSize: '' + CAST(@PageSize AS VARCHAR(20)) + '' | @PageNumber: '' + CAST(@PageNumber AS VARCHAR(20)) + '' | @OffsetValue: '' + CAST(@OffsetValue AS VARCHAR(20));
    EXEC [UTL].[spPagingCalculateOffset] @PageSize=@PageSize OUTPUT, @PageNumber=@PageNumber OUTPUT, @OffsetValue=@OffsetValue OUTPUT;
    PRINT ''@PageSize: '' + CAST(@PageSize AS VARCHAR(20)) + '' | @PageNumber: '' + CAST(@PageNumber AS VARCHAR(20)) + '' | @OffsetValue: '' + CAST(@OffsetValue AS VARCHAR(20));

    DECLARE @Result NVARCHAR(MAX);
    WITH RootCTE AS (
        SELECT RSU.*
        FROM [RSU].[vwUserResourceFullSearchDataSet] AS RSU WITH(NOLOCK)
        LEFT OUTER JOIN [ACC].[Users] AS U WITH(NOLOCK)
            ON (U.UserID = RSU.UserId)
        LEFT OUTER JOIN [RSU].[UserResourceAddresses] AS URA WITH(NOLOCK)
            ON (URA.UserResourceAddressID = RSU.UserResourceAddressId)
        WHERE
            (RSU.DealerTenantId IN (SELECT DealerTenantId FROM [CNS].[fxGroupMasterDealersTo2000](@DealerTenantId)))
            AND ((@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](RSU.PhoneHome) = @PhoneNumber)
                OR (@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](RSU.PhoneCell) = @PhoneNumber)
                OR (@PhoneNumber IS NULL OR [UTL].[fxRemovePhoneDecorations](U.PhoneNumber) = @PhoneNumber))
            AND (@FirstName IS NULL OR RSU.FirstName LIKE @FirstName + ''%'')
            AND (@LastName IS NULL OR RSU.LastName LIKE @LastName + ''%'')
            AND (@Email IS NULL OR RSU.Email LIKE @Email + ''%'')
            AND (@Street IS NULL OR URA.StreetAddress LIKE @Street + ''%'')
            AND (@UserResourceId IS NULL OR RSU.Id = @UserResourceId)
            AND (U.IsDeleted = ''False'')
    ), TotalCountCTE AS (
        SELECT COUNT(*) AS TotalRows FROM RootCTE
    ), ResourceInfoCTE AS (
        SELECT
            RT.ID AS id
            , RT.DealerTenantId AS dealerId
            , RT.UserId AS userId
            , RT.UserResourceAddressId AS userResourceAddressId
            , RT.UserEmployeeTypeId AS userEmployeeTypeId
            , RT.UserEmployeeTypeName AS userEmployeeTypeName
            , RT.RecruitedById AS recruitedById
            , RT.CompanyId AS companyId
            , RT.RecruitedOn AS recruitedOn
            , RT.FullName AS fullName
            , RT.PublicFullName AS publicFullName
            , RT.SSN AS sSN
            , RT.FirstName AS firstName
            , RT.MiddleName AS middleName
            , RT.LastName AS lastName
            , RT.PreferredName AS preferredName
            , RT.CompanyName AS companyName
            , RT.MaritalStatus AS maritalStatus
            , RT.SpouseName AS spouseName
            , RT.UserName AS userName
            , RT.Password AS password
            , RT.BirthDate AS birthDate
            , RT.HomeTown AS homeTown
            , RT.BirthCity AS birthCity
            , RT.BirthState AS birthState
            , RT.BirthCountry AS birthCountry
            , RT.Sex AS sex
            , RT.ShirtSize AS shirtSize
            , RT.HatSize AS hatSize
            , RT.DLNumber AS dLNumber
            , RT.DLState AS dLState
            , RT.DLCountry AS dLCountry
            , RT.DLExpiresOn AS dLExpiresOn
            , RT.DLExpiration AS dLExpiration
            , RT.Height AS height
            , RT.Weight AS weight
            , RT.EyeColor AS eyeColor
            , RT.HairColor AS hairColor
            , RT.PhoneHome AS phoneHome
            , RT.PhoneCell AS phoneCell
            , RT.PhoneFax AS phoneFax
            , RT.Email AS email
            , RT.StreetAddress AS streetAddress
            , RT.City AS city
            , RT.PoliticalStateId AS politicalStateId
            , RT.PostalCode AS postalCode
            , RT.CorporateEmail AS corporateEmail
            , RT.TreeLevel AS treeLevel
            , RT.HasVerifiedAddress AS hasVerifiedAddress
            , RT.RightToWorkExpirationDate AS rightToWorkExpirationDate
            , RT.RightToWorkNotes AS rightToWorkNotes
            , RT.RightToWorkStatusID AS rightToWorkStatusID
            , RT.IsLocked AS isLocked
            , RT.IsActive AS isActive
        FROM RootCTE AS RT WITH(NOLOCK)
        ORDER BY RT.FullName
        OFFSET @OffsetValue ROWS
        FETCH NEXT @PageSize ROWS ONLY
    )
    SELECT
        @Result = (SELECT * FROM ResourceInfoCTE FOR JSON PATH, INCLUDE_NULL_VALUES)
        , @TotalRows = (SELECT TOP(1) TotalCountCTE.TotalRows FROM TotalCountCTE ORDER BY TotalCountCTE.TotalRows);

    DECLARE @TotalPages INT = @TotalRows / @PageSize
        , @Reminder INT = @TotalRows % @PageSize;
    IF (@Reminder > 0) SET @TotalPages = @TotalPages + 1;

    DECLARE @Totals NVARCHAR(MAX) = (
        SELECT
            @TotalPages AS totalPages
            , @PageSize AS pageSize
            , @PageNumber AS pageNumber
            , @TotalRows AS totalRows
        FOR JSON PATH, INCLUDE_NULL_VALUES);
    SET @Totals = SUBSTRING(@Totals, 2, LEN(@Totals) - 2);

    SELECT @Result = (
        SELECT
            JSON_QUERY(@Totals, ''$'') AS pagingInfo
            , JSON_QUERY(@Result, ''$'') AS resultSet
        FOR JSON PATH, INCLUDE_NULL_VALUES);
    SET @Result = SUBSTRING(@Result, 2, LEN(@Result) - 2);
    SELECT @Result AS JsonOutPutMethod;

END';

    -- ================================================================
    -- STEP 12: Record migration
    -- ================================================================
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName,
        'Deprecates ACC.Dealers: adds 3 columns to DealerTenants, renames DealerId->DealerTenantId in 21 tables, retargets 22 FKs to DealerTenants, drops Dealers, updates functions/views/SPs.');

    COMMIT TRANSACTION;
    PRINT 'Migration 20260505_1800 applied successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- This migration has no automatic rollback — ACC.Dealers has been dropped.
-- To rollback, restore from a pre-migration backup or:
--   1. Recreate ACC.Dealers from Tables/ACC/Dealers.sql (archived)
--   2. Rename DealerTenantId back to DealerId in all 21 tables
--   3. Retarget FKs back to ACC.Dealers
--   4. Recreate objects from their previous schema files
--   5. Remove from SchemaVersion:
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260505_1800_DeprecateDealers_ReplaceWithDealerTenants';
*/
