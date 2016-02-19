/*
Бизнес-логика (как всё задумывалось)

1. Через представление можно добавить профиль, нельзя задавать ProfileID
2. Имя в профиле, возраст и страна могут быть не заданы (пользователь имеет право скрыть эти данные от создателей базы)
3. Каждый профиль содержит ссылку на какой-то конфиг
4. Конфигурационный файл у профиля задан всегда, по умолчанию 1
5. Если меняется через представление язык или тема конфига у профия, то ищется подходящий, а если не находится, то создаётся новый с шрифтом по умолчанию 14
6. Если добавляется новый профиль, то сначала ищется для него подходящий конфиг, в случае ненахождения создаётся новый
7. Если удаляем профили через представление, то конфиги остаются в базе
8. Первых семь пользователей удалить нельзя
*/



--Creating tables and view
USE SocialNetwork
GO
IF OBJECT_ID ('dbo.[ViewTwo]') IS NOT NULL
	DROP VIEW [ViewTwo]
GO
IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
IF OBJECT_ID('dbo.Configs', 'U') IS NOT NULL
	DROP TABLE dbo.Configs;
GO
CREATE TABLE Configs(
	ConfigID int IDENTITY PRIMARY KEY,
	ConfigLang nvarchar(3) DEFAULT 'Eng',
    ConfigTheme nvarchar(20) DEFAULT 'LightBlue',
    ConfigFont int DEFAULT 14
);
GO
INSERT INTO Configs (ConfigLang) VALUES ('Eng');
INSERT INTO Configs VALUES ('Rus', 'Red', 16);
INSERT INTO Configs VALUES ('Eng', 'Black', 16);
INSERT INTO Configs VALUES ('Eng', 'Yellow', 14);
INSERT INTO Configs VALUES ('Ger', 'Black', 8);

IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
CREATE TABLE Profiles(
	ProfileID int IDENTITY PRIMARY KEY,
	ProfileName nvarchar(40) ,--NOT NULL,
    ProfileAge int,
	ProfileCountry nvarchar(40) ,--DEFAULT 'Russia',
	ConfigID int DEFAULT 1 NOT NULL
	CONSTRAINT ProfileConfig FOREIGN KEY (ConfigID) REFERENCES Configs (ConfigID)
	--ON DELETE SET NULL
	ON DELETE SET DEFAULT
	--ON DELETE CASCADE
	--ON DELETE NO ACTION
);
GO


INSERT INTO Profiles VALUES ('Alexandr', 20, 'Russia', 5);
INSERT INTO Profiles VALUES ('Kate', 28, 'Russia', 1);
INSERT INTO Profiles VALUES ('Ivan', 19, 'Russia', 2);
INSERT INTO Profiles VALUES ('Shane', 17, 'USA', 3);
INSERT INTO Profiles VALUES ('John', 24, 'USA', 4);
INSERT INTO Profiles VALUES ('Xian', 20, 'China', 5);
INSERT INTO Profiles (ProfileName, ProfileAge) VALUES ('Anna', 24);


IF OBJECT_ID ('dbo.[ViewTwo]') IS NOT NULL
	DROP VIEW [ViewTwo]
GO
CREATE VIEW [ViewTwo]  AS
	SELECT 
		p.ProfileID, p.ProfileName, p.ProfileAge, c.ConfigLang, c.ConfigTheme
	FROM
		dbo.[Profiles] p INNER JOIN dbo.[Configs] c
	ON
		c.ConfigID = p.ConfigID
GO

--Simple triggers, one trigger with RAISERROR on some condition
--DROP TRIGGER dbo.[InsertNigger]
GO
CREATE TRIGGER dbo.[InsertNigger]
	ON Profiles
	AFTER INSERT AS
		PRINT 'Inserted'
GO

--DROP TRIGGER dbo.[UpdateNigger]
GO
CREATE TRIGGER dbo.[UpdateNigger]
	ON Profiles
	AFTER UPDATE AS
		PRINT 'Updated'
