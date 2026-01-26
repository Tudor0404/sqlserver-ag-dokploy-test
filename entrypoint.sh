#!/bin/bash
set -e

SA_PASSWORD="${MSSQL_SA_PASSWORD}"
CERTS_DIR="/certs"

# Function to run SQL commands
run_sql() {
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -Q "$1"
}

run_sql_file() {
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -i "$1"
}

# Function to wait for SQL Server to be ready
wait_for_sql() {
    echo "Waiting for SQL Server to start..."
    for i in {1..60}; do
        if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -Q "SELECT 1" &>/dev/null; then
            echo "SQL Server is ready!"
            return 0
        fi
        echo "Attempt $i/60 - SQL Server not ready yet..."
        sleep 2
    done
    echo "SQL Server failed to start!"
    return 1
}

# Function to wait for a file to exist
wait_for_file() {
    local file=$1
    local max_attempts=${2:-120}
    echo "Waiting for file: $file"
    for i in $(seq 1 $max_attempts); do
        if [ -f "$file" ]; then
            echo "File found: $file"
            return 0
        fi
        sleep 2
    done
    echo "Timeout waiting for file: $file"
    return 1
}

# Function to wait for remote SQL Server
wait_for_remote_sql() {
    local host=$1
    echo "Waiting for $host to be ready..."
    for i in {1..60}; do
        if /opt/mssql-tools18/bin/sqlcmd -S "$host" -U sa -P "$SA_PASSWORD" -C -Q "SELECT 1" &>/dev/null; then
            echo "$host is ready!"
            return 0
        fi
        sleep 2
    done
    echo "$host failed to respond!"
    return 1
}

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQL_PID=$!

# Wait for SQL Server to be ready
wait_for_sql

if [ "$NODE_ROLE" = "primary" ]; then
    echo "=== Configuring PRIMARY node ==="

    # Clean up old certificate files if they exist
    rm -f /var/opt/mssql/ag_cert.cer /var/opt/mssql/ag_cert.pvk

    # Run primary setup
    run_sql_file /scripts/01_primary_setup.sql

    # Export certificates to shared volume
    cp /var/opt/mssql/ag_cert.cer "$CERTS_DIR/primary_cert.cer"
    cp /var/opt/mssql/ag_cert.pvk "$CERTS_DIR/primary_cert.pvk"

    # Signal that primary certs are ready
    touch "$CERTS_DIR/primary_ready"
    echo "Primary certificates exported."

    # Wait for secondary certificates
    wait_for_file "$CERTS_DIR/secondary_ready"

    # Copy secondary certs locally
    cp "$CERTS_DIR/secondary_cert.cer" /var/opt/mssql/
    cp "$CERTS_DIR/secondary_cert.pvk" /var/opt/mssql/

    # Clean up existing AG if present (to allow reconfiguration)
    echo "Running AG cleanup..."
    run_sql_file /scripts/00_cleanup_ag.sql

    # Complete AG setup on primary
    run_sql_file /scripts/02_primary_create_ag.sql

    # Signal AG is created
    touch "$CERTS_DIR/ag_created"
    echo "=== PRIMARY setup complete ==="

elif [ "$NODE_ROLE" = "secondary" ]; then
    echo "=== Configuring SECONDARY node ==="

    # Wait for primary to be ready first
    wait_for_remote_sql "sqlserver-primary"

    # Clean up old certificate files if they exist
    rm -f /var/opt/mssql/ag_cert_secondary.cer /var/opt/mssql/ag_cert_secondary.pvk

    # Run secondary setup
    run_sql_file /scripts/01_secondary_setup.sql

    # Export certificates to shared volume
    cp /var/opt/mssql/ag_cert_secondary.cer "$CERTS_DIR/secondary_cert.cer"
    cp /var/opt/mssql/ag_cert_secondary.pvk "$CERTS_DIR/secondary_cert.pvk"

    # Signal that secondary certs are ready
    touch "$CERTS_DIR/secondary_ready"
    echo "Secondary certificates exported."

    # Wait for primary certificates
    wait_for_file "$CERTS_DIR/primary_ready"

    # Copy primary certs locally
    cp "$CERTS_DIR/primary_cert.cer" /var/opt/mssql/ag_cert.cer
    cp "$CERTS_DIR/primary_cert.pvk" /var/opt/mssql/ag_cert.pvk

    # Import primary certificate
    run_sql_file /scripts/02_secondary_import_cert.sql

    # Wait for AG to be created on primary
    wait_for_file "$CERTS_DIR/ag_created"

    # Join the AG
    run_sql_file /scripts/03_secondary_join_ag.sql

    echo "=== SECONDARY setup complete ==="
fi

echo "=== SQL Server AG node is running ==="

# Keep container running
wait $SQL_PID