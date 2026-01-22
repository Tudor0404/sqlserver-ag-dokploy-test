USE master;
GO

-- Create master key
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrong!Passw0rd';
GO

-- Create certificate
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'AG_Cert_Secondary')
    CREATE CERTIFICATE AG_Cert_Secondary WITH SUBJECT = 'AG Certificate for Secondary';
GO

-- Backup certificate
BACKUP CERTIFICATE AG_Cert_Secondary
TO FILE = '/var/opt/mssql/ag_cert_secondary.cer'
WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/ag_cert_secondary.pvk',
    ENCRYPTION BY PASSWORD = 'CertPassword123!'
);
GO

-- Create endpoint
IF NOT EXISTS (SELECT * FROM sys.endpoints WHERE name = 'AG_Endpoint')
    CREATE ENDPOINT AG_Endpoint
        STATE = STARTED
        AS TCP (LISTENER_PORT = 5022)
        FOR DATABASE_MIRRORING (
            AUTHENTICATION = CERTIFICATE AG_Cert_Secondary,
            ROLE = ALL,
            ENCRYPTION = REQUIRED ALGORITHM AES
        );
GO

-- Create login
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'AG_Login')
    CREATE LOGIN AG_Login WITH PASSWORD = 'AGLoginPassword123!';
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AG_User')
    CREATE USER AG_User FOR LOGIN AG_Login;
GO

PRINT 'Secondary initial setup complete. ';
GO