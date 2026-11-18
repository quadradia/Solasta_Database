/*******************************************************************************
 * Object Type: Schema
 * Schema: MSG
 * Name: MSG
 * Description: Messaging with leads and customers: SMS, MMS and email conversations, the outbound send
 *              queue, per-address opt-in and opt-out, and message templates. Replaces GoHighLevel
 *              Conversations (lead-to-quote phase 7).
 * Dependencies: none
 * Author: Andres Sosa
 * Created: 2026-11-18
 ******************************************************************************/
IF SCHEMA_ID(N'MSG') IS NULL
    EXEC (N'CREATE SCHEMA [MSG] AUTHORIZATION [dbo]');
GO
