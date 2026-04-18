/******************************************************************************
**		File: uddt_GetUserTypeGroupsByDealerIdResult.sql
**		Name: uddt_GetUserTypeGroupsByDealerIdResult
**		Desc: Represents the result set returned by spGetUserTypeGroupsByDealerId.
**            Each row describes a single UserTypeGroup record.
**
**		Typical Usage: Passed as a READONLY parameter to stored procedures
**                     that consume the output of spGetUserTypeGroupsByDealerId.
**
**		Columns:
**		-------
**		[Id]                - UserTypeGroupID (VARCHAR 20, primary key of the source table)
**		[UserTypeGroupName] - Display name of the user type group
**		[IsActive]          - Whether the record is active
**		[IsDeleted]         - Whether the record is soft-deleted
**		[ModifiedDate]      - Date/time the record was last modified (with timezone offset)
**		[ModifiedById]      - GUID of the user who last modified the record
**		[CreatedDate]       - Date/time the record was created (with timezone offset)
**		[CreatedById]       - GUID of the user who created the record
**
**		Auth: Andres Sosa
**		Date: 2026-04-17
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	2026-04-17	Andres Sosa		Created By
**
*******************************************************************************/

IF EXISTS (
    SELECT 1
FROM sys.table_types
WHERE name = N'uddt_GetUserTypeGroupsByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserTypeGroupsByDealerIdResult];
GO

CREATE TYPE [RSU].[uddt_GetUserTypeGroupsByDealerIdResult] AS TABLE
(
    [Id] VARCHAR(20) NOT NULL,
    [UserTypeGroupName] VARCHAR(50) NOT NULL,
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
Usage example:

-- Stored procedure that accepts this type:
CREATE PROCEDURE [RSU].[sp_ProcessUserTypeGroups]
    @Data [RSU].[uddt_GetUserTypeGroupsByDealerIdResult] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Id], [UserTypeGroupName], [IsActive], [IsDeleted] FROM @Data;
END
GO

-- Calling the procedure:
DECLARE @Results [RSU].[uddt_GetUserTypeGroupsByDealerIdResult];

INSERT INTO @Results ([Id], [UserTypeGroupName], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
VALUES (
    'GRP001',
    'Field Sales',
    1,
    0,
    SYSDATETIMEOFFSET(),
    'E6872B58-52B2-415C-A32B-45805F95A70A',
    SYSDATETIMEOFFSET(),
    'E6872B58-52B2-415C-A32B-45805F95A70A'
);

EXEC [RSU].[sp_ProcessUserTypeGroups] @Data = @Results;
*/
