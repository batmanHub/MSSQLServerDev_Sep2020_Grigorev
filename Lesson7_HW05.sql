/*1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice */

DECLARE @x XML
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'D:\sqlServer\LESSON7\StockItems.xml',
   SINGLE_BLOB)
   as d)

--select @x as SourceXML

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @x

;DECLARE  @maxID int = (select MAX(StockitemID) FROM Warehouse.StockItems); 

;With cteToMerge as (
SELECT 
parseXML.*
,@maxID + Row_Number() OVer (ORDER BY Items.StockItemName) as newStockItemID -- конструкция для вставки нового идентификатора
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	 [StockItemName] nvarchar(50)  '@Name'
	,[SupplierID] int 'SupplierID'
	,[UnitPackageID] int 'Package/UnitPackageID'
	,OuterPackageID int 'Package/OuterPackageID'
	,QuantityPerOuter int 'Package/QuantityPerOuter'
	,TypicalWeightPerUnit decimal(18,3) 'Package/TypicalWeightPerUnit'
	,LeadTimeDays int 'LeadTimeDays'
	,IsChillerStock bit 'IsChillerStock'
	,TaxRate decimal(18,3) 'TaxRate'
	,UnitPrice decimal(18,2) 'UnitPrice'
	) as parseXML
LEFT JOIN Warehouse.StockItems as Items ON Items.StockItemName = parseXML.StockItemName
)

--select * from cteToMerge 

MERGE Warehouse.StockItems AS StockItems
USING cteToMerge  ON  StockItems.[StockItemName] = cteToMerge.[StockItemName]

	WHEN MATCHED THEN 	
		UPDATE SET
			StockItems.SupplierID		= cteToMerge.SupplierID
			,StockItems.UnitPackageID	= cteToMerge.SupplierID
			,StockItems.OuterPackageID	= cteToMerge.OuterPackageID
			,StockItems.QuantityPerOuter	= cteToMerge.QuantityPerOuter
			,StockItems.TypicalWeightPerUnit	= cteToMerge.TypicalWeightPerUnit
			,StockItems.LeadTimeDays	= cteToMerge.LeadTimeDays
			,StockItems.IsChillerStock	= cteToMerge.IsChillerStock
			,StockItems.TaxRate	= cteToMerge.TaxRate
			,StockItems.UnitPrice	= cteToMerge.UnitPrice

	WHEN NOT MATCHED THEN 		
		INSERT (
			StockItemID
			,StockItemName
			,SupplierID
			,UnitPackageID
			,OuterPackageID
			,QuantityPerOuter
			,TypicalWeightPerUnit
			,LeadTimeDays
			,IsChillerStock
			,TaxRate
			,UnitPrice
			,LastEditedBy
			,ValidFrom
			,ValidTo
		) 
		VALUES (
			cteToMerge.newStockItemID   
			,cteToMerge.StockItemName
			,cteToMerge.SupplierID
			,cteToMerge.UnitPackageID
			,cteToMerge.OuterPackageID
			,cteToMerge.QuantityPerOuter
			,cteToMerge.TypicalWeightPerUnit
			,cteToMerge.LeadTimeDays
			,cteToMerge.IsChillerStock
			,cteToMerge.TaxRate
			,cteToMerge.UnitPrice
			,1
			,DEFAULT
			,DEFAULT
		)

OUTPUT $action, inserted.*, deleted.*; --измененные строки

/*2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml*/
 -- FOR XML PATH
SELECT 
	StockItemName AS [@Name]
	,SupplierID
	,UnitPackageID AS [Package/UnitPackageID]
	,OuterPackageID AS [Package/OuterPackageID]
	,QuantityPerOuter AS [Package/QuantityPerOuter]
	,TypicalWeightPerUnit AS [TypicalWeightPerUnit/QuantityPerOuter]
	,LeadTimeDays
	,IsChillerStock
	,TaxRate
	,UnitPrice
	,'StockItemID: ' + str(StockItemID) as "comment()"
FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems')
GO

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select
	StockItemID
	,StockItemName
	--,CustomFields
	,JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
	,JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
FROM Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести:
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле
*/

select
	StockItemID
	,StockItemName
	--,CustomFields
	,JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
	,JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
	--,JSON_QUERY(CustomFields, '$.Tags') as TagsJson
	,AllTags.tags as Tags
FROM Warehouse.StockItems as items
CROSS APPLY (
	Select 
		value  
	FROM OPENJSON (CustomFields, '$.Tags')
	WHERE 
		value = 'Vintage'
	) as VintageTag
CROSS APPLY (
	Select 
		STRING_AGG(value,', ')  as tags 
	FROM OPENJSON (CustomFields, '$.Tags')
	) as AllTags

