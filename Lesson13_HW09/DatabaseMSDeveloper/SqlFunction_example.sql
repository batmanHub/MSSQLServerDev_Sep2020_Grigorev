USE [WideWorldImporters]
GO

--пример скалярной функции генерирующей простой пароль
SELECT [dbo].[GetPasswordSimple] () as mySimplePassword

--пример скалярной функции генерирующей простой пароль c выбором длины
SELECT [dbo].[GetPasswordbyLen] (155) as mySimplePassword_155Chars

--пример скалярной функции генерирующей пароль c выбором длины и спецСимволов
SELECT [dbo].[GetPassword] (12,1) as myPassword_SpecialChars

--пример табличной функции генерирующей 5 паролей длинной 10 символом, имеющие спецсимволы
select
*
from [dbo].[GetPasswords](10,1,5)

