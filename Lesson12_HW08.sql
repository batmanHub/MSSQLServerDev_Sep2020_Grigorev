/*
1) Ќаписать функцию возвращающую  лиента с наибольшей суммой покупки.
*/

IF OBJECT_ID ( 'dbo.GetCustomerByMaxSum', 'P' ) IS NOT NULL   
    DROP PROCEDURE dbo.GetCustomerByMaxSum;  
GO 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description: ”ровень изол¤ции : Read Committed
-- =============================================
CREATE PROCEDURE GetCustomerByMaxSum
	@topCustomersCount int = 1
AS
BEGIN
	SET NOCOUNT ON;
	Select TOP (@topCustomersCount) 
		cust.CustomerName
		,SUM (UnitPrice * Quantity) as SaleSum
	FROM Sales.Customers as cust
	JOIN Sales.Orders on Orders.CustomerID = cust.CustomerID
	JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
    GROUP BY Orders.CustomerID,cust.CustomerName
	ORDER BY SUM (UnitPrice * Quantity) DESC
END
GO


Exec GetCustomerByMaxSum 
Go

Exec GetCustomerByMaxSum  @topCustomersCount=5
GO

/*2) Ќаписать хранимую процедуру с вход¤щим параметром —ustomerID, вывод¤щую сумму покупки по этому клиенту.
*/

IF OBJECT_ID ( 'dbo.GetCustomerSalesSumByID', 'P' ) IS NOT NULL   
    DROP PROCEDURE dbo.GetCustomerSalesSumByID;  
GO  


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description: ”ровень изол¤ции : Read Committed
-- =============================================
CREATE PROCEDURE GetCustomerSalesSumByID
	@CustomerID int
AS
BEGIN
	SET NOCOUNT ON;
	
	IF @CustomerID is null
		BEGIN
			--RAISERROR(N'ќЎ»Ѕ ј:ѕередан пустой идентификатор покупател¤', 12, 1);
			PRINT N'ќЎ»Ѕ ј:ѕередан пустой идентификатор покупател¤'
			RETURN
		END

	Select Top (1)
		SUM (UnitPrice * Quantity) as SaleSum
	FROM Sales.Customers as cust
	JOIN Sales.Orders on Orders.CustomerID = cust.CustomerID
	JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
   	WHERE cust.CustomerID = @CustomerID
	GROUP BY Orders.CustomerID,cust.CustomerName
	ORDER BY SUM (UnitPrice * Quantity) DESC
END
GO

Exec GetCustomerSalesSumByID @CustomerID = null
GO
Exec GetCustomerSalesSumByID @CustomerID = 5
GO

/*3) —оздать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.*/
IF  OBJECT_ID ( 'dbo.uFN_GetCustomerSalesSumByID','FN' ) IS NOT NULL   
    DROP FUNCTION dbo.uFN_GetCustomerSalesSumByID;  
GO  
-- =============================================
-- Description: ”ровень изол¤ции : Read Committed
-- =============================================
CREATE FUNCTION uFN_GetCustomerSalesSumByID (@CustomerID int)
RETURNS DECIMAL (18,2)
AS
BEGIN
	Declare @SUM DECIMAL (18,2)
	
	Select Top (1)
		@SUM = SUM (UnitPrice * Quantity)  
	FROM Sales.Customers as cust
	JOIN Sales.Orders on Orders.CustomerID = cust.CustomerID
	JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
   	WHERE cust.CustomerID = @CustomerID
	GROUP BY Orders.CustomerID,cust.CustomerName
	ORDER BY SUM (UnitPrice * Quantity) DESC
	
	Return @SUM
END
GO

SET STATISTICS TIME on

Select dbo.uFN_GetCustomerSalesSumByID(6) as SaleSum;
Exec GetCustomerSalesSumByID @CustomerID = 6;

/*4) —оздайте табличную функцию покажите как ее можно вызвать дл¤ каждой строки result set'а без использовани¤ цикла. */

IF  OBJECT_ID ( 'dbo.uFN_GetCustomerSalesSumByIDTable','IF' ) IS NOT NULL   
    DROP FUNCTION dbo.uFN_GetCustomerSalesSumByIDTable;  
GO  
-- =============================================
-- Description: ”ровень изол¤ции : Read Committed
-- =============================================
CREATE FUNCTION uFN_GetCustomerSalesSumByIDTable (@CustomerID int)
RETURNS TABLE
AS
    RETURN(
	
	Select Top (1)
	 cust.CustomerID
	 ,SUM (UnitPrice * Quantity) as SumTotal 
	FROM Sales.Customers as cust
	JOIN Sales.Orders on Orders.CustomerID = cust.CustomerID
	JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
   	WHERE cust.CustomerID = @CustomerID
	GROUP BY cust.CustomerID,cust.CustomerName
	ORDER BY SUM (UnitPrice * Quantity) DESC
);
GO

select
Customers.CustomerID,
sums.SumTotal
from Sales.Customers
cross apply  dbo.uFN_GetCustomerSalesSumByIDTable(Customers.CustomerID)  as sums


--¬о всех процедурах, в описании укажите дл¤ преподавател¤м
--5) какой уровень изол¤ции нужен и почему. 
--ƒл¤ всех процедур и функций подойдет уровень изол¤ции Read Committed, т.к. требуетс¤ однократно прочитать подтвержденные данные на момент вызова процедур, при этом изменени¤ строк не планируетс¤.