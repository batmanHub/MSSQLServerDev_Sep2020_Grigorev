--Оконные функции
--1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.
--В качестве запроса с временной таблицей и табличной переменной можно взять свой запрос или следующий запрос:
--Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
--Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
--Пример
--Дата продажи Нарастающий итог по месяцу
--2015-01-29 4801725.31
--2015-01-30 4801725.31
--2015-01-31 4801725.31
--2015-02-01 9626342.98
--2015-02-02 9626342.98
--2015-02-03 9626342.98
--Продажи можно взять из таблицы Invoices.
--Нарастающий итог должен быть без оконной функции.

--1.1 С временной таблицей
 set statistics time on

DROP TABLE IF EXISTS #SalesSumm;
DROP TABLE IF EXISTS #SalesSummToatalByYM;

Select 
row_number() over(ORDER BY inv.InvoiceDate,inv.InvoiceID ) as n,
inv.InvoiceID
,cust.CustomerName
,inv.InvoiceDate
,InvSum.InvoiceSumm
INTO #SalesSumm
from Sales.Invoices as inv
Inner join Sales.Customers as cust ON cust.CustomerID = inv.CustomerID
CROSS APPLY (
	Select Top (1)
	SUM(invLines.UnitPrice * invLines.Quantity) as InvoiceSumm
	from Sales.InvoiceLines as invLines
	Where invLines.InvoiceID = inv.InvoiceID
	GROUP BY invLines.InvoiceID
) as InvSum
WHERE inv.InvoiceDate > '2015-01-01'

Select 
YEAR(SalesSumm.InvoiceDate) as year
,MONTH(SalesSumm.InvoiceDate) as month
,SUM (InvoiceSumm) as TotalSum
INTO #SalesSummToatalByYM
from #SalesSumm as SalesSumm
GROUP BY YEAR(SalesSumm.InvoiceDate),MONTH(SalesSumm.InvoiceDate)
ORDER BY YEAR(SalesSumm.InvoiceDate),MONTH(SalesSumm.InvoiceDate)


select 
InvoiceID
,CustomerName
,InvoiceDate
,InvoiceSumm
,(Select top (1)
	SUM(ts.TotalSum)
	FROM #SalesSummToatalByYM as ts
	where (ts.year<YEAR(InvoiceDate)) OR ( ts.year=YEAR(InvoiceDate) AND ts.month<= Month(InvoiceDate))
	)  as RunningTotal
from #SalesSumm 
order by n

----1.2 с Табличной переменной

DECLARE @SalesSumm Table(
 n bigint,
 InvoiceID int,
 CustomerName nvarchar(100),
 InvoiceDate date,
 InvoiceSumm float
 );

 DECLARE @SalesSummToatalByYM Table(
 year smallint,
 month smallint,
 TotalSum float
 );

 INSERT INTO @SalesSumm (n, InvoiceID,CustomerName,InvoiceDate,InvoiceSumm)
Select 
row_number() over(ORDER BY inv.InvoiceDate,inv.InvoiceID ) as n,
inv.InvoiceID
,cust.CustomerName
,inv.InvoiceDate
,InvSum.InvoiceSumm
from Sales.Invoices as inv
Inner join Sales.Customers as cust ON cust.CustomerID = inv.CustomerID
CROSS APPLY (
	Select Top (1)
	SUM(invLines.UnitPrice * invLines.Quantity) as InvoiceSumm
	from Sales.InvoiceLines as invLines
	Where invLines.InvoiceID = inv.InvoiceID
	GROUP BY invLines.InvoiceID
) as InvSum
WHERE inv.InvoiceDate > '2015-01-01'

INSERT INTO @SalesSummToatalByYM
Select 
YEAR(SalesSumm.InvoiceDate) as year
,MONTH(SalesSumm.InvoiceDate) as month
,SUM (InvoiceSumm) as TotalSum
from #SalesSumm as SalesSumm
GROUP BY YEAR(SalesSumm.InvoiceDate),MONTH(SalesSumm.InvoiceDate)
ORDER BY YEAR(SalesSumm.InvoiceDate),MONTH(SalesSumm.InvoiceDate)

select 
InvoiceID
,CustomerName
,InvoiceDate
,InvoiceSumm
,(Select top (1)
	SUM(ts.TotalSum)
	FROM @SalesSummToatalByYM as ts
	where (ts.year<YEAR(InvoiceDate)) OR ( ts.year=YEAR(InvoiceDate) AND ts.month<= Month(InvoiceDate))
	)  as RunningTotal
from @SalesSumm 
order by n


--1.3 Итог. Планы подобные, с временными таблицами чуть медленнее, 

--2. Если вы брали предложенный выше запрос, то сделайте расчет суммы нарастающим итогом с помощью оконной функции.
--Сравните 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on; 


