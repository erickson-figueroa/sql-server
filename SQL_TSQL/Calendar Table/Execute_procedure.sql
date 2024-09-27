-- Parameter 1 --> Your calendar table name.
-- Parameter 2 --> Primary Key name.
-- Parameter 3 --> Date from year-month-day format.
-- Parameter 4 --> The years that you want to generate, starting from the start date.
-- Parameter 5 --> The language of the month, day, timestamp etc. IF you do NOT specify 'EN', by default it will create everything in English.

-- Execute the procedure
EXEC sp_CreateTableCalendar 'DimTime', 'PK_DimTime', '2023-01-01', 3, 'EN'