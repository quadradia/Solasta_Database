/*******************************************************************************
 * Object Type: Table
 * Schema: INE
 * Name: MovementTypes
 * Description: Kinds of stock movement and the rules INE.spMovementPost enforces for
 *              each: whether a from and/or to location is required, which location
 *              types they may be, and whether the movement needs a job (QAL.Leads).
 *              Seeded with fixed IDs; code reads them by Code.
 * Dependencies: none
 * Author: Andres Sosa
 * Created: 2026-11-17
 ******************************************************************************/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'INE.MovementTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [INE].[MovementTypes]
    (
        [MovementTypeID] [int] NOT NULL,
        -- Receive, Transfer, IssueToJob, ReturnFromJob, ReturnToVendor, AdjustIn, AdjustOut, Scrap, Reversal
        [Code] [varchar](20) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        -- 1 = stock leaves FromLocationId; 1 = stock arrives at ToLocationId.
        -- (Reversal has both 0: its ends mirror the movement it reverses.)
        [RequiresFrom] [bit] NOT NULL,
        [RequiresTo] [bit] NOT NULL,
        -- The location type required at each end (INE.LocationTypes.Code); NULL means any
        -- stock-holding location (Warehouse, Vehicle, Staging).
        [FromLocationTypeCode] [varchar](20) NULL,
        [ToLocationTypeCode] [varchar](20) NULL,
        [RequiresLead] [bit] NOT NULL CONSTRAINT [DF_MovementTypes_RequiresLead] DEFAULT ((0)),
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_MovementTypes_SortOrder] DEFAULT ((0)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_MovementTypes_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_MovementTypes_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MovementTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_MovementTypes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_MovementTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_MovementTypes] PRIMARY KEY CLUSTERED ([MovementTypeID] ASC),
        CONSTRAINT [UQ_MovementTypes_Code] UNIQUE ([Code])
    );
END;
GO
