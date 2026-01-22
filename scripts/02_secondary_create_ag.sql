USE master;
GO

-- Import primary certificate
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'AG_Cert')
    CREATE CERTIFICATE AG_Cert
        AUTHORIZATION AG_User
        FROM FILE = '/var/opt/mssql/ag_cert.cer'
        WITH PRIVATE KEY (
            FILE = '/var/opt/mssql/ag_cert.pvk',
            DECRYPTION BY PASSWORD = 'CertPassword123!'
        );
GO

GRANT CONNECT ON ENDPOINT::AG_Endpoint TO AG_Login;
GO

PRINT 'Primary certificate imported on secondary.';
GO