CREATE PROCEDURE GetCustomerOrderSummary
-- Created By: Erickson Figueroa
-- Creation Date: March 2024
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE to calculate total order amounts per customer
    WITH CustomerOrderTotals AS (
        SELECT
            c.CustomerID,
            c.CompanyName,
            SUM(od.UnitPrice * od.Quantity) AS TotalOrderAmount
        FROM Customers c
        JOIN Orders o ON c.CustomerID = o.CustomerID
        JOIN [Order Details] od ON o.OrderID = od.OrderID
        WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
        GROUP BY c.CustomerID, c.CompanyName
    ),

    -- CTE to calculate average order amount across all customers
    AverageOrderAmount AS (
        SELECT AVG(TotalOrderAmount) AS AverageAmount
        FROM CustomerOrderTotals
    )

    -- Final SELECT statement to retrieve customer order summary
    SELECT
        cot.CustomerID,
        cot.CompanyName,
        cot.TotalOrderAmount,
        aoa.AverageAmount,
        CASE
            WHEN cot.TotalOrderAmount > aoa.AverageAmount THEN 'Above Average'
            WHEN cot.TotalOrderAmount = aoa.AverageAmount THEN 'Average'
            ELSE 'Below Average'
        END AS OrderAmountCategory
    FROM CustomerOrderTotals cot, AverageOrderAmount aoa
    ORDER BY cot.TotalOrderAmount DESC;
END;
GO

-- Testing Execution:
-- EXEC GetCustomerOrderSummary '2023-01-01', '2023-12-31';