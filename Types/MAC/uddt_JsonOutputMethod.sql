/******************************************************************************
**		File: uddt_JsonOutputMethod.sql
**		Name: uddt_JsonOutputMethod
**		Desc: A single-column table type that holds a JSON output string.
**
**		Typical Usage: Passed as a READONLY parameter to stored procedures
**                     that consume or process JSON output payloads.
**
**		Columns:
**		-------
**		[JsonOutPutMethod] - The raw JSON output string (NVARCHAR MAX, nullable)
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
    SELECT 1
FROM sys.table_types
WHERE name = N'uddt_JsonOutputMethod'
    AND schema_id = SCHEMA_ID(N'MAC')
)
    DROP TYPE [MAC].[uddt_JsonOutputMethod];
GO

CREATE TYPE [MAC].[uddt_JsonOutputMethod] AS TABLE
(
    [JsonOutPutMethod] NVARCHAR(MAX) NULL
);
GO

/*
Usage example:

-- Stored procedure that accepts this type:
CREATE PROCEDURE [MAC].[sp_ProcessJsonOutput]
    @Data [MAC].[uddt_JsonOutputMethod] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [JsonOutPutMethod] FROM @Data;
END
GO

-- Calling the procedure:
DECLARE @Output [MAC].[uddt_JsonOutputMethod];

INSERT INTO @Output ([JsonOutPutMethod])
VALUES (N'{"key":"value"}');

EXEC [MAC].[sp_ProcessJsonOutput] @Data = @Output;
*/
