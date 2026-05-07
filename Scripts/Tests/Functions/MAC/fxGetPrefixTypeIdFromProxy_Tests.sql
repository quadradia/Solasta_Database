/******************************************************************************
**		File: fxGetPrefixTypeIdFromProxy_Tests.sql
**		Name: Unit Tests — MAC.fxGetPrefixTypeIdFromProxy
**		Desc: Validates that the TVF correctly parses a Proxy-ID string and
**            resolves the Prefix, PartKey, GuidIdentifier, TypeId, TableName,
**            and TypeName for all registered prefixes, plus edge cases.
**
**		Test Cases:
**		  TC-01  MSTR prefix  → DealerTenantTypes, TypeId=1, TypeName=DealerTenant
**		  TC-02  QUAD prefix  → DealerTenantTypes, TypeId=2, TypeName=DealerTenant
**		  TC-03  AFST prefix  → AffiliateTypes,    TypeId=3, TypeName=Affiliate
**		  TC-04  AFIN prefix  → AffiliateTypes,    TypeId=1, TypeName=Affiliate
**		  TC-05  AFPR prefix  → AffiliateTypes,    TypeId=2, TypeName=Affiliate
**		  TC-06  Unknown prefix → parsed OK, lookup cols are NULL
**		  TC-07  Proxy string parsing — Prefix, PartKey, GuidIdentifier split
**
**		Dependencies:
**		  - MAC.fxGetPrefixTypeIdFromProxy
**		  - MAC.vwTableTypesAndPrefixes
**		  - ACC.DealerTenantTypes  (seeded: MSTR=1, QUAD=2)
**		  - AFL.AffiliateTypes     (seeded: AFST=1, AFIN=2, AFPR=3)
**
**		Usage:
**		  sqlcmd -S DESKTOP-GAHBRKG -U sa -d SOL_MAIN -b -i "Scripts\Tests\Functions\MAC\fxGetPrefixTypeIdFromProxy_Tests.sql"
**
**		Auth: Andres E. Sosa
**		Date: 2026-05-07
*******************************************************************************
**	Change History
*******************************************************************************
**	Date:		Author:			Description:
**	-----------	---------------	-------------------------------------------
**	2026-05-07	Andres E. Sosa	Created
*******************************************************************************/

SET NOCOUNT ON;
PRINT '============================================================';
PRINT 'Unit Tests: MAC.fxGetPrefixTypeIdFromProxy';
PRINT 'Run Date : ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================================';

-- ---------------------------------------------------------------------------
-- Accumulate test results
-- ---------------------------------------------------------------------------
CREATE TABLE #TestResults
(
    TestId INT NOT NULL,
    TestName VARCHAR(100) NOT NULL,
    Passed BIT NOT NULL,
    Expected VARCHAR(500) NULL,
    Actual VARCHAR(500) NULL,
    Notes VARCHAR(200) NULL
);

-- Reusable test-case GUID for deterministic parsing tests
DECLARE @TestGuid VARCHAR(36) = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';

