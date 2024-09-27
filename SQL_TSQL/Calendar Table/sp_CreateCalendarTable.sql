CREATE PROCEDURE sp_CreateCalendarTable
    @tableName NVARCHAR(255),      
    @constraintName NVARCHAR(255), 
    @startDate SMALLDATETIME,       
    @yearsAhead INT,
    @language NVARCHAR(2)
AS
BEGIN
    -- Author: Erickson Figueroa
    -- Description: Stored procedure to create and populate a calendar table.
    -- Purpose: Create a calendar table with dates and their attributes (month, year, quarter, etc.).
    -- 
    -- Parameters:
    --   @tableName: Name of the table to be created.
    --   @constraintName: Name of the primary key constraint.
    --   @startDate: Start date of the calendar (format year-month-day: 20230101).
    --   @yearsAhead: Number of years forward to generate the calendar, starting from the chosen start date.
    --
    --   @language: Language for month and day names ('ES' for Spanish, otherwise defaults to English).
    --
    -- Example usage:
    --
    --   EXEC sp_CreateCalendarTable 'DimTime', 'PK_DimTime', '2023-01-01', 3, 'ES'
    --

    -- Define local variables.
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @endDate SMALLDATETIME;
    DECLARE @DateYYYYMMDD INT;
    DECLARE @Year SMALLINT, @Quarter CHAR(2), @Month SMALLINT;
    DECLARE @Week SMALLINT, @Day SMALLINT, @DayOfWeek SMALLINT;
    DECLARE @QuarterName CHAR(7), @MonthName CHAR(15);
    DECLARE @MonthAbbrev CHAR(3);
    DECLARE @WeekName CHAR(10), @DayMonthName CHAR(6), @DayOfWeekName CHAR(10);

    -- Initial configuration.
    SET DATEFORMAT dmy;
    SET DATEFIRST 1;

    BEGIN TRANSACTION;

    /* Calendar Description

      Quarters:

        Quarter 1 -> Jan, Feb, Mar
        Quarter 2 -> Apr, May, Jun
        Quarter 3 -> Jul, Aug, Sep
        Quarter 4 -> Oct, Nov, Dec
    
        DateSK       -- Surrogate Key (SK)                            (20251214)
        Date         -- The date in YMD                                (2025-12-14)
        Year         -- The year                                       
        Quarter      -- Every three months                             (1,2,3,4)
        Week         -- Week number of the year                       
        Day          -- The day of the week                           
        DayOfWeek    -- Day of the week order                          (1,2,3,4,5,6,7)
        QuarterName  -- Name of the quarter                            (Q4/25)
        MonthName    -- Full month name                                (December)
        MonthAbbrev  -- First three letters of the month name          (Dec)
        WeekName     -- Week number and abbreviated year               (Week 24,25,26 etc.)
        DayMonthName -- Day and month name with first three letters    (14 Dec)
        DayOfWeekName -- Name of the weekday

   */

    -- Create the table if it doesn't exist, otherwise drop it
    SET @sql = N'IF OBJECT_ID(''' + @tableName + ''') IS NOT NULL DROP TABLE ' + @tableName + ';
                CREATE TABLE ' + @tableName + ' (
                    DateSK INT NOT NULL,
                    Date DATE NOT NULL, 
                    Year SMALLINT NOT NULL,
                    Quarter SMALLINT NOT NULL,
                    Month SMALLINT NOT NULL,
                    Week SMALLINT NOT NULL,
                    Day SMALLINT NOT NULL,
                    DayOfWeek SMALLINT NOT NULL,
                    QuarterName CHAR(7) NOT NULL,
                    MonthName CHAR(15) NOT NULL,
                    MonthAbbrev CHAR(3) NOT NULL,
                    WeekName CHAR(10) NOT NULL,
                    DayMonthName CHAR(6) NOT NULL,
                    DayOfWeekName CHAR(10) NOT NULL
                );';
    EXEC sp_executesql @sql;

    -- Check and drop the constraint if it exists, otherwise drop it
    IF EXISTS (SELECT 1 FROM sys.objects WHERE name = @constraintName AND type IN ('PK', 'UQ'))
    BEGIN
        SET @sql = N'ALTER TABLE ' + @tableName + ' DROP CONSTRAINT ' + @constraintName;
        EXEC sp_executesql @sql;
    END

    -- Check and drop the index if it exists, otherwise drop it
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @constraintName AND OBJECT_ID = OBJECT_ID(@tableName))
    BEGIN
        SET @sql = N'DROP INDEX ' + @constraintName + ' ON ' + @tableName;
        EXEC sp_executesql @sql;
    END

    -- Create the primary key constraint
    SET @sql = N'ALTER TABLE ' + @tableName + ' ADD CONSTRAINT ' + @constraintName + ' PRIMARY KEY CLUSTERED (DateSK)';
    EXEC sp_executesql @sql;

    -- Date range to generate: from @startDate to @endDate (after adding @yearsAhead)
    SET @endDate = DATEADD(YEAR, @yearsAhead, @startDate);
    SET @endDate = DATEADD(DAY, -1, @endDate); -- Adjust so that it doesn't include the first day of the next year

    -- Generate calendar data using a loop
    WHILE (@startDate <= @endDate) 
    BEGIN
        SET @DateYYYYMMDD = YEAR(@startDate) * 10000 + MONTH(@startDate) * 100 + DATEPART(dd, @startDate);
        SET @Year = DATEPART(yy, @startDate);
        SET @Quarter = DATEPART(qq, @startDate);
        SET @Month = DATEPART(m, @startDate);
        SET @Week = DATEPART(wk, @startDate);
        SET @Day = RIGHT('0' + CAST(DATEPART(dd, @startDate) AS VARCHAR(2)), 2);
        SET @DayOfWeek = DATEPART(dw, @startDate);
        SET @MonthName = DATENAME(mm, @startDate);
        SET @MonthAbbrev = LEFT(@MonthName, 3);
        SET @QuarterName = 'Q' + CAST(@Quarter AS CHAR(1)) + '/' + RIGHT(CAST(@Year AS CHAR(4)), 2);
        SET @WeekName = 'Week ' + CAST(@Week AS CHAR(2)) + '/' + RIGHT(CAST(@Year AS CHAR(4)), 2);
        SET @DayMonthName = CAST(@Day AS CHAR(2)) + ' ' + RTRIM(@MonthName);
        SET @DayOfWeekName = DATENAME(dw, @startDate);

         -- Determine month names, day names, quarter names, and abbreviations based on Spanish language
        IF @language = 'ES'
        BEGIN
            SELECT @MonthName = 
                CASE 
                    WHEN @Month = 1 THEN 'Enero'
                    WHEN @Month = 2 THEN 'Febrero'
                    WHEN @Month = 3 THEN 'Marzo'
                    WHEN @Month = 4 THEN 'Abril'
                    WHEN @Month = 5 THEN 'Mayo'
                    WHEN @Month = 6 THEN 'Junio'
                    WHEN @Month = 7 THEN 'Julio'
                    WHEN @Month = 8 THEN 'Agosto'
                    WHEN @Month = 9 THEN 'Septiembre'
                    WHEN @Month = 10 THEN 'Octubre'
                    WHEN @Month = 11 THEN 'Noviembre'
                    WHEN @Month = 12 THEN 'Diciembre'
                END;
            SELECT @DayOfWeekName = 
                CASE @DayOfWeek
                    WHEN 1 THEN 'Lunes'
                    WHEN 2 THEN 'Martes'
                    WHEN 3 THEN 'Miércoles'
                    WHEN 4 THEN 'Jueves'
                    WHEN 5 THEN 'Viernes'
                    WHEN 6 THEN 'Sábado'
                    WHEN 7 THEN 'Domingo'
                END;
            SET @QuarterName = 'T' + CAST(@Quarter AS CHAR(1)) + '/' + RIGHT(CAST(@Year AS CHAR(4)), 2);
            SET @MonthAbbrev = LEFT(@MonthName, 3);
            SET @WeekName = 'Sem ' + CAST(@Week AS CHAR(2)) + '/' + RIGHT(CAST(@Year AS CHAR(4)), 2);
            SET @DayMonthName = CAST(@Day AS CHAR(2)) + ' ' + RTRIM(@MonthName);
        END
        -- If not 'ES', generate everything in English format
        ELSE
        BEGIN
            SET @MonthName = DATENAME(mm, @startDate);
            SET @MonthAbbrev = LEFT(DATENAME(mm, @startDate), 3);
            SET @DayOfWeekName = DATENAME(dw, @startDate);
        END

        -- Insert data into the calendar table
        SET @sql = 'INSERT INTO ' + @tableName + ' (DateSK, Date, Year, Quarter, Month, Week, Day, DayOfWeek, QuarterName, MonthName, MonthAbbrev, WeekName, DayMonthName, DayOfWeekName)
                    VALUES (' + CAST(@DateYYYYMMDD AS NVARCHAR) + ', ''' + CAST(@startDate AS NVARCHAR) + ''', ' + CAST(@Year AS NVARCHAR) + ', ' + 
                    CAST(@Quarter AS NVARCHAR) + ', ' + CAST(@Month AS NVARCHAR) + ', ' + CAST(@Week AS NVARCHAR) + ', ' + CAST(@Day AS NVARCHAR) + ', ' + 
                    CAST(@DayOfWeek AS NVARCHAR) + ', ''' + @QuarterName + ''', ''' + @MonthName + ''', ''' + @MonthAbbrev + ''', ''' + @WeekName + ''', ''' + @DayMonthName + ''', ''' + @DayOfWeekName + ''')';
        EXEC sp_executesql @sql;

        -- Increment the date
        SET @startDate = DATEADD(DAY, 1, @startDate);
    END

    COMMIT TRANSACTION;

    -- Verify the created table
    SET @sql = 'SELECT * FROM ' + @tableName;
    EXEC sp_executesql @sql;
END;