GO

--DROP TRIGGER dbo.[DeleteNigger]
GO
CREATE TRIGGER dbo.[DeleteNigger]
	ON Profiles
	INSTEAD OF DELETE AS
	BEGIN
		IF (SELECT COUNT(*) FROM deleted WHERE ProfileID<=7) > 0
			RAISERROR('%s', 16, 1, 'Deleting users 1, ..., 7 is forbidden')
		ELSE
			DELETE FROM Profiles
			WHERE ProfileID IN (SELECT ProfileID FROM deleted);
	END;
GO


--DELETE FROM dbo.ViewTwo;
--SELECT * FROM dbo.ViewTwo;
--DELETE FROM dbo.ViewTwo WHERE ProfileName='ROGER';
--INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge) VALUES ('ROGER', 66666);
--INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge) VALUES ('ROGER', 20);
--UPDATE dbo.ViewTwo SET ProfileAge = 66666 WHERE ProfileName = 'ROGER';
--UPDATE dbo.ViewTwo SET ProfileAge = 20 WHERE ProfileName = 'ROGER';

--DELETE FROM dbo.Profiles;
SELECT * FROM dbo.Profiles;
DELETE FROM dbo.Profiles WHERE ProfileName='ROGER';
INSERT INTO dbo.Profiles (ProfileName, ProfileAge) VALUES ('ROGER', 66666);
INSERT INTO dbo.Profiles (ProfileName, ProfileAge) VALUES ('ROGER', 20);
UPDATE dbo.Profiles SET ProfileAge = 66666 WHERE ProfileName = 'ROGER';
UPDATE dbo.Profiles SET ProfileAge = 20 WHERE ProfileName = 'ROGER';


--Advanced triggers for business logic
USE SocialNetwork
GO

DROP TRIGGER dbo.[InsertNigger]
GO
CREATE TRIGGER dbo.[InsertNigger]
	ON ViewTwo
	INSTEAD OF INSERT AS
	BEGIN
		DECLARE @pID int;
		DECLARE @pName nvarchar(40);
		DECLARE @pAge int;
		DECLARE @cLang nvarchar(40);
		DECLARE @cTheme nvarchar(40);
        
		DECLARE @cID nvarchar(40);
		
		DECLARE @cur CURSOR;
		SET @cur = CURSOR FOR
			SELECT * FROM inserted;
		OPEN @cur;
		FETCH NEXT FROM @cur INTO @pID, @pName, @pAge, @cLang, @cTheme
        
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @pID IS NOT NULL
				RAISERROR('%s', 16, 1, 'Declaring ProfileID is forbidden') --PRINT 'Declaring ProfileID is forbidden'
                
                
			ELSE BEGIN
				--Serching for or creating a config
				IF @cLang  IS NULL SET @cLang  = 'Eng'
				IF @cTheme IS NULL SET @cTheme = 'LightBlue'
				SELECT @cID = ConfigID
					FROM Configs
					WHERE @cLang = ConfigLang AND @cTheme = ConfigTheme
				IF @cID IS NULL BEGIN
					INSERT INTO dbo.Configs (ConfigLang, ConfigTheme) VALUES (@cLang, @cTheme)
					SET @cID = @@IDENTITY ---SELECT @cID = ConfigID
						---------------------FROM Configs         --@@scope_identity (лучше), @@identity
						---------------------WHERE @cLang = ConfigLang AND @cTheme = ConfigTheme
				END;
				
				--Creating a profile
				INSERT INTO dbo.Profiles (ProfileName, ProfileAge, ConfigID) VALUES (@pName, @pAge, @cID);
			END;
			FETCH NEXT FROM @cur INTO @pID, @pName, @pAge, @cLang, @cTheme
		END;
		CLOSE @cur
		DEALLOCATE @cur
	END;
GO

