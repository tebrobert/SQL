--Tables with vertical fragmentation
USE SocialNetworkDataBase1;
GO
IF OBJECT_ID('Profiles', 'U') IS NOT NULL
	DROP TABLE Profiles
GO
CREATE TABLE Profiles
(
	ProfileID int PRIMARY KEY NOT NULL ,--CHECK(ProfileID BETWEEN 1 AND 10),
	ProfileName nvarchar(40),
--	ProfileAge int
);
GO

USE SocialNetworkDataBase2;
GO
IF OBJECT_ID('Profiles', 'U') IS NOT NULL
	DROP TABLE Profiles
GO
CREATE TABLE Profiles
(
	ProfileID int PRIMARY KEY NOT NULL ,--CHECK(ProfileID BETWEEN 11 AND 20),
--	ProfileName nvarchar(40),
	ProfileAge int
);
GO

--Sectioned view with triggers
USE SocialNetworkDataBase1;
GO
IF OBJECT_ID ('MixedView') IS NOT NULL
	DROP VIEW MixedView
GO
CREATE VIEW MixedView AS
	SELECT p1.ProfileID, p1.ProfileName, p2.ProfileAge
	FROM SocialNetworkDataBase1.dbo.Profiles p1, SocialNetworkDataBase2.dbo.Profiles p2
	WHERE p1.ProfileID = p2.ProfileID
GO

IF OBJECT_ID ('dbo.[InsertNigger]', 'TR') IS NOT NULL
	DROP TRIGGER dbo.[InsertNigger]
GO
CREATE TRIGGER dbo.[InsertNigger]
	ON MixedView
	INSTEAD OF INSERT AS
	BEGIN
		INSERT INTO SocialNetworkDataBase1.dbo.Profiles SELECT ProfileID, ProfileName FROM inserted
		INSERT INTO SocialNetworkDataBase2.dbo.Profiles SELECT ProfileID, ProfileAge FROM inserted
	END;
GO

IF OBJECT_ID ('dbo.[DeleteNigger]', 'TR') IS NOT NULL
	DROP TRIGGER dbo.[DeleteNigger]
GO
CREATE TRIGGER dbo.[DeleteNigger]
	ON MixedView
	INSTEAD OF DELETE AS
	BEGIN
		DELETE FROM SocialNetworkDataBase1.dbo.Profiles WHERE ProfileID IN (SELECT ProfileID FROM deleted)
		DELETE FROM SocialNetworkDataBase2.dbo.Profiles WHERE ProfileID IN (SELECT ProfileID FROM deleted)
	END;
GO

IF OBJECT_ID ('dbo.[UpdateNigger]', 'TR') IS NOT NULL
	DROP TRIGGER dbo.[UpdateNigger]
GO
CREATE TRIGGER dbo.[UpdateNigger]
	ON MixedView
	INSTEAD OF UPDATE AS
	BEGIN
		IF UPDATE(ProfileID)
			RAISERROR('%s', 16, 1, 'Changing ProfileID is not allowed')
		ELSE
		BEGIN
			UPDATE SocialNetworkDataBase1.dbo.Profiles SET ProfileName = i.ProfileName FROM inserted i WHERE Profiles.ProfileID = i.ProfileID
			UPDATE SocialNetworkDataBase2.dbo.Profiles SET ProfileAge = i.ProfileAge FROM inserted i WHERE Profiles.ProfileID = i.ProfileID
		END
	END;
GO

INSERT INTO MixedView VALUES ( 1, 'Kate', 15)
INSERT INTO MixedView VALUES ('Kate', 15)
INSERT INTO MixedView VALUES ('Anna', 15)
INSERT INTO MixedView VALUES ('Serj', 15)
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

-- identity
