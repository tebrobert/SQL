USE SocialNetwork
GO
IF OBJECT_ID('Table1') IS NOT NULL
	DROP TABLE Table1
GO
IF OBJECT_ID('Table2') IS NOT NULL
	DROP TABLE Table2
GO

CREATE TABLE Table1(
	ID int,
	ColA int
)

CREATE TABLE Table2(
	ColB int,
	ColC int
)

INSERT INTO Table1 VALUES (1, 2), (2, 2), (3, 4), (5, 7)
INSERT INTO Table2 VALUES (1, 4), (2, 5), (4, 8), (4, 10)

SELECT * FROM dbo.Table1 AS t1 LEFT JOIN dbo.Table2 AS t2
	ON t1.ColA = t2.ColB;
GO

SELECT * FROM dbo.Table1 AS t1 RIGHT JOIN dbo.Table2 AS t2
	ON t1.ColA = t2.ColB;
GO

SELECT * FROM dbo.Table1 AS t1 INNER JOIN dbo.Table2 AS t2
	ON t1.ColA = t2.ColB;
GO

SELECT * FROM dbo.Table1 AS t1 FULL OUTER JOIN dbo.Table2 AS t2
	ON t1.ColA = t2.ColB;
GO
