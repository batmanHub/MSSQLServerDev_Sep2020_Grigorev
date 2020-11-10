/*1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers*/
DECLARE  @dateNow DATE = Cast(getDate() as Date)
--delete from Sales.Customers where CustomerName like 'CustomerName%'
INSERT INTO [Sales].[Customers]
           ([CustomerID]
           ,[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[BuyingGroupID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[CreditLimit]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[DeliveryRun]
           ,[RunPosition]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[DeliveryLocation]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])
		   OUTPUT inserted.[CustomerID], inserted.[CustomerName]
     VALUES
	 --1 row---------------------------------------------------------------
           (NEXT VALUE FOR Sequences.CustomerID
           ,'CustomerName11'
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1 --[PostalCityID]
           ,10.22
           ,@dateNow
           ,11.33
           ,0
           ,0
           ,7
           ,'(220) 335566'
           ,'(220) 335577'
           ,null--'DeliveryRun, nvarchar(5),>
           ,null--'RunPosition, nvarchar(5),>
           ,'WWW.Example.Com'--'WebsiteURL, nvarchar(256),>
           ,'DeliveryAddressLine1'
           ,'DeliveryAddressLine2'
           ,335511--'DeliveryPostalCode, nvarchar(10),>
           ,null--'DeliveryLocation, geography,>
           ,'PostalAddressLine1'
           ,'PostalAddressLine2'
           ,343531--'PostalPostalCode, nvarchar(10),>
           ,1 ),
	 --2 row---------------------------------------------------------------
		   (NEXT VALUE FOR Sequences.CustomerID
           ,'CustomerName2'
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,13.22
           ,@dateNow
           ,10.33
           ,0
           ,0
           ,7
           ,'(220) 115566'
           ,'(220) 115577'
           ,null--'DeliveryRun, nvarchar(5),>
           ,null--'RunPosition, nvarchar(5),>
           ,'WWW.Example2.Com'--'WebsiteURL, nvarchar(256),>
           ,'DeliveryAddressLine12'
           ,'DeliveryAddressLine22'
           ,335511--'DeliveryPostalCode, nvarchar(10),>
           ,null--'DeliveryLocation, geography,>
           ,'PostalAddressLine12'
           ,'PostalAddressLine22'
           ,343531--'PostalPostalCode, nvarchar(10),>
           ,2 ),
	 --3 row---------------------------------------------------------------
		   (NEXT VALUE FOR Sequences.CustomerID
           ,'CustomerName3'
           ,1
           ,2
           ,1
           ,2
           ,1
           ,2
           ,1
           ,1
           ,7.22
           ,@dateNow
           ,7.33
           ,0
           ,0
           ,7
           ,'(220) 335336'
           ,'(220) 335337'
           ,null--'DeliveryRun, nvarchar(5),>
           ,null--'RunPosition, nvarchar(5),>
           ,'WWW.Example.Com'--'WebsiteURL, nvarchar(256),>
           ,'DeliveryAddressLine33'
           ,'DeliveryAddressLine33'
           ,335511--'DeliveryPostalCode, nvarchar(10),>
           ,null--'DeliveryLocation, geography,>
           ,'PostalAddressLine33'
           ,'PostalAddressLine33'
           ,343531--'PostalPostalCode, nvarchar(10),>
           ,1 ),
	 --4 row---------------------------------------------------------------
		   (NEXT VALUE FOR Sequences.CustomerID
           ,'CustomerName4'
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,10.22
           ,@dateNow
           ,11.33
           ,0
           ,0
           ,7
           ,'(220) 12345'
           ,'(220) 12345'
           ,null--'DeliveryRun, nvarchar(5),>
           ,null--'RunPosition, nvarchar(5),>
           ,'WWW.Example4.Com'--'WebsiteURL, nvarchar(256),>
           ,'DeliveryAddressLine14'
           ,'DeliveryAddressLine24'
           ,335511--'DeliveryPostalCode, nvarchar(10),>
           ,null--'DeliveryLocation, geography,>
           ,'PostalAddressLine44'
           ,'PostalAddressLine44'
           ,343533--'PostalPostalCode, nvarchar(10),>
           ,1 ),
	 --5 row---------------------------------------------------------------
		   (NEXT VALUE FOR Sequences.CustomerID
           ,'CustomerName5'
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,1
           ,10.22
           ,@dateNow
           ,11.33
           ,0
           ,0
           ,7
           ,'(220) 555566'
           ,'(220) 555577'
           ,null--'DeliveryRun, nvarchar(5),>
           ,null--'RunPosition, nvarchar(5),>
           ,'WWW.Example.Com'--'WebsiteURL, nvarchar(256),>
           ,'DeliveryAddressLine5'
           ,'DeliveryAddressLine5'
           ,335511--'DeliveryPostalCode, nvarchar(10),>
           ,null--'DeliveryLocation, geography,>
           ,'PostalAddressLine5'
           ,'PostalAddressLine5'
           ,343531--'PostalPostalCode, nvarchar(10),>
           ,1 )
GO

/*2. удалите 1 запись из Customers, которая была вами добавлена*/

DELETE FROM [Sales].[Customers]  
OUTPUT deleted.*
WHERE CustomerName = 'CustomerName5'

/*3. изменить одну запись, из добавленных через UPDATE*/
UPDATE [Sales].[Customers] 
SET WebsiteURL = 'WWW.NewWebSite.ru'
OUTPUT deleted.WebsiteURL as del_WebSite,inserted.WebsiteURL as Ins_WebSite
WHERE CustomerID = (Select top 1 CustomerID Where CustomerName = 'CustomerName4')

/*4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть*/

;With cteToMerge as (
	Select Top (1)
	[CustomerID] ,	[CustomerName] ,	[BillToCustomerID],	[CustomerCategoryID],	[BuyingGroupID],[PrimaryContactPersonID],	[AlternateContactPersonID],	 [DeliveryMethodID],  [DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],	[DeliveryLocation],	[PostalAddressLine1],	[PostalAddressLine2],	[PostalPostalCode],	[LastEditedBy]
	FROM [Sales].[Customers] as cust 
	Where CustomerName like 'CustomerName5'
	
	UNION ALL

	Select
			1533 as [CustomerID]
           ,'CustomerName55' as [CustomerName]
           ,1 as [BillToCustomerID]
           ,1 as [CustomerCategoryID]
           ,1 as [BuyingGroupID]
           ,1 as [PrimaryContactPersonID]
           ,1 as [AlternateContactPersonID]
           ,1 as [DeliveryMethodID]
           ,1 as [DeliveryCityID]
           ,1 as [PostalCityID]
           ,10.22 as [CreditLimit]
           ,GETDATE() as [AccountOpenedDate]
           ,11.33 as [StandardDiscountPercentage]
           ,0 as [IsStatementSent]
           ,0 as [IsOnCreditHold]
           ,8 [PaymentDays]
           ,'(220) 5355566' as [PhoneNumber]
           ,'(220) 5535577' as [FaxNumber]
           ,null--'DeliveryRun, nvarchar(5),>
           ,null--'RunPosition, nvarchar(5),>
           ,'WWW.Example.Com' as WebsiteURL
           ,'DeliveryAddressLine5' 
           ,'DeliveryAddressLine5'
           ,335511 as DeliveryPostalCode
           ,null as DeliveryLocation
           ,'PostalAddressLine5'
           ,'PostalAddressLine5'
           ,343531 as PostalPostalCode
           ,1 
)

MERGE  [Sales].[Customers] as Customers
USING cteToMerge as s ON (s.CustomerID = Customers.CustomerID)
WHEN MATCHED 
	THEN UPDATE SET
	Customers.[WebsiteURL] = 'WWW.newWebSite22.RU'
	,Customers.[AccountOpenedDate] = GetDate() - 550
WHEN NOT MATCHED BY TARGET 
	THEN INSERT ([CustomerID] ,	[CustomerName] ,	[BillToCustomerID],	[CustomerCategoryID],	[BuyingGroupID],[PrimaryContactPersonID],	[AlternateContactPersonID],	 [DeliveryMethodID],  [DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[DeliveryRun],[RunPosition],[WebsiteURL],[DeliveryAddressLine1],[DeliveryAddressLine2],[DeliveryPostalCode],	[DeliveryLocation],	[PostalAddressLine1],	[PostalAddressLine2],	[PostalPostalCode],	[LastEditedBy])
		VALUES (S.[CustomerID] ,s.[CustomerName] ,s.[BillToCustomerID],s.[CustomerCategoryID],s.[BuyingGroupID],s.[PrimaryContactPersonID],s.[AlternateContactPersonID],s.[DeliveryMethodID],s.[DeliveryCityID],s.[PostalCityID],s.[CreditLimit],s.[AccountOpenedDate],s.[StandardDiscountPercentage],s.[IsStatementSent],s.[IsOnCreditHold],s.[PaymentDays],s.[PhoneNumber],s.[FaxNumber],s.[DeliveryRun],s.[RunPosition],s.WebSiteURL,s.[DeliveryAddressLine1],s.[DeliveryAddressLine2],s.[DeliveryPostalCode],s.[DeliveryLocation],s.[PostalAddressLine1],s.[PostalAddressLine2],s.[PostalPostalCode],s.[LastEditedBy])
OUTPUT 
	$action,
	inserted.[CustomerID] as ins_CustID , deleted.[CustomerID] as del_CustID
	,inserted.[CustomerName] as ins_Name, deleted.[CustomerName] as del_Name
	,inserted.[WebsiteURL] as ins_Website, deleted.[WebsiteURL] as del_website
	,inserted.[AccountOpenedDate] as ins_ACCDate, deleted.[AccountOpenedDate] as del_ACCDate
;

/*5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert */

EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;  
GO  

drop table if exists [Application].[People_BulCTest];

CREATE TABLE [Application].[People_BulCTest](
	[PersonID] [int] primary key NOT NULL,
	[FullName] [nvarchar](50) NOT NULL,
	[PreferredName] [nvarchar](50) NOT NULL,
	[LogonName] [nvarchar](50) NULL,
	[IsSystemUser] [bit] NOT NULL,
	[IsEmployee] [bit] NOT NULL,
	[IsSalesperson] [bit] NOT NULL,
	[PhoneNumber] [nvarchar](20) NULL,
	[FaxNumber] [nvarchar](20) NULL,
	[EmailAddress] [nvarchar](256) NULL,
	[TotalSaleCount] [int] NULL
	);

Declare @select nvarchar(Max) = N'Select PersonID ,[FullName],[PreferredName],[LogonName],[IsSystemUser],[IsEmployee],[IsSalesperson],[PhoneNumber],[FaxNumber],[EmailAddress],[TotalSaleCount] FROM [WideWorldImporters].[Application].[People];';
Declare @mySrvName Nvarchar(100) =   @@SERVERNAME

Declare @fileName nvarchar(100) = 'D:\1\People_BulCTest_1.txt'

Declare @upload_comand Nvarchar(500) = 'bcp "'+@select+'"  QUERYOUT  "'+@fileName+'" -T -w -t";;" -S ' + @mySrvName;
exec master..xp_cmdshell @upload_comand

/*5.1 Загрузка с помощью bcp in*/
Declare @load_comand nvarchar (300) =  'bcp "WideWorldImporters.Application.People_BulCTest"  IN  "'+@fileName+'" -T -w -t";;" -S ' + @mySrvName;
select @load_comand
exec master..xp_cmdshell @load_comand

/*5.2 Загрузка с помощью BULK INSERT*/
	BULK INSERT WideWorldImporters.Application.People_BulCTest
			FROM "D:\1\People_BulCTest_1.txt"
			WITH 
				(
				BATCHSIZE = 100, 
				DATAFILETYPE = 'widechar',
				ERRORFILE = 'D:\1\People_BulCTest_1_error.txt' ,
				FIELDTERMINATOR = ';;',
				ROWTERMINATOR ='\n',
				KEEPNULLS,
				TABLOCK        
				);


