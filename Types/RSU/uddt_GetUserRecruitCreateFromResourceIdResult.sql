/******************************************************************************
**      File: uddt_GetUserRecruitCreateFromResourceIdResult.sql
**      Name: uddt_GetUserRecruitCreateFromResourceIdResult
**      Desc: Represents the result set returned by RSU.spUserRecruitCreateFromResourceId.
**            Used to strongly type the full UserRecruit row returned after creation.
**
**      Typical Usage: Passed as READONLY parameter or used as a return-capture
**                     table variable when calling spUserRecruitCreateFromResourceId.
**
**      Columns:
**      -------
**      [Id]                        - UserRecruitID (PK identity from UserRecruits)
**      [UserResourceId]            - FK to UserResources
**      [UserTypeId]                - FK to UserTypes (smallint)
**      [ReportsToId]               - Optional reporting hierarchy FK
**      [UserRecruitAddressId]      - FK to UserRecruitAddresses
**      [DealerId]                  - FK to Dealers
**      [SeasonId]                  - FK to Seasons
**      [OwnerApprovalId]           - Optional owner approval reference
**      [TeamId]                    - Optional FK to Teams
**      [PayScaleId]                - Optional pay scale reference
**      [SchoolId]                  - Optional FK to Schools (smallint)
**      [ShackingUpId]              - Optional cohabitation FK
**      [UserRecruitCohabbitTypeId] - Optional cohabitation type FK
**      [AlternatePayScheduleId]    - Optional alternate pay schedule FK
**      [Location]                  - Location description
**      [OwnerApprovalDate]         - Timestamp of owner approval
**      [ManagerApprovalDate]       - Timestamp of manager approval
**      [EmergencyName]             - Emergency contact name
**      [EmergencyPhone]            - Emergency contact phone
**      [EmergencyRelationship]     - Emergency contact relationship
**      [IsRecruiter]               - Flag: recruit is also a recruiter
**      [PreviousSummer]            - Previous summer employment notes
**      [SignatureDate]             - Date contract was signed
**      [HireDate]                  - Date recruit was hired
**      [GPExemptions]              - GP tax exemptions count
**      [GPW4Allowances]            - GP W4 allowances (tinyint)
**      [GPW9Name]                  - GP W9 legal name
**      [GPW9BusinessName]          - GP W9 business name
**      [GPW9TIN]                   - GP W9 tax identification number
**      [SocialSecCardStatusID]     - Social security card status
**      [DriversLicenseStatusID]    - Driver's license status
**      [W4StatusID]                - W4 form status
**      [I9StatusID]                - I9 form status
**      [W9StatusID]                - W9 form status
**      [SocialSecCardNotes]        - Notes on SSN card
**      [DriversLicenseNotes]       - Notes on driver's license
**      [W4Notes]                   - Notes on W4
**      [I9Notes]                   - Notes on I9
**      [W9Notes]                   - Notes on W9
**      [EIN]                       - Employer Identification Number
**      [SUTA]                      - State Unemployment Tax Account
**      [WorkersComp]               - Workers compensation info
**      [FedFilingStatus]           - Federal filing status
**      [EICFilingStatus]           - Earned Income Credit filing status
**      [TaxWitholdingState]        - State abbreviation for withholding
**      [StateFilingStatus]         - State filing status
**      [GPDependents]              - Number of GP dependents
**      [CriminalOffense]           - Flag: criminal offense on record
**      [Offense]                   - Description of offense
**      [OffenseExplanation]        - Explanation of offense
**      [Rent]                      - Rent amount (money)
**      [Pet]                       - Pet deposit/fee (money)
**      [Utilities]                 - Utilities amount (money)
**      [Fuel]                      - Fuel amount (money)
**      [Furniture]                 - Furniture amount (money)
**      [CellPhoneCredit]           - Cell phone credit (money)
**      [GasCredit]                 - Gas credit (money)
**      [RentExempt]                - Flag: rent exempt
**      [IsServiceTech]             - Flag: is service technician
**      [StateId]                   - State abbreviation
**      [CountryId]                 - Country code
**      [StreetAddress]             - Street address line 1
**      [StreetAddress2]            - Street address line 2
**      [City]                      - City
**      [PostalCode]                - Postal/ZIP code
**      [CBxSocialSecCard]          - Checkbox: SSN card received
**      [CBxDriversLicense]         - Checkbox: license received
**      [CBxW4]                     - Checkbox: W4 received
**      [CBxI9]                     - Checkbox: I9 received
**      [CBxW9]                     - Checkbox: W9 received
**      [PersonalMultiple]          - Personal multiplier
**      [IsActive]                  - Soft active flag
**      [IsDeleted]                 - Soft delete flag
**      [CreatedById]               - Audit: created by user GUID
**      [CreatedDate]               - Audit: creation timestamp
**      [ModifiedById]              - Audit: last modified by user GUID
**      [ModifiedDate]              - Audit: last modification timestamp
**
**      Auth: Andres Sosa
**      Date: 2026-04-17
*******************************************************************************
**  Change History
*******************************************************************************
**  Date:        Author:          Description:
**  -----------  ---------------  -----------------------------------------------
**  2026-04-17   Andres Sosa      Created By
**
*******************************************************************************/

