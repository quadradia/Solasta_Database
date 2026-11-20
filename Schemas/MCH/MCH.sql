/*******************************************************************************
 * Object Type: Schema
 * Schema: MCH
 * Name: MCH
 * Description: Merchant services: card and ACH processing through a payment gateway (Cybersource first).
 *              Gateway-neutral transaction requests and responses; the money itself lands in MAC.Payments.
 *              Never stores full card numbers, CVV, full bank account numbers or gateway credentials.
 * Dependencies: none
 * Author: Andres Sosa
 * Created: 2026-11-20
 ******************************************************************************/
IF SCHEMA_ID(N'MCH') IS NULL
    EXEC (N'CREATE SCHEMA [MCH] AUTHORIZATION [dbo]');
GO
