--Data bases creation
USE master;
GO

IF DB_ID ('SocialNetworkDataBase1') IS NOT NULL
	DROP DATABASE SocialNetworkDataBase1;
GO
CREATE DATABASE SocialNetworkDataBase1
    ON (NAME = SocialNetworkDataBase1, FILENAME = 'E:\SQL\SocialNetworkDataBase.mdf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 1MB )
    LOG ON (NAME = SocialNetworkDataBase1_Log, FILENAME = 'E:\SQL\SocialNetworkDataBase1.ldf', SIZE = 1MB, MAXSIZE = 20MB, FILEGROWTH = 1MB )
GO

IF DB_ID ('SocialNetworkDataBase2') IS NOT NULL
	DROP DATABASE SocialNetworkDataBase2;
GO
CREATE DATABASE SocialNetworkDataBase2
    ON (NAME = SocialNetworkDataBase2, FILENAME = 'E:\SQL\SocialNetworkDataBase2.mdf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 1MB )
    LOG ON (NAME = SocialNetworkDataBase2_Log, FILENAME = 'E:\SQL\SocialNetworkDataBase2.ldf', SIZE = 1MB, MAXSIZE = 20MB, FILEGROWTH = 1MB )
GO

--Tables with horisontal fragmentation
USE SocialNetworkDataBase1;
GO
IF OBJECT_ID('Profiles', 'U') IS NOT NULL
	DROP TABLE Profiles
GO
CREATE TABLE Profiles
(
	ProfileID int PRIMARY KEY NOT NULL CHECK(ProfileID BETWEEN 1 AND 10),
	ProfileName nvarchar(40),
	ProfileAge int
);
GO

USE SocialNetworkDataBase2;
GO
IF OBJECT_ID('Profiles', 'U') IS NOT NULL
	DROP TABLE Profiles
GO
CREATE TABLE Profiles
(
	ProfileID int PRIMARY KEY NOT NULL CHECK(ProfileID BETWEEN 11 AND 20),
	ProfileName nvarchar(40),
	ProfileAge int
);
GO

--Sectioned view with triggers
USE SocialNetworkDataBase1;
--USE SocialNetworkDataBase2;
GO
IF OBJECT_ID ('MixedView') IS NOT NULL
	DROP VIEW MixedView
GO
CREATE VIEW MixedView AS
	SELECT *
	FROM SocialNetworkDataBase1.dbo.Profiles
	UNION ALL
	SELECT *
	FROM SocialNetworkDataBase2.dbo.Profiles
GO

DROP TRIGGER dbo.[InsertNigger]
GO
CREATE TRIGGER dbo.[InsertNigger]
	ON MixedView
	INSTEAD OF INSERT AS
	BEGIN
		INSERT INTO SocialNetworkDataBase1.dbo.Profiles SELECT * FROM inserted WHERE ProfileID BETWEEN 1 AND 10
		INSERT INTO SocialNetworkDataBase2.dbo.Profiles SELECT * FROM inserted WHERE ProfileID BETWEEN 11 AND 20
		IF (SELECT COUNT(*) FROM inserted WHERE ProfileID > 20) > 0
			PRINT 'Some values were not inserted'
	END;
GO

DROP TRIGGER dbo.[DeleteNigger]
GO
CREATE TRIGGER dbo.[DeleteNigger]
	ON MixedView
	INSTEAD OF DELETE AS
	BEGIN
		DECLARE @pID int;
		DECLARE @pName nvarchar(40);
		DECLARE @pAge int;
		DECLARE @cur CURSOR;
		SET @cur = CURSOR FOR
			SELECT * FROM deleted;
		OPEN @cur;
		FETCH NEXT FROM @cur INTO @pID, @pName, @pAge
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @pID BETWEEN 1 AND 10
				DELETE FROM SocialNetworkDataBase1.dbo.Profiles WHERE @pID = ProfileID
			ELSE IF @pID BETWEEN 11 AND 20
				DELETE FROM SocialNetworkDataBase2.dbo.Profiles WHERE @pID = ProfileID
			ELSE
				PRINT 'Doesn''t exist'
			FETCH NEXT FROM @cur INTO @pID, @pName, @pAge
		END;
		CLOSE @cur
		DEALLOCATE @cur
	END;
GO

DROP TRIGGER dbo.[UpdateNigger]
GO
CREATE TRIGGER dbo.[UpdateNigger]
	ON MixedView
	INSTEAD OF UPDATE AS
	BEGIN
		DECLARE @pID_delete int;
		DECLARE @pName_delete nvarchar(40);
		DECLARE @pAge_delete int;
		DECLARE @pID_insert int;
		DECLARE @pName_insert nvarchar(40);
		DECLARE @pAge_insert int;

		DECLARE @cur_delete CURSOR;
		SET @cur_delete = CURSOR FOR
			SELECT * FROM deleted;
		OPEN @cur_delete;

		DECLARE @cur_insert CURSOR;
		SET @cur_insert = CURSOR FOR
			SELECT * FROM inserted;
		OPEN @cur_insert;

		FETCH NEXT FROM @cur_delete INTO @pID_delete, @pName_delete, @pAge_delete
		FETCH NEXT FROM @cur_insert INTO @pID_insert, @pName_insert, @pAge_insert
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @pID_delete != @pID_insert BEGIN
				PRINT 'Changing ProfileID is not allowed'

				FETCH NEXT FROM @cur_delete INTO @pID_delete, @pName_delete, @pAge_delete
				FETCH NEXT FROM @cur_insert INTO @pID_insert, @pName_insert, @pAge_insert

				CONTINUE
			END

			--Updating profile
			IF @pID_delete BETWEEN 1 AND 10
			BEGIN
				UPDATE SocialNetworkDataBase1.dbo.Profiles SET ProfileName = @pName_insert WHERE ProfileID = @pID_delete
				UPDATE SocialNetworkDataBase1.dbo.Profiles SET ProfileAge = @pAge_insert WHERE ProfileID = @pID_delete
			END
			ELSE IF @pID_delete BETWEEN 11 AND 20
			BEGIN
				UPDATE SocialNetworkDataBase2.dbo.Profiles SET ProfileName = @pName_insert WHERE ProfileID = @pID_delete
				UPDATE SocialNetworkDataBase2.dbo.Profiles SET ProfileAge = @pAge_insert WHERE ProfileID = @pID_delete
			END

			FETCH NEXT FROM @cur_delete INTO @pID_delete, @pName_delete, @pAge_delete
			FETCH NEXT FROM @cur_insert INTO @pID_insert, @pName_insert, @pAge_insert
		END;
		CLOSE @cur_delete
		CLOSE @cur_insert
		DEALLOCATE @cur_delete
		DEALLOCATE @cur_insert
	END;
GO

USE SocialNetworkDataBase1;
--USE SocialNetworkDataBase2;
GO
INSERT INTO MixedView VALUES ( 1, 'Kate', 15)
INSERT INTO MixedView VALUES ( 2, 'Anna', 24)
INSERT INTO MixedView VALUES ( 3, 'John', 12)
INSERT INTO MixedView VALUES ( 4, 'Rain', 25)
INSERT INTO MixedView VALUES (15, 'Love', 37)
INSERT INTO MixedView VALUES (16, 'Hope', 28)
INSERT INTO MixedView VALUES (17, 'Alan', 45)
INSERT INTO MixedView VALUES (18, 'Serj', 43)
INSERT INTO MixedView VALUES (58, 'Bill', 20)

DELETE FROM MixedView WHERE ProfileName = 'Anna' OR ProfileName = 'Serj'
DELETE FROM MixedView

UPDATE MixedView SET ProfileAge = 19 WHERE ProfileName = 'Kate'
UPDATE MixedView SET ProfileID = 19 WHERE ProfileName = 'Kate'

SELECT * FROM MixedView
SELECT * FROM MixedView WHERE ProfileID BETWEEN 3 AND 17
SELECT * FROM SocialNetworkDataBase1.dbo.Profiles
SELECT * FROM SocialNetworkDataBase2.dbo.Profiles


/*
Без триггеров
В обоих базах создать представление

*/