/******************************************************************************
**		File: uddt_GetUserEmployeeTypesByDealerIdResult.sql
**		Name: uddt_GetUserEmployeeTypesByDealerIdResult
**		Desc: Represents the result set returned by spGetUserEmployeeTypesByDealerId.
**            Each row describes a single UserEmployeeType record.
**
**		Typical Usage: Passed as a READONLY parameter to stored procedures
**                     that consume the output of spGetUserEmployeeTypesByDealerId.
**
**		Columns:
**		-------
**		[Id]                   - UserEmployeeTypeID (VARCHAR 20, primary key of the source table)
**		[UserEmployeeTypeName] - Display name of the employee type
**		[IsActive]             - Whether the record is active
**		[IsDeleted]            - Whether the record is soft-deleted
**		[CreatedById]          - GUID of the user who created the record
**		[CreatedDate]          - Date/time the record was created (with timezone offset)
**		[ModifiedById]         - GUID of the user who last modified the record
**		[ModifiedDate]         - Date/time the record was last modified (with timezone offset)
**
**		Auth: Andres Sosa
**		Date: 2026-04-16
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	2026-04-16	Andres Sosa		Created By
**
*******************************************************************************/

IF EXISTS (
    SELECT 1 FROM sys.table_types
    WHERE name = N'uddt_GetUserEmployeeTypesByDealerIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult];
GO

CREATE TYPE [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult] AS TABLE
(
    [Id]                    VARCHAR(20)          NOT NULL,
    [UserEmployeeTypeName]  NVARCHAR(50)         NOT NULL,
    [IsActive]              BIT                  NOT NULL,
    [IsDeleted]             BIT                  NOT NULL,
    [CreatedById]           UNIQUEIDENTIFIER     NOT NULL,
    [CreatedDate]           DATETIMEOFFSET(7)    NOT NULL,
    [ModifiedById]          UNIQUEIDENTIFIER     NOT NULL,
    [ModifiedDate]          DATETIMEOFFSET(7)    NOT NULL,

    PRIMARY KEY ([Id])
);
GO

/*
Usage example:

-- Stored procedure that accepts this type:
CREATE PROCEDURE [RSU].[sp_ProcessUserEmployeeTypes]
    @Data [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [Id], [UserEmployeeTypeName], [IsActive], [IsDeleted] FROM @Data;
END
GO

-- Calling the procedure:
DECLARE @Results [RSU].[uddt_GetUserEmployeeTypesByDealerIdResult];

INSERT INTO @Results ([Id], [UserEmployeeTypeName], [IsActive], [IsDeleted], [CreatedById], [CreatedDate], [ModifiedById], [ModifiedDate])
VALUES (
    'EMP001',
    'Full Time',
    1,
    0,
    'E6872B58-52B2-415C-A32B-45805F95A70A',
    SYSDATETIMEOFFSET(),
    'E6872B58-52B2-415C-A32B-45805F95A70A',
    SYSDATETIMEOFFSET()
);

EXEC [RSU].[sp_ProcessUserEmployeeTypes] @Data = @Results;
*/
