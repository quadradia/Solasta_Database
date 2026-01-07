/*
View: vw_ViewName
Description: Brief description of what this view provides
Author: Your Name
Date: YYYY-MM-DD
Dependencies: List any tables or views this view depends on
Example Usage:
    SELECT * FROM [dbo].[vw_ViewName] WHERE [Column] = 'value'
*/

-- Drop and recreate (or use CREATE OR ALTER in SQL Server 2016+)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ViewName')
    DROP VIEW [dbo].[vw_ViewName];
GO

CREATE VIEW [dbo].[vw_ViewName]
AS
    SELECT 
        t1.[Id],
        t1.[Name],
        t1.[Description],
        t1.[IsActive],
        t1.[CreatedDate],
        t2.[RelatedField],
        -- Add calculated columns or aggregations as needed
        CASE 
            WHEN t1.[IsActive] = 1 THEN 'Active'
            ELSE 'Inactive'
        END AS [Status]
    FROM [dbo].[TableName] t1
    LEFT JOIN [dbo].[RelatedTable] t2 ON t1.[RelatedId] = t2.[Id]
    WHERE t1.[IsActive] = 1;  -- Filter as needed
GO

-- Add extended property for documentation
EXEC sys.sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Brief description of what this view provides',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'vw_ViewName';
GO

/*
Notes:
- Views should be used for commonly accessed data combinations
- Consider indexing base tables for better view performance
- Avoid using views for complex aggregations that could be materialized
- Document any assumptions about data filtering or business logic
*/
