-- Общее количество ошибок
SELECT COUNT(*) AS [Кол-во ошибок] FROM Clients_Stat


-- Количество ошибок по строками и по полям
IF OBJECT_ID('tempdb..#Clients_Stat_LineNum') IS NOT NULL
DROP TABLE #Clients_Stat_LineNum
CREATE TABLE #Clients_Stat_LineNum (
	 [LineNum] int
	,[ID] int
	,[FIO] int
	,[Document] int
	,[Type_phone] int
	,[Phone] int
)

SET NOCOUNT ON
DECLARE @i int = 1
WHILE @i <= 104
BEGIN
	INSERT INTO #Clients_Stat_LineNum
	SELECT
		 @i
		,(SELECT COUNT(*) FROM Clients_Stat WHERE [LineNum] = @i AND [FieldId] = 'ID')
		,(SELECT COUNT(*) FROM Clients_Stat WHERE [LineNum] = @i AND [FieldId] = 'FIO')
		,(SELECT COUNT(*) FROM Clients_Stat WHERE [LineNum] = @i AND [FieldId] = 'Document')
		,(SELECT COUNT(*) FROM Clients_Stat WHERE [LineNum] = @i AND [FieldId] = 'Type_phone')
		,(SELECT COUNT(*) FROM Clients_Stat WHERE [LineNum] = @i AND [FieldId] = 'Phone')
	
    SET @i = @i + 1
END
SELECT * FROM #Clients_Stat_LineNum


-- Количество ошибок по полям
SELECT
	 Clients_Stat.[FieldId] AS [Поле]
	,COUNT(*) AS [Кол-во ошибок]
FROM Clients_Stat
GROUP BY Clients_Stat.[FieldId]


-- Количество ошибок по полям и типам
SELECT
	 Clients_Stat.[FieldId] AS [Поле]
	,Errors.[Description] AS [Ошибка]
	,COUNT(*) AS [Кол-во ошибок]
FROM Clients_Stat
JOIN Errors ON	Errors.[Id] = Clients_Stat.[ErrorId]
GROUP BY Errors.[Description], Clients_Stat.[FieldId]
