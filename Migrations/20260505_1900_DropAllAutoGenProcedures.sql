/*
Migration: 20260505_1900_DropAllAutoGenProcedures
Author: Andres Sosa
Date: 2026-05-05
Description:
    Drops all auto-generated stored procedures matching the pattern [<schema>].[spAutoGen_*].
    These procedures were imported from a different database and are no longer needed.

    Procedures dropped (99 total, all in [RSU] schema):
      spAutoGen_LocationRoles_CREATE/DELETE/UPDATE
      spAutoGen_Seasons_CREATE/DELETE/UPDATE
      spAutoGen_SeasonSummers_CREATE/DELETE/UPDATE
      spAutoGen_SeasonSummerSeasonMaps_CREATE/DELETE/UPDATE
      spAutoGen_SiteCodes_CREATE/DELETE/UPDATE
      spAutoGen_TeamLocationRosters_CREATE/DELETE/UPDATE
      spAutoGen_TeamLocations_CREATE/DELETE/UPDATE
      spAutoGen_TeamLocationsAndUsers_CREATE/DELETE/UPDATE
      spAutoGen_TeamLocationStateMappings_CREATE/DELETE/UPDATE
      spAutoGen_Teams_CREATE/DELETE/UPDATE
      spAutoGen_TerminationCategories_CREATE/DELETE/UPDATE
      spAutoGen_TerminationNotes_CREATE/DELETE/UPDATE
      spAutoGen_TerminationReasons_CREATE/DELETE/UPDATE
      spAutoGen_Terminations_CREATE/DELETE/UPDATE
      spAutoGen_TerminationStatusCodes_CREATE/DELETE/UPDATE
      spAutoGen_TerminationStatuses_CREATE/DELETE/UPDATE
      spAutoGen_TerminationTypes_CREATE/DELETE/UPDATE
      spAutoGen_UserAuthentication_CREATE/DELETE/UPDATE
      spAutoGen_UserEmployeeTypes_CREATE/DELETE/UPDATE
      spAutoGen_UserPhotos_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruitAddresses_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruitCohabbitTypes_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruitGoals_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruitPolicyAndProcedures_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruitRegistrations_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruits_CREATE/DELETE/UPDATE
      spAutoGen_UserRecruitSeasonGoals_CREATE/DELETE/UPDATE
      spAutoGen_UserResourceAddresses_CREATE/DELETE/UPDATE
      spAutoGen_UserResourceImages_CREATE/DELETE/UPDATE
      spAutoGen_UserResources_CREATE/DELETE/UPDATE
      spAutoGen_UserTypeGroups_CREATE/DELETE/UPDATE
      spAutoGen_UserTypes_CREATE/DELETE/UPDATE
      spAutoGen_UserTypeTeamTypes_CREATE/DELETE/UPDATE

Dependencies: None
*/

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = '20260505_1900_DropAllAutoGenProcedures';

    IF EXISTS (SELECT 1
FROM [dbo].[SchemaVersion]
WHERE [MigrationName] = @MigrationName)
    BEGIN
    PRINT 'Migration already applied. Skipping...';
    ROLLBACK TRANSACTION;
    RETURN;
