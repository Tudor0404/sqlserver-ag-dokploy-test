USE master;
GO

-- Join the Availability Group
ALTER AVAILABILITY GROUP [TestAG] JOIN WITH (CLUSTER_TYPE = NONE);
GO

-- Grant create database permission for automatic seeding
ALTER AVAILABILITY GROUP [TestAG] GRANT CREATE ANY DATABASE;
GO

PRINT 'Secondary joined the Availability Group.';
GO