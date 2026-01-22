USE master;
GO

-- Import secondary certificate
IF NOT EXISTS (SELECT * FROM sys. certificates WHERE name = 'AG_Cert_Secondary')
    CREATE CERTIFICATE AG_Cert_Secondary
        AUTHORIZATION AG_User
        FROM FILE = '/var/opt/mssql/secondary_cert.cer'
        WITH PRIVATE KEY (
            FILE = '/var/opt/mssql/secondary_cert.pvk',
            DECRYPTION BY PASSWORD = 'CertPassword123!'
        );
GO

GRANT CONNECT ON ENDPOINT:: AG_Endpoint TO AG_Login;
GO

-- Create the Availability Group
IF NOT EXISTS (SELECT * FROM sys.availability_groups WHERE name = 'TestAG')
    CREATE AVAILABILITY GROUP [TestAG]
    WITH (
        CLUSTER_TYPE = NONE,
        DB_FAILOVER = OFF,
        DTC_SUPPORT = NONE
    )
    FOR DATABASE TestAGDB
    REPLICA ON
        N'sqlserver-primary' WITH (
            ENDPOINT_URL = N'TCP://sqlserver-primary:5022',
            AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
            FAILOVER_MODE = MANUAL,
            SEEDING_MODE = AUTOMATIC,
            SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
        ),
        N'sqlserver-secondary' WITH (
            ENDPOINT_URL = N'TCP://sqlserver-secondary:5022',
            AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
            FAILOVER_MODE = MANUAL,
            SEEDING_MODE = AUTOMATIC,
            SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
        );
GO

PRINT 'Availability Group created on primary.';
GO