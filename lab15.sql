--Creating manually linked tables
USE SocialNetworkDataBase1
GO
IF OBJECT_ID ('dbo.[MixedView]') IS NOT NULL
	DROP VIEW [MixedView]
GO
IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
USE SocialNetworkDataBase2
GO
IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
IF OBJECT_ID('dbo.Configs', 'U') IS NOT NULL
	DROP TABLE dbo.Configs;
GO

USE SocialNetworkDataBase2
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

USE SocialNetworkDataBase1
GO
IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
CREATE TABLE Profiles(
	ProfileID int IDENTITY PRIMARY KEY,
	ProfileName nvarchar(40) ,--NOT NULL,
    ProfileAge int,
	ProfileCountry nvarchar(40) ,--DEFAULT 'Russia',
	ConfigID int DEFAULT 1 NOT NULL
);
GO


INSERT INTO Profiles VALUES ('Alexandr', 20, 'Russia', 5);
INSERT INTO Profiles VALUES ('Kate', 28, 'Russia', 1);
INSERT INTO Profiles VALUES ('Ivan', 19, 'Russia', 2);
INSERT INTO Profiles VALUES ('Shane', 17, 'USA', 3);
INSERT INTO Profiles VALUES ('John', 24, 'USA', 4);
INSERT INTO Profiles VALUES ('Xian', 20, 'China', 5);
INSERT INTO Profiles (ProfileName, ProfileAge) VALUES ('Anna', 24);

--Triggers for manual linking tables
USE SocialNetworkDataBase1
GO
IF OBJECT_ID ('dbo.[InsertProfilesNigger]', 'TR') IS NOT NULL
	DROP TRIGGER [InsertProfilesNigger]
GO
CREATE TRIGGER dbo.[InsertProfilesNigger]
	ON Profiles
	INSTEAD OF INSERT AS
    BEGIN
        IF (
            (SELECT COUNT(*) FROM inserted AS i
                                 INNER JOIN SocialNetworkDataBase2.dbo.Configs AS c
                                 ON i.ConfigID = c.ConfigID)
            !=
            (SELECT COUNT(*) FROM inserted)
        )
            RAISERROR('%s', 16, 1, 'Config doesn''t exist')
        ELSE
        BEGIN
            INSERT INTO Profiles SELECT ProfileName, ProfileAge, ProfileCountry, ConfigID FROM inserted

            UPDATE Profiles SET ConfigID = DEFAULT WHERE ConfigID IS NULL
        END
    END;
GO


USE SocialNetworkDataBase1
GO
IF OBJECT_ID ('dbo.[DeleteProfilesNigger]', 'TR') IS NOT NULL
	DROP TRIGGER [DeleteProfilesNigger]
GO
CREATE TRIGGER dbo.[DeleteProfilesNigger]
    ON Profiles
    INSTEAD OF DELETE AS
    BEGIN
        IF (SELECT COUNT(*) FROM deleted WHERE ProfileID BETWEEN 1 AND 7) > 0
            RAISERROR('%s', 16, 1, 'Deleting users 1, ..., 7 is forbidden')
        ELSE
            DELETE FROM Profiles WHERE ProfileID IN (SELECT ProfileID FROM deleted)
    END
GO


USE SocialNetworkDataBase1
GO
IF OBJECT_ID ('dbo.[UpdateProfilesNigger]', 'TR') IS NOT NULL
    DROP TRIGGER [UpdateProfilesNigger]
GO
CREATE TRIGGER dbo.[UpdateProfilesNigger]
    ON Profiles
    INSTEAD OF UPDATE AS
    BEGIN
        IF UPDATE(ProfileID)
            RAISERROR('%s', 16, 1, 'Changing ProfileID is forbidden')
        ELSE IF (
            (SELECT COUNT(*) FROM inserted AS i
                                 INNER JOIN SocialNetworkDataBase2.dbo.Configs AS c
                                 ON i.ConfigID = c.ConfigID)
            !=
            (SELECT COUNT(*) FROM inserted)
        )
            RAISERROR('%s', 16, 1, 'Config doesn''t exist')
        ELSE BEGIN
			UPDATE Profiles
                SET ProfileName     = i.ProfileName,
                    ProfileAge      = i.ProfileAge,
                    ProfileCountry  = i.ProfileCountry,
                    ConfigID        = i.ConfigID
                FROM inserted i
                WHERE Profiles.ProfileID = i.ProfileID

            UPDATE Profiles SET ConfigID = DEFAULT WHERE ConfigID IS NULL
        END
    END
GO


USE SocialNetworkDataBase2
GO
IF OBJECT_ID ('dbo.[InsertConfigsNigger]', 'TR') IS NOT NULL
    DROP TRIGGER [InsertConfigsNigger]
GO
CREATE TRIGGER dbo.[InsertConfigsNigger]
    ON Configs
    INSTEAD OF INSERT AS
    BEGIN
        INSERT INTO Configs SELECT ConfigLang, ConfigTheme, ConfigFont FROM inserted
        UPDATE Configs SET ConfigLang   = DEFAULT	WHERE ConfigLang    IS NULL
        UPDATE Configs SET ConfigTheme  = DEFAULT	WHERE ConfigTheme   IS NULL
        UPDATE Configs SET ConfigFont   = DEFAULT	WHERE ConfigFont    IS NULL
    END
GO

