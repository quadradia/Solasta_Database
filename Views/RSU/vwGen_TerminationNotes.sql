/******************************************************************************
**		View: [RSU].[vwGen_TerminationNotes]
**		Desc: 
**		Auth: ANDRES E. SOSA
**		Date: 10/02/2015 (UTC)
*******************************************************************************/
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwGen_TerminationNotes' AND schema_id = SCHEMA_ID('RSU'))
    DROP VIEW [RSU].[vwGen_TerminationNotes];
GO

CREATE   VIEW [RSU].[vwGen_TerminationNotes]
AS
	-- QUERY VIEW
	SELECT
		[RSU].[TerminationNotes].[TerminationNoteID]
		, [RSU].[TerminationNotes].[TerminationId]
		, [RSU].[TerminationNotes].[NoteText]
		, [RSU].[TerminationNotes].[IsActive]
		, [RSU].[TerminationNotes].[CreatedById]
		, [RSU].[TerminationNotes].[CreatedDate]
		, [RSU].[TerminationNotes].[ModifiedById]
		, [RSU].[TerminationNotes].[ModifiedDate]
	FROM
		[RSU].[TerminationNotes]
		INNER JOIN (SELECT TOP 1 * FROM [GEN].fxGetAccessLevel('Read', 'RSU','TerminationNotes') AS ALIN WHERE (ALIN.ReadAccessId >= 1) ORDER BY ALIN.ReadAccessId DESC) AS AL
		ON
			((AL.ReadAccessId = 2))
			AND ([RSU].[TerminationNotes].IsDeleted = 'FALSE')

;
GO