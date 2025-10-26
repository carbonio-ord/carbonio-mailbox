# Docker Troubleshooting Guide

## Common Issues and Solutions

### Platform Architecture Error (Apple Silicon / M1/M2/M3)

**Error:**
```
failed to solve: maven:3-eclipse-temurin-17-alpine: no match for platform in manifest
```

**Cause:** Running on Apple Silicon (ARM64) but Docker image doesn't support ARM64 or platform mismatch.

**Solution:** Add `platform: linux/amd64` to docker-compose.yml (already fixed!)

```yaml
services:
  mailbox:
    platform: linux/amd64  # Forces x86_64 emulation
    build:
      context: .
      dockerfile: docker/mailbox/Dockerfile
```

**Note:** This uses Rosetta 2 emulation on Apple Silicon. Build will take longer (~15-20 minutes first time) but works perfectly.

---

### Build Takes Too Long

**Expected:**
- First build: 10-20 minutes (compiles entire codebase)
- Subsequent builds: 2-5 minutes (uses cache)

**On Apple Silicon with platform: linux/amd64:**
- First build: 15-25 minutes (includes emulation overhead)
- Subsequent builds: 3-7 minutes

**Tips:**
```bash
# View build progress
docker-compose build --progress=plain

# Build without cache (if stuck)
docker-compose build --no-cache
```

---

### Port Already in Use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8080: bind: address already in use
```

**Solution:**
```bash
# Find what's using the port
lsof -i :8080

# If it's the old development server
kill $(lsof -ti:8080)

# Then restart Docker
docker-compose up -d
```

---

### Service Not Starting

**Symptoms:**
- Container exits immediately
- Health check failing
- Can't connect to API

**Debug Steps:**

```bash
# 1. Check container status
docker-compose ps

# 2. View logs
docker-compose logs mailbox

# 3. Check for errors
docker-compose logs mailbox | grep -i error

# 4. Enter container for debugging
docker-compose exec mailbox bash
```

**Common Causes:**
- Database not ready (wait 30 seconds, it has health checks)
- LDAP not ready (check openldap logs)
- Memory issues (increase MAILBOXD_JAVA_OPTS)

---

### Database Connection Failed

**Error in logs:**
```
Unable to connect to database
```

**Solutions:**

```bash
# 1. Check MariaDB is running
docker-compose ps mariadb
# Should show "healthy"

# 2. Check MariaDB logs
docker-compose logs mariadb

# 3. Restart database
docker-compose restart mariadb

# 4. Wait for health check
# The mailbox service depends on mariadb being healthy

# 5. Test connection manually
docker-compose exec mailbox mysql -h mariadb -u zextras -pzextras zimbra
```

---

### LDAP Connection Failed

**Error in logs:**
```
LDAP connection refused
```

**Solutions:**

```bash
# 1. Check OpenLDAP is running
docker-compose ps openldap

# 2. Check logs
docker-compose logs openldap

# 3. Test LDAP connection
docker-compose exec mailbox ldapsearch -x -H ldap://openldap:389 -b "dc=carbonio,dc=local"

# 4. Restart LDAP
docker-compose restart openldap
```

---

### Out of Memory

**Error:**
```
java.lang.OutOfMemoryError: Java heap space
```

**Solution:**

Edit `docker-compose.yml`:
```yaml
mailbox:
  environment:
    MAILBOXD_JAVA_OPTS: "-Xss256k -Xms4096m -Xmx4096m"  # Increased from 2GB to 4GB
```

Then restart:
```bash
docker-compose restart mailbox
```

---

### Clean Start (Reset Everything)

**When to use:**
- Build issues
- Corrupted data
- Want fresh start

**WARNING: Deletes all data!**

```bash
# Stop and remove everything
docker-compose down -v

# Remove images (optional)
docker-compose down -v --rmi all

# Start fresh
docker-compose up -d
```

---

### Build Cache Issues

**Symptoms:**
- Old code still running after changes
- Build succeeds but changes not reflected

**Solution:**

```bash
# Rebuild without cache
docker-compose build --no-cache

# Or for specific service
docker-compose build --no-cache mailbox

