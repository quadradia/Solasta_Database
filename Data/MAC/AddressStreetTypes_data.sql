/*******************************************************************************
 * Object Type: Data (Seed)
 * Schema: MAC
 * Name: AddressStreetTypes_data
 * Description: Idempotent seed for MAC.AddressStreetTypes (44 rows), generated from dev
 *              SOL_MAIN on 2026-11-06 so new environments (production) get the same
 *              reference data. Merges on the primary key; never deletes rows.
 * Author: Andres Sosa
 * Created: 2026-11-06
 * Dependencies: MAC.AddressStreetTypes
 ******************************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET IDENTITY_INSERT [MAC].[AddressStreetTypes] ON;
MERGE INTO [MAC].[AddressStreetTypes] AS target
USING (VALUES
    (1, N'AL', N'AL - ALLEY', N'ALLEY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (2, N'AV', N'AV - AVENUE', N'AVENUE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (3, N'BV', N'BV - BOULEVARD', N'BOULEVARD', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (4, N'BD', N'BD - BUILDING', N'BUILDING', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (5, N'CN', N'CN - CENTER', N'CENTER', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (6, N'CI', N'CI - CIRCLE', N'CIRCLE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (7, N'CT', N'CT - COURT', N'COURT', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (8, N'CS', N'CS - CRESCENT', N'CRESCENT', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (9, N'DA', N'DA - DALE', N'DALE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (10, N'DR', N'DR - DRIVE', N'DRIVE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (11, N'EX', N'EX - EXPRESSWAY', N'EXPRESSWAY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (12, N'FY', N'FY - FREEWAY', N'FREEWAY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (13, N'GA', N'GA - GARDEN', N'GARDEN', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (14, N'GR', N'GR - GROVE', N'GROVE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (15, N'HT', N'HT - HEIGHTS', N'HEIGHTS', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (16, N'HY', N'HY - HIGHWAY', N'HIGHWAY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (17, N'HI', N'HI - HILL', N'HILL', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (18, N'KN', N'KN - KNOLL', N'KNOLL', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (19, N'LN', N'LN - LANE', N'LANE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (20, N'LP', N'LP - LOOP', N'LOOP', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (21, N'MA', N'MA - MALL', N'MALL', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (22, N'OV', N'OV - OVAL', N'OVAL', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (23, N'PK', N'PK - PARK', N'PARK', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (24, N'PY', N'PY - PARKWAY', N'PARKWAY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (25, N'PA', N'PA - PATH', N'PATH', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (26, N'PI', N'PI - PIKE', N'PIKE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (27, N'PL', N'PL - PLACE', N'PLACE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (28, N'PZ', N'PZ - PLAZA', N'PLAZA', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (29, N'PT', N'PT - POINT', N'POINT', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (30, N'RD', N'RD - ROAD', N'ROAD', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (31, N'RT', N'RT - ROUTE', N'ROUTE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (32, N'RO', N'RO - ROW', N'ROW', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (33, N'RN', N'RN - RUN', N'RUN', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (34, N'RR', N'RR - RURALROUTE', N'RURALROUTE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (35, N'SQ', N'SQ - SQUARE', N'SQUARE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (36, N'ST', N'ST - STREET', N'STREET', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (37, N'TC', N'TC - TERRACE', N'TERRACE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (38, N'TY', N'TY - THRUWAY', N'THRUWAY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (39, N'TR', N'TR - TRAIL', N'TRAIL', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (40, N'TP', N'TP - TURNPIKE', N'TURNPIKE', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (41, N'VI', N'VI - VIADUCT', N'VIADUCT', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (42, N'VW', N'VW- VIEW', N'VIEW', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (43, N'WK', N'WK - WALK', N'WALK', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a'),
    (44, N'WY', N'WY - WAY', N'WAY', 1, 0, '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a', '2017-02-04 23:58:02.7739282 -07:00', 'e6872b58-52b2-415c-a32b-45805f95a70a')
) AS source ([AddressStreetTypeID], [AddressStreetTypeCode], [AddressStreetTypeCombinedDescription], [AddressStreetTypeDescription], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
ON target.[AddressStreetTypeID] = source.[AddressStreetTypeID]
WHEN MATCHED THEN
    UPDATE SET
        target.[AddressStreetTypeCode] = source.[AddressStreetTypeCode],
        target.[AddressStreetTypeCombinedDescription] = source.[AddressStreetTypeCombinedDescription],
        target.[AddressStreetTypeDescription] = source.[AddressStreetTypeDescription],
        target.[IsActive] = source.[IsActive],
        target.[IsDeleted] = source.[IsDeleted],
        target.[ModifiedDate] = source.[ModifiedDate],
        target.[ModifiedById] = source.[ModifiedById]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([AddressStreetTypeID], [AddressStreetTypeCode], [AddressStreetTypeCombinedDescription], [AddressStreetTypeDescription], [IsActive], [IsDeleted], [ModifiedDate], [ModifiedById], [CreatedDate], [CreatedById])
    VALUES (source.[AddressStreetTypeID], source.[AddressStreetTypeCode], source.[AddressStreetTypeCombinedDescription], source.[AddressStreetTypeDescription], source.[IsActive], source.[IsDeleted], source.[ModifiedDate], source.[ModifiedById], source.[CreatedDate], source.[CreatedById]);
SET IDENTITY_INSERT [MAC].[AddressStreetTypes] OFF;

PRINT 'MAC.AddressStreetTypes seeded.';
GO