USE SocialNetworkDataBase2
GO
IF OBJECT_ID ('dbo.[DeleteConfigsNigger]', 'TR') IS NOT NULL
    DROP TRIGGER [DeleteConfigsNigger]
GO
CREATE TRIGGER dbo.[DeleteConfigsNigger]
    ON Configs
    INSTEAD OF DELETE AS
    BEGIN
		DECLARE @s nvarchar(40)
		SELECT @s = COLUMN_DEFAULT FROM SocialNetworkDataBase1.INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='ConfigID'
		DECLARE @k int
		SET @k = CAST(SUBSTRING(@s, 3, len(@s) - 4) AS int)
		
        IF (SELECT COUNT(*) FROM deleted WHERE ConfigID = @k) > 0
            RAISERROR('%s', 16, 1, 'Deleting configuration 1 is forbidden')
        ELSE BEGIN
            UPDATE SocialNetworkDataBase1.dbo.Profiles SET ConfigID = DEFAULT
                WHERE ConfigID IN (SELECT ConfigID FROM deleted)
            DELETE FROM Configs WHERE ConfigID IN (SELECT ConfigID FROM deleted)
        END
    END
GO

USE SocialNetworkDataBase2
GO
IF OBJECT_ID ('dbo.[UpdateConfigsNigger]', 'TR') IS NOT NULL
    DROP TRIGGER [UpdateConfigsNigger]
GO
CREATE TRIGGER dbo.[UpdateConfigsNigger]
    ON Configs
    INSTEAD OF UPDATE AS
    BEGIN
		DECLARE @s nvarchar(40)
		SELECT @s = COLUMN_DEFAULT FROM SocialNetworkDataBase1.INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='ConfigID'
		DECLARE @k int
		SET @k = CAST(SUBSTRING(@s, 3, len(@s) - 4) AS int)

        IF UPDATE(ConfigID)
			RAISERROR('%s', 16, 1, 'Changing ConfigID is forbidden')
        ELSE IF (SELECT COUNT(*) FROM deleted WHERE ConfigID = @k) > 0
			RAISERROR('%s', 16, 1, 'Changing configuration 1 is forbidden')
        ELSE
            UPDATE Configs
                SET ConfigLang  = i.ConfigLang,
                    ConfigTheme = i.ConfigTheme,
                    ConfigFont  = i.ConfigFont
                FROM inserted i
                WHERE Configs.ConfigID = i.ConfigID
    END
GO

--Testing
USE SocialNetworkDataBase1
GO
IF OBJECT_ID ('dbo.[MixedView]') IS NOT NULL
    DROP VIEW [MixedView]
GO
CREATE VIEW [MixedView]  AS
    SELECT 
        p.ProfileID, p.ProfileName, p.ProfileAge, c.ConfigLang, c.ConfigTheme
    FROM
        SocialNetworkDataBase1.dbo.[Profiles] p INNER JOIN SocialNetworkDataBase2.dbo.[Configs] c
    ON
        c.ConfigID = p.ConfigID
GO


USE SocialNetworkDataBase1
GO
SELECT * FROM MixedView

SELECT * FROM SocialNetworkDataBase1.dbo.Profiles
SELECT * FROM SocialNetworkDataBase2.dbo.Configs
INSERT INTO SocialNetworkDataBase1.dbo.Profiles VALUES ('ROGER', 100, 'USA', 2);
INSERT INTO SocialNetworkDataBase1.dbo.Profiles (ProfileName) VALUES ('ROGER');
INSERT INTO SocialNetworkDataBase1.dbo.Profiles (ProfileName, ConfigID) VALUES ('ROGER', 100);
INSERT INTO SocialNetworkDataBase1.dbo.Profiles (ProfileName, ConfigID) VALUES ('ROGER', 2);
DELETE FROM SocialNetworkDataBase1.dbo.Profiles WHERE ProfileName='ROGER';
DELETE FROM SocialNetworkDataBase1.dbo.Profiles WHERE ConfigID=2;
DELETE FROM SocialNetworkDataBase1.dbo.Profiles WHERE ProfileID=1;
UPDATE SocialNetworkDataBase1.dbo.Profiles SET ProfileCountry='USA' WHERE ProfileID=3;
UPDATE SocialNetworkDataBase1.dbo.Profiles SET ConfigID=100 WHERE ProfileName='ROGER';

SELECT * FROM SocialNetworkDataBase1.dbo.Profiles
SELECT * FROM SocialNetworkDataBase2.dbo.Configs
DELETE FROM SocialNetworkDataBase2.dbo.Configs WHERE ConfigID=5
DELETE FROM SocialNetworkDataBase2.dbo.Configs WHERE ConfigID=2
DELETE FROM SocialNetworkDataBase2.dbo.Configs WHERE ConfigID=1
INSERT INTO SocialNetworkDataBase2.dbo.Configs (ConfigLang) VALUES (NULL)
INSERT INTO SocialNetworkDataBase2.dbo.Configs (ConfigLang) VALUES ('Eng')
INSERT INTO SocialNetworkDataBase2.dbo.Configs (ConfigLang, ConfigTheme, ConfigFont) VALUES ('Eng', 'Dark', 8)
UPDATE SocialNetworkDataBase2.dbo.Configs SET ConfigTheme='Snowwhite' WHERE ConfigID <= 2
UPDATE SocialNetworkDataBase2.dbo.Configs SET ConfigFont=22 WHERE ConfigLang = 'Ger'