END

    -- LocationRoles
    IF OBJECT_ID('[RSU].[spAutoGen_LocationRoles_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_LocationRoles_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_LocationRoles_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_LocationRoles_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_LocationRoles_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_LocationRoles_UPDATE];

    -- Seasons
    IF OBJECT_ID('[RSU].[spAutoGen_Seasons_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Seasons_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_Seasons_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Seasons_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_Seasons_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Seasons_UPDATE];

    -- SeasonSummers
    IF OBJECT_ID('[RSU].[spAutoGen_SeasonSummers_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SeasonSummers_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_SeasonSummers_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SeasonSummers_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_SeasonSummers_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SeasonSummers_UPDATE];

    -- SeasonSummerSeasonMaps
    IF OBJECT_ID('[RSU].[spAutoGen_SeasonSummerSeasonMaps_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SeasonSummerSeasonMaps_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_SeasonSummerSeasonMaps_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SeasonSummerSeasonMaps_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_SeasonSummerSeasonMaps_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SeasonSummerSeasonMaps_UPDATE];

    -- SiteCodes
    IF OBJECT_ID('[RSU].[spAutoGen_SiteCodes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SiteCodes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_SiteCodes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SiteCodes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_SiteCodes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_SiteCodes_UPDATE];

    -- TeamLocationRosters
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationRosters_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationRosters_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationRosters_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationRosters_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationRosters_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationRosters_UPDATE];

    -- TeamLocations
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocations_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocations_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocations_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocations_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocations_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocations_UPDATE];

    -- TeamLocationsAndUsers
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationsAndUsers_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationsAndUsers_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationsAndUsers_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationsAndUsers_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationsAndUsers_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationsAndUsers_UPDATE];

    -- TeamLocationStateMappings
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationStateMappings_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationStateMappings_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationStateMappings_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationStateMappings_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TeamLocationStateMappings_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TeamLocationStateMappings_UPDATE];

    -- Teams
    IF OBJECT_ID('[RSU].[spAutoGen_Teams_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Teams_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_Teams_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Teams_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_Teams_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Teams_UPDATE];

    -- TerminationCategories
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationCategories_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationCategories_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationCategories_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationCategories_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationCategories_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationCategories_UPDATE];

    -- TerminationNotes
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationNotes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationNotes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationNotes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationNotes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationNotes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationNotes_UPDATE];

    -- TerminationReasons
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationReasons_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationReasons_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationReasons_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationReasons_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationReasons_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationReasons_UPDATE];

    -- Terminations
    IF OBJECT_ID('[RSU].[spAutoGen_Terminations_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Terminations_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_Terminations_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Terminations_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_Terminations_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_Terminations_UPDATE];

    -- TerminationStatusCodes
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationStatusCodes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationStatusCodes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationStatusCodes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationStatusCodes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationStatusCodes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationStatusCodes_UPDATE];

    -- TerminationStatuses
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationStatuses_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationStatuses_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationStatuses_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationStatuses_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationStatuses_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationStatuses_UPDATE];

    -- TerminationTypes
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationTypes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationTypes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationTypes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationTypes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_TerminationTypes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_TerminationTypes_UPDATE];

    -- UserAuthentication
    IF OBJECT_ID('[RSU].[spAutoGen_UserAuthentication_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserAuthentication_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserAuthentication_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserAuthentication_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserAuthentication_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserAuthentication_UPDATE];

    -- UserEmployeeTypes
    IF OBJECT_ID('[RSU].[spAutoGen_UserEmployeeTypes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserEmployeeTypes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserEmployeeTypes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserEmployeeTypes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserEmployeeTypes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserEmployeeTypes_UPDATE];

    -- UserPhotos
    IF OBJECT_ID('[RSU].[spAutoGen_UserPhotos_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserPhotos_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserPhotos_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserPhotos_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserPhotos_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserPhotos_UPDATE];

    -- UserRecruitAddresses
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitAddresses_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitAddresses_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitAddresses_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitAddresses_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitAddresses_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitAddresses_UPDATE];

    -- UserRecruitCohabbitTypes
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitCohabbitTypes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitCohabbitTypes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitCohabbitTypes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitCohabbitTypes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitCohabbitTypes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitCohabbitTypes_UPDATE];

    -- UserRecruitGoals
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitGoals_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitGoals_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitGoals_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitGoals_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitGoals_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitGoals_UPDATE];

    -- UserRecruitPolicyAndProcedures
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitPolicyAndProcedures_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitPolicyAndProcedures_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitPolicyAndProcedures_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitPolicyAndProcedures_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitPolicyAndProcedures_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitPolicyAndProcedures_UPDATE];

    -- UserRecruitRegistrations
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitRegistrations_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitRegistrations_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitRegistrations_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitRegistrations_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitRegistrations_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitRegistrations_UPDATE];

    -- UserRecruits
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruits_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruits_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruits_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruits_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruits_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruits_UPDATE];

    -- UserRecruitSeasonGoals
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitSeasonGoals_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitSeasonGoals_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitSeasonGoals_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitSeasonGoals_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserRecruitSeasonGoals_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserRecruitSeasonGoals_UPDATE];

    -- UserResourceAddresses
    IF OBJECT_ID('[RSU].[spAutoGen_UserResourceAddresses_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResourceAddresses_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserResourceAddresses_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResourceAddresses_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserResourceAddresses_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResourceAddresses_UPDATE];

    -- UserResourceImages
    IF OBJECT_ID('[RSU].[spAutoGen_UserResourceImages_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResourceImages_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserResourceImages_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResourceImages_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserResourceImages_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResourceImages_UPDATE];

    -- UserResources
    IF OBJECT_ID('[RSU].[spAutoGen_UserResources_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResources_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserResources_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResources_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserResources_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserResources_UPDATE];

    -- UserTypeGroups
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypeGroups_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypeGroups_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypeGroups_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypeGroups_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypeGroups_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypeGroups_UPDATE];

    -- UserTypes
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypes_UPDATE];

    -- UserTypeTeamTypes
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypeTeamTypes_CREATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypeTeamTypes_CREATE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypeTeamTypes_DELETE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypeTeamTypes_DELETE];
    IF OBJECT_ID('[RSU].[spAutoGen_UserTypeTeamTypes_UPDATE]', 'P') IS NOT NULL DROP PROCEDURE [RSU].[spAutoGen_UserTypeTeamTypes_UPDATE];

    -- Record migration
    INSERT INTO [dbo].[SchemaVersion]
    ([MigrationName], [Description])
VALUES
    (@MigrationName, 'Drops all 99 auto-generated [RSU].[spAutoGen_*] stored procedures imported from a legacy database.');

    COMMIT TRANSACTION;
    PRINT 'Migration applied successfully: ' + @MigrationName;

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/*
ROLLBACK SCRIPT:
-- This migration drops procedures that were auto-generated from a legacy database.
-- To roll back, re-run the original source scripts for each procedure file under:
--   Procedures/RSU/spAutoGen_*.sql
-- Then remove the SchemaVersion record:
DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = '20260505_1900_DropAllAutoGenProcedures';
*/