-- ============================================================
-- TC-01  MSTR prefix → DealerTenantTypes, TypeId=1
-- ============================================================
BEGIN
    DECLARE @Proxy01 VARCHAR(100) = 'MSTR:3176D:' + @TestGuid;

    DECLARE @Prefix01        NVARCHAR(50);
    DECLARE @PartKey01       VARCHAR(6);
    DECLARE @GuidId01        VARCHAR(50);
    DECLARE @TypeId01        INT;
    DECLARE @TableName01     NVARCHAR(100);
    DECLARE @TypeName01      NVARCHAR(100);

    SELECT
        @Prefix01    = [Prefix],
        @PartKey01   = [PartKey],
        @GuidId01    = [GuidIdentifier],
        @TypeId01    = [TypeId],
        @TableName01 = [TableName],
        @TypeName01  = [TypeName]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy01);

    DECLARE @Pass01 BIT = CASE
        WHEN @Prefix01    = 'MSTR'
        AND @PartKey01   = '3176D'
        AND @GuidId01    = @TestGuid
        AND @TypeId01    = 1
        AND @TableName01 = 'DealerTenantTypes'
        AND @TypeName01  = 'DealerTenant'
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            1, 'TC-01: MSTR prefix resolves to DealerTenantTypes TypeId=1',
            @Pass01,
            'Prefix=MSTR|PartKey=3176D|GuidIdentifier=' + @TestGuid + '|TypeId=1|TableName=DealerTenantTypes|TypeName=DealerTenant',
            'Prefix=' + ISNULL(@Prefix01,'NULL')
            + '|PartKey=' + ISNULL(@PartKey01,'NULL')
            + '|GuidIdentifier=' + ISNULL(@GuidId01,'NULL')
            + '|TypeId=' + ISNULL(CAST(@TypeId01 AS VARCHAR),'NULL')
            + '|TableName=' + ISNULL(@TableName01,'NULL')
            + '|TypeName=' + ISNULL(@TypeName01,'NULL'),
            NULL
    );
END;

-- ============================================================
-- TC-02  QUAD prefix → DealerTenantTypes, TypeId=2
-- ============================================================
BEGIN
    DECLARE @Proxy02 VARCHAR(100) = 'QUAD:3176D:' + @TestGuid;

    DECLARE @Prefix02    NVARCHAR(50);
    DECLARE @TypeId02    INT;
    DECLARE @TableName02 NVARCHAR(100);
    DECLARE @TypeName02  NVARCHAR(100);

    SELECT
        @Prefix02    = [Prefix],
        @TypeId02    = [TypeId],
        @TableName02 = [TableName],
        @TypeName02  = [TypeName]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy02);

    DECLARE @Pass02 BIT = CASE
        WHEN @Prefix02    = 'QUAD'
        AND @TypeId02    = 2
        AND @TableName02 = 'DealerTenantTypes'
        AND @TypeName02  = 'DealerTenant'
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            2, 'TC-02: QUAD prefix resolves to DealerTenantTypes TypeId=2',
            @Pass02,
            'Prefix=QUAD|TypeId=2|TableName=DealerTenantTypes|TypeName=DealerTenant',
            'Prefix=' + ISNULL(@Prefix02,'NULL')
            + '|TypeId=' + ISNULL(CAST(@TypeId02 AS VARCHAR),'NULL')
            + '|TableName=' + ISNULL(@TableName02,'NULL')
            + '|TypeName=' + ISNULL(@TypeName02,'NULL'),
            NULL
    );
END;

-- ============================================================
-- TC-03  AFST prefix → AffiliateTypes, TypeId=1
-- ============================================================
BEGIN
    DECLARE @Proxy03 VARCHAR(100) = 'AFST:3176D:' + @TestGuid;

    DECLARE @Prefix03    NVARCHAR(50);
    DECLARE @TypeId03    INT;
    DECLARE @TableName03 NVARCHAR(100);
    DECLARE @TypeName03  NVARCHAR(100);

    SELECT
        @Prefix03    = [Prefix],
        @TypeId03    = [TypeId],
        @TableName03 = [TableName],
        @TypeName03  = [TypeName]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy03);

    DECLARE @Pass03 BIT = CASE
        WHEN @Prefix03    = 'AFST'
        AND @TypeId03    = 3
        AND @TableName03 = 'AffiliateTypes'
        AND @TypeName03  = 'Affiliate'
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            3, 'TC-03: AFST prefix resolves to AffiliateTypes TypeId=1',
            @Pass03,
            'Prefix=AFST|TypeId=1|TableName=AffiliateTypes|TypeName=Affiliate',
            'Prefix=' + ISNULL(@Prefix03,'NULL')
            + '|TypeId=' + ISNULL(CAST(@TypeId03 AS VARCHAR),'NULL')
            + '|TableName=' + ISNULL(@TableName03,'NULL')
            + '|TypeName=' + ISNULL(@TypeName03,'NULL'),
            NULL
    );
END;

