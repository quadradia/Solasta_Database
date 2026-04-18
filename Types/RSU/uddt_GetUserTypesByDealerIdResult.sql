/******************************************************************************
**      File: uddt_GetUserTypesByDealerIdResult.sql
**      Name: uddt_GetUserTypesByDealerIdResult
**      Desc: Represents the result set returned by RSU.spGetUserTypesByDealerId.
**            Used to strongly type the list of UserType rows returned for a dealer.
**
**      Typical Usage: Used as a return-capture table variable when calling
**                     spGetUserTypesByDealerId to hold the filtered UserType rows.
**
**      Columns:
**      -------
**      [Id]                - UserTypeID (PK, smallint identity from UserTypes)
**      [UserTypeTeamTypeId]- FK to UserTypeTeamTypes
**      [UserTypeGroupId]   - FK to UserTypeGroups (varchar)
**      [UserTypeName]      - Display name of the user type
**      [SecurityLevel]     - Security level (tinyint)
**      [SpawnTypeID]       - FK to spawn type
**      [RoleLocationID]    - FK to role location
**      [ReportingLevel]    - Reporting hierarchy level
**      [IsCommissionable]  - Flag: type earns commission
**      [IsActive]          - Soft active flag
**      [IsDeleted]         - Soft delete flag
**      [ModifiedDate]      - Audit: last modification timestamp
**      [ModifiedById]      - Audit: last modified by user GUID
**      [CreatedDate]       - Audit: creation timestamp
**      [CreatedById]       - Audit: created by user GUID
**
**      Auth: Andres Sosa
**      Date: 2026-04-17
*******************************************************************************
**  Change History
*******************************************************************************
**  Date:        Author:          Description:
**  -----------  ---------------  -----------------------------------------------
**  2026-04-17   Andres Sosa      Created By
**
*******************************************************************************/

IF EXISTS (
    SELECT 1
FROM sys.table_types
WHERE name = N'uddt_GetUserTypesByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserTypesByDealerIdResult];
GO

CREATE TYPE [RSU].[uddt_GetUserTypesByDealerIdResult] AS TABLE
(
    [Id] SMALLINT NOT NULL,
    [UserTypeTeamTypeId] INT NOT NULL,
    [UserTypeGroupId] VARCHAR(20) NOT NULL,
    [UserTypeName] VARCHAR(30) NOT NULL,
    [SecurityLevel] TINYINT NOT NULL,
    [SpawnTypeID] INT NOT NULL,
    [RoleLocationID] INT NOT NULL,
    [ReportingLevel] INT NOT NULL,
    [IsCommissionable] BIT NULL,
    [IsActive] BIT NOT NULL,
    [IsDeleted] BIT NOT NULL,
    [ModifiedDate] DATETIMEOFFSET(7) NOT NULL,
    [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate] DATETIMEOFFSET(7) NOT NULL,
    [CreatedById] UNIQUEIDENTIFIER NOT NULL,

    PRIMARY KEY ([Id])
);
GO

/*
================================================================================
USAGE EXAMPLE
================================================================================

-- Stored procedure accepting the type:
CREATE PROCEDURE [RSU].[spProcessUserTypes]
    @Results [RSU].[uddt_GetUserTypesByDealerIdResult] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM @Results;
END
GO

-- Caller pattern:
DECLARE @Result [RSU].[uddt_GetUserTypesByDealerIdResult];

INSERT INTO @Result
EXEC [RSU].[spGetUserTypesByDealerId]
    @DealerId = 101;

SELECT * FROM @Result;
================================================================================
*/
