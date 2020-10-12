/*Напишите запросы:
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года. Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.
*/

--1.1 вложенный
select 
People.PersonID
,People.FullName
from 
Application.People as People
where IsSalesperson = 1 AND People.PersonID  <> ALL   
	(Select	Distinct
	Invoices.SalespersonPersonID 
	From Sales.Invoices
	INNER JOIN Application.People ON People.PersonID = Invoices.SalespersonPersonID
	Where Invoices.InvoiceDate  between '2015-04-01' and '2015-04-30'
	);

--delete from Sales.CustomerTransactions where CustomerTransactions.InvoiceID in (select Invoices.InvoiceID from Sales.Invoices where Invoices.InvoiceDate  between '2015-04-01' and '2015-04-30' and SalespersonPersonID in (7,2))
--delete from Sales.InvoiceLines where InvoiceID in (select Invoices.InvoiceID from Sales.Invoices where Invoices.InvoiceDate  between '2015-04-01' and '2015-04-30' and SalespersonPersonID in (7,2))
--delete from Warehouse.StockItemTransactions where InvoiceID in (select Invoices.InvoiceID from Sales.Invoices where Invoices.InvoiceDate  between '2015-04-01' and '2015-04-30' and SalespersonPersonID in (7,2))
--delete from Sales.Invoices where Invoices.InvoiceDate  between '2015-04-01' and '2015-04-30' and SalespersonPersonID in (7,2)

--1.2 через CTE
;with sellersIds as (
	Select	Distinct
	Invoices.SalespersonPersonID
	From Sales.Invoices
	Where Invoices.InvoiceDate  between '2015-04-01' and '2015-04-30'
)
select 
People.FullName
from 
Application.People as People
where IsSalesperson = 1 AND People.PersonID  <> ALL (select * from sellersIds)

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.
*/
--2.1 подзапрос
select 
StockItemID
,StockItemName
,UnitPrice
from
[Warehouse].[StockItems] 
where UnitPrice  <=  ALL (
	select (UnitPrice) FROM
	[Warehouse].[StockItems]
	)

--2.2 с CTE 
; WITH minPrices as 
(
select MIN(UnitPrice) as minPrice
FROM [Warehouse].[StockItems]
)
select 
StockItemID
,StockItemName
,UnitPrice
from [Warehouse].[StockItems] 
where UnitPrice <= (select top (1) minPrice from  minPrices)


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. Представьте несколько способов (в том числе с CTE).
*/
--3.1 Вложенный запрос, если клиенты повторяются, будет меньше 5 клиентов 
 
select 
CustomerID
,CustomerName
,PhoneNumber
from Sales.Customers 
where Customers.CustomerID in (
	select top 5 
	CustomerID
	from
	Sales.CustomerTransactions
	where IsFinalized = 1
	order by TransactionAmount desc)

--3.2 CTE, +выберем 5 уникальных клиентов
;With CustomerIDsMaxTrans as 
(
select top 5 
	CustomerID as CustomerID
	,MAX(TransactionAmount) as TransactionAmount
	from
	Sales.CustomerTransactions
	where IsFinalized = 1
	group by CustomerID
	order by MAX(TransactionAmount) desc
)
select 
CustomerID
,CustomerName
,PhoneNumber
from Sales.Customers 
where Customers.CustomerID in (select CustomerIDsMaxTrans.CustomerID from CustomerIDsMaxTrans)


/*
4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).
*/
--4.1 Вариант с временными таблицами, с агрегацией имен сотрудников в одну строку
IF OBJECT_ID('tempdb.dbo.#ExpensiveStockItems', 'U') IS NOT NULL
  DROP TABLE #ExpensiveStockItems; 
IF OBJECT_ID('tempdb.dbo.#InvoicesIds', 'U') IS NOT NULL
  DROP TABLE #InvoicesIds; 
IF OBJECT_ID('tempdb.dbo.#InvoicesData', 'U') IS NOT NULL
  DROP TABLE #InvoicesData; 

-- выберем 3 дорогих товара
select top 3
	StockItems.StockItemID
	,StockItemName
	,UnitPrice
INTO #ExpensiveStockItems
from
[Warehouse].[StockItems] 
order by UnitPrice desc,StockItemID;
select * from #ExpensiveStockItems

