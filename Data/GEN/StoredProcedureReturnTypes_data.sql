/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: GEN
 * Name: StoredProcedureReturnTypes_data
 * Description: Idempotent seed for GEN.StoredProcedureReturnTypes (30 rows), generated from dev
 *              SOL_MAIN on 2026-11-06 so new environments (production) get the same
 *              reference data. Merges on the primary key; never deletes rows.
 * Author: Andres Sosa
 * Created: 2026-11-06
 * Dependencies: GEN.StoredProcedureReturnTypes
 ******************************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET IDENTITY_INSERT [GEN].[StoredProcedureReturnTypes] ON;
MERGE INTO [GEN].[StoredProcedureReturnTypes] AS target
USING (VALUES
    (2, N'WAL', N'spWalletAccountUpdateBalance', N'int'),
    (3, N'GBD', N'spTransactionP2PStart', N'Transaction'),
    (4, N'RAT', N'spGetAssetsByType', N'AssetWithRateTypeTableType'),
    (5, N'RAT', N'spGetCurrentRate', N'CurrentRateTypeTableType'),
    (6, N'KYC', N'spFinishKycIndividual', N'FinishKycIndividualResultTableType'),
    (7, N'ACC', N'spValidateIdentityIdWithApplicationProxy', N'ApplicationValidationResultTableType'),
    (8, N'GBD', N'spTransactionSearch', N'TransactionSearchItemTableType'),
    (9, N'GBD', N'spTransactionSearchByProxy', N'TransactionSearchItemTableType'),
    (10, N'WAL', N'spGetRecentRecipientsByEntityProxy', N'RecentRecipientsResultTableType'),
    (11, N'GBD', N'spPaymentRequestsByContextUser', N'PaymentRequestTableType'),
    (12, N'RSU', N'spGetMetaDataJson', N'JsonOutputMethodTableType'),
    (14, N'RSU', N'spUserResourceNewDefaultPlusUser', N'UserResourceFullSearchDataSetView'),
    (15, N'RSU', N'spUserResourceSalesRepSummaryByMfaId', N'JsonOutputMethodTableType'),
    (16, N'RSU', N'spUserResourceSearchFull_JSON', N'JsonOutputMethodTableType'),
    (17, N'RSU', N'spUserResourceSearchFull', N'UserResourceFullSearchDataSetView'),
    (18, N'RSU', N'spUserResourceSearch', N'JsonOutputMethodTableType'),
    (19, N'RSU', N'spGetUserEmployeeTypesByDealerId', N'GetUserEmployeeTypesByDealerIdResultTableType'),
    (20, N'RSU', N'spGetUserTypeGroupsByDealerId', N'GetUserTypeGroupsByDealerIdResultTableType'),
    (21, N'RSU', N'spUserRecruitCreateFromResourceId', N'GetUserRecruitCreateFromResourceIdResultTableType'),
    (22, N'RSU', N'spUserResourceDelete_JSON', N'JsonOutputMethodTableType'),
    (23, N'RSU', N'spUserResourceAvatarSaveJson', N'JsonOutputMethodTableType'),
    (24, N'RSU', N'spUserResourceBySesonId', N'JsonOutputMethodTableType'),
    (25, N'RSU', N'spUserResourceFullGetByContextDealerJSON', N'JsonOutputMethodTableType'),
    (26, N'RSU', N'spUserResourceFullGetByGPEmployeeId', N'GetUserRecruitCreateFromResourceIdResultTableType'),
    (27, N'RSU', N'spUserResourceFullGetById', N'UserResource'),
    (28, N'RSU', N'spGetUserTypesByDealerId', N'GetUserTypesByDealerIdResultTableType'),
    (29, N'RSU', N'spGetUserTypeTeamTypesByDealerId', N'GetUserTypeTeamTypesByDealerIdResultTableType'),
    (30, N'RSU', N'spUserResourceAvatarGetJson', N'JsonOutputMethodTableType'),
    (31, N'RSU', N'spUserResourceDisableEnableToggle', N'JsonOutputMethodTableType'),
    (32, N'RSU', N'spUserResourceFullGetByContextDealer', N'GetUserRecruitCreateFromResourceIdResultTableType')
) AS source ([StoredProcedureReturnTypeID], [SchemaName], [SPROCName], [CSharpReturnType])
ON target.[StoredProcedureReturnTypeID] = source.[StoredProcedureReturnTypeID]
WHEN MATCHED THEN
    UPDATE SET
        target.[SchemaName] = source.[SchemaName],
        target.[SPROCName] = source.[SPROCName],
        target.[CSharpReturnType] = source.[CSharpReturnType]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([StoredProcedureReturnTypeID], [SchemaName], [SPROCName], [CSharpReturnType])
    VALUES (source.[StoredProcedureReturnTypeID], source.[SchemaName], source.[SPROCName], source.[CSharpReturnType]);
SET IDENTITY_INSERT [GEN].[StoredProcedureReturnTypes] OFF;

PRINT 'GEN.StoredProcedureReturnTypes seeded.';
GO