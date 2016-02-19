USE SocialNetwork;
GO

--
IF OBJECT_ID ('dbo.[IndexedView]') IS NOT NULL
	DROP VIEW dbo.[IndexedView]
GO
IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
IF OBJECT_ID('dbo.Configs', 'U') IS NOT NULL
	DROP TABLE dbo.Configs;
GO


-- Таблица с автоинкрементным первичным ключом
IF OBJECT_ID('dbo.Profiles', 'U') IS NOT NULL
	DROP TABLE dbo.Profiles;
GO
CREATE TABLE Profiles(
	ProfileID int IDENTITY PRIMARY KEY,
	ProfileName nvarchar(40),
    ProfileAge int
);
GO

-- Значение DEFAULT
ALTER TABLE Profiles
ADD ProfileCountry nvarchar(40)
    CONSTRAINT ProfileCountry DEFAULT('Russia');
GO

-- Проверка CHECK
ALTER TABLE Profiles
ADD CONSTRAINT ageCheck
    CHECK (ProfileAge >= 14);
GO

-- Функция вычисления
INSERT INTO Profiles VALUES ('Alexandr', 13, 'Russia');
INSERT INTO Profiles VALUES ('Kate', 2, 'Russia');
INSERT INTO Profiles VALUES ('Ivan', 1, 'Russia');
INSERT INTO Profiles VALUES ('Shane', 32, 'USA');
INSERT INTO Profiles VALUES ('John', 24, 'USA');
INSERT INTO Profiles VALUES ('Xian', 20, 'China');
INSERT INTO Profiles (ProfileName, ProfileAge) VALUES ('Anna', 24);
GO

-- Таблица с первичным ключом на основе глобального уникального идентификатора
IF OBJECT_ID('dbo.Configs', 'U') IS NOT NULL
	DROP TABLE dbo.Configs;
GO
CREATE TABLE Configs(
	ConfigID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
	ConfigLang nvarchar(3)
);

INSERT INTO Configs (ConfigLang) VALUES ('Eng');
INSERT INTO Configs VALUES (NEWID(), 'Rus');

-- Таблица с первичным ключом на основе последовательности
IF OBJECT_ID('dbo.Communities', 'U') IS NOT NULL
	DROP TABLE dbo.Communities;
GO
CREATE TABLE Communities(
	CommunityID int PRIMARY KEY,
    CommunityName nvarchar(50)
);
GO

DROP SEQUENCE ordSeq;
GO
CREATE SEQUENCE ordSeq
	START WITH 0
	INCREMENT BY 1;
GO 

INSERT INTO Communities VALUES (NEXT VALUE FOR ordSeq, 'The Beatles Fan Community'); 
INSERT INTO Communities VALUES (NEXT VALUE FOR ordSeq, 'Bussiness Community'); 

-- Две связанные таблицы
-- варианты действий для ограничений ссылочной целостности (NO ACTION | CASCADE | SET NULL | SET DEFAULT).
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
	ProfileName nvarchar(40) NOT NULL,
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

DELETE FROM Configs WHERE ConfigFont = '8';