# Then restart
docker-compose up -d
```

---

### Volume Permission Issues

**Error:**
```
Permission denied: /opt/zextras/store
```

**Solution:**

```bash
# Remove volumes and recreate
docker-compose down -v
docker-compose up -d
```

---

### Health Check Always Failing

**Symptoms:**
```
docker-compose ps shows "unhealthy"
```

**Debug:**

```bash
# 1. Check what health check is doing
docker inspect carbonio-mailbox | grep -A 10 Healthcheck

# 2. Run health check manually
docker-compose exec mailbox curl -f http://localhost:8080/service/soap

# 3. Check if service is actually running
docker-compose exec mailbox netstat -tlnp | grep 8080

# 4. View startup logs
docker-compose logs mailbox | tail -100
```

---

### Container Keeps Restarting

**Check logs:**
```bash
docker-compose logs --tail=100 mailbox
```

**Common causes:**
- Startup script error
- Missing dependencies
- Configuration error
- Java crash

**Fix:**
```bash
# Enter container to debug
docker-compose run --rm mailbox bash

# Check entrypoint script
cat /entrypoint.sh

# Run manually to see error
bash /entrypoint.sh
```

---

### Network Issues

**Can't connect between containers:**

```bash
# Check network exists
docker network ls | grep carbonio

# Inspect network
docker network inspect carbonio-mailbox_carbonio-net

# Check if containers are on network
docker-compose exec mailbox ping mariadb
docker-compose exec mailbox ping openldap
```

---

### Apple Silicon Specific Issues

**Slow performance:**
- Expected with `platform: linux/amd64` (uses emulation)
- For better performance, consider using development mode (run.sh)

**Alternative for development on M1/M2/M3:**
```bash
# Use development mode instead
./run.sh

# Faster startup, no emulation
# Perfect for API testing and development
```

**Use Docker mode when:**
- Need persistent data
- Testing production-like setup
- Integration testing
- Data survives restarts

---

### Checking System Resources

```bash
# View resource usage
docker stats

# View specific container
docker stats carbonio-mailbox

# Check disk usage
docker system df

# Clean unused resources
docker system prune
```

---

## Getting Help

If issues persist:

1. **Check logs:**
   ```bash
   docker-compose logs --tail=200
   ```

2. **Check GitHub issues:**
   - carbonio-mailbox issues
   - Docker-specific problems

3. **Verify setup:**
   ```bash
   docker --version
   docker-compose --version
   uname -m  # Check architecture
   ```

4. **Collect debug info:**
   ```bash
   docker-compose config  # Verify configuration
   docker-compose ps      # Check status
   docker-compose logs    # Get logs
   ```

---

## Quick Reference

```bash
# Start services
./docker-deploy.sh start

# View logs
./docker-deploy.sh logs

# Check status
./docker-deploy.sh status

# Stop services
./docker-deploy.sh stop

# Clean everything (deletes data!)
./docker-deploy.sh clean

# Enter container
docker-compose exec mailbox bash

# Database access
docker-compose exec mariadb mysql -u root -ppassword zimbra

# Restart specific service
docker-compose restart mailbox
```

---

## Platform-Specific Notes

### macOS (Apple Silicon - M1/M2/M3)
- Uses `platform: linux/amd64` (emulation)
- Slower builds (15-25 minutes first time)
- Works perfectly, just slower
- For development, use `./run.sh` instead

### macOS (Intel)
- No platform issues
- Normal build times (10-15 minutes)

### Linux (x86_64)
- Native performance
- Fastest builds

### Windows (WSL2)
- Should work same as Linux
- Ensure WSL2 backend enabled in Docker Desktop

---

## Success Indicators

When everything is working:

```bash
$ docker-compose ps
NAME                 STATUS         PORTS
carbonio-ldap        running        0.0.0.0:1389->389/tcp
carbonio-mariadb     running (healthy)   0.0.0.0:3306->3306/tcp
carbonio-mailbox     running (healthy)   0.0.0.0:8080->8080/tcp, ...

$ curl http://localhost:8080/service/soap
<soap:Envelope...>
  <soap:Body>
    <soap:Fault>
      <soap:Detail>empty request payload</soap:Detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
```

That "empty request payload" error means the API is working! ✅
