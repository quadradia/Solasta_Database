/******************************************************************************
**		File: fxRemovePhoneDecorations.sql
**		Name: fxRemovePhoneDecorations
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
**		Date: 04/12/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	04/12/2017	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [UTL].[fxRemovePhoneDecorations];
GO

CREATE FUNCTION [UTL].[fxRemovePhoneDecorations](
	@PhoneNumber VARCHAR(20)
)
RETURNS VARCHAR(20)
AS
BEGIN
    /** Context User */
    DECLARE @UserID UNIQUEIDENTIFIER = CAST(CONTEXT_INFO() AS UNIQUEIDENTIFIER)
		, @UserGuidMasked VARCHAR(50);
    SET @UserGuidMasked = (SELECT 'XXXXXXX-XXXX-XXXX-XXXX-' + RIGHT(CAST(@UserID AS VARCHAR(50)), 12))

    /** INITIALIZE */
    DECLARE @Result VARCHAR(20);

    SET @Result = REPLACE(@PhoneNumber,'(','');
    SET @Result = REPLACE(@Result,')','');
    SET @Result = REPLACE(@Result,'-','');
    SET @Result = REPLACE(@Result,' ','');
    SET @Result = REPLACE(@Result,'x','');

    /** Return result */
    RETURN @Result;
END
GO
