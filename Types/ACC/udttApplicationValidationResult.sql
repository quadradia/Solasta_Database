/*******************************************************************************
 * Object Type: User-Defined Table Type
 * Schema: ACC
 * Name: udttApplicationValidationResult
 * Description: Carries application and entity validation results.
 * Typical Usage: Table-valued parameter or intermediate validation result.
 * Author: Database Team
 * Created: 2026-10-30
 ******************************************************************************/

IF TYPE_ID(N'ACC.udttApplicationValidationResult') IS NULL
BEGIN
    EXEC(N'
        CREATE TYPE [ACC].[udttApplicationValidationResult] AS TABLE
        (
            [ApplicationID] INT NOT NULL,
            [EntityTypeID] INT NULL,
            [Proxy] VARCHAR(100) NOT NULL,
            [ApplicationName] NVARCHAR(100) NOT NULL,
            [EntityTypeName] NVARCHAR(100) NULL,
            [Username] NVARCHAR(256) NOT NULL,
            [Email] NVARCHAR(MAX) NULL,
            [EntityID] BIGINT NOT NULL,
            [UserEntityTypeID] INT NOT NULL,
            [ValidationStatus] NVARCHAR(150) NOT NULL,
            PRIMARY KEY CLUSTERED ([ApplicationID] ASC, [EntityID] ASC)
                WITH (IGNORE_DUP_KEY = OFF)
        );
    ');
END;
GO