DROP TRIGGER dbo.[DeleteNigger]
GO
CREATE TRIGGER dbo.[DeleteNigger]
	ON ViewTwo
	INSTEAD OF DELETE AS
	BEGIN
		 -- DECLARE @pID int;
		 -- DECLARE @pName nvarchar(40);
		IF (SELECT COUNT(*) FROM deleted WHERE ProfileID<=7) > 0                        -- DECLARE @pAge int;
			RAISERROR('%s', 16, 1, 'Deleting users 1, ..., 7 is forbidden')	            -- DECLARE @cLang nvarchar(40);
		ELSE                                                                            -- DECLARE @cTheme nvarchar(40);
            DELETE FROM dbo.Profiles WHERE ProfileID IN (SELECT ProfileId FROM deleted) -- DECLARE @cur CURSOR;
        
		-- SET @cur = CURSOR FOR
			-- SELECT * FROM deleted;
		-- OPEN @cur;
		-- FETCH NEXT FROM @cur INTO @pID, @pName, @pAge, @cLang, @cTheme

		-- WHILE @@FETCH_STATUS = 0
		-- BEGIN
			-- IF @pID <= 7 PRINT 'Deleting users 1, ..., 7 is forbidden'
			-- ELSE BEGIN
				-- DELETE FROM dbo.Profiles WHERE ProfileID=@pID;
				-- PRINT 'User '+@pName+' deleted'
			-- END;

			-- FETCH NEXT FROM @cur INTO @pID, @pName, @pAge, @cLang, @cTheme
		-- END;
		-- CLOSE @cur
		-- DEALLOCATE @cur
	END;
GO

DROP TRIGGER dbo.[UpdateNigger]
GO
CREATE TRIGGER dbo.[UpdateNigger]
	ON ViewTwo
	INSTEAD OF UPDATE AS
	BEGIN
		DECLARE @pID_delete int;
		DECLARE @pName_delete nvarchar(40);
		DECLARE @pAge_delete int;
		DECLARE @cLang_delete nvarchar(40);
		DECLARE @cTheme_delete nvarchar(40);
		DECLARE @pID_insert int;
		DECLARE @pName_insert nvarchar(40);
		DECLARE @pAge_insert int;
		DECLARE @cLang_insert nvarchar(40);
		DECLARE @cTheme_insert nvarchar(40);
		DECLARE @cID int;

		DECLARE @cur_delete CURSOR;
		SET @cur_delete = CURSOR FOR
			SELECT * FROM deleted;
		OPEN @cur_delete;

		DECLARE @cur_insert CURSOR;
		SET @cur_insert = CURSOR FOR
			SELECT * FROM inserted;
		OPEN @cur_insert;

		FETCH NEXT FROM @cur_delete INTO @pID_delete, @pName_delete, @pAge_delete, @cLang_delete, @cTheme_delete
		FETCH NEXT FROM @cur_insert INTO @pID_insert, @pName_insert, @pAge_insert, @cLang_insert, @cTheme_insert
--		FETCH NEXT FROM @cur_delete
--		FETCH NEXT FROM @cur_insert
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @pID_delete != @pID_insert BEGIN
                RAISERROR('%s', 16, 1, 'Changing ProfileID is not allowed')
				CONTINUE
			END

			--Updating profile
			UPDATE dbo.Profiles SET ProfileName = @pName_insert WHERE ProfileID = @pID_delete
			UPDATE dbo.Profiles SET ProfileAge = @pAge_insert WHERE ProfileID = @pID_delete

			--Serching for or creating new config
			IF @cLang_insert  IS NULL SET @cLang_insert  = 'Eng'
			IF @cTheme_insert IS NULL SET @cTheme_insert = 'LightBlue'
--			PRINT '@cTheme_insert '+@cTheme_insert
			SELECT @cID = ConfigID
				FROM Configs
				WHERE @cLang_insert = ConfigLang AND @cTheme_insert = ConfigTheme
