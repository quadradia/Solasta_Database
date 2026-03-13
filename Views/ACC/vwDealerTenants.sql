/******************************************************************************
**		File: vwDealerTenants.sql
**		Name: vwDealerTenants
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
**		Date: 01/28/2026
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-----------------------------------------------
**	01/28/2026	Andres Sosa		Created by
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwDealerTenants' AND schema_id = SCHEMA_ID('ACC'))
    DROP VIEW [ACC].[vwDealerTenants];
GO

CREATE VIEW [ACC].[vwDealerTenants]
AS
	-- Enter Query here
	SELECT
        DT.DealerTenantID AS ID
        , DTT.DealerTenantTypeName AS DealerTenantType
        , DT.DealerTenantName AS DealerTenantName
    FROM
        [ACC].[DealerTenants] AS DT WITH(NOLOCK)
        INNER JOIN [ACC].[DealerTenantTypes] AS DTT WITH(NOLOCK)
        ON
            (DT.DealerTenantTypeId = DTT.DealerTenantTypeId)
GO