-- ============================================================
-- TC-04  AFIN prefix → AffiliateTypes, TypeId=2
-- ============================================================
BEGIN
    DECLARE @Proxy04 VARCHAR(100) = 'AFIN:3176D:' + @TestGuid;

    DECLARE @Prefix04    NVARCHAR(50);
    DECLARE @TypeId04    INT;
    DECLARE @TableName04 NVARCHAR(100);
    DECLARE @TypeName04  NVARCHAR(100);

    SELECT
        @Prefix04    = [Prefix],
        @TypeId04    = [TypeId],
        @TableName04 = [TableName],
        @TypeName04  = [TypeName]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy04);

    DECLARE @Pass04 BIT = CASE
        WHEN @Prefix04    = 'AFIN'
        AND @TypeId04    = 1
        AND @TableName04 = 'AffiliateTypes'
        AND @TypeName04  = 'Affiliate'
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            4, 'TC-04: AFIN prefix resolves to AffiliateTypes TypeId=2',
            @Pass04,
            'Prefix=AFIN|TypeId=2|TableName=AffiliateTypes|TypeName=Affiliate',
            'Prefix=' + ISNULL(@Prefix04,'NULL')
            + '|TypeId=' + ISNULL(CAST(@TypeId04 AS VARCHAR),'NULL')
            + '|TableName=' + ISNULL(@TableName04,'NULL')
            + '|TypeName=' + ISNULL(@TypeName04,'NULL'),
            NULL
    );
END;

-- ============================================================
-- TC-05  AFPR prefix → AffiliateTypes, TypeId=3
-- ============================================================
BEGIN
    DECLARE @Proxy05 VARCHAR(100) = 'AFPR:3176D:' + @TestGuid;

    DECLARE @Prefix05    NVARCHAR(50);
    DECLARE @TypeId05    INT;
    DECLARE @TableName05 NVARCHAR(100);
    DECLARE @TypeName05  NVARCHAR(100);

    SELECT
        @Prefix05    = [Prefix],
        @TypeId05    = [TypeId],
        @TableName05 = [TableName],
        @TypeName05  = [TypeName]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy05);

    DECLARE @Pass05 BIT = CASE
        WHEN @Prefix05    = 'AFPR'
        AND @TypeId05    = 2
        AND @TableName05 = 'AffiliateTypes'
        AND @TypeName05  = 'Affiliate'
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            5, 'TC-05: AFPR prefix resolves to AffiliateTypes TypeId=3',
            @Pass05,
            'Prefix=AFPR|TypeId=3|TableName=AffiliateTypes|TypeName=Affiliate',
            'Prefix=' + ISNULL(@Prefix05,'NULL')
            + '|TypeId=' + ISNULL(CAST(@TypeId05 AS VARCHAR),'NULL')
            + '|TableName=' + ISNULL(@TableName05,'NULL')
            + '|TypeName=' + ISNULL(@TypeName05,'NULL'),
            NULL
    );
END;

