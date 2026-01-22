USE master;
GO

-- Create master key
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrong! Passw0rd';
GO

-- Create certificate
IF NOT EXISTS (SELECT * FROM sys. certificates WHERE name = 'AG_Cert')
    CREATE CERTIFICATE AG_Cert WITH SUBJECT = 'AG Certificate for Primary';
GO

-- Backup certificate
BACKUP CERTIFICATE AG_Cert
TO FILE = '/var/opt/mssql/ag_cert. cer'
WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/ag_cert.pvk',
    ENCRYPTION BY PASSWORD = 'CertPassword123!'
);
GO

-- Create endpoint
IF NOT EXISTS (SELECT * FROM sys.endpoints WHERE name = 'AG_Endpoint')
    CREATE ENDPOINT AG_Endpoint
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (
            AUTHENTICATION = CERTIFICATE AG_Cert,
            ROLE = ALL,
            ENCRYPTION = REQUIRED ALGORITHM AES
        );
GO

-- Create login
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'AG_Login')
    CREATE LOGIN AG_Login WITH PASSWORD = 'AGLoginPassword123!';
GO

IF NOT EXISTS (SELECT * FROM sys. database_principals WHERE name = 'AG_User')
    CREATE USER AG_User FOR LOGIN AG_Login;
GO

-- Create test database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TestAGDB')
BEGIN
    CREATE DATABASE TestAGDB;
END
GO

USE TestAGDB;
GO

IF NOT EXISTS (SELECT * FROM sys. tables WHERE name = 'TestTable')
BEGIN
CREATE TABLE TestTable (
                           ID INT PRIMARY KEY IDENTITY(1,1),
                           Name NVARCHAR(100),
                           CreatedDate DATETIME DEFAULT GETDATE()
);
INSERT INTO TestTable (Name) VALUES ('Test Record 1'), ('Test Record 2');
END
GO

-- Backup database (required for AG)
BACKUP DATABASE TestAGDB TO DISK = '/var/opt/mssql/TestAGDB.bak' WITH FORMAT, INIT;
BACKUP LOG TestAGDB TO DISK = '/var/opt/mssql/TestAGDB_log.trn' WITH FORMAT, INIT;
GO

PRINT 'Primary initial setup complete. ';
GO