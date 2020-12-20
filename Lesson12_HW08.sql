/*
1) Написать функцию возвращающую  клиента с наибольшей суммой покупки.
*/

IF  OBJECT_ID ( 'dbo.uFN_GetCustomerIDByMaxSum','FN' ) IS NOT NULL   
    DROP FUNCTION dbo.uFN_GetCustomerIDByMaxSum;  
GO  
IF  OBJECT_ID ( 'dbo.uFN_GetCustomerIDByMaxSum_withMax','FN' ) IS NOT NULL   
    DROP FUNCTION dbo.uFN_GetCustomerIDByMaxSum_withMax;  
GO  
-- =============================================
-- Description: Уровень изол¤ции : Read Committed
-- =============================================
CREATE FUNCTION uFN_GetCustomerIDByMaxSum ()
RETURNS int
AS
BEGIN
	Declare @CustomerID int;

	Set @CustomerID = ( select  orders2.CustomerID FROM (
		Select TOP (1) 
			Orders.OrderID
			,SUM (UnitPrice * Quantity) as SaleSum
		FROM  Sales.Orders as orders
		JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
		GROUP BY Orders.OrderID
		ORDER BY SUM (UnitPrice * Quantity) DESC
		) as topOrder
		join Sales.Orders as orders2 ON orders2.OrderID = topOrder.OrderID
		)
	Return (@CustomerID)
END;
GO

CREATE FUNCTION uFN_GetCustomerIDByMaxSum_withMax ()
RETURNS int
AS
BEGIN
	Declare @CustomerID int;

	Set @CustomerID = ( Select 
	Orders.CustomerID
	--Orders.OrderID
	--,SUM (UnitPrice * Quantity) as SaleSum
	FROM  Sales.Orders as orders
	JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
	GROUP BY Orders.OrderID,Orders.CustomerID
	HAVING SUM (UnitPrice * Quantity) = (
		Select MAX(SaleSum2) 
		FROM (
			Select 
				SUM (UnitPrice * Quantity) as SaleSum2
			FROM  Sales.Orders as orders2
			JOIN Sales.OrderLines as OrderLines2 ON Orders2.OrderID = OrderLines2.OrderID
			GROUP BY Orders2.OrderID
			) as SalesSums
		) --as topSalesSum
	)
	Return (@CustomerID)
END;
GO

set statistics time on
select dbo.uFN_GetCustomerIDByMaxSum () as TopCustomer
select dbo.uFN_GetCustomerIDByMaxSum_withMax () as TopCustomer2
--если выполнять как функцию, то 

/*2) Написать хранимую процедуру с вход¤щим параметром CustomerID, выводящую сумму покупки по этому клиенту.
*/

IF OBJECT_ID ( 'dbo.GetCustomerSalesSumByID', 'P' ) IS NOT NULL   
    DROP PROCEDURE dbo.GetCustomerSalesSumByID;  
GO  


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description: Уровень изол¤ции : Read Committed
-- =============================================
CREATE PROCEDURE GetCustomerSalesSumByID
	@CustomerID int
AS
BEGIN
	SET NOCOUNT ON;
	
	IF @CustomerID is null
		BEGIN
			PRINT N'Ошибка:ѕередан пустой идентификатор покупателя'
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

/*3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.*/
IF  OBJECT_ID ( 'dbo.uFN_GetCustomerSalesSumByID','FN' ) IS NOT NULL   
    DROP FUNCTION dbo.uFN_GetCustomerSalesSumByID;  
GO  
-- =============================================
-- Description: Уровень изол¤ции : Read Committed
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

/*4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использовани¤ цикла. */

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
--Для всех процедур и функций подойдет уровень изол¤ции Read Committed, т.к. требуетс¤ однократно прочитать подтвержденные данные на момент вызова процедур, при этом изменени¤ строк не планируетс¤.