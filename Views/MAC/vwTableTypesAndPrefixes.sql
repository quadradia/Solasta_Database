/******************************************************************************
**		File: vwTableTypesAndPrefixes.sql
**		Name: vwTableTypesAndPrefixes
**		Desc: Central Proxy-ID prefix registry view. Returns a unified row set of
**            all *Types tables that participate in the Proxy-ID pattern, exposing
**            each registered prefix alongside its type metadata.
**
**            This view is the lookup target for MAC.fxGetPrefixTypeIdFromProxy
**            when parsing an inbound proxy string back to its TypeId and TypeName.
**
**            MAINTENANCE: Every time a new Proxy-enabled entity type is created,
**            add a new UNION block here AND register the prefix in
**            .github/ProxyID-PrefixRegistry.md.
**
**		Return values: Id, Prefix, Name, Description, Schema, TableName, TypeName
**
**		Called by: MAC.fxGetPrefixTypeIdFromProxy
**
**		Parameters:
**		Input							Output
**     ----------					-----------
**      (none)                      Rowset of all registered prefixes
**
**		Auth: Andres E. Sosa
**		Date: 2026-05-05
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:				Description:
**	-----------	---------------		-------------------------------------------
**	2026-05-05	Andres E. Sosa		Created By
**
*******************************************************************************/

IF EXISTS (SELECT *
FROM sys.views
WHERE name = 'vwTableTypesAndPrefixes' AND schema_id = SCHEMA_ID('MAC'))
    DROP VIEW [MAC].[vwTableTypesAndPrefixes];
GO

CREATE VIEW [MAC].[vwTableTypesAndPrefixes]
AS
    -- =========================================================================
    -- ACC.DealerTenantTypes  (Prefix examples: MSTR, QUAD)
    -- Entity: DealerTenant
    -- =========================================================================
    SELECT
        [DealerTenantTypeID]          AS [Id]
        , [Prefix]
        , [DealerTenantTypeName]      AS [Name]
        , [DealerTenantTypeDescription] AS [Description]
        , 'ACC'                       AS [Schema]
        , 'DealerTenantTypes'         AS [TableName]
        , 'DealerTenant'              AS [TypeName]
    FROM
        [ACC].[DealerTenantTypes]
    WHERE
        (IsDeleted = 0)

    -- =========================================================================
    -- ADD NEW UNION BLOCKS BELOW as new Proxy-enabled entities are onboarded.
    -- Follow the checklist in .github/ProxyID-PrefixRegistry.md.
    -- =========================================================================
GO
