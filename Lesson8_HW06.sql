/*
Динамический PIVOT
Пишем динамический PIVOT.
По заданию из занятия “Операторы CROSS APPLY, PIVOT, CUBE”.
Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
Месяц Год Количество покупок

Нужно написать запрос, который будет генерировать результаты для всех клиентов.
Имя клиента указывать полностью из CustomerName.
Дата должна иметь формат dd.mm.yyyy например 25.12.2019 
*/


DECLARE  @dml AS NVARCHAR(MAX),
		 @ColumnName AS NVARCHAR(MAX);

SELECT @ColumnName = ISNULL(@ColumnName + ',','') + QUOTENAME(sc.CustomerName)
	FROM (
	SELECT DISTINCT  CustomerName 
    FROM sales.Customers 
	) as sc
       
--Select @ColumnName    

SET @dml = N'
Select 
	FORMAT ( InvoiceDateMonth,''dd.MM.yyyy'') as InvoiceMonth
	,' +@ColumnName + '
	FROM (
		select 
			Inv.InvoiceID as InvoiceID,
			DATEFROMPARTS(YEAR(Inv.InvoiceDate),MONTH(Inv.InvoiceDate),1) as InvoiceDateMonth,
			Cust.CustomerName
			from Sales.Invoices as Inv
			inner join Sales.Customers as cust ON cust.CustomerID = Inv.CustomerID
		 ) as SourceTable
PIVOT ( COUNT(InvoiceID) FOR  CustomerName IN (' +@ColumnName + ') ) as PivotTable
ORDER BY InvoiceDateMonth'

EXEC sp_executesql @dml
