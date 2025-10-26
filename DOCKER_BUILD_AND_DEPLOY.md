# Docker Build and Production Deployment Guide

## Complete Guide to Building and Deploying Carbonio Mailbox with Docker

This guide shows you how to build Docker images and deploy Carbonio Mailbox in production mode.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Building Docker Images](#building-docker-images)
3. [Running with Docker Compose](#running-with-docker-compose)
4. [Environment Variables](#environment-variables)
5. [Production Deployment](#production-deployment)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

### TL;DR - Get Running in 3 Commands

```bash
# 1. Build images
docker-compose build

# 2. Start all services
docker-compose up -d

# 3. Check status
docker-compose ps
```

Access at: http://localhost:8080

---

## Building Docker Images

### Option 1: Build Manually

#### Build Mailbox Image

```bash
# From the carbonio-mailbox directory
docker build -f docker/mailbox/Dockerfile -t carbonio-mailbox:latest .
```

**What this does:**
- Uses multi-stage build (build + runtime)
- Stage 1: Compiles code with Maven
- Stage 2: Creates runtime container with JRE only
- Installs all dependencies
- Sets up CLI tools (zmprov, zmmailbox, zmgsautil)
- Downloads OpenTelemetry agent for tracing

**Build time:** ~10-15 minutes (first time)

#### Build MariaDB Image

```bash
docker build -f docker/mariadb/Dockerfile -t carbonio-mariadb:latest .
```

**What this does:**
- Based on mariadb:10.4
- Copies SQL initialization scripts
- Auto-creates zimbra and chat databases on first run
- Sets up zextras user with full permissions

**Build time:** ~1-2 minutes

### Option 2: Build with Docker Compose

See [Running with Docker Compose](#running-with-docker-compose) section below.

---

## Running with Docker Compose

### Step 1: Create docker-compose.yml

Create this file in the carbonio-mailbox directory:

```yaml
version: '3.8'

services:
  # OpenLDAP Directory Server
  openldap:
    image: osixia/openldap:1.5.0
    container_name: carbonio-ldap
    environment:
      LDAP_ORGANISATION: "Carbonio"
      LDAP_DOMAIN: "carbonio.local"
      LDAP_ADMIN_PASSWORD: "password"
      LDAP_CONFIG_PASSWORD: "qh6hWZvc"
      LDAP_TLS: "false"
    ports:
      - "1389:389"
      - "636:636"
    networks:
      - carbonio-net
    volumes:
      - ldap-data:/var/lib/ldap
      - ldap-config:/etc/ldap/slapd.d

  # MariaDB Database
  mariadb:
    build:
      context: .
      dockerfile: docker/mariadb/Dockerfile
    container_name: carbonio-mariadb
    environment:
      MARIADB_ROOT_PASSWORD: password
    ports:
      - "3306:3306"
    networks:
      - carbonio-net
    volumes:
      - mariadb-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-ppassword"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Carbonio Mailbox Service
  mailbox:
    build:
      context: .
      dockerfile: docker/mailbox/Dockerfile
    container_name: carbonio-mailbox
    hostname: mailbox.carbonio.local
    environment:
      # LDAP Configuration
      LDAP_URL: "ldap://openldap:389"
      LDAP_ROOT_PASSWORD: "qh6hWZvc"
      LDAP_ADMIN_PASSWORD: "password"

      # Database Configuration
      MARIADB_URL: "mariadb"
      MARIADB_PORT: "3306"
      MARIADB_ROOT_PASSWORD: "password"

      # Service URLs (optional - for full Carbonio stack)
      CARBONIO_FILES_SERVICE_URL: "http://carbonio-files:10000"
      CARBONIO_PREVIEW_SERVICE_URL: "http://carbonio-preview:10000"

      # Java Options
      MAILBOXD_JAVA_OPTS: "-Xss256k -Xms2048m -Xmx2048m"

      # Tracing (optional)
      # TRACING_OPTIONS: "-Dotel.service.name=carbonio-mailbox -Dotel.traces.exporter=zipkin -Dotel.exporter.zipkin.endpoint=http://zipkin:9411/api/v2/spans"
    ports:
      - "8080:8080"   # HTTP API
      - "7071:7071"   # Admin API
      - "8443:8443"   # HTTPS
      - "5005:5005"   # Debug port (JDWP)
    networks:
      - carbonio-net
    volumes:
      - mailbox-store:/opt/zextras/store
      - mailbox-index:/opt/zextras/index
      - mailbox-logs:/opt/zextras/log
    depends_on:
      mariadb:
        condition: service_healthy
      openldap:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/service/soap"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

networks:
  carbonio-net:
    driver: bridge

volumes:
  ldap-data:
  ldap-config:
  mariadb-data:
  mailbox-store:
  mailbox-index:
  mailbox-logs:
```

### Step 2: Start Services

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f mailbox

# Wait for services to be ready (takes ~2-3 minutes)
docker-compose ps
```

### Step 3: Verify Services

```bash
# Check all containers are running
docker-compose ps

# Should show:
# carbonio-ldap      running
# carbonio-mariadb   running (healthy)
# carbonio-mailbox   running (healthy)

# Check mailbox logs
docker-compose logs mailbox | grep "Server started"

# Test the API
curl http://localhost:8080/service/soap
# Should return: "empty request payload"
```

### Step 4: Create Test Account

```bash
# Enter mailbox container
docker-compose exec mailbox bash

# Create domain
zmprov createDomain test.com

# Create admin account
zmprov createAccount admin@test.com password zimbraIsAdminAccount TRUE

# Create user account
zmprov createAccount user@test.com password

# Exit container
exit
```

### Step 5: Test Authentication

```bash
# Test login
curl -X POST http://localhost:8080/service/soap \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <AuthRequest xmlns="urn:zimbraAccount">
      <account by="name">admin@test.com</account>
      <password>password</password>
    </AuthRequest>
  </soap:Body>
</soap:Envelope>'
```

You should get an auth token back!

---

## Environment Variables

### Mailbox Container Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LDAP_URL` | `ldap://openldap:389` | LDAP server URL |
| `LDAP_ROOT_PASSWORD` | `qh6hWZvc` | LDAP root password |
| `LDAP_ADMIN_PASSWORD` | `password` | LDAP admin (zimbra user) password |
| `MARIADB_URL` | `mariadb` | MariaDB hostname |
| `MARIADB_PORT` | `3306` | MariaDB port |
| `MARIADB_ROOT_PASSWORD` | `password` | MariaDB root password |
| `CARBONIO_FILES_SERVICE_URL` | `http://carbonio-files:10000` | Files service URL (optional) |
| `CARBONIO_PREVIEW_SERVICE_URL` | `http://carbonio-preview:10000` | Preview service URL (optional) |
| `MAILBOXD_JAVA_OPTS` | `-Xss256k -Xms1996m -Xmx1996m` | Java heap and stack settings |
| `TRACING_OPTIONS` | (empty) | OpenTelemetry tracing options |

### MariaDB Container Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MARIADB_ROOT_PASSWORD` | `password` | Root password for MariaDB |

### OpenLDAP Container Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LDAP_ORGANISATION` | `Carbonio` | Organization name |
| `LDAP_DOMAIN` | `carbonio.local` | LDAP domain |
| `LDAP_ADMIN_PASSWORD` | `password` | Admin password |
| `LDAP_CONFIG_PASSWORD` | `qh6hWZvc` | Config password |

---

## Production Deployment

### Production-Ready docker-compose.yml

For production, add these improvements:

```yaml
version: '3.8'

services:
  openldap:
    image: osixia/openldap:1.5.0
    restart: unless-stopped
    environment:
      LDAP_ORGANISATION: "YourCompany"
      LDAP_DOMAIN: "mail.yourdomain.com"
      LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
      LDAP_CONFIG_PASSWORD: "${LDAP_CONFIG_PASSWORD}"
      LDAP_TLS: "true"
      LDAP_TLS_CRT_FILENAME: "server.crt"
      LDAP_TLS_KEY_FILENAME: "server.key"
      LDAP_TLS_CA_CRT_FILENAME: "ca.crt"
    networks:
      - carbonio-net
    volumes:
      - ldap-data:/var/lib/ldap
      - ldap-config:/etc/ldap/slapd.d
      - ./certs:/container/service/slapd/assets/certs
    # Don't expose ports externally in production
    # Use internal network only

  mariadb:
    build:
      context: .
      dockerfile: docker/mariadb/Dockerfile
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: "${MARIADB_ROOT_PASSWORD}"
    networks:
      - carbonio-net
    volumes:
      - mariadb-data:/var/lib/mysql
      # Backup directory
      - ./backups:/backups
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-p${MARIADB_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
    # Don't expose port externally

  mailbox:
    build:
      context: .
      dockerfile: docker/mailbox/Dockerfile
    restart: unless-stopped
    hostname: mail.yourdomain.com
    environment:
      LDAP_URL: "ldaps://openldap:636"
      LDAP_ROOT_PASSWORD: "${LDAP_CONFIG_PASSWORD}"
      LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
      MARIADB_URL: "mariadb"
      MARIADB_PORT: "3306"
      MARIADB_ROOT_PASSWORD: "${MARIADB_ROOT_PASSWORD}"
      MAILBOXD_JAVA_OPTS: "-Xss256k -Xms4096m -Xmx4096m"
      # Enable tracing in production
      TRACING_OPTIONS: "-Dotel.service.name=carbonio-mailbox -Dotel.traces.exporter=otlp -Dotel.exporter.otlp.endpoint=http://otel-collector:4317"
    ports:
      - "8080:8080"
      - "7071:7071"
      - "8443:8443"
    networks:
      - carbonio-net
    volumes:
      - mailbox-store:/opt/zextras/store
      - mailbox-index:/opt/zextras/index
      - mailbox-logs:/opt/zextras/log
      # SSL certificates
      - ./certs:/opt/zextras/ssl
    depends_on:
      mariadb:
        condition: service_healthy
      openldap:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/service/soap"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 6G
        reservations:
          cpus: '2'
          memory: 4G

  # Reverse Proxy (NGINX)
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    networks:
      - carbonio-net
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - mailbox

networks:
  carbonio-net:
    driver: bridge

volumes:
  ldap-data:
    driver: local
  ldap-config:
    driver: local
  mariadb-data:
    driver: local
  mailbox-store:
    driver: local
  mailbox-index:
    driver: local
  mailbox-logs:
    driver: local
```

### Production Environment File

Create `.env` file:

```bash
# Database
MARIADB_ROOT_PASSWORD=your-secure-password-here

# LDAP
LDAP_ADMIN_PASSWORD=your-ldap-admin-password
LDAP_CONFIG_PASSWORD=your-ldap-config-password
```

**IMPORTANT:** Never commit `.env` to git!

```bash
# Add to .gitignore
echo ".env" >> .gitignore
```

### Production Checklist

Before deploying to production:

- [ ] Change all default passwords
- [ ] Enable SSL/TLS (LDAPS, HTTPS)
- [ ] Set up SSL certificates
- [ ] Configure reverse proxy (NGINX)
- [ ] Set up backups
- [ ] Configure monitoring
- [ ] Set resource limits
- [ ] Use secrets management (Docker Secrets or Vault)
- [ ] Enable logging to external system
- [ ] Set up health checks
- [ ] Configure firewall rules
- [ ] Set proper hostnames
- [ ] Enable OpenTelemetry tracing
- [ ] Test disaster recovery

---

## Advanced Configuration

### Enable OpenTelemetry Tracing

```yaml
mailbox:
  environment:
    TRACING_OPTIONS: >-
      -Dotel.service.name=carbonio-mailbox
      -Dotel.traces.exporter=zipkin
      -Dotel.exporter.zipkin.endpoint=http://zipkin:9411/api/v2/spans
      -Dotel.metrics.exporter=prometheus
      -Dotel.exporter.prometheus.port=9464
```

### Increase Memory for Production

```yaml
mailbox:
  environment:
    MAILBOXD_JAVA_OPTS: "-Xss256k -Xms8192m -Xmx8192m"
```

### Custom localconfig.xml

Mount your own configuration:

```yaml
mailbox:
  volumes:
    - ./my-localconfig.xml:/localconfig/localconfig.xml:ro
```

### Database Backups

```bash
# Backup script (run with cron)
docker-compose exec mariadb mysqldump -u root -p$MARIADB_ROOT_PASSWORD \
  --all-databases > backups/backup-$(date +%Y%m%d-%H%M%S).sql

# Restore
docker-compose exec -T mariadb mysql -u root -p$MARIADB_ROOT_PASSWORD \
  < backups/backup-20250126-120000.sql
```

---

## Useful Commands

### Manage Services

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart mailbox only
docker-compose restart mailbox

# View logs
docker-compose logs -f mailbox

# View all logs
docker-compose logs -f

# Check status
docker-compose ps
```

### Access Containers

```bash
# Enter mailbox container
docker-compose exec mailbox bash

# Enter MariaDB container
docker-compose exec mariadb bash

# Enter LDAP container
docker-compose exec openldap bash
```

### CLI Tools in Mailbox Container

```bash
# Provision commands
docker-compose exec mailbox zmprov help

# Create domain
docker-compose exec mailbox zmprov createDomain example.com

# Create account
docker-compose exec mailbox zmprov createAccount user@example.com password

# List all accounts
docker-compose exec mailbox zmprov getAllAccounts

# Mailbox utility
docker-compose exec mailbox zmmailbox help

# GAL sync utility
docker-compose exec mailbox zmgsautil help
```

### Database Access

```bash
# MySQL client
docker-compose exec mariadb mysql -u root -ppassword zimbra

# Show databases
docker-compose exec mariadb mysql -u root -ppassword -e "SHOW DATABASES;"

# Show tables
docker-compose exec mariadb mysql -u root -ppassword zimbra -e "SHOW TABLES;"
```

### Check Service Health

```bash
# Mailbox API
curl http://localhost:8080/service/soap

# Check ports
lsof -i :8080
lsof -i :7071
lsof -i :3306
lsof -i :1389

# Inside container
docker-compose exec mailbox netstat -tlnp
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs mailbox

# Common issues:
# 1. Database not ready - wait longer
# 2. LDAP connection failed - check openldap container
# 3. Port already in use - kill existing process
```

### Database Connection Failed

```bash
# Check MariaDB is running
docker-compose ps mariadb

# Check MariaDB logs
docker-compose logs mariadb

# Test connection
docker-compose exec mailbox mysql -h mariadb -u zextras -pzextras zimbra
```

### LDAP Connection Failed

```bash
# Check OpenLDAP is running
docker-compose ps openldap

# Check LDAP logs
docker-compose logs openldap

# Test LDAP connection
docker-compose exec mailbox ldapsearch -x -H ldap://openldap:389 -b "dc=carbonio,dc=local"
```

### Out of Memory

```bash
# Increase Java heap
# Edit docker-compose.yml:
MAILBOXD_JAVA_OPTS: "-Xss256k -Xms4096m -Xmx4096m"

# Restart
docker-compose restart mailbox
```

### Reset Everything

```bash
# Stop and remove all containers, networks, volumes
docker-compose down -v

# Remove images
docker-compose down -v --rmi all

# Start fresh
docker-compose up -d
```

### View Resource Usage

```bash
# All containers
docker stats

# Specific container
docker stats carbonio-mailbox
```

---

## Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| **Passwords** | Default (password) | Secure, from .env |
| **SSL/TLS** | Disabled | Enabled (LDAPS, HTTPS) |
| **Ports** | Exposed to host | Internal only |
| **Memory** | 2GB | 4-8GB+ |
| **Restart Policy** | no | unless-stopped |
| **Volumes** | Named volumes | Bind mounts + backups |
| **Monitoring** | Logs only | Full observability |
| **Reverse Proxy** | Direct access | NGINX/Traefik |
| **Data Persistence** | Optional | Required |

---

## Next Steps

1. **Start services**: `docker-compose up -d`
2. **Create accounts**: Use zmprov CLI
3. **Test API**: Use simple_test.sh
4. **Add more services**: Files, Preview, Chat, etc.
5. **Set up reverse proxy**: NGINX configuration
6. **Enable monitoring**: Prometheus + Grafana
7. **Configure backups**: Automated database dumps

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    Docker Host                       │
│                                                      │
│  ┌───────────────┐         ┌────────────────┐      │
│  │     NGINX     │────────▶│    Mailbox     │      │
│  │   (Port 80)   │         │  (Port 8080)   │      │
│  │  (Port 443)   │         │  (Port 7071)   │      │
│  └───────────────┘         └────────┬───────┘      │
│                                     │               │
│                            ┌────────┴────────┐      │
│                            │                 │      │
│                      ┌─────▼─────┐    ┌─────▼──────┐
│                      │  MariaDB  │    │  OpenLDAP  │
│                      │ (Port     │    │  (Port     │
│                      │  3306)    │    │   389)     │
│                      └───────────┘    └────────────┘
│                                                      │
│  Volumes:                                            │
│  - mailbox-store (persistent mail data)             │
│  - mailbox-index (search indexes)                   │
│  - mariadb-data (database files)                    │
│  - ldap-data (directory data)                       │
└─────────────────────────────────────────────────────┘
```

---

## Summary

You now know how to:
- Build Docker images for Carbonio Mailbox
- Run services with Docker Compose
- Configure environment variables
- Deploy in production mode
- Troubleshoot common issues

**For development**: Use the simple docker-compose.yml
**For production**: Use the production-ready version with SSL, secrets, and monitoring

Happy deploying! 🚀
