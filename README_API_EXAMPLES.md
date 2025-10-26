# 🎯 Carbonio Mailbox - API Interaction Examples

## 📂 Files Created

| File | Purpose |
|------|---------|
| `QUICK_START.md` | Quick reference guide |
| `API_USAGE_GUIDE.md` | Complete API documentation |
| `simple_test.sh` | Basic authentication test |
| `complete_example.sh` | Full workflow demo |
| `test_api.sh` | Multiple curl examples |
| `test_mailbox_api.py` | Python client examples |

## 🚀 Getting Started

### 1. Quick Test (30 seconds)
```bash
./simple_test.sh
```
This will authenticate and show you a valid auth token.

### 2. Complete Workflow (1 minute)
```bash
./complete_example.sh
```
This demonstrates:
- Authentication
- Getting account info
- Listing folders
- Sending email
- Searching messages

### 3. Read Documentation
```bash
# Quick start
open QUICK_START.md

# Full API guide
open API_USAGE_GUIDE.md
```

## 📡 Core API Operations

### Authentication & Account
```bash
# Authenticate
AuthRequest (urn:zimbraAccount)
→ Returns: authToken, lifetime

# Get account info
GetInfoRequest (urn:zimbraAccount)
→ Returns: name, quota, preferences

# Change password
ChangePasswordRequest (urn:zimbraAccount)
```

### Mail Operations
```bash
# Get folders
GetFolderRequest (urn:zimbraMail)

# Send message
SendMsgRequest (urn:zimbraMail)

# Search messages
SearchRequest (urn:zimbraMail)
  Example: <query>in:inbox</query>

# Get specific message
GetMsgRequest (urn:zimbraMail)
```

### Admin Operations
```bash
# Admin auth (different namespace!)
AuthRequest (urn:zimbraAdmin)

# Create account
CreateAccountRequest (urn:zimbraAdmin)

# Modify account
ModifyAccountRequest (urn:zimbraAdmin)
```

## 🔑 Test Credentials

```
Regular User: test@test.com / password
Admin User:   admin@test.com / password
```

## 📊 Verified Working Operations

Based on actual test runs:

| Operation | Status | Notes |
|-----------|--------|-------|
| Authentication | ✅ Working | Returns valid token |
| GetInfo | ✅ Working | Returns account details |
| GetFolders | ✅ Working | ~10 folders found |
| Search | ✅ Working | Inbox search confirmed |
| SendMsg | ⚠️ Partial | Saves locally, no SMTP |

## 🎨 Code Examples

### Bash/curl
```bash
# See: complete_example.sh
# Full working example with all steps
./complete_example.sh
```

### Python
```bash
# See: test_mailbox_api.py
# Requires: pip3 install requests
python3 test_mailbox_api.py
```

### Java
```java
// Using the client library
ZMailbox.Options options = new ZMailbox.Options();
options.setUri("http://localhost:8080");
options.setAccount("test@test.com");
options.setPassword("password");

ZMailbox mbox = ZMailbox.getMailbox(options);
String name = mbox.getAccountInfo(false).getName();
```

## 🛠️ Customizing Examples

All scripts are designed to be modified. For example:

```bash
# Edit complete_example.sh to:
# - Add more operations
# - Change test accounts
# - Modify search queries
# - Add calendar operations

vi complete_example.sh
```

## 📖 Learning Path

1. **Start Here**: QUICK_START.md
2. **Try It**: `./simple_test.sh`
3. **Full Demo**: `./complete_example.sh`
4. **Deep Dive**: API_USAGE_GUIDE.md
5. **Study Code**: `soap/src/main/java/com/zimbra/soap/`
6. **Run Tests**: `store/src/test/java/`

## 💻 Common Use Cases

### Send an Email
```xml
<SendMsgRequest xmlns="urn:zimbraMail">
    <m>
        <e t="t" a="recipient@test.com"/>
        <su>Subject Here</su>
        <mp ct="text/plain">
            <content>Message body</content>
        </mp>
    </m>
</SendMsgRequest>
```

### Search Inbox
```xml
<SearchRequest xmlns="urn:zimbraMail" types="message" limit="25">
    <query>in:inbox</query>
</SearchRequest>
```

### Get User Preferences
```xml
<GetPrefsRequest xmlns="urn:zimbraAccount"/>
```

### Create Folder
```xml
<CreateFolderRequest xmlns="urn:zimbraMail">
    <folder name="My New Folder" l="1"/>
</CreateFolderRequest>
```

## 🔍 Debugging Tips

### View Raw SOAP
```bash
# Add -v to see full request/response
curl -v -X POST "http://localhost:8080/service/soap" ...
```

### Pretty Print XML
```bash
curl ... | xmllint --format -
```

### Extract Values
```bash
# Get auth token
TOKEN=$(curl ... | grep -o '<authToken>[^<]*' | cut -d'>' -f2)
echo $TOKEN
```

## 🎓 Advanced Topics

See **API_USAGE_GUIDE.md** for:
- Complete SOAP operation list (100+ operations)
- Admin namespace operations
- Calendar and appointment APIs
- Contact management
- Folder and tag operations
- Search query syntax
- Error handling
- Best practices

## 📞 Quick Reference

```bash
# Service Info
URL:   http://localhost:8080/service/soap
Admin: http://localhost:8080/service/admin/soap

# Check Service
lsof -i :8080

# Test Auth
./simple_test.sh

# Full Demo
./complete_example.sh

# Stop Service
kill $(lsof -ti:8080)
```

## ✨ What You Can Do Now

✅ Authenticate users
✅ Get account information  
✅ List folders
✅ Search messages
✅ Create/modify folders
✅ Get preferences
✅ Manage identities
✅ Calendar operations
✅ Contact management
✅ Admin operations

All via SOAP API at **http://localhost:8080**!

---

**Questions?** Check API_USAGE_GUIDE.md or explore the test files!