Select 
inv.InvoiceID
,cust.CustomerName
,inv.InvoiceDate
,InvSum.InvoiceSumm
,SUM (InvSum.InvoiceSumm) OVER (ORDER BY YEAR(Inv.InvoiceDate),MONTH(Inv.InvoiceDate)) as RunningTotal
from Sales.Invoices as inv
Inner join Sales.Customers as cust ON cust.CustomerID = inv.CustomerID
CROSS APPLY (
	Select Top (1)
	SUM(invLines.UnitPrice * invLines.Quantity) as InvoiceSumm
	from Sales.InvoiceLines as invLines
	Where invLines.InvoiceID = inv.InvoiceID
	GROUP BY invLines.InvoiceID
	) as InvSum
WHERE inv.InvoiceDate > '2015-01-01'
ORDER BY inv.InvoiceDate,inv.InvoiceID

--с оконной функцией 1 сек, без нее около 1,5 сек.


--2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

;With countSaleItemsByMonth as (
select 
Month(inv.InvoiceDate) as InvoiceDateMonth,
--Count(invLines.InvoiceID) as countProd,
invLines.StockItemID ,
COUNT(invLines.StockItemID) OVER (Partition BY Month(inv.InvoiceDate),invLines.StockItemID ) as CountStockItem
from Sales.Invoices as inv
inner join Sales.InvoiceLines as invLines On inv.InvoiceID = invLines.InvoiceID
Where YEAR(inv.InvoiceDate) = 2016
),
countSaleItemsByMonthWithRank as (
select 
*,
DENSE_RANK() OVER (Partition by s1.InvoiceDateMonth ORDER BY s1.CountStockItem Desc,StockItemID) as productRankinMonth
from countSaleItemsByMonth as s1
) 
select 
s.InvoiceDateMonth,
items.StockItemName,
s.CountStockItem
,s.productRankinMonth
from countSaleItemsByMonthWithRank as s
inner join Warehouse.StockItems as items on items.StockItemID = s.StockItemID
where s.productRankinMonth<3
group by s.InvoiceDateMonth,items.StockItemName,s.CountStockItem,s.productRankinMonth
Order by s.InvoiceDateMonth,s.CountStockItem desc

/*3. Функции одним запросом
Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций*/

select 
StockItemID
,LEAD(StockItemID) OVER( ORDER BY StockItemName) as [Next StockItemID] 
,LAG(StockItemID) OVER( ORDER BY StockItemName) as [Prev StockItemID]
,StockItemName
,items.Brand
,items.UnitPrice
,ROW_NUMBER() OVER (PARTITION BY LEFT(StockItemName,1)  ORDER BY StockItemName) as [order by Item Name with partition]
,COUNT(StockItemID) OVER() as [count items]
,COUNT(StockItemID) OVER(PARTITION BY LEFT(StockItemName,1)) as [count items]
,LAG(StockItemName,2,'No items') OVER( ORDER BY StockItemName) as [Prev StockItemID]
,items.TypicalWeightPerUnit
,NTILE(30) OVER(  ORDER BY items.TypicalWeightPerUnit) as [group by weight]
from Warehouse.StockItems as items
--order by StockItemName
order by TypicalWeightPerUnit

/*4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки*/
;With cte as (
select
peoples.PersonID
,peoples.PreferredName
,cust.CustomerID
,cust.CustomerName
,inv.InvoiceDate
,inv.InvoiceID
,LAST_VALUE (inv.InvoiceID) OVER(PARTITION BY peoples.PersonID ORDER BY inv.InvoiceDate,inv.InvoiceID  ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) as LastInvoiceID
--,LAST_VALUE (inv.InvoiceDate) OVER(PARTITION BY peoples.PersonID ORDER BY inv.InvoiceDate,inv.InvoiceID ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) as LastInvoiceDate
,SUM (Lines.UnitPrice * Lines.Quantity) OVER (PARTITION BY Lines.InvoiceID) as InvoiceSum
from Application.People as peoples
JOIN Sales.Invoices as inv ON inv.SalespersonPersonID = peoples.PersonID
JOIN Sales.InvoiceLines as Lines ON Lines.InvoiceID = inv.InvoiceID
JOIN Sales.Customers as cust ON cust.CustomerID = inv.CustomerID
WHERE peoples.IsSalesperson = 1
)
Select distinct * from cte
Where InvoiceID = LastInvoiceID 
Order By PersonID 

/*5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки*/
;With cte as (
Select
cust.CustomerID
,cust.CustomerName
,Lines.StockItemID
,Lines.UnitPrice
,inv.InvoiceDate
,DENSE_RANK () OVER (PARTITION BY cust.CustomerID ORDER BY Lines.UnitPrice desc,Lines.StockItemID) as ItemRank
from Sales.Customers as cust
JOIN Sales.Invoices as inv ON inv.CustomerID = cust.CustomerID
JOIN Sales.InvoiceLines as Lines ON Lines.InvoiceID = inv.InvoiceID
)
Select 
CustomerID
,CustomerName
,StockItemID
,UnitPrice
,Max(InvoiceDate) as InvoiceDate
--,ItemRank
 from cte 
Where cte.ItemRank <3
GROUP BY CustomerID,CustomerName,StockItemID,UnitPrice,ItemRank
Order by CustomerID,ItemRank desc