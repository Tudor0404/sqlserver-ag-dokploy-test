FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    gnupg2 \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install SQL Server tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Add SQL tools to PATH
ENV PATH="$PATH:/opt/mssql-tools18/bin"

# Copy scripts
COPY entrypoint.sh /entrypoint.sh
COPY scripts/ /scripts/
RUN chmod +x /entrypoint.sh /scripts/*.sh 2>/dev/null || true

# Create certs directory with proper permissions
RUN mkdir -p /certs && chown -R mssql:mssql /certs

USER mssql

ENTRYPOINT ["/entrypoint.sh"]