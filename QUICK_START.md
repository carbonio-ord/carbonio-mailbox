# Carbonio Mailbox - Quick Start Guide

## ✅ Service Status

Your Carbonio Mailbox service is **RUNNING** and ready to use!

- **🌐 Service URL**: http://localhost:8080
- **📡 SOAP Endpoint**: http://localhost:8080/service/soap
- **🔧 Admin Endpoint**: http://localhost:8080/service/admin/soap
- **💾 Database**: In-memory HSQLDB (development mode)
- **📂 LDAP**: In-memory LDAP server

## 🎯 Test Accounts

| Username | Password | Role |
|----------|----------|------|
| test@test.com | password | Regular User |
| admin@test.com | password | Admin User |

## 🚀 Quick Test

Try this one-liner to test authentication:

```bash
./simple_test.sh
```

Or run the complete workflow:

```bash
./complete_example.sh
```

## 📝 Example API Call

### Authenticate
```bash
curl -X POST "http://localhost:8080/service/soap" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Body>
        <AuthRequest xmlns="urn:zimbraAccount">
            <account by="name">test@test.com</account>
            <password>password</password>
        </AuthRequest>
    </soap:Body>
</soap:Envelope>'
```

**Response:**
```xml
<AuthResponse xmlns="urn:zimbraAccount">
    <authToken>0_097f27a89595c75122d5849b9f...</authToken>
    <lifetime>172799999</lifetime>
</AuthResponse>
```

## ✨ What Works

Based on the test run, these operations are confirmed working:

✅ **Authentication** - User login with username/password
✅ **Get Account Info** - Retrieve account details
✅ **Get Folders** - List mailbox folders (~10 folders found)
✅ **Search Messages** - Search inbox and folders
⚠️ **Send Email** - Partially working (needs SMTP config for external delivery)

## 📚 Available Scripts

| Script | Description |
|--------|-------------|
| `simple_test.sh` | Basic authentication test |
| `complete_example.sh` | Full workflow demonstration |
| `test_api.sh` | Multiple curl examples |
| `test_mailbox_api.py` | Python client examples (needs `requests`) |

## 📖 Full Documentation

See **API_USAGE_GUIDE.md** for:
- Complete list of SOAP operations
- Detailed request/response examples
- Java client library usage
- Admin operations
- Best practices

## 🔍 Explore the API

### View Available Operations

All SOAP operations are defined in Java classes:

```bash
# Account operations
ls soap/src/main/java/com/zimbra/soap/account/message/*Request.java

# Mail operations
ls soap/src/main/java/com/zimbra/soap/mail/message/*Request.java

# Admin operations
ls soap/src/main/java/com/zimbra/soap/admin/message/*Request.java
```

### Common Operations

**Account** (urn:zimbraAccount):
- AuthRequest, GetInfoRequest, GetPrefsRequest
- ChangePasswordRequest, CreateIdentityRequest

**Mail** (urn:zimbraMail):
- GetFolderRequest, SendMsgRequest, SearchRequest
- CreateFolderRequest, GetMsgRequest, GetConvRequest

**Admin** (urn:zimbraAdmin):
- CreateAccountRequest, ModifyAccountRequest
- GetAccountRequest, DeleteAccountRequest

## 🛠️ Development Mode Notes

The service is running in **development mode** with:

- **In-memory database** - Data is lost when service stops
- **In-memory LDAP** - No persistence
- **Default domain** - test.com
- **Pre-created accounts** - test@test.com and admin@test.com
- **No email delivery** - SMTP not configured (messages stay local)

Perfect for:
- Testing SOAP APIs
- Developing client applications
- Learning the Carbonio architecture
- Running integration tests

## 🔄 Service Management

### Check if Service is Running
```bash
lsof -i :8080
```

### View Service Logs
The service outputs logs to the terminal where you ran:
```bash
mvn exec:java -pl store -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" ...
```

### Stop the Service
- Press `Ctrl+C` in the Maven terminal, OR
- Find and kill the process:
```bash
ps aux | grep SampleLocalMailbox
kill <PID>
```

### Restart the Service
```bash
mvn exec:java -pl store \
  -Dexec.mainClass="com.zextras.mailbox.SampleLocalMailbox" \
  -Dexec.classpathScope=test \
  -Dlog4j.configurationFile=docker/mailbox/log4j.properties
```

## 🎓 Learning Resources

### Code Examples
```
store/src/test/java/qa/unittest/TestUtil.java
store/src/test/java/com/zimbra/soap/
```

### SOAP Definitions
```
soap/src/main/java/com/zimbra/soap/
```

### Client Library
```
client/src/main/java/com/zimbra/client/ZMailbox.java
```

## 💡 Tips

1. **Save Auth Tokens** - Tokens last ~48 hours, reuse them
2. **Check Namespaces** - Use correct xmlns (zimbraAccount, zimbraMail, zimbraAdmin)
3. **Format Responses** - Pipe to `xmllint --format -` for readability
4. **Study Tests** - Look at test files for usage examples
5. **SOAP Faults** - Errors return as `<soap:Fault>` elements

## 🐛 Troubleshooting

**Service Not Responding?**
```bash
# Check if it's running
lsof -i :8080

# Check build succeeded
ls -la store/target/zm-store.jar

# Restart the service
```

**Authentication Failing?**
- Verify credentials: test@test.com / password
- Check SOAP namespace: urn:zimbraAccount
- Ensure Content-Type header is set

**Can't Send Email?**
- Normal in dev mode (no SMTP server)
- Messages save locally but don't deliver
- Use SearchRequest to find sent messages

## 🎉 Next Steps

1. ✅ **Service is Running** - Already done!
2. 📚 **Read API_USAGE_GUIDE.md** - Learn all operations
3. 🔨 **Try Examples** - Run the provided scripts
4. 💻 **Write Code** - Use Java client or REST/SOAP directly
5. 🧪 **Explore Tests** - Study test files for patterns

---

**Need Help?**
- Check API_USAGE_GUIDE.md for detailed docs
- Look at test files in store/src/test/java
- Read source code in soap/src/main/java

Happy coding! 🚀
