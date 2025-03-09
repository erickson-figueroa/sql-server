CREATE PROCEDURE CustomerListByStateAndOrder 

-- Created By: Erickson Figueroa
-- Creation Date: August 2021

@States VARCHAR(128),
@OrderType VARCHAR(20) = 'CompanyName' -- Default order by CompanyName

AS 

BEGIN 

    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX); 

    -- Dynamic query assembly with string concatenation and join
    SET @SQL = 'SELECT c.Region, c.CustomerID, c.CompanyName, c.ContactName, c.Phone, o.OrderID ' +
               'FROM Customers c ' +
               'JOIN Orders o ON c.CustomerID = o.CustomerID ' +
               'WHERE c.Region IN (' + @States + ') ';

    -- Add dynamic ordering based on parameter
    IF @OrderType = 'OrderID'
        SET @SQL = @SQL + 'ORDER BY o.OrderID';
    ELSE IF @OrderType = 'Region'
        SET @SQL = @SQL + 'ORDER BY c.Region, c.CompanyName';
    ELSE
        SET @SQL = @SQL + 'ORDER BY c.CompanyName, c.Region'; -- Default order

    PRINT @SQL; -- for testing & debugging

    EXEC sp_executeSQL @SQL; 

END 
GO