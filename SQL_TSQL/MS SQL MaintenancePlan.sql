USE [TEST_DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_MyMaintenancePlan]    Script Date: 11/18/2011 09:55:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-----------------------------------------------------------------------------------------------------
-- SP_MyMaintenancePlan                                                                            --
-- Created By: Erickson Figueroa                                                                   --
-- Date: 11/18/2011                                                                                 --
-- Description: Stored procedure for database maintenance plan                                      --
------------------------------------------------------------------------------------------------------

ALTER PROCEDURE [dbo].[SP_MyMaintenancePlan]
AS
BEGIN
    SET NOCOUNT ON

    -------------------------------------------------------------------------------------------------------
    -- Variables to hold the database name                                                               --
    ------------------------------------------------------------------------------------------------------
    DECLARE @DB1 NVARCHAR(MAX);
    DECLARE @MSGLG NVARCHAR(MAX);

    -- Set the database name
    SET @DB1 = 'PRACTICA_4';

    -----------------------------------------------------------------------------------------------------
    -- Verify that the database exists                                                                 --
    ----------------------------------------------------------------------------------------------------

    -- Wait for a short period
    WAITFOR DELAY '00:00:05';

    ------------------------------------------------------------------------------------------------------
    -- Start checks and reorganizations                                                                 --
    ------------------------------------------------------------------------------------------------------

    -- Check database integrity and potential errors for repair
    DBCC CHECKDB(N'PRACTICA_4')
    WITH
        PHYSICAL_ONLY;

    -- Wait for a short period
    WAITFOR DELAY '00:00:05';

    ------------------------------------------------------------------------------------------------------
    -- Reorganize and rebuild indexes for tables                                                        --
    ------------------------------------------------------------------------------------------------------
    DECLARE @MODE BIT;
    SET @MODE = 2; -- Set to 1 for REORGANIZE, 2 for REBUILD
    DECLARE @VAR_IDX VARCHAR(500); -- Variable to hold index alteration statements

    -- Main cursor for index operations
    DECLARE CMAIN CURSOR FOR
    SELECT
        'ALTER INDEX ' + A.NAME + ' ON ' + C.NAME + '.' + B.NAME + ' ' +
        (CASE @MODE
            WHEN 1 THEN 'REORGANIZE'
            WHEN 2 THEN 'REBUILD'
        END) AS STMT
    FROM SYS.INDEXES A
    JOIN SYS.TABLES B ON A.OBJECT_ID = B.OBJECT_ID
    JOIN SYS.SCHEMAS C ON B.SCHEMA_ID = C.SCHEMA_ID
    WHERE A.NAME IS NOT NULL;

    OPEN CMAIN;
    FETCH NEXT FROM CMAIN INTO @VAR_IDX;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT (@VAR_IDX); -- Print the statement (for debugging)
        EXEC (@VAR_IDX);
        FETCH NEXT FROM CMAIN INTO @VAR_IDX;
    END;

    CLOSE CMAIN;
    DEALLOCATE CMAIN;
    SET NOCOUNT ON;

    -- Wait for a short period
    WAITFOR DELAY '00:00:05';

    ------------------------------------------------------------------------------------------------------
    -- Update statistics                                                                                --
    ------------------------------------------------------------------------------------------------------

    DECLARE @SQL VARCHAR(MAX); -- Dynamic SQL query
    DECLARE @DB2 SYSNAME; -- Database name variable

    -- Cursor to iterate through databases
    DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR
    SELECT [NAME]
    FROM MASTER..SYSDATABASES
    WHERE [NAME] NOT IN ('MODEL', 'TEMPDB', 'MASTER', 'MSDB', 'DISTRIBUTION', 'REPORTSERVER$DBALOCAL', 'REPORTSERVER$DBALOCALTEMPDB')
    ORDER BY [NAME];

    OPEN curDB;
    FETCH NEXT FROM curDB INTO @DB2;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @SQL = 'USE [' + @DB2 + ']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13);
        PRINT @SQL;
        EXEC (@SQL);
        FETCH NEXT FROM curDB INTO @DB2;
    END;

    CLOSE curDB;
    DEALLOCATE curDB;

END;

EXEC [SP_MyMaintenancePlan];