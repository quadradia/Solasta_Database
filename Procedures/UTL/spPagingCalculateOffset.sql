DROP PROCEDURE IF EXISTS [UTL].[spPagingCalculateOffset];
GO

/******************************************************************************
**		File: spPagingCalculateOffset.sql
**		Name: spPagingCalculateOffset
**		Desc: 
**
**		This template can be customized:
**              
**		Return values:
** 
**		Called by:   
**              
**		Parameters:
**		Input							Output
**     ----------						-----------
**
**		Auth: AndrÃ©s Sosa
**		Date: 04/05/2018
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	04/05/2018	AndrÃ©s Sosa		Created By
**	
*******************************************************************************/
CREATE   Procedure [UTL].[spPagingCalculateOffset]
(
	@PageSize INT OUTPUT
	, @PageNumber INT OUTPUT
	, @OffsetValue INT OUTPUT
)
AS
BEGIN
	/** SET NO COUNTING */
	SET NOCOUNT ON

	/** INIT */
	IF (@PageSize IS NULL OR @PageSize = 0) BEGIN
		SET @PageSize = 1;
	END;
	IF (@PageNumber IS NULL OR @PageNumber = 0) BEGIN
		SET @PageNumber = 1;
	END;

	/** CALCULATE OFFSET */
	IF (@PageNumber > 1) BEGIN
		SET @OffsetValue = (@PageSize * (@PageNumber - 1));
	END
END

GO
