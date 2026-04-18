/******************************************************************************
**      File: uddt_GetUserTypeTeamTypesByDealerIdResult.sql
**      Name: uddt_GetUserTypeTeamTypesByDealerIdResult
**      Desc: Represents the result set returned by RSU.spGetUserTypeTeamTypesByDealerId.
**            Used to strongly type the list of UserTypeTeamType rows returned for a dealer.
**
**      Typical Usage: Used as a return-capture table variable when calling
**                     spGetUserTypeTeamTypesByDealerId to hold the result rows.
**
**      Columns:
**      -------
**      [Id]                   - UserTypeTeamTypeID (PK identity from UserTypeTeamTypes)
**      [UserTypeTeamTypeName] - Display name of the team type
**      [ParentId]             - Optional self-referencing parent FK
**      [IsActive]             - Soft active flag
**      [IsDeleted]            - Soft delete flag
**      [CreatedById]          - Audit: created by user GUID
**      [CreatedDate]          - Audit: creation timestamp
**      [ModifiedById]         - Audit: last modified by user GUID
**      [ModifiedDate]         - Audit: last modification timestamp
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
WHERE name = N'uddt_GetUserTypeTeamTypesByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult];
GO

CREATE TYPE [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult] AS TABLE
(
    [Id] INT NOT NULL,
    [UserTypeTeamTypeName] VARCHAR(30) NOT NULL,
    [ParentId] INT NULL,
    [IsActive] BIT NOT NULL,
    [IsDeleted] BIT NOT NULL,
    [CreatedById] UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate] DATETIMEOFFSET(7) NOT NULL,
    [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate] DATETIMEOFFSET(7) NOT NULL,

    PRIMARY KEY ([Id])
);
GO

/*
================================================================================
USAGE EXAMPLE
================================================================================

-- Stored procedure accepting the type:
CREATE PROCEDURE [RSU].[spProcessUserTypeTeamTypes]
    @Results [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM @Results;
END
GO

-- Caller pattern:
DECLARE @Result [RSU].[uddt_GetUserTypeTeamTypesByDealerIdResult];

INSERT INTO @Result
EXEC [RSU].[spGetUserTypeTeamTypesByDealerId]
    @DealerId = 101;

SELECT * FROM @Result;
================================================================================
*/
