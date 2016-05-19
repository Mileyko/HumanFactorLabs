-- Справочник типов ошибок
IF EXISTS (
	SELECT * FROM sys.foreign_keys 
	WHERE	object_id = OBJECT_ID('FK_Clients_Stat_Errors')
		AND	parent_object_id = OBJECT_ID('Clients_Stat')
)
ALTER TABLE Clients_Stat DROP CONSTRAINT [FK_Clients_Stat_Errors]
  
IF OBJECT_ID('Errors', 'U') IS NOT NULL
DROP TABLE Errors
CREATE TABLE Errors (
	 [Id] int
	,[Description] varchar(250)
	,CONSTRAINT PK_Errors PRIMARY KEY CLUSTERED ([Id])
)
INSERT INTO Errors
			SELECT 1, 'Обязательное поле'
UNION ALL	SELECT 2, 'Длинное поле'
UNION ALL	SELECT 3, 'Неправильный тип данных'

DECLARE @error int -- Тип ошибки

-- Статистика ошибок
IF OBJECT_ID('Clients_Stat', 'U') IS NOT NULL
DROP TABLE Clients_Stat
CREATE TABLE Clients_Stat (
	 [LineNum] bigint
	,[FieldId] varchar(50)
	,[ErrorId] int
	,CONSTRAINT PK_LineNum PRIMARY KEY CLUSTERED ([LineNum], [FieldId], [ErrorId])
	,CONSTRAINT [FK_Clients_Stat_Errors] FOREIGN KEY ([ErrorId])
	 REFERENCES Errors ([Id])
)
 
-- Загружаем сырые данные из файлы во временную таблицу
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

-- Таблица с данными клиентов дополненная номером строки
IF OBJECT_ID('tempdb..#Clients_RAW') IS NOT NULL
DROP TABLE #Clients_RAW
CREATE TABLE #Clients_RAW (
	 [LineNum] int IDENTITY(1, 1) 
	,[ID] varchar(max)
	,[FIO] varchar(max)
	,[Document] varchar(max)
	,[Type_phone] varchar(max)
	,[Phone] varchar(max)
)
INSERT INTO #Clients_RAW (
	 [ID]
	,[FIO]
	,[Document]
	,[Type_phone]
	,[Phone]
)
SELECT * FROM #Clients
DROP TABLE #Clients


-- Очистка данных

-- Шаг 1. Обязательные поля (NOT NULL)
IF OBJECT_ID('tempdb..#Clients_NULL') IS NOT NULL
DROP TABLE #Clients_NULL
CREATE TABLE #Clients_NULL (
	 [LineNum] int
	,[ID] varchar(max) NOT NULL
	,[FIO] varchar(max) NOT NULL
	,[Document] varchar(max) NOT NULL
	,[Type_phone] varchar(max) NULL
	,[Phone] varchar(max) NULL
)

SET @error = 1
INSERT INTO Clients_Stat
SELECT [LineNum], 'ID', @error FROM #Clients_RAW
WHERE	[ID] IS NULL
UNION ALL
SELECT [LineNum], 'FIO', @error FROM #Clients_RAW
WHERE	[FIO] IS NULL
UNION ALL
SELECT [LineNum], 'Document', @error FROM #Clients_RAW
WHERE	[Document] IS NULL

INSERT INTO #Clients_NULL
SELECT * FROM #Clients_RAW
WHERE	LineNum NOT IN (SELECT LineNum FROM Clients_Stat)


-- Шаг 2. Отфильтруем записи с длинной значения большей требуемой
IF OBJECT_ID('tempdb..#Clients_LENGTH') IS NOT NULL
DROP TABLE #Clients_LENGTH
CREATE TABLE #Clients_LENGTH (
	 [LineNum] int
	,[ID] varchar(4) NOT NULL
	,[FIO] varchar(20) NOT NULL
	,[Document] varchar(12) NOT NULL
	,[Type_phone] varchar(1) NULL
	,[Phone] varchar(11) NULL
)

SET @error = 2
INSERT INTO Clients_Stat
SELECT [LineNum], 'ID', @error FROM #Clients_RAW
WHERE	LEN([ID]) > 4
	OR	([ID] LIKE '[+]%' AND LEN([ID]) > 4 + 1)
UNION ALL
SELECT [LineNum], 'FIO', @error FROM #Clients_RAW
WHERE	LEN([FIO]) > 20
UNION ALL
SELECT [LineNum], 'Document', @error FROM #Clients_RAW
WHERE	LEN([Document]) > 12
UNION ALL
SELECT [LineNum], 'Type_phone', @error FROM #Clients_RAW
WHERE	LEN([Type_phone]) > 1
UNION ALL
SELECT [LineNum], 'Phone', @error FROM #Clients_RAW
WHERE	LEN([Phone]) > 11

INSERT INTO #Clients_LENGTH
SELECT * FROM #Clients_NULL
WHERE	LineNum NOT IN (SELECT LineNum FROM Clients_Stat)

DROP TABLE #Clients_NULL


-- Шаг 3. Отфильтруем записи с неправильным или неприводимым к нужному типами данных 
IF OBJECT_ID('Clients', 'U') IS NOT NULL
DROP TABLE Clients
CREATE TABLE Clients (
	 [ID] numeric(4) NOT NULL
	,[FIO] varchar(20) NOT NULL
	,[Document] varchar(12) NOT NULL
	,[Type_phone] numeric(1) NULL
	,[Phone] numeric(11) NULL
)

SET @error = 3
INSERT INTO Clients_Stat
SELECT [LineNum], 'ID', @error FROM #Clients_RAW
WHERE	[ID] IS NOT NULL AND (ISNUMERIC([ID]) = 0 OR [ID] LIKE '%[-,.]%')
UNION ALL
SELECT [LineNum], 'Type_phone', @error FROM #Clients_RAW
WHERE	[Type_phone] IS NOT NULL AND (ISNUMERIC([Type_phone]) = 0 OR [Type_phone] LIKE '%[-,.]%')
UNION ALL
SELECT [LineNum], 'Phone', @error FROM #Clients_RAW
WHERE	[Phone] IS NOT NULL AND (ISNUMERIC([Phone]) = 0 OR [Phone] LIKE '%[-,.]%')

INSERT INTO Clients
SELECT
	 CAST([ID] AS numeric(4))
	,CAST([FIO] AS varchar(20))
	,CAST([Document] AS varchar(12))
	,CAST([Type_phone] AS numeric(1))
	,CAST([Phone] AS numeric(11))
FROM #Clients_LENGTH
WHERE	LineNum NOT IN (SELECT LineNum FROM Clients_Stat)

DROP TABLE #Clients_LENGTH
DROP TABLE #Clients_RAW


-- Результат
SELECT * FROM Clients --WHERE [ID] = 74

-- Статистика
SELECT * FROM Clients_Stat --WHERE [LineNum] = 1
