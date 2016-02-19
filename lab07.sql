USE SocialNetwork;
GO

-- Создать представление на основе одной из таблиц задания 6.
IF OBJECT_ID ('dbo.[ViewOne]', 'V') IS NOT NULL
	DROP VIEW [ViewOne]
GO
CREATE VIEW [ViewOne] AS
	SELECT p.ProfileID, p.ProfileName, p.ProfileAge
	FROM [Profiles] p
	WHERE ProfileAge > 23
	WITH CHECK OPTION;
GO

-- Создать представление на основе полей обеих связанных таблиц задания 6.
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

-- Создать индекс для одной из таблиц задания 6, включив в него дополнительные неключевые поля.
CREATE NONCLUSTERED INDEX IndexOne
	ON dbo.[Communities] (CommunityID)
	INCLUDE (CommunityName);
GO

-- Создать индексированное представление.
IF OBJECT_ID ('dbo.[IndexedView]') IS NOT NULL
	DROP VIEW dbo.[IndexedView]
GO
CREATE VIEW [IndexedView] WITH SCHEMABINDING AS --Привязка к схеме (обязательно)
	SELECT ProfileID, ProfileName, ProfileAge
	FROM dbo.[Profiles]
	WITH CHECK OPTION;
GO
CREATE UNIQUE CLUSTERED INDEX ClIndex
	ON dbo.[IndexedView] (ProfileName);
GO

--
DROP INDEX IndexOne ON dbo.[Communities];

IF OBJECT_ID ('dbo.[ViewOne]', 'V') IS NOT NULL
	DROP VIEW [ViewOne]
GO
IF OBJECT_ID ('dbo.[ViewTwo]') IS NOT NULL
	DROP VIEW [ViewTwo]
GO
IF OBJECT_ID ('dbo.[IndexedView]') IS NOT NULL
	DROP VIEW dbo.[IndexedView]
GO



--
SELECT * FROM dbo.ViewOne
DELETE FROM dbo.ViewOne WHERE ProfileName='ROGER';
INSERT INTO dbo.ViewOne (ProfileName, ProfileAge) VALUES ('ROGER', 66666);
INSERT INTO dbo.ViewOne (ProfileName, ProfileAge) VALUES ('ROGER', 20);
UPDATE dbo.ViewOne SET ProfileAge = 66666 WHERE ProfileName = 'ROGER';
UPDATE dbo.ViewOne SET ProfileAge = 20 WHERE ProfileName = 'ROGER';

SELECT * FROM dbo.Profiles
DELETE FROM dbo.Profiles WHERE ProfileName='ROGER';
INSERT INTO dbo.Profiles (ProfileName, ProfileAge) VALUES ('ROGER', 66666);
INSERT INTO dbo.Profiles (ProfileName, ProfileAge) VALUES ('ROGER', 20);
UPDATE dbo.Profiles SET ProfileAge = 66666 WHERE ProfileName = 'ROGER';
UPDATE dbo.Profiles SET ProfileAge = 20 WHERE ProfileName = 'ROGER';
