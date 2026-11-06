/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: AccountTypes_data
 * Description: Idempotent seed for MAC.AccountTypes (4 rows), generated from dev
 *              SOL_MAIN on 2026-11-06 so new environments (production) get the same
 *              reference data. Merges on the primary key; never deletes rows.
 * Author: Andres Sosa
 * Created: 2026-11-06
 * Dependencies: MAC.AccountTypes
 ******************************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET IDENTITY_INSERT [MAC].[AccountTypes] ON;
MERGE INTO [MAC].[AccountTypes] AS target
USING (VALUES
    (1, N'Monitored Alarm Systems', N'MAS', N'A', N'MasAccounts', 1, 0, '2016-11-25 11:34:19.9023995 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2016-11-25 11:34:19.9023995 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (2, N'Camera System', N'CAS', N'C', N'CasAccounts', 1, 0, '2017-01-20 20:26:23.6491452 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-01-20 20:26:23.6491452 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (3, N'Home Automation System', N'HAU', N'H', N'HauAccounts', 1, 0, '2017-01-20 20:26:43.5747580 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-01-20 20:26:43.5747580 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (4, N'Home Warranty', N'HWY', N'W', N'HwyAccounts', 1, 0, '2017-09-22 10:55:45.3502093 -06:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-09-22 10:55:45.3502093 -06:00', 'e6872b58-52b2-415c-a32b-45805f95a70a')
) AS source ([AccountTypeID], [AccountTypeName], [SchemaName], [AccountNumberPrefix], [TableName], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
ON target.[AccountTypeID] = source.[AccountTypeID]
WHEN MATCHED THEN
    UPDATE SET
        target.[AccountTypeName] = source.[AccountTypeName],
        target.[SchemaName] = source.[SchemaName],
        target.[AccountNumberPrefix] = source.[AccountNumberPrefix],
        target.[TableName] = source.[TableName],
        target.[IsActive] = source.[IsActive],
        target.[IsDeleted] = source.[IsDeleted],
        target.[ModifiedDate] = source.[ModifiedDate],
        target.[ModifiedById] = source.[ModifiedById]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([AccountTypeID], [AccountTypeName], [SchemaName], [AccountNumberPrefix], [TableName], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
    VALUES (source.[AccountTypeID], source.[AccountTypeName], source.[SchemaName], source.[AccountNumberPrefix], source.[TableName], source.[IsActive], source.[IsDeleted], source.[ModifiedDate], source.[ModifiedById], source.[CreatedDate], source.[CreatedById]);
SET IDENTITY_INSERT [MAC].[AccountTypes] OFF;

PRINT 'MAC.AccountTypes seeded.';
GO