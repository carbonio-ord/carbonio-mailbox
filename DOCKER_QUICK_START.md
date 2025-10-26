# Docker Quick Start Guide

## Get Carbonio Mailbox Running with Docker in 5 Minutes

This is the fastest way to get Carbonio Mailbox running in production mode with persistent storage.

---

## Prerequisites

- Docker installed and running
- Docker Compose installed
- 4GB+ free RAM
- 10GB+ free disk space

---

## Quick Start (3 Commands)

```bash
# 1. Start everything
./docker-deploy.sh start

# 2. Create test accounts
./docker-deploy.sh setup

# 3. Test the API
curl http://localhost:8080/service/soap
```

That's it! Your Carbonio Mailbox is running with:
- MariaDB (persistent database)
- OpenLDAP (directory service)
- Full production setup

---

## What Gets Deployed

### Services

| Service | Port | Description |
|---------|------|-------------|
| **Mailbox** | 8080 | HTTP SOAP API |
| **Mailbox** | 7071 | Admin SOAP API |
| **Mailbox** | 8443 | HTTPS |
| **MariaDB** | 3306 | Database |
| **OpenLDAP** | 1389 | Directory |

### Volumes (Persistent Storage)

- `mailbox-store` - Email and attachment storage
- `mailbox-index` - Search indexes
- `mariadb-data` - Database files
- `ldap-data` - Directory data
- `mailbox-logs` - Application logs

All data persists across restarts! 🎉

---

## Common Commands

```bash
# Start services
./docker-deploy.sh start

# Stop services
./docker-deploy.sh stop

# Restart services
./docker-deploy.sh restart

# View logs
./docker-deploy.sh logs

# Check status
./docker-deploy.sh status

# Create test accounts
./docker-deploy.sh setup

# Clean everything (WARNING: deletes all data!)
./docker-deploy.sh clean
```

---

## Access Services

### SOAP API

```bash
# User API
curl http://localhost:8080/service/soap

# Admin API
curl http://localhost:7071/service/admin/soap
```

### Test Authentication

```bash
curl -X POST http://localhost:8080/service/soap \
  -H "Content-Type: application/soap+xml" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <AuthRequest xmlns="urn:zimbraAccount">
      <account by="name">user@test.com</account>
      <password>password</password>
    </AuthRequest>
  </soap:Body>
</soap:Envelope>'
```

### Docker CLI Tools

```bash
# Enter mailbox container
docker-compose exec mailbox bash

# Create account
docker-compose exec mailbox zmprov createAccount newuser@test.com password

# List all accounts
docker-compose exec mailbox zmprov getAllAccounts

# Access database
docker-compose exec mariadb mysql -u root -ppassword zimbra
```

---

## Test Accounts

After running `./docker-deploy.sh setup`:

| Email | Password | Type |
|-------|----------|------|
| admin@test.com | password | Admin |
| user@test.com | password | User |

---

## Differences from Development Setup

| Aspect | Development (run.sh) | Docker (docker-deploy.sh) |
|--------|---------------------|---------------------------|
| **Database** | HSQLDB (in-memory) | MariaDB (persistent) |
| **LDAP** | In-memory | OpenLDAP (persistent) |
| **Data Persistence** | ❌ Lost on restart | ✅ Persists across restarts |
| **Startup Time** | ~30 seconds | ~2-3 minutes (first time) |
| **Production-like** | No | Yes |
| **Resource Usage** | Low | Medium |
| **Use Case** | API development | Production/Testing |

---

## Troubleshooting

### Service won't start

```bash
# Check logs
./docker-deploy.sh logs

# Check Docker is running
docker info

# Check ports are free
lsof -i :8080
lsof -i :3306
lsof -i :1389
```

### Build takes too long

First build takes 10-15 minutes to compile the code. Subsequent builds are faster.

### Out of memory

```bash
# Edit docker-compose.yml and increase memory:
MAILBOXD_JAVA_OPTS: "-Xss256k -Xms4096m -Xmx4096m"

# Restart
./docker-deploy.sh restart
```

### Database connection failed

```bash
# Check MariaDB is healthy
docker-compose ps

# View MariaDB logs
docker-compose logs mariadb

# Restart database
docker-compose restart mariadb
```

### Reset everything

```bash
# WARNING: This deletes all data!
./docker-deploy.sh clean

# Then start fresh
./docker-deploy.sh start
./docker-deploy.sh setup
```

---

## What's Different from Development Mode

### Development Mode (run.sh)
- In-memory database (HSQLDB)
- In-memory LDAP
- Data lost on restart
- Fast startup
- Perfect for API testing

### Docker Mode (docker-deploy.sh)
- Persistent database (MariaDB)
- Persistent LDAP (OpenLDAP)
- Data survives restarts
- Slower startup
- Production-like environment

**When to use Docker:**
- Testing with persistent data
- Production deployment
- Multi-server setup
- Integration testing
- Team development

**When to use Development mode:**
- Quick API testing
- Code development
- Learning the API
- Fast iteration

---

## Next Steps

1. **Read full guide**: [DOCKER_BUILD_AND_DEPLOY.md](DOCKER_BUILD_AND_DEPLOY.md)
2. **Test the API**: Use the test scripts in the repo
3. **Add more services**: Carbonio Files, Preview, etc.
4. **Production deployment**: Follow production checklist in the full guide

---

## File Reference

- `docker-compose.yml` - Service definitions
- `docker-deploy.sh` - Deployment script (this is what you use!)
- `.env.example` - Environment variables template
- `DOCKER_BUILD_AND_DEPLOY.md` - Complete documentation
- `docker/mailbox/Dockerfile` - Mailbox image definition
- `docker/mariadb/Dockerfile` - Database image definition

---

## Summary

**To get started:**

```bash
./docker-deploy.sh start   # Start everything
./docker-deploy.sh setup   # Create test accounts
./docker-deploy.sh status  # Verify it's working
```

**To use the API:**

Test accounts: user@test.com / password
API Endpoint: http://localhost:8080/service/soap

**To stop:**

```bash
./docker-deploy.sh stop
```

**Your data is persistent!** Unlike the development setup, your emails, folders, and settings will survive restarts.

Happy deploying! 🚀