-- ============================================================
-- TC-06  Unknown prefix → Prefix parsed, lookups return NULL
-- ============================================================
BEGIN
    DECLARE @Proxy06 VARCHAR(100) = 'ZZZZ:3176D:' + @TestGuid;

    DECLARE @Prefix06    NVARCHAR(50);
    DECLARE @PartKey06   VARCHAR(6);
    DECLARE @GuidId06    VARCHAR(50);
    DECLARE @TypeId06    INT;
    DECLARE @TableName06 NVARCHAR(100);
    DECLARE @TypeName06  NVARCHAR(100);

    SELECT
        @Prefix06    = [Prefix],
        @PartKey06   = [PartKey],
        @GuidId06    = [GuidIdentifier],
        @TypeId06    = [TypeId],
        @TableName06 = [TableName],
        @TypeName06  = [TypeName]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy06);

    -- Parsing must succeed; lookup columns must be NULL for an unregistered prefix
    DECLARE @Pass06 BIT = CASE
        WHEN @Prefix06  = 'ZZZZ'
        AND @PartKey06 = '3176D'
        AND @GuidId06  = @TestGuid
        AND @TypeId06    IS NULL
        AND @TableName06 IS NULL
        AND @TypeName06  IS NULL
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            6, 'TC-06: Unknown prefix — parsing OK, lookup columns are NULL',
            @Pass06,
            'Prefix=ZZZZ|PartKey=3176D|GuidIdentifier=' + @TestGuid + '|TypeId=NULL|TableName=NULL|TypeName=NULL',
            'Prefix=' + ISNULL(@Prefix06,'NULL')
            + '|PartKey=' + ISNULL(@PartKey06,'NULL')
            + '|GuidIdentifier=' + ISNULL(@GuidId06,'NULL')
            + '|TypeId=' + ISNULL(CAST(@TypeId06 AS VARCHAR),'NULL')
            + '|TableName=' + ISNULL(@TableName06,'NULL')
            + '|TypeName=' + ISNULL(@TypeName06,'NULL'),
            'Prefix not in vwTableTypesAndPrefixes'
    );
END;

-- ============================================================
-- TC-07  String parsing — all three segments extracted correctly
--        Uses a real-world proxy from function documentation.
-- ============================================================
BEGIN
    DECLARE @Proxy07 VARCHAR(100) = 'MSTR:316BD:E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8';

    DECLARE @Prefix07  NVARCHAR(50);
    DECLARE @PartKey07 VARCHAR(6);
    DECLARE @GuidId07  VARCHAR(50);

    SELECT
        @Prefix07  = [Prefix],
        @PartKey07 = [PartKey],
        @GuidId07  = [GuidIdentifier]
    FROM [MAC].[fxGetPrefixTypeIdFromProxy](@Proxy07);

    DECLARE @Pass07 BIT = CASE
        WHEN @Prefix07  = 'MSTR'
        AND @PartKey07 = '316BD'
        AND @GuidId07  = 'E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8'
        THEN 1 ELSE 0
    END;

    INSERT INTO #TestResults
    VALUES
        (
            7, 'TC-07: Proxy string parsing — Prefix, PartKey, GuidIdentifier split correctly',
            @Pass07,
            'Prefix=MSTR|PartKey=316BD|GuidIdentifier=E2CDF52E-D5CA-468D-A2F4-D8892DAC0EB8',
            'Prefix=' + ISNULL(@Prefix07,'NULL')
            + '|PartKey=' + ISNULL(@PartKey07,'NULL')
            + '|GuidIdentifier=' + ISNULL(@GuidId07,'NULL'),
            'Uses documented example from function header'
    );
END;

-- ============================================================
-- Results
-- ============================================================
PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'TEST RESULTS';
PRINT '------------------------------------------------------------';

SELECT
    TestId                                              AS [#],
    TestName                                            AS [Test],
    CASE Passed WHEN 1 THEN 'PASS' ELSE 'FAIL' END     AS [Status],
    CASE Passed WHEN 0 THEN Expected  ELSE NULL END     AS [Expected  (on fail)],
    CASE Passed WHEN 0 THEN Actual    ELSE NULL END     AS [Actual    (on fail)],
    Notes                                               AS [Notes]
FROM #TestResults
ORDER BY TestId;

DECLARE @TotalTests INT  = (SELECT COUNT(*)
FROM #TestResults);
DECLARE @Passed     INT  = (SELECT COUNT(*)
FROM #TestResults
WHERE Passed = 1);
DECLARE @Failed     INT  = (SELECT COUNT(*)
FROM #TestResults
WHERE Passed = 0);

PRINT '';
PRINT 'Summary: ' + CAST(@Passed AS VARCHAR) + '/' + CAST(@TotalTests AS VARCHAR) + ' passed'
    + CASE @Failed WHEN 0 THEN ' — ALL TESTS PASSED' ELSE ' — ' + CAST(@Failed AS VARCHAR) + ' FAILED' END;
PRINT '============================================================';

DROP TABLE #TestResults;
