/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: AppointmentTypes
 * Description: The tenant's kinds of appointment (On Site Visit, Phone Call, Post Installation On Site Review, ...).
               Kind says how it happens (OnSite, Phone, Video, Office); staff rename, add or retire types.
 * Author: Andres Sosa
 * Created: 2026-11-23
 * Dependencies: ACC.DealerTenants
 * Migrations: 20261123_1530_AddACE_Appointments
 ******************************************************************************/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'ACE.AppointmentTypes', N'U') IS NULL
BEGIN
    CREATE TABLE [ACE].[AppointmentTypes]
    (
        [AppointmentTypeID] [int] IDENTITY(1,1) NOT NULL,
        [DealerTenantId] [int] NOT NULL,
        -- Stable code for automations (ONSITE, PHONE, POST_INSTALL_REVIEW); unique per tenant.
        [Code] [varchar](50) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        -- How the appointment happens: OnSite (at the contact's address), Phone, Video or Office.
        [Kind] [varchar](10) NOT NULL,
        [DefaultDurationMinutes] [int] NOT NULL,
        -- Calendar color, #RRGGBB.
        [Color] [varchar](7) NOT NULL,
        [SortOrder] [int] NOT NULL CONSTRAINT [DF_AppointmentTypes_SortOrder] DEFAULT ((0)),
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_AppointmentTypes_IsActive] DEFAULT ((1)),
        [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_AppointmentTypes_IsDeleted] DEFAULT ((0)),
        [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AppointmentTypes_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AppointmentTypes_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AppointmentTypes_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
        [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AppointmentTypes_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
        [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_AppointmentTypes_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT [PK_AppointmentTypes] PRIMARY KEY CLUSTERED ([AppointmentTypeID] ASC),
        CONSTRAINT [FK_AppointmentTypes_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
        CONSTRAINT [UQ_AppointmentTypes_Code] UNIQUE ([DealerTenantId], [Code]),
        CONSTRAINT [CK_AppointmentTypes_Kind] CHECK ([Kind] IN ('OnSite', 'Phone', 'Video', 'Office')),
        CONSTRAINT [CK_AppointmentTypes_Duration] CHECK ([DefaultDurationMinutes] BETWEEN 5 AND 1440),
        CONSTRAINT [CK_AppointmentTypes_Color] CHECK ([Color] LIKE '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')
    );
    PRINT 'Created [ACE].[AppointmentTypes]';
END;
GO
