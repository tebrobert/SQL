USE master;
GO

-- Создание базы данных
IF DB_ID ('SocialNetwork') IS NOT NULL
	DROP DATABASE SocialNetwork;
GO
CREATE DATABASE SocialNetwork
    ON (NAME = SocialNetwork, FILENAME = 'E:\SQL\SocialNetwork.mdf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 1MB )
    LOG ON (NAME = SocialNetwork_Log, FILENAME = 'E:\SQL\SocialNetwork.ldf', SIZE = 1MB, MAXSIZE = 20MB, FILEGROWTH = 1MB )
GO

-- Создание таблицы
USE SocialNetwork;
GO
CREATE TABLE Profiles ( name nvarchar(40), id int, email nvarchar(40) );
GO

-- Добавление файловой группы и файла данных
USE master;
GO
ALTER DATABASE SocialNetwork
    ADD FILEGROUP FileGroup1;
GO
ALTER DATABASE SocialNetwork
    ADD FILE  ( NAME = File1, FILENAME = 'E:\SQL\fil1.ndf', SIZE = 5MB, MAXSIZE=25MB, FILEGROWTH = 1MB ) TO FILEGROUP FileGroup1;
GO

-- Изменение типа файловой группы на "по умолчанию"
ALTER  DATABASE SocialNetwork
MODIFY FILEGROUP FileGroup1 Default;
GO

-- Создание второй таблицы
USE SocialNetwork;
GO
CREATE TABLE NuTable ( name nvarchar(40), email nvarchar(40) );

-- Удаление файловой группы
ALTER DATABASE SocialNetwork
    MODIFY FILEGROUP [PRIMARY] Default;
DROP TABLE NuTable;
ALTER DATABASE SocialNetwork
    REMOVE FILE File1;
ALTER DATABASE SocialNetwork
    REMOVE FILEGROUP FileGroup1;
GO

-- Создание схемы, перемещение в неё таблицы, удаление схемы
CREATE SCHEMA NuSchema;
GO
ALTER SCHEMA NuSchema TRANSFER dbo.Profiles;
DROP TABLE NuSchema.Profiles;
DROP SCHEMA NuSchema;
GO
