-- Сравниваем количество клиентов в исходном файле с количеством правильных и с ошибками из статистики
IF OBJECT_ID('tempdb..#Clients') IS NOT NULL
DROP TABLE #Clients
CREATE TABLE #Clients (
	 [ID] varchar(max)
	,[FIO] varchar(max)
	,[Document] varchar(max)
	,[Type_phone] varchar(max)
	,[Phone] varchar(max)
)
BULK INSERT #Clients FROM 'c:\data\Clients.csv'
WITH (
	 FIELDTERMINATOR = ';'
	,ROWTERMINATOR = '\n'
	,FIRSTROW = 1
	,CODEPAGE = '1251'
)

DECLARE @TotalLines int = (SELECT COUNT(*) FROM #Clients)
DROP TABLE #Clients

SELECT
	 @TotalLines AS [Кол-во клиентов в файле]
	,(SELECT COUNT(DISTINCT [LineNum]) FROM Clients_Stat) + (SELECT COUNT(*) FROM Clients) AS [Кол-во отфильтрованных клиентов и в статистике ошибок]


-- Сравниваем файл с отфильтрованными клиентами (получён с помощью python-скрипта) с таблицей отфильтрованных клиентов 
IF OBJECT_ID('tempdb..#ValidClients') IS NOT NULL
DROP TABLE #ValidClients
CREATE TABLE #ValidClients (
	 [ID] varchar(max)
	,[FIO] varchar(max)
	,[Document] varchar(max)
	,[Type_phone] varchar(max)
	,[Phone] varchar(max)
)
BULK INSERT #ValidClients FROM 'c:\data\Valid clients.csv'
WITH (
	 FIELDTERMINATOR = ';'
	,ROWTERMINATOR = '\n'
	,FIRSTROW = 1
	,CODEPAGE = '1251'
)

DECLARE @d int = (
	SELECT COUNT(*)
	FROM Clients AS Clients 
	FULL JOIN #ValidClients ValidClients
	ON		ValidClients.[ID] = Clients.[ID]
	WHERE	Clients.[ID] IS NULL
		OR	ValidClients.[ID] IS NULL
)
SELECT
	CASE
		WHEN @d = 0 THEN 'Нет'
		ELSE 'Есть'
	END AS [Различия] 
DROP TABLE #ValidClients
