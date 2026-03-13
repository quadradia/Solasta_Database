/******************************************************************************
**		File: fxGroupMasterDealersTo2000.sql
**		Name: fxGroupMasterDealersTo2000
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
**		Date: 05/23/2020
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	05/23/2020	Andrés E. Sosa	Created By
**
*******************************************************************************/

DROP FUNCTION IF EXISTS [CNS].[fxGroupMasterDealersTo2000];
GO

CREATE FUNCTION [CNS].[fxGroupMasterDealersTo2000]
(
	@CurrentDealerID INT
)
RETURNS
@ReturnList TABLE
(
	DealerID INT NOT NULL
)
WITH SCHEMABINDING
AS
BEGIN
	/** LOCALS */
	DECLARE @RJHDealerID INT = 3042
		, @KLDealerID INT = 3050
		, @TargetDealerID INT = 2000;

	IF (@CurrentDealerID = @TargetDealerID OR @CurrentDealerID = @RJHDealerID OR @CurrentDealerID = @KLDealerID) BEGIN
		INSERT INTO @ReturnList ( DealerID ) VALUES ( @TargetDealerID ), ( @RJHDealerID ), ( @KLDealerID ), ( 0 );
	END ELSE BEGIN
		INSERT INTO @ReturnList ( DealerID ) VALUES ( @CurrentDealerID ), ( 0 );
	END;

	RETURN;
END
GO
