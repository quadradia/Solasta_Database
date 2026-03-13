/******************************************************************************
**		File: fxGetDefaultGuidId.sql
**		Name: fxGetDefaultGuidId
**		Desc:
**
**		This template can be customized:
**
**		Return values: Table of IDs/Ints
**
**		Called by:
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**
**		Auth: Andrés E. Sosa
**		Date: 11/19/2016
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	11/19/2016	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxGetDefaultGuidId];
GO

CREATE FUNCTION [UTL].[fxGetDefaultGuidId]
(
	@Id UNIQUEIDENTIFIER
)
RETURNS UNIQUEIDENTIFIER
WITH SCHEMABINDING
AS
BEGIN
    /** Declarations */
    DECLARE @Result UNIQUEIDENTIFIER = @Id;

    /** Execute actions. */
    IF (@Id IS NULL OR @Id = '00000000-0000-0000-0000-000000000000') BEGIN
        SET @Result = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER);
    END

    RETURN @Result;
END
GO
