USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal". �������: �� ������, ������������ ������.
�������: Warehouse.StockItems.
*/
SELECT  
	[StockItemID]
    ,[StockItemName]
FROM [Warehouse].[StockItems]
WHERE StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders). ������� ����� JOIN, � ����������� ������� ������� �� �����. �������: �� ����������, ������������ ����������.
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
*/
SELECT 
	 Suppliers.SupplierID
    ,SupplierName
    --,PurchaseOrders.PurchaseOrderID
  FROM [Purchasing].[Suppliers]
  LEFT JOIN [Purchasing].PurchaseOrders 
	 ON PurchaseOrders.SupplierID = [Suppliers].[SupplierID]
  WHERE PurchaseOrders.PurchaseOrderID is null
  /*
  3. ������ (Orders) � ����� ������ ����� 100$ ���� ����������� ������ ������ ����� 20 ���� � �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ � ������� ��.��.����
* �������� ������, � ������� ���� �������
* ����� ��������, � �������� ��������� �������
* ����� ����, � ������� ��������� ���� ������� (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������, ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).
�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
  */
DECLARE 
	@pagesize BIGINT = 100, 
	@pagenum  BIGINT = 11;

  select
  Orders.OrderID
  ,Orders.OrderDate
  ,convert(nvarchar(16), Orders.OrderDate, 104) as OrderDate 
  ,DATENAME(MONTH, Orders.OrderDate) as OrderDateMonth 
  ,DATENAME(quarter, Orders.OrderDate) as OrderDateQuarter
  ,CASE 
		WHEN MONTH(Orders.OrderDate) >=1 and MONTH(Orders.OrderDate) < 5	THEN 1
		WHEN MONTH(Orders.OrderDate) >=5 and MONTH(Orders.OrderDate) < 9	THEN 2
		WHEN MONTH(Orders.OrderDate) >=9 and MONTH(Orders.OrderDate) <= 12	THEN 3
		ELSE 0
		END OrderDateTremester
  ,Customer.CustomerName
  from Sales.Orders as Orders
  JOIN Sales.OrderLines as OrderLines ON OrderLines.OrderID = Orders.OrderID
  JOIN Sales.Customers as Customer ON Customer.CustomerID = Orders.CustomerID
  WHERE
	(UnitPrice > 100 OR Quantity > 20) AND Orders.PickingCompletedWhen is not null
  order by OrderDateQuarter,OrderDateTremester, Orders.OrderDate
  OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY; 
  
  /*
4. ������ ����������� (Purchasing.Suppliers), ������� ���� ��������� � ������ 2014 ���� � ��������� Air Freight ��� Refrigerated Air Freight (DeliveryMethodName).
�������:
* ������ �������� (DeliveryMethodName)
* ���� ��������
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
  */
  select 
  DeliveryMethods.DeliveryMethodName
  ,PurchaseOrders.ExpectedDeliveryDate
  --,PurchaseOrders.OrderDate
  ,Suppliers.SupplierName
  ,People.FullName
  ,PurchaseOrders.*
  from Purchasing.Suppliers
  left join Application.DeliveryMethods 
		ON DeliveryMethods.DeliveryMethodID = Suppliers.DeliveryMethodID
  left join Purchasing.PurchaseOrders 
		ON PurchaseOrders.DeliveryMethodID = DeliveryMethods.DeliveryMethodID
  LEFT JOIN Application.People 
		ON People.PersonID = PurchaseOrders.ContactPersonID
  Where 
  PurchaseOrders.OrderDate between '2014-01-01' and '2014-01-31' 
  AND 
  (DeliveryMethods.DeliveryMethodName = 'Air Freight' OR DeliveryMethods.DeliveryMethodName = 'Refrigerated Air Freight')

  /*
  5. ������ ��������� ������ (�� ����) � ������ ������� � ������ ����������, ������� ������� ����� (SalespersonPerson).
  */
  Select top 10
  Orders.OrderID
  ,Orders.OrderDate
  ,SalesPerson.FullName as SalesPersonName
  ,ContactPerson.FullName as ContactPersonName
  from Sales.Orders
  LEFT JOIN Application.People as SalesPerson  ON SalesPerson.PersonID = SalespersonPersonID
  LEFT JOIN Application.People as ContactPerson  ON ContactPerson.PersonID = ContactPersonID
  order by Orders.OrderDate desc

  /*
  6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g. ��� ������ �������� � Warehouse.StockItems.
  */
  select DISTINCT
  Customers.CustomerID
  ,Customers.CustomerName
  ,Customers.PhoneNumber
  from Sales.Orders 
  INNER JOIN Sales.OrderLines ON OrderLines.OrderID = Orders.OrderID
  LEFT JOIN  Sales.Customers  ON Customers.CustomerID = Orders.CustomerID
  LEFT JOIN  Warehouse.StockItems ON StockItems.StockItemID = OrderLines.StockItemID
  where StockItemName = 'Chocolate frogs 250g'
  
  /*
  7. ��������� ������� ���� ������, ����� ����� ������� �� �������
  �������:
* ��� �������
* ����� �������
* ������� ���� �� ����� �� ���� �������
* ����� ����� ������
������� �������� � ������� Sales.Invoices � ��������� ��������.
  */
  select
  YEAR(InvoiceDate) as InvoiceDateYEAR,
  MONTH(InvoiceDate) as InvoiceDateMonthNumber
  ,AVG(UnitPrice) as AVGPrice
  ,SUM(UnitPrice) as SumPrice
  from 
  Sales.Invoices
  inner join Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
  GROUP BY 
  ROLLUP (YEAR(InvoiceDate) , MONTH(InvoiceDate) )
  order by InvoiceDateYEAR,InvoiceDateMonthNumber

  /*
  8. ���������� ��� ������, ��� ����� ����� ������ ��������� 10 000
�������:
* ��� �������
* ����� �������
* ����� ����� ������
������� �������� � ������� Sales.Invoices � ��������� ��������.
  */
  select
  YEAR(InvoiceDate) as InvoiceDateYEAR,
  MONTH(InvoiceDate) as InvoiceDateMonthNumber
  ,SUM(UnitPrice) as SumPrice
  from 
  Sales.Invoices
  inner join Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID 
  GROUP BY YEAR(InvoiceDate) , MONTH(InvoiceDate) HAVING SUM(UnitPrice)>10000
  order by InvoiceDateYEAR,InvoiceDateMonthNumber

  /*
  9. ������� ����� ������, ���� ������ ������� � ���������� ���������� �� �������, �� �������, ������� ������� ����� 50 �� � �����.
����������� ������ ���� �� ����, ������, ������.
�������:
* ��� �������
* ����� �������
* ������������ ������
* ����� ������
* ���� ������ �������
* ���������� ����������
������� �������� � ������� Sales.Invoices � ��������� ��������.
  */
  select
  MIN(InvoiceDate)				as FirstInvoiceDate 
  ,YEAR(InvoiceDate)			as InvoiceDateYEAR
  ,MONTH(InvoiceDate)			as InvoiceDateMonthNumber
  ,StockItems.StockItemName     as StockItemName
  ,SUM(Quantity)				as QuantityByMonth
  ,SUM(InvoiceLines.UnitPrice)  as SumPriceMonth
  from 
  Sales.Invoices
  inner join Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID 
  LEFT JOIN  Warehouse.StockItems ON StockItems.StockItemID = InvoiceLines.StockItemID
  GROUP BY YEAR(InvoiceDate) , MONTH(InvoiceDate),StockItems.StockItemName 
	HAVING SUM(Quantity)<50
  order by InvoiceDateYEAR,InvoiceDateMonthNumber,StockItemName

  /*
�����������:
�������� ������� 8-9 ���, ����� ���� � �����-�� ������ �� ���� ������, �� ���� ����� ����� ����������� �� � �����������, �� ��� ���� ����. 
  */
 
 /*8 ���*/
    select
  YEAR(InvoiceDate) as InvoiceDateYEAR,
  MonthNumbers.MonthNumber as InvoiceDateMonthNumber
  ,SUM(isNuLL(UnitPrice,0)) as SumPrice
  from (values(1), (2), (3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) as MonthNumbers (MonthNumber)
  LEFT JOIN Sales.Invoices ON MONTH(InvoiceDate) = MonthNumbers.MonthNumber
  LEFT join Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID 
  GROUP BY YEAR(InvoiceDate) , MonthNumbers.MonthNumber 
	HAVING SUM(isNuLL(UnitPrice,0)) >10000 OR SUM(isNuLL(UnitPrice,0))  = 0
  order by InvoiceDateYEAR,MonthNumbers.MonthNumber

  /*9 ��� - ������ �������, �� ����� ��������*/ 
  ;with helpQuery as(
  Select  distinct
	YEAR(InvoicesYears.InvoiceDate) as InvoicesYear
	,MonthNumbers.MonthNumber
	,StockItems.StockItemID
  From Sales.Invoices as InvoicesYears
  CROSS JOIN (values(1), (2), (3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) as MonthNumbers (MonthNumber)
  CROSS JOIN Warehouse.StockItems 
  )

  select 
  MIN(InvoiceDate)				as FirstInvoiceDate 
  ,helpQuery.InvoicesYear
  ,helpQuery.MonthNumber
  ,StockItems.StockItemName
  ,CASE 
	WHEN Invoices.InvoiceID is not null THEN SUM(InvoiceLines.Quantity)
	ELSE 0
   END QuantityByMonth
  ,CASE 
	WHEN Invoices.InvoiceID is not null THEN SUM(InvoiceLines.UnitPrice)
	ELSE 0
   END SumPriceMonth
  from helpQuery
  INNER JOIN Warehouse.StockItems ON StockItems.StockItemID = helpQuery.StockItemID
  LEFT JOIN Sales.InvoiceLines ON helpQuery.StockItemID = InvoiceLines.StockItemID
  LEFT JOIN Sales.Invoices as Invoices  ON Invoices.InvoiceID = InvoiceLines.InvoiceID and MONTH(Invoices.InvoiceDate)=helpQuery.MonthNumber and YEAR(Invoices.InvoiceDate) = helpQuery.InvoicesYear
  GROUP BY InvoicesYear , MonthNumber,StockItems.StockItemName,Invoices.InvoiceID 
	HAVING   CASE 
				WHEN Invoices.InvoiceID is not null THEN SUM(InvoiceLines.Quantity)
				ELSE 0
			END < 50
  ORDER BY InvoicesYear,MonthNumber,StockItemName
 