--			PRINT '@cID '+CAST(@cID AS nvarchar(40))
			IF @cID IS NULL BEGIN
				INSERT INTO dbo.Configs (ConfigLang, ConfigTheme) VALUES (@cLang_insert, @cTheme_insert)
                SET @cID = @@IDENTITY ---SELECT @cID = ConfigID
                    ---------------------FROM Configs         --@@scope_identity, @@identity
					---------------------WHERE @cLang = ConfigLang AND @cTheme = ConfigTheme
			END;
--			PRINT '@cID '+CAST(@cID AS nvarchar(40))
--			PRINT '@cTheme_insert '+@cTheme_insert

			--Updating profile
			UPDATE dbo.Profiles SET ConfigID = @cID WHERE ProfileID = @pID_delete
--			DELETE FROM dbo.ViewTwo WHERE @pID = ProfileID
--			INSERT INTO dbo.ViewTwo VALUES @pID = ProfileID
			FETCH NEXT FROM @cur_delete INTO @pID_delete, @pName_delete, @pAge_delete, @cLang_delete, @cTheme_delete
			FETCH NEXT FROM @cur_insert INTO @pID_insert, @pName_insert, @pAge_insert, @cLang_insert, @cTheme_insert
--			FETCH NEXT FROM @cur_delete
--			FETCH NEXT FROM @cur_insert
		END;
		CLOSE @cur_delete
		CLOSE @cur_insert
		DEALLOCATE @cur_delete
		DEALLOCATE @cur_insert
	END;
GO


--Testing
USE SocialNetwork
GO
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo

DELETE FROM dbo.ViewTwo WHERE ProfileName='ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
DELETE FROM dbo.ViewTwo WHERE ProfileName='MOLLY';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
--INSERT INTO dbo.ViewTwo VALUES (14, 'ROGER', 20, 'Fra', 'Black');
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge, ConfigLang, ConfigTheme) VALUES ('ROGER', 66666, 'Rus', 'Red'  );
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (             ProfileAge, ConfigLang, ConfigTheme) VALUES (         55555, 'Rus', 'Red'  );
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (ProfileName,             ConfigLang, ConfigTheme) VALUES ('MOLLY',        'Rus', 'Red'  );
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge,             ConfigTheme) VALUES ('ROGER', 44444,        'Black');
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge                         ) VALUES ('Kate',  33333                );
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge, ConfigLang, ConfigTheme) VALUES ('MOLLY', 22222, 'Rus', 'Black');
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
INSERT INTO dbo.ViewTwo (ProfileName, ProfileAge, ConfigLang, ConfigTheme) VALUES ('ROGER', 11111, 'Ger', 'White');
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
UPDATE dbo.ViewTwo SET ProfileAge = ProfileAge * 10 + 1 WHERE ProfileName = 'ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
UPDATE dbo.ViewTwo SET ProfileAge = 66666 WHERE ProfileName = 'ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
UPDATE dbo.ViewTwo SET ProfileAge = 20 WHERE ProfileName = 'ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
UPDATE dbo.ViewTwo SET ConfigTheme = 'Black' WHERE ProfileID = 7;------------------------------
SELECT * FROM Profiles
SELECT * FROM Configs
UPDATE dbo.ViewTwo SET ConfigTheme = 'Blue'      WHERE ProfileName = 'ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
UPDATE dbo.ViewTwo SET ConfigLang  = 'Eng'       WHERE ProfileName = 'ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo
UPDATE dbo.ViewTwo SET ConfigLang  = 'Rus'       WHERE ProfileName = 'ROGER';
SELECT * FROM Profiles
SELECT * FROM Configs
SELECT * FROM ViewTwo



DROP TRIGGER dbo.[InsertNigger]
GO
CREATE TRIGGER dbo.[InsertNigger]
	ON ViewTwo
	INSTEAD OF INSERT AS
	BEGIN
        INSERT INTO dbo.Profiles VALUES ((SELECT ProfileName FROM inserted))
	END;
GO