IF EXISTS (
    SELECT 1
FROM sys.table_types
WHERE name = N'uddt_GetUserRecruitCreateFromResourceIdResult'
    AND schema_id = SCHEMA_ID(N'RSU')
)
    DROP TYPE [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult];
GO

CREATE TYPE [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult] AS TABLE
(
    [Id] INT NOT NULL,
    [UserResourceId] INT NOT NULL,
    [UserTypeId] SMALLINT NOT NULL,
    [ReportsToId] INT NULL,
    [UserRecruitAddressId] INT NULL,
    [DealerId] INT NOT NULL,
    [SeasonId] INT NOT NULL,
    [OwnerApprovalId] INT NULL,
    [TeamId] INT NULL,
    [PayScaleId] INT NULL,
    [SchoolId] SMALLINT NULL,
    [ShackingUpId] INT NULL,
    [UserRecruitCohabbitTypeId] INT NULL,
    [AlternatePayScheduleId] INT NULL,
    [Location] NVARCHAR(50) NULL,
    [OwnerApprovalDate] DATETIMEOFFSET(7) NULL,
    [ManagerApprovalDate] DATETIMEOFFSET(7) NULL,
    [EmergencyName] NVARCHAR(50) NULL,
    [EmergencyPhone] VARCHAR(20) NULL,
    [EmergencyRelationship] NVARCHAR(50) NULL,
    [IsRecruiter] BIT NOT NULL,
    [PreviousSummer] NVARCHAR(200) NULL,
    [SignatureDate] DATETIMEOFFSET(7) NULL,
    [HireDate] DATETIMEOFFSET(7) NULL,
    [GPExemptions] INT NULL,
    [GPW4Allowances] TINYINT NULL,
    [GPW9Name] NVARCHAR(50) NULL,
    [GPW9BusinessName] NVARCHAR(100) NULL,
    [GPW9TIN] VARCHAR(50) NULL,
    [SocialSecCardStatusID] INT NOT NULL,
    [DriversLicenseStatusID] INT NOT NULL,
    [W4StatusID] INT NOT NULL,
    [I9StatusID] INT NOT NULL,
    [W9StatusID] INT NOT NULL,
    [SocialSecCardNotes] NVARCHAR(250) NULL,
    [DriversLicenseNotes] NVARCHAR(250) NULL,
    [W4Notes] NVARCHAR(250) NULL,
    [I9Notes] NVARCHAR(250) NULL,
    [W9Notes] NVARCHAR(250) NULL,
    [EIN] NVARCHAR(50) NULL,
    [SUTA] NVARCHAR(50) NULL,
    [WorkersComp] NVARCHAR(MAX) NULL,
    [FedFilingStatus] NVARCHAR(50) NULL,
    [EICFilingStatus] NVARCHAR(50) NULL,
    [TaxWitholdingState] NVARCHAR(5) NULL,
    [StateFilingStatus] NVARCHAR(50) NULL,
    [GPDependents] INT NULL,
    [CriminalOffense] BIT NULL,
    [Offense] NVARCHAR(MAX) NULL,
    [OffenseExplanation] NVARCHAR(MAX) NULL,
    [Rent] MONEY NULL,
    [Pet] MONEY NULL,
    [Utilities] MONEY NULL,
    [Fuel] MONEY NULL,
    [Furniture] MONEY NULL,
    [CellPhoneCredit] MONEY NULL,
    [GasCredit] MONEY NULL,
    [RentExempt] BIT NOT NULL,
    [IsServiceTech] BIT NOT NULL,
    [StateId] VARCHAR(4) NULL,
    [CountryId] NVARCHAR(10) NULL,
    [StreetAddress] NVARCHAR(50) NULL,
    [StreetAddress2] NVARCHAR(50) NULL,
    [City] NVARCHAR(50) NULL,
    [PostalCode] NVARCHAR(10) NULL,
    [CBxSocialSecCard] BIT NULL,
    [CBxDriversLicense] BIT NULL,
    [CBxW4] BIT NULL,
    [CBxI9] BIT NULL,
    [CBxW9] BIT NULL,
    [PersonalMultiple] INT NULL,
    [IsActive] BIT NOT NULL,
    [IsDeleted] BIT NOT NULL,
    [CreatedById] UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate] DATETIMEOFFSET(7) NOT NULL,
    [ModifiedById] UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate] DATETIMEOFFSET(7) NOT NULL,

    PRIMARY KEY ([Id])
);
GO

/*
================================================================================
USAGE EXAMPLE
================================================================================

-- Stored procedure accepting the type:
CREATE PROCEDURE [RSU].[spProcessUserRecruitResult]
    @Results [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM @Results;
END
GO

-- Caller pattern:
DECLARE @Result [RSU].[uddt_GetUserRecruitCreateFromResourceIdResult];

INSERT INTO @Result
EXEC [RSU].[spUserRecruitCreateFromResourceId]
    @UserResourceId = 1001,
    @SeasonId       = 5,
    @UserTypeId     = 3;

SELECT * FROM @Result;
================================================================================
*/