--выберем уникальные Id накладных с дорогими товарами 
Select Distinct
	InvoiceLines.InvoiceID
	,StockItemID
INTO #InvoicesIds
from Sales.InvoiceLines
where InvoiceLines.StockItemID IN (Select StockItemID FROM #ExpensiveStockItems);
select * from #InvoicesIds order by StockItemID
--Выберем ID города и Имя упаковавшего накладную 
Select 
  Customers.DeliveryCityID
  ,People.FullName as PackedPeopleName
INTO #InvoicesData
from Sales.Invoices 
LEFT JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID
LEFT JOIN Application.People ON People.PersonID = Invoices.PackedByPersonID
Where Invoices.InvoiceID IN (select #InvoicesIds.InvoiceID from #InvoicesIds)
GROUP BY DeliveryCityID, People.FullName
--Order by DeliveryCityID, PackedPeopleName;
--select * from #InvoicesData where DeliveryCityID = 15

--4.1итоговый запрос
select 
	 CityID
	,CityName
	,String_AGG(#InvoicesData.PackedPeopleName,', ') as [List of persons packing the invoices]
from Application.Cities 
INNER JOIN #InvoicesData ON #InvoicesData.DeliveryCityID = Cities.CityID
Group by CityID,CityName

--4.2 СTE + подзапросы, без агригации имен сотрудников
;With SelectInvoicesIds as (
Select 
	Customers.DeliveryCityID
	,People.FullName as PackedPeopleName
	,Invoices.PackedByPersonID
	from   Sales.Invoices
	LEFT JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID
	LEFT JOIN Application.People ON People.PersonID = Invoices.PackedByPersonID
	Where Invoices.InvoiceID IN (
		select  Distinct
		InvoiceLines.InvoiceID
		from Sales.InvoiceLines
		where InvoiceLines.StockItemID in(
			Select top 3
				Items.StockItemID 
			FROM [Warehouse].[StockItems] as Items
			order by Items.UnitPrice desc,Items.StockItemID
			)
		)
	GROUP BY Customers.DeliveryCityID, Invoices.PackedByPersonID,People.FullName
	--Order by DeliveryCityID, PackedPeopleName
)
select 
	SelectInvoicesIds.DeliveryCityID
	,Cities.CityName
	,SelectInvoicesIds.PackedByPersonID
	,SelectInvoicesIds.PackedPeopleName
from SelectInvoicesIds
inner join Application.Cities ON Cities.CityID = SelectInvoicesIds.DeliveryCityID
Order by DeliveryCityID,PackedPeopleName

/*
Опционально:

5. Объясните, что делает и оптимизируйте запрос:*/
SET STATISTICS IO, TIME ON
GO

SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC
--Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения. Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). Напишите ваши рассуждения по поводу оптимизации. 

/*вариант 5.1
Запрос выбирает ид накладной, дату накладной, Имя продавца,  сумму товаров по накладной и сумму товаров из связанного заказа (если комплектация заказа завершена), если сумма накладной больше 27000 
Сделал с временной таблицей и CTE
*/
IF OBJECT_ID('tempdb.dbo.#SalesTotals', 'U') IS NOT NULL
  DROP TABLE #SalesTotals; 

SELECT 
InvoiceId, 
SUM(Quantity*UnitPrice) AS TotalSumm
into #SalesTotals
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000

;with
OrdersTotals as (
SELECT 
OrderLines.OrderId,
SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems
FROM  Sales.Orders
INNER JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
WHERE Orders.PickingCompletedWhen IS NOT NULL
GROUP BY OrderLines.OrderId
)

Select
Invoices.InvoiceID,
Invoices.InvoiceDate,
SalesPerson.FullName as SalesPersonName,
#SalesTotals.TotalSumm AS TotalSummByInvoice,
OrdersTotals.TotalSummForPickedItems
FROM Sales.Invoices
INNER JOIN Application.People as SalesPerson ON SalesPerson.PersonID = Invoices.SalespersonPersonID
INNER JOIN #SalesTotals ON #SalesTotals.InvoiceID = Invoices.InvoiceID
LEFT JOIN OrdersTotals  ON #SalesTotals.InvoiceID = OrdersTotals.OrderID 
ORDER BY TotalSumm DESC

