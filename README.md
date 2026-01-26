# SQL Server Availability Group Setup

This project sets up a SQL Server Availability Group with two replicas (primary and secondary) using Docker.

## Configuration

### Backup Priority Settings

The Availability Group is configured with different backup priorities for each replica:

- **Primary replica (`sqlserver-primary`)**: Priority **70** (higher preference for backups)
- **Secondary replica (`sqlserver-secondary`)**: Priority **30** (lower preference for backups)

This configuration ensures that automated backup operations prefer the primary instance while still allowing backups on the secondary if needed.

## Deployment

### Start/Restart the Availability Group

```bash
docker-compose up -d
```

The containers will automatically:
1. Start SQL Server on both nodes
2. Create certificates and endpoints
3. Clean up any existing Availability Group configuration
4. Create the Availability Group with configured backup priorities
5. Join the secondary replica

**Note:** The AG is automatically dropped and recreated on startup, so any configuration changes (like backup priorities) will be applied when you restart the containers.

### Full Reset (Delete All Data)

```bash
docker-compose down -v
docker-compose up -d
```

This will delete all data volumes and start completely fresh.

## Verification

### Check Backup Priority Settings

Connect to either SQL Server instance and run:

```sql
SELECT
    ar.replica_server_name,
    ar.backup_priority,
    ar.availability_mode_desc,
    ar.failover_mode_desc
FROM sys.availability_replicas ar
INNER JOIN sys.availability_groups ag ON ar.group_id = ag.group_id
WHERE ag.name = 'TestAG';
```

Expected output:
- `sqlserver-primary`: `backup_priority = 70`
- `sqlserver-secondary`: `backup_priority = 30`

### Check AG Health

```sql
SELECT * FROM sys.dm_hadr_availability_group_states;
```

## Connection Strings

- **Primary:** `Server=localhost,1433;Database=TestAGDB;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;`
- **Secondary:** `Server=localhost,1434;Database=TestAGDB;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;`

## Scripts

- `scripts/00_cleanup_ag.sql` - Drops the existing Availability Group (runs automatically during deployment)
- `scripts/01_primary_setup.sql` - Initial setup for primary node
- `scripts/01_secondary_setup.sql` - Initial setup for secondary node
- `scripts/02_primary_create_ag.sql` - Creates the Availability Group with backup priorities
- `scripts/02_secondary_import_cert.sql` - Imports primary certificate on secondary
- `scripts/03_secondary_join_ag.sql` - Joins secondary to the AG

## Notes

- The cleanup script (`00_cleanup_ag.sql`) runs automatically on deployment to ensure the AG is created with the latest configuration
- Certificates and endpoints are preserved during cleanup - only the AG is dropped and recreated
- The test database (`TestAGDB`) is preserved and automatically re-added to the AG
