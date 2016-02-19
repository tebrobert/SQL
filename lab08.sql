USE SocialNetwork;
GO


--Создать хранимую процедуру, производящую выборку
--из некоторой таблицы и возвращающую результат выборки в виде курсора
IF OBJECT_ID ('dbo.ProcedureOne', 'P') IS NOT NULL
	DROP PROCEDURE dbo.ProcedureOne;
GO
CREATE PROCEDURE dbo.ProcedureOne
	@CursorArg CURSOR VARYING OUTPUT
AS
	SET @CursorArg = CURSOR 
		FOR
		SELECT ProfileID, ProfileName
		FROM dbo.Profiles
	OPEN @CursorArg
--	CLOSE @CursorArg
GO

DECLARE @Cursor CURSOR;
EXEC dbo.ProcedureOne @CursorArg = @Cursor OUTPUT;
--	OPEN @Cursor
--	FETCH NEXT FROM @Cursor;
--	CLOSE @Cursor
--	OPEN @Cursor
FETCH NEXT FROM @Cursor;
WHILE (@@FETCH_STATUS = 0)
	FETCH NEXT FROM @Cursor;

CLOSE @Cursor;
DEALLOCATE @Cursor;
GO

--Модифицировать хранимую процедуру п.1. таким образом,
--чтобы выборка осуществлялась с формированием столбца,
--значение которого формируется пользовательской функцией

IF OBJECT_ID ('dbo.FunctionOne', 'FN') IS NOT NULL
	DROP FUNCTION dbo.FunctionOne
GO
CREATE FUNCTION dbo.FunctionOne (@country nvarchar(40)) RETURNS int AS
BEGIN;
	DECLARE @res int;
	SET @res = 0;
	IF (@country = 'Russia')
		SET @res=1;
	IF (@country = 'USA')
		SET @res=2;
	IF (@country = 'China')
		SET @res=3;
	RETURN @res
END;
GO

ALTER PROCEDURE dbo.ProcedureOne
	@CursorArg CURSOR VARYING OUTPUT
AS
	SET @CursorArg = CURSOR 
		FOR
		SELECT ProfileID, ProfileName, dbo.FunctionOne(ProfileCountry) AS CountryID
		FROM dbo.Profiles
	OPEN @CursorArg
GO

DECLARE @Cursor CURSOR;
EXEC dbo.ProcedureOne @CursorArg = @Cursor OUTPUT;

FETCH NEXT FROM @Cursor;
WHILE (@@FETCH_STATUS = 0)
	FETCH NEXT FROM @Cursor;

CLOSE @Cursor;
DEALLOCATE @Cursor;
GO


--Создать хранимую процедуру, вызывающую процедуру п.1.,
--осуществляющую прокрутку возвращаемого курсора и выводящую сообщения,
--сформированные из записей при выполнении условия, заданного еще одной пользовательской функцией

IF OBJECT_ID ('dbo.FunctionCheck', 'FN') IS NOT NULL
	DROP FUNCTION dbo.FunctionCheck
GO
CREATE FUNCTION dbo.FunctionCheck (@num int) RETURNS int AS
BEGIN;
	DECLARE @res int;
	SET @res = @num % 2;
	RETURN @res;
END;
GO

IF OBJECT_ID ('dbo.ProcedurePrint', 'P') IS NOT NULL
	DROP PROCEDURE dbo.ProcedurePrint
GO
CREATE PROCEDURE dbo.ProcedurePrint AS
BEGIN;
	DECLARE @cursor CURSOR;
	DECLARE @FID int;
	DECLARE @FName nvarchar(40);
	DECLARE @FCountryID int;

	EXEC dbo.ProcedureOne @CursorArg = @cursor OUTPUT;

	FETCH NEXT FROM @cursor INTO @FID, @FName, @FCountryID;
	WHILE (@@FETCH_STATUS = 0)
	BEGIN;
		IF (dbo.FunctionCheck(@FID)=1)	
		BEGIN;
			PRINT CAST(@FID AS nvarchar)+' '+@FName;
		END;
		FETCH NEXT FROM @cursor INTO @FID, @FName, @FCountryID;
	END;
END;
GO

EXEC dbo.ProcedurePrint;
GO

--Модифицировать хранимую процедуру п.2. таким образом,
--чтобы выборка формировалась с помощью табличной функции


--IF OBJECT_ID ('dbo.TableFunction', 'FN') IS NOT NULL
	DROP FUNCTION dbo.TableFunction
GO
CREATE FUNCTION dbo.TableFunction() RETURNS @T TABLE(ColA int, ColB int) AS
BEGIN;
	DECLARE @i int;
	DECLARE @a int;
	DECLARE @b int;
	DECLARE @c int;
	SET @i = 3;
	SET @a = 1;
	SET @b = 1;
	SET @c = 2;

	INSERT INTO @T VALUES (1, @a);
	INSERT INTO @T VALUES (2, @b);
	INSERT INTO @T VALUES (@i, @c);

	WHILE @i <= 10
	BEGIN;
		SET @i = @i + 1;
		SET @a = @b;
		SET @b = @c;
		SET @c = @a + @b;
		INSERT INTO @T VALUES (@i, @c);
	END;

	RETURN;
END;
GO

ALTER PROCEDURE dbo.ProcedureOne
	@CursorArg CURSOR VARYING OUTPUT
AS
	SET @CursorArg = CURSOR 
		FOR
		SELECT * FROM dbo.TableFunction();
	OPEN @CursorArg
GO

DECLARE @Cursor CURSOR;
EXEC dbo.ProcedureOne @CursorArg = @Cursor OUTPUT;

FETCH NEXT FROM @Cursor;
WHILE (@@FETCH_STATUS = 0)
	FETCH NEXT FROM @Cursor;

CLOSE @Cursor;
DEALLOCATE @Cursor;
GO
