/******************************************************************************
**		File: vwGenRandomAlpaNumericChar.sql
**		Name: vwGenRandomAlpaNumericChar
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
**     ----------						-----------
**
**		Auth: Andres Sosa
**		Date: 01/20/2017
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	01/20/2017	Andres Sosa		Created by
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGenRandomAlpaNumericChar' AND schema_id = SCHEMA_ID('UTL'))
    DROP VIEW [UTL].[vwGenRandomAlpaNumericChar];
GO

CREATE   VIEW [UTL].[vwGenRandomAlpaNumericChar]
AS
	-- Enter Query here
	SELECT 
		SUBSTRING(x,(ABS(CHECKSUM(NEWID()))%36)+1,1) AS RndChar
	FROM
		(select x=N'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ') a
GO