# How to Run Carbonio Mailbox Service

## 🚀 Quick Start

### Start the Service

```bash
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test \
  -Dlog4j.configurationFile=docker/mailbox/log4j.properties
```

The service will:
- Start on port 8080 (HTTP)
- Start on port 7071 (Admin)
- Start on port 8443 (HTTPS)
- Use in-memory HSQLDB database
- Use in-memory LDAP server
- Create test accounts automatically

### Wait for Startup

You'll see log output. Wait for:
```
Server started successfully
```

Service is ready when you see Jetty server started on port 8080.

---

## 📋 Step-by-Step Instructions

### 1. Prerequisites

Make sure you have:
- ✅ Java 17 installed
- ✅ Maven 3.9+ installed
- ✅ Project already built (`mvn clean install -DskipTests`)

Check versions:
```bash
java -version    # Should show Java 17
mvn -version     # Should show Maven 3.9+
```

### 2. Build the Project (First Time Only)

```bash
# From the carbonio-mailbox directory
mvn clean install -DskipTests
```

This takes ~5 minutes. You only need to do this once, or after code changes.

### 3. Start the Service

```bash
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test \
  -Dlog4j.configurationFile=docker/mailbox/log4j.properties
```

**What this does:**
- `-pl store` - Runs from the store module
- `-Dexec.mainClass` - Main class to run
- `-Dexec.classpathScope=test` - Include test dependencies
- `-Dlog4j.configurationFile` - Logging configuration

### 4. Verify It's Running

Open a new terminal and run:
```bash
curl http://localhost:8080/service/soap
```

You should see an error about "empty request payload" - that's normal! It means the service is running.

Or check with:
```bash
lsof -i :8080
```

You should see Java process listening on port 8080.

---

## 🛑 How to Stop the Service

### Method 1: Stop from Terminal
If you're in the terminal where Maven is running:
```bash
# Press Ctrl+C
```

### Method 2: Kill the Process
From another terminal:
```bash
# Find the process
ps aux | grep SampleLocalMailbox

# Kill it (replace <PID> with actual process ID)
kill <PID>
```

### Method 3: Kill by Port
```bash
# Find and kill process on port 8080
kill $(lsof -ti:8080)
```

---

## 🔄 How to Restart the Service

### Quick Restart
```bash
# Stop the service (Ctrl+C)
# Then start again
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test \
  -Dlog4j.configurationFile=docker/mailbox/log4j.properties
```

### After Code Changes
```bash
# 1. Stop the service
# 2. Rebuild
mvn clean install -DskipTests -pl store

# 3. Restart
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test
```

---

## 📊 Service Status

### Check if Running
```bash
# Check port 8080
lsof -i :8080

# Or
netstat -an | grep LISTEN | grep 8080
```

### Check Ports
```bash
# All service ports
lsof -i :8080 -i :7071 -i :8443
```

Expected output:
```
COMMAND   PID  USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
java    18827  user  353u  IPv6  0x...      0t0  TCP *:8080 (LISTEN)
java    18827  user  354u  IPv6  0x...      0t0  TCP *:7071 (LISTEN)
java    18827  user  355u  IPv6  0x...      0t0  TCP *:8443 (LISTEN)
```

### Test the API
```bash
./simple_test.sh
```

---

## 🔧 Service Configuration

### Ports
- **8080** - User SOAP API (HTTP)
- **7071** - Admin SOAP API
- **8443** - HTTPS/SSL

### Test Accounts (Auto-Created)
- **User**: test@test.com / password
- **Admin**: admin@test.com / password

### Data Storage
- **Database**: In-memory HSQLDB
  - Data lost when service stops
  - Perfect for testing
- **LDAP**: In-memory
  - User accounts created on startup

---

## 📝 Common Issues & Solutions

### Issue: Port Already in Use
```
Error: Address already in use
```

**Solution:**
```bash
# Kill existing process
kill $(lsof -ti:8080)

# Then start again
mvn exec:java ...
```

### Issue: Build Failed
```
Error: Could not find or load main class
```

**Solution:**
```bash
# Rebuild the project
mvn clean install -DskipTests

# Then start
mvn exec:java ...
```

### Issue: Out of Memory
```
Error: Java heap space
```

**Solution:**
```bash
# Increase Maven memory
export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=512m"

# Then start
mvn exec:java ...
```

### Issue: Can't Connect
```bash
# Check if service is running
lsof -i :8080

# Check logs for errors
# (they appear in the terminal where Maven is running)

# Restart service
# (Ctrl+C and start again)
```

---

## 🎯 Production vs Development

### Current Setup (Development)
- In-memory database (data lost on restart)
- In-memory LDAP
- HTTP only (no SSL required)
- Auto-created test accounts
- Single server mode

### For Production (Not covered here)
You would need:
- External database (MySQL/PostgreSQL)
- External LDAP server
- SSL/TLS certificates
- Multiple servers
- Persistent storage

---

## 💡 Tips & Tricks

### Run in Background
```bash
# Start in background (won't see logs)
nohup mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test \
  > mailbox.log 2>&1 &

# Check logs
tail -f mailbox.log
```

### Quick Restart Script
Create `restart.sh`:
```bash
#!/bin/bash
kill $(lsof -ti:8080) 2>/dev/null
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test
```

```bash
chmod +x restart.sh
./restart.sh
```

### Watch Logs
The service logs to the terminal. Common log messages:

**Starting:**
```
Initializing LDAP server...
Starting HSQLDB database...
Starting Jetty server...
Server started on port 8080
```

**Ready:**
```
Started ServerConnector@...{HTTP/1.1, (http/1.1)}{0.0.0.0:8080}
```

**Errors:**
Look for `ERROR` or `Exception` in the logs

---

## 🏃 Quick Commands Reference

```bash
# Start service
mvn exec:java -pl store -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" -Dexec.classpathScope=test

# Check if running
lsof -i :8080

# Test API
./simple_test.sh

# Stop service
kill $(lsof -ti:8080)

# View logs (if running in background)
tail -f mailbox.log

# Restart
# Ctrl+C, then run start command again
```

---

## 📖 Next Steps After Starting

1. **Test the API**
   ```bash
   ./simple_test.sh
   ```

2. **Run full workflow**
   ```bash
   ./complete_example.sh
   ```

3. **Read the docs**
   - API_USAGE_GUIDE.md - All API operations
   - TEST_RESULTS.md - What works and how
   - QUICK_START.md - Quick reference

4. **Start developing**
   - Use the SOAP API at http://localhost:8080/service/soap
   - Authenticate with test@test.com / password
   - Build your application!

---

## ⚠️ Important Notes

1. **Data is NOT persistent**
   - Everything is in-memory
   - Data lost when service stops
   - Perfect for testing, not for production

2. **Test accounts reset**
   - On each restart, accounts are recreated
   - Any data you created is lost

3. **Ports must be free**
   - 8080, 7071, and 8443 must be available
   - Kill any existing processes using these ports

4. **Keep terminal open**
   - Service runs in foreground
   - Closing terminal stops the service
   - Use background mode if needed

---

## 🎉 You're Ready!

Start the service with:
```bash
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test
```

Then test it with:
```bash
./simple_test.sh
```

Happy coding! 🚀
