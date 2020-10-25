--Pivot и Cross Apply
--1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
--Название клиента
--МесяцГод Количество покупок

--Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
--имя клиента нужно поменять так чтобы осталось только уточнение
--например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
--дата должна иметь формат dd.mm.yyyy например 25.12.2019

--Например, как должны выглядеть результаты:
--InvoiceMonth Peeples Valley, AZ Medicine Lodge, KS Gasport, NY Sylvanite, MT Jessie, ND
--01.01.2013 3 1 4 2 2
--01.02.2013 7 3 4 2 1
Select
CONVERT (Varchar, InvoiceDateMonth,104) as InvoiceMonth,
[Sylvanite, MT],[Peeples Valley, AZ],[Medicine Lodge, KS],[Gasport, NY],[Jessie, ND]
FROM (
	select 
	Inv.InvoiceID as InvoiceID,
	DATEFROMPARTS(YEAR(Inv.InvoiceDate),MONTH(Inv.InvoiceDate),1) as InvoiceDateMonth,
	Cust.shortName
	from Sales.Invoices as Inv
	inner join (select 
			Customers.CustomerID,
			SUBSTRING(CustomerName,CHARINDEX('(',CustomerName)+1,CHARINDEX(')',CustomerName)-CHARINDEX('(',CustomerName)-1) as shortName
			from 
			Sales.Customers 
			where Customers.CustomerID between 2 and 6 ) as Cust ON Cust.CustomerID = Inv.CustomerID
	) as SourceTable
PIVOT ( COUNT(InvoiceID) FOR  shortName IN ([Sylvanite, MT],[Peeples Valley, AZ],[Medicine Lodge, KS],[Gasport, NY],[Jessie, ND]) ) as PivotTable
ORDER BY InvoiceDateMonth

--2. Для всех клиентов с именем, в котором есть Tailspin Toys
--вывести все адреса, которые есть в таблице, в одной колонке

--Пример результатов
--CustomerName AddressLine
--Tailspin Toys (Head Office) Shop 38
--Tailspin Toys (Head Office) 1877 Mittal Road
--Tailspin Toys (Head Office) PO Box 8975
--Tailspin Toys (Head Office) Ribeiroville
--.....
Select
CustomerName,DeliveryAddress 
FROM (
	select
	CustomerName
	,DeliveryAddressLine1
	,DeliveryAddressLine2
	,PostalAddressLine1
	,PostalAddressLine2
	from Sales.Customers
	where CustomerName like 'Tailspin Toys%'
	) AS CustomersAdreses
UNPIVOT (DeliveryAddress FOR Name IN (DeliveryAddressLine1,DeliveryAddressLine2,PostalAddressLine1,PostalAddressLine2)) as unpvtCustomersAdreses

--3. В таблице стран есть поля с кодом страны цифровым и буквенным
--сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
--Пример выдачи

--CountryId CountryName Code
--1 Afghanistan AFG
--1 Afghanistan 4
--3 Albania ALB
--3 Albania 8
Select
CountryName,Code
FROM (
	Select
	CountryName
	,IsoAlpha3Code
	,Cast (IsoNumericCode as nvarchar(3)) as IsoNumericCode
	from Application.Countries) as Countr
UNPIVOT (Code FOR Name in (IsoAlpha3Code,IsoNumericCode)) as unpvtCountries

--4. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

select 
cust.CustomerID,CustomerName,CustomerInvoices.*
from Sales.Customers as Cust
Cross Apply ( 
	Select top (2)
	invLines.StockItemID,
	invLines.UnitPrice,
	inv.InvoiceDate
	from Sales.Invoices as inv
	Inner join Sales.InvoiceLines as invLines ON invLines.InvoiceID = inv.InvoiceID
	Where inv.CustomerID = Cust.CustomerID
	Order BY invLines.UnitPrice DESC
	) as CustomerInvoices
order by cust.CustomerID

