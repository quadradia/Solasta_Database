/*
Migration: 20261123_1530_AddACE_Appointments
Author: Andres Sosa
Date: 2026-11-23
Description: Appointment scheduling. Staff book calendar appointments with leads, contacts (MSG.Conversations not yet
             linked to a lead) and customers, by type. New tables:
               ACE.AppointmentTypes  the tenant's kinds of appointment (On Site Visit, Phone Call, Post Installation
                                     On Site Review, ...): name, how it happens (Kind), default length, calendar color
               ACE.Appointments      one row per appointment: type, who it is with, start and end, status, the
                                     staff member assigned, where (address) or how (phone), notes and outcome.
                                     Appointments live only in Solasta for now; the External* columns are kept for a
                                     later one-way sync to Google or Outlook calendars.
             Seeds five types for every tenant. Proxy prefix: CEAP (appointment).
Dependencies:
  20261118_2215_CreateMSG_Messaging (MSG.Conversations)
Rollback:
  DROP TABLE [ACE].[Appointments];
  DROP TABLE [ACE].[AppointmentTypes];
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261123_1530_AddACE_Appointments';
Expected impact: two new tables, the second empty, the first seeded with five rows per tenant. No existing data changes.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MigrationName NVARCHAR(255) = N'20261123_1530_AddACE_Appointments';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MSG.Conversations', N'U') IS NULL OR OBJECT_ID(N'QAL.Leads', N'U') IS NULL OR OBJECT_ID(N'ACE.Customers', N'U') IS NULL
        THROW 50001, 'Appointments require QAL.Leads, ACE.Customers and MSG.Conversations (20261118_2215_CreateMSG_Messaging).', 1;

    ---------------------------------------------------------------------------
    -- ACE.AppointmentTypes
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- ACE.Appointments
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'ACE.Appointments', N'U') IS NULL
    BEGIN
        CREATE TABLE [ACE].[Appointments]
        (
            [AppointmentID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [AppointmentTypeId] [int] NOT NULL,
            [Proxy] [varchar](100) NOT NULL,
            [PartKey] [varchar](6) NOT NULL,
            -- Who it is with: a lead, a customer (which keeps its LeadId), a contact's conversation, or several of
            -- them for the same person. At least one is set.
            [LeadId] [bigint] NULL,
            [CustomerId] [bigint] NULL,
            [ConversationId] [bigint] NULL,
            [Title] [nvarchar](200) NOT NULL,
            [StartDate] [datetimeoffset](7) NOT NULL,
            [EndDate] [datetimeoffset](7) NOT NULL,
            -- Scheduled, Confirmed (the contact confirmed), then Completed, Canceled or NoShow.
            [Status] [varchar](15) NOT NULL CONSTRAINT [DF_Appointments_Status] DEFAULT ('Scheduled'),
            [StatusDate] [datetimeoffset](7) NULL,
            -- Why it was canceled or missed.
            [StatusReason] [nvarchar](500) NULL,
            -- ACC.Users.UserID of the staff member who goes or calls.
            [AssignedToUserId] [uniqueidentifier] NULL,
            -- Where (OnSite, Office) or how (Phone: E.164; Video: a meeting link) it happens.
            [Location] [nvarchar](400) NULL,
            [Phone] [varchar](20) NULL,
            [MeetingUrl] [nvarchar](500) NULL,
            [Notes] [nvarchar](4000) NULL,
            -- What happened, written when it is completed.
            [OutcomeNotes] [nvarchar](4000) NULL,
            -- Reserved for a one-way sync to an external calendar (Google, Microsoft); unused for now.
            [ExternalCalendarProvider] [varchar](20) NULL,
            [ExternalEventId] [nvarchar](255) NULL,
            [ExternalSyncedDate] [datetimeoffset](7) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Appointments_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Appointments_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Appointments_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Appointments_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Appointments_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Appointments_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Appointments_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Appointments] PRIMARY KEY CLUSTERED ([AppointmentID] ASC),
            CONSTRAINT [FK_Appointments_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Appointments_AppointmentTypes] FOREIGN KEY ([AppointmentTypeId]) REFERENCES [ACE].[AppointmentTypes] ([AppointmentTypeID]),
            CONSTRAINT [FK_Appointments_Leads] FOREIGN KEY ([LeadId]) REFERENCES [QAL].[Leads] ([LeadID]),
            CONSTRAINT [FK_Appointments_Customers] FOREIGN KEY ([CustomerId]) REFERENCES [ACE].[Customers] ([CustomerID]),
            CONSTRAINT [FK_Appointments_Conversations] FOREIGN KEY ([ConversationId]) REFERENCES [MSG].[Conversations] ([ConversationID]),
            CONSTRAINT [UQ_Appointments_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_Appointments_With] CHECK ([LeadId] IS NOT NULL OR [CustomerId] IS NOT NULL OR [ConversationId] IS NOT NULL),
            CONSTRAINT [CK_Appointments_Dates] CHECK ([EndDate] > [StartDate]),
            CONSTRAINT [CK_Appointments_Status] CHECK ([Status] IN ('Scheduled', 'Confirmed', 'Completed', 'Canceled', 'NoShow')),
            CONSTRAINT [CK_Appointments_Phone] CHECK ([Phone] IS NULL OR [Phone] LIKE '+[1-9]%'),
            CONSTRAINT [CK_Appointments_ExternalProvider] CHECK ([ExternalCalendarProvider] IS NULL OR [ExternalCalendarProvider] IN ('Google', 'Microsoft'))
        );
        PRINT 'Created [ACE].[Appointments]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.Appointments') AND [name] = N'IX_Appointments_Calendar')
        CREATE NONCLUSTERED INDEX [IX_Appointments_Calendar] ON [ACE].[Appointments] ([DealerTenantId], [StartDate])
            INCLUDE ([EndDate], [Status], [AssignedToUserId], [AppointmentTypeId]) WHERE [IsDeleted] = 0;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.Appointments') AND [name] = N'IX_Appointments_AssignedToUserId')
        CREATE NONCLUSTERED INDEX [IX_Appointments_AssignedToUserId] ON [ACE].[Appointments] ([AssignedToUserId], [StartDate])
            INCLUDE ([EndDate], [Status]) WHERE [AssignedToUserId] IS NOT NULL AND [IsDeleted] = 0;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.Appointments') AND [name] = N'IX_Appointments_LeadId')
        CREATE NONCLUSTERED INDEX [IX_Appointments_LeadId] ON [ACE].[Appointments] ([LeadId], [StartDate]) WHERE [LeadId] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.Appointments') AND [name] = N'IX_Appointments_CustomerId')
        CREATE NONCLUSTERED INDEX [IX_Appointments_CustomerId] ON [ACE].[Appointments] ([CustomerId], [StartDate]) WHERE [CustomerId] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'ACE.Appointments') AND [name] = N'IX_Appointments_ConversationId')
        CREATE NONCLUSTERED INDEX [IX_Appointments_ConversationId] ON [ACE].[Appointments] ([ConversationId], [StartDate]) WHERE [ConversationId] IS NOT NULL;

    ---------------------------------------------------------------------------
    -- Seeds: five types for every tenant (staff can rename, add or retire them)
    ---------------------------------------------------------------------------
    INSERT INTO [ACE].[AppointmentTypes] ([DealerTenantId], [Code], [Name], [Description], [Kind], [DefaultDurationMinutes], [Color], [SortOrder])
    SELECT T.[DealerTenantID], S.[Code], S.[Name], S.[Description], S.[Kind], S.[Minutes], S.[Color], S.[SortOrder]
    FROM [ACC].[DealerTenants] T
    CROSS JOIN (VALUES
        ('ONSITE', N'On Site Visit', N'Visit the property to measure and present a quote.', 'OnSite', 60, '#2563EB', 10),
        ('PHONE', N'Phone Call', N'A scheduled call with the contact.', 'Phone', 30, '#16A34A', 20),
        ('INSTALL', N'Installation', N'Install the lights.', 'OnSite', 240, '#EA580C', 30),
        ('POST_INSTALL_REVIEW', N'Post Installation On Site Review', N'Walk the finished installation with the customer.', 'OnSite', 45, '#9333EA', 40),
        ('SERVICE', N'Service Visit', N'Repair or adjust an existing installation.', 'OnSite', 60, '#DC2626', 50)
    ) AS S ([Code], [Name], [Description], [Kind], [Minutes], [Color], [SortOrder])
    WHERE T.[IsDeleted] = 0
      AND NOT EXISTS (SELECT 1 FROM [ACE].[AppointmentTypes] A WHERE A.[DealerTenantId] = T.[DealerTenantID] AND A.[Code] = S.[Code]);

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Appointment scheduling: ACE.AppointmentTypes (seeded per tenant) and ACE.Appointments',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
