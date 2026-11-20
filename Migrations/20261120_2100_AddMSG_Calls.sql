/*
Migration: 20261120_2100_AddMSG_Calls
Author: Andres Sosa
Date: 2026-11-20
Description: Recorded click-to-call from the admin app. Staff press Call on a conversation; Twilio rings the staff
             member's phone first and then the contact (a "bridge" call), plays the contact a recording notice and
             records both sides. New table:
               MSG.Calls   one row per call: both phones, the Twilio number shown, Twilio's call ids, status and
                           duration, and the recording, copied from Twilio into DOC.Documents
             MSG.Conversations.LastMessageChannel may now be 'Call', so a call shows in the inbox like a message.
             Proxy prefix: MGCL (call).
Dependencies:
  20261118_2215_CreateMSG_Messaging
Rollback:
  DROP TABLE [MSG].[Calls];
  UPDATE [MSG].[Conversations] SET [LastMessageChannel] = NULL WHERE [LastMessageChannel] = 'Call';
  ALTER TABLE [MSG].[Conversations] DROP CONSTRAINT [CK_Conversations_LastMessageChannel];
  ALTER TABLE [MSG].[Conversations] ADD CONSTRAINT [CK_Conversations_LastMessageChannel]
      CHECK ([LastMessageChannel] IS NULL OR [LastMessageChannel] IN ('SMS', 'Email'));
  DELETE FROM [dbo].[SchemaVersion] WHERE [MigrationName] = N'20261120_2100_AddMSG_Calls';
Expected impact: one new, empty table and one widened check constraint. No existing data changes.
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
    DECLARE @MigrationName NVARCHAR(255) = N'20261120_2100_AddMSG_Calls';
    DECLARE @StartedAt DATETIME2 = SYSUTCDATETIME();

    IF EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [MigrationName] = @MigrationName AND [Success] = 1)
    BEGIN
        PRINT 'Migration already applied. Skipping...';
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF OBJECT_ID(N'MSG.Conversations', N'U') IS NULL OR OBJECT_ID(N'DOC.Documents', N'U') IS NULL
        THROW 50001, 'Calls require MSG.Conversations (20261118_2215_CreateMSG_Messaging) and DOC.Documents.', 1;

    ---------------------------------------------------------------------------
    -- MSG.Conversations: a call can be the latest activity
    ---------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Conversations_LastMessageChannel'
                 AND [parent_object_id] = OBJECT_ID(N'MSG.Conversations') AND [definition] NOT LIKE '%Call%')
        ALTER TABLE [MSG].[Conversations] DROP CONSTRAINT [CK_Conversations_LastMessageChannel];
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE [name] = N'CK_Conversations_LastMessageChannel'
                     AND [parent_object_id] = OBJECT_ID(N'MSG.Conversations'))
        ALTER TABLE [MSG].[Conversations] ADD CONSTRAINT [CK_Conversations_LastMessageChannel]
            CHECK ([LastMessageChannel] IS NULL OR [LastMessageChannel] IN ('SMS', 'Email', 'Call'));

    ---------------------------------------------------------------------------
    -- MSG.Calls
    ---------------------------------------------------------------------------
    IF OBJECT_ID(N'MSG.Calls', N'U') IS NULL
    BEGIN
        CREATE TABLE [MSG].[Calls]
        (
            [CallID] [bigint] IDENTITY(1,1) NOT NULL,
            [DealerTenantId] [int] NOT NULL,
            [ConversationId] [bigint] NOT NULL,
            -- The recording, copied from Twilio into DOC once the call ends.
            [RecordingDocumentId] [bigint] NULL,
            [Proxy] [varchar](100) NOT NULL,
            [PartKey] [varchar](6) NOT NULL,
            -- Outbound (staff called the contact). Inbound is reserved for calls to Solasta's number.
            [Direction] [varchar](10) NOT NULL,
            -- Initiated (asked Twilio), RingingStaff, RingingContact, InProgress, then Completed, NoAnswer, Busy,
            -- Failed or Canceled. ErrorMessage says which phone did not answer.
            [Status] [varchar](15) NOT NULL,
            -- ACC.Users.UserID of the staff member who placed the call.
            [StaffUserId] [uniqueidentifier] NOT NULL,
            -- Bridge calls ring the staff member's phone first, then the contact. All three are E.164.
            [StaffPhone] [varchar](20) NOT NULL,
            [ContactPhone] [varchar](20) NOT NULL,
            -- The Twilio number the contact sees.
            [CallerId] [varchar](20) NOT NULL,
            [Provider] [varchar](20) NOT NULL CONSTRAINT [DF_Calls_Provider] DEFAULT ('Twilio'),
            -- Twilio's id for the first leg (to the staff phone) and for the leg to the contact (CA...).
            [ProviderCallSid] [varchar](64) NULL,
            [ContactCallSid] [varchar](64) NULL,
            -- True when the call was set to be recorded (the contact hears a recording notice first).
            [IsRecorded] [bit] NOT NULL,
            -- Pending (Twilio has it, not yet copied), Stored (in DOC), Failed, or NULL (no recording).
            [RecordingStatus] [varchar](10) NULL,
            [RecordingSid] [varchar](64) NULL,
            [RecordingDurationSeconds] [int] NULL,
            [RecordingAttemptCount] [int] NOT NULL CONSTRAINT [DF_Calls_RecordingAttemptCount] DEFAULT ((0)),
            -- When the contact answered and when the call ended; DurationSeconds is the contact leg's talk time.
            [AnsweredDate] [datetimeoffset](7) NULL,
            [EndedDate] [datetimeoffset](7) NULL,
            [DurationSeconds] [int] NULL,
            [ErrorCode] [varchar](50) NULL,
            [ErrorMessage] [nvarchar](1000) NULL,
            -- Staff's notes about the call.
            [Notes] [nvarchar](2000) NULL,
            [IsActive] [bit] NOT NULL CONSTRAINT [DF_Calls_IsActive] DEFAULT ((1)),
            [IsDeleted] [bit] NOT NULL CONSTRAINT [DF_Calls_IsDeleted] DEFAULT ((0)),
            [ModifiedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Calls_ModifiedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [ModifiedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Calls_ModifiedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [CreatedDate] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Calls_CreatedDate] DEFAULT (SYSDATETIMEOFFSET()),
            [CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Calls_CreatedById] DEFAULT ('E6872B58-52B2-415C-A32B-45805F95A70A'),
            [DEX_ROW_TS] [datetimeoffset](7) NOT NULL CONSTRAINT [DF_Calls_DEX_ROW_TS] DEFAULT (SYSDATETIMEOFFSET()),
            CONSTRAINT [PK_Calls] PRIMARY KEY CLUSTERED ([CallID] ASC),
            CONSTRAINT [FK_Calls_DealerTenants] FOREIGN KEY ([DealerTenantId]) REFERENCES [ACC].[DealerTenants] ([DealerTenantID]),
            CONSTRAINT [FK_Calls_Conversations] FOREIGN KEY ([ConversationId]) REFERENCES [MSG].[Conversations] ([ConversationID]),
            CONSTRAINT [FK_Calls_Documents] FOREIGN KEY ([RecordingDocumentId]) REFERENCES [DOC].[Documents] ([DocumentID]),
            CONSTRAINT [UQ_Calls_Proxy] UNIQUE ([Proxy]),
            CONSTRAINT [CK_Calls_Direction] CHECK ([Direction] IN ('Outbound', 'Inbound')),
            CONSTRAINT [CK_Calls_Status] CHECK ([Status] IN ('Initiated', 'RingingStaff', 'RingingContact', 'InProgress', 'Completed', 'NoAnswer', 'Busy', 'Failed', 'Canceled')),
            CONSTRAINT [CK_Calls_Phones] CHECK ([StaffPhone] LIKE '+[1-9]%' AND [ContactPhone] LIKE '+[1-9]%' AND [CallerId] LIKE '+[1-9]%'),
            CONSTRAINT [CK_Calls_Provider] CHECK ([Provider] IN ('Twilio')),
            CONSTRAINT [CK_Calls_RecordingStatus] CHECK ([RecordingStatus] IS NULL OR [RecordingStatus] IN ('Pending', 'Stored', 'Failed')),
            CONSTRAINT [CK_Calls_RecordingStored] CHECK ([RecordingStatus] IS NULL OR [RecordingStatus] <> 'Stored' OR [RecordingDocumentId] IS NOT NULL),
            CONSTRAINT [CK_Calls_Counts] CHECK ([RecordingAttemptCount] >= 0 AND ([DurationSeconds] IS NULL OR [DurationSeconds] >= 0) AND ([RecordingDurationSeconds] IS NULL OR [RecordingDurationSeconds] >= 0))
        );
        PRINT 'Created [MSG].[Calls]';
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Calls') AND [name] = N'IX_Calls_ConversationId')
        CREATE NONCLUSTERED INDEX [IX_Calls_ConversationId] ON [MSG].[Calls] ([ConversationId], [CreatedDate]);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Calls') AND [name] = N'UX_Calls_ProviderCallSid')
        CREATE UNIQUE NONCLUSTERED INDEX [UX_Calls_ProviderCallSid] ON [MSG].[Calls] ([Provider], [ProviderCallSid]) WHERE [ProviderCallSid] IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [object_id] = OBJECT_ID(N'MSG.Calls') AND [name] = N'IX_Calls_RecordingPending')
        CREATE NONCLUSTERED INDEX [IX_Calls_RecordingPending] ON [MSG].[Calls] ([CallID]) INCLUDE ([DealerTenantId], [RecordingSid], [RecordingAttemptCount]) WHERE [RecordingStatus] = 'Pending';

    INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [ExecutionTimeMs], [Success])
    VALUES (@MigrationName, N'Recorded click-to-call: MSG.Calls, and Call as a conversation''s last channel',
            DATEDIFF(MILLISECOND, @StartedAt, SYSUTCDATETIME()), 1);

    COMMIT TRANSACTION;
    PRINT 'Migration ' + @MigrationName + ' applied successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
