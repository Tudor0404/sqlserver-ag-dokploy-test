USE master;
GO

-- Drop the Availability Group if it exists
-- This should be run on the PRIMARY replica
-- When the AG is dropped on primary, it's automatically removed from all replicas
IF EXISTS (SELECT * FROM sys.availability_groups WHERE name = 'TestAG')
BEGIN
    PRINT 'Dropping Availability Group [TestAG]...';
    DROP AVAILABILITY GROUP [TestAG];
    PRINT 'Availability Group dropped successfully.';
END
ELSE
BEGIN
    PRINT 'Availability Group [TestAG] does not exist. Nothing to drop.';
END
GO

-- Wait a moment for the drop to complete
WAITFOR DELAY '00:00:02';
GO

PRINT 'Cleanup complete. Ready to recreate Availability Group.';
GO
