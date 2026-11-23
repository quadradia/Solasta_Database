/*******************************************************************************
 * Object Type: Table
 * Schema: ACE
 * Name: Appointments
 * Description: Calendar appointments with a lead, a customer or a contact (MSG.Conversations), by type, assigned
               to a staff member. Proxy prefix CEAP. Solasta-only for now; External* columns are kept for a later
               one-way sync to Google or Outlook.
 * Author: Andres Sosa
 * Created: 2026-11-23
 * Dependencies: ACC.DealerTenants, ACE.AppointmentTypes, QAL.Leads, ACE.Customers, MSG.Conversations
 * Migrations: 20261123_1530_AddACE_Appointments
 ******************************************************************************/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
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
GO
