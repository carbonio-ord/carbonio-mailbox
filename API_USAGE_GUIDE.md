# Carbonio Mailbox API Usage Guide

## 🚀 Service Overview

The **Carbonio Mailbox** service is now running locally with:
- **HTTP Endpoint**: `http://localhost:8080`
- **SOAP Service**: `http://localhost:8080/service/soap`
- **Admin SOAP**: `http://localhost:8080/service/admin/soap`
- **Database**: In-memory HSQLDB (development)
- **LDAP**: In-memory LDAP server (development)

## 🔐 Test Accounts

Two accounts are pre-configured:

| Account | Username | Password | Type |
|---------|----------|----------|------|
| Regular User | `test@test.com` | `password` | Standard user |
| Admin User | `admin@test.com` | `password` | Admin account |

## 📡 API Basics

### SOAP Protocol

Carbonio Mailbox uses SOAP 1.2. All requests follow this structure:

```xml
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Header>
        <!-- Authentication token goes here for authenticated requests -->
        <context xmlns="urn:zimbra">
            <authToken>YOUR_AUTH_TOKEN</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <!-- Your request goes here -->
    </soap:Body>
</soap:Envelope>
```

## 🔑 Authentication

### 1. Basic Authentication

**Request:**
```xml
<AuthRequest xmlns="urn:zimbraAccount">
    <account by="name">test@test.com</account>
    <password>password</password>
</AuthRequest>
```

**Response:**
```xml
<AuthResponse xmlns="urn:zimbraAccount">
    <authToken>0_b020770dce7f4a3856e77c3...</authToken>
    <lifetime>172799999</lifetime>
</AuthResponse>
```

### 2. Using curl

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

### 3. Extract and Save Token

Save the `<authToken>` value for use in subsequent requests.

## 📋 Common Operations

### Get Account Information

```xml
<GetInfoRequest xmlns="urn:zimbraAccount"/>
```

**Full curl example:**
```bash
curl -X POST "http://localhost:8080/service/soap" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Header>
        <context xmlns="urn:zimbra">
            <authToken>YOUR_AUTH_TOKEN_HERE</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <GetInfoRequest xmlns="urn:zimbraAccount"/>
    </soap:Body>
</soap:Envelope>'
```

### Get Folder List

```xml
<GetFolderRequest xmlns="urn:zimbraMail"/>
```

### Send Email

```xml
<SendMsgRequest xmlns="urn:zimbraMail">
    <m>
        <e t="t" a="recipient@test.com"/>
        <su>Email Subject</su>
        <mp ct="text/plain">
            <content>Email body text here.</content>
        </mp>
    </m>
</SendMsgRequest>
```

### Search Mail

```xml
<SearchRequest xmlns="urn:zimbraMail" types="message" limit="25">
    <query>in:inbox</query>
</SearchRequest>
```

## 📚 Available SOAP Operations

### Account Operations (urn:zimbraAccount)
- `AuthRequest` - Authenticate user
- `GetInfoRequest` - Get account information
- `GetPrefsRequest` - Get user preferences
- `ChangePasswordRequest` - Change user password
- `GetIdentitiesRequest` - Get user identities
- `GetSignaturesRequest` - Get email signatures
- `ModifyPrefsRequest` - Modify preferences
- `CreateIdentityRequest` - Create new identity
- `CreateSignatureRequest` - Create email signature
- `SearchGalRequest` - Search Global Address List

### Mail Operations (urn:zimbraMail)
- `GetFolderRequest` - Get folder hierarchy
- `SendMsgRequest` - Send email message
- `GetMsgRequest` - Get specific message
- `SearchRequest` - Search for messages
- `CreateFolderRequest` - Create new folder
- `GetConvRequest` - Get conversation
- `MsgActionRequest` - Perform action on message (delete, flag, etc.)
- `ConvActionRequest` - Perform action on conversation
- `SaveDraftRequest` - Save draft message
- `ItemActionRequest` - General item actions
- `CreateContactRequest` - Create contact
- `GetContactsRequest` - Get contacts
- `CreateAppointmentRequest` - Create calendar appointment
- `GetAppointmentRequest` - Get appointment details

### Admin Operations (urn:zimbraAdmin)
- `AuthRequest` - Admin authentication
- `GetAccountRequest` - Get account details
- `CreateAccountRequest` - Create new account
- `ModifyAccountRequest` - Modify account attributes
- `DeleteAccountRequest` - Delete account
- `GetAllAccountsRequest` - List all accounts
- `CreateDomainRequest` - Create domain
- `GetDomainRequest` - Get domain info
- `ModifyDomainRequest` - Modify domain

## 🛠️ Testing Tools

### Quick Scripts

1. **simple_test.sh** - Basic authentication test
   ```bash
   ./simple_test.sh
   ```

2. **test_api.sh** - Comprehensive curl examples
   ```bash
   ./test_api.sh
   ```

3. **test_mailbox_api.py** - Python client examples (requires `requests` module)
   ```bash
   # Install dependencies first
   pip3 install requests
   python3 test_mailbox_api.py
   ```

### Manual Testing with curl

```bash
# 1. Authenticate and save token
TOKEN=$(curl -s -X POST "http://localhost:8080/service/soap" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Body>
        <AuthRequest xmlns="urn:zimbraAccount">
            <account by="name">test@test.com</account>
            <password>password</password>
        </AuthRequest>
    </soap:Body>
</soap:Envelope>' | grep -o '<authToken>[^<]*' | cut -d'>' -f2)

echo "Auth Token: $TOKEN"

# 2. Use token for subsequent requests
curl -X POST "http://localhost:8080/service/soap" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d "<?xml version=\"1.0\"?>
<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">
    <soap:Header>
        <context xmlns=\"urn:zimbra\">
            <authToken>$TOKEN</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <GetInfoRequest xmlns=\"urn:zimbraAccount\"/>
    </soap:Body>
</soap:Envelope>"
```

## 📖 Documentation Sources

### SOAP API Definitions
All SOAP request/response classes are in:
```
soap/src/main/java/com/zimbra/soap/
├── account/message/     # Account operations
├── mail/message/        # Mail operations
├── admin/message/       # Admin operations
└── ...
```

### Example Code
Look at test files for practical examples:
```
store/src/test/java/
├── qa/unittest/TestUtil.java          # Test utilities
├── com/zimbra/soap/AuthRequestTest.java  # Authentication examples
└── ...
```

### Client Library
The client library is available at:
```
client/src/main/java/com/zimbra/client/ZMailbox.java
```

## 🔍 Exploring the API

### View WSDL Documentation
```bash
# Generate SOAP documentation
mvn antrun:run@generate-soap-docs
```

### Explore with Browser
- Service endpoint: http://localhost:8080/service/soap
- Admin endpoint: http://localhost:8080/service/admin/soap

## 💡 Tips & Best Practices

1. **Token Lifetime**: Auth tokens expire after ~48 hours (172800000 ms)

2. **Error Handling**: SOAP faults are returned in this format:
   ```xml
   <soap:Fault>
       <soap:Code><soap:Value>soap:Sender</soap:Value></soap:Code>
       <soap:Reason><soap:Text>Error message</soap:Text></soap:Reason>
   </soap:Fault>
   ```

3. **Namespaces**: Always use the correct namespace:
   - Account operations: `urn:zimbraAccount`
   - Mail operations: `urn:zimbraMail`
   - Admin operations: `urn:zimbraAdmin`

4. **Content Type**: Use `application/soap+xml; charset=utf-8`

5. **Development Mode**: The current service runs with in-memory storage. Data is lost when the service stops.

## 🔧 Advanced Usage

### Using the Java Client Library

```java
import com.zimbra.client.ZMailbox;

// Create mailbox instance
ZMailbox.Options options = new ZMailbox.Options();
options.setAccount("test@test.com");
options.setAccountBy(ZMailbox.AccountBy.name);
options.setPassword("password");
options.setUri("http://localhost:8080");

ZMailbox mbox = ZMailbox.getMailbox(options);

// Get account info
String accountName = mbox.getAccountInfo(false).getName();
System.out.println("Logged in as: " + accountName);

// Send message
ZMailbox.ZOutgoingMessage msg = new ZMailbox.ZOutgoingMessage();
msg.setToAddress("admin@test.com");
msg.setSubject("Test from Java");
msg.setMessagePart(new ZMailbox.ZOutgoingMessage.MessagePart("text/plain", "Hello!"));
mbox.sendMessage(msg, null, false);
```

### Creating Test Accounts

Use the Provisioning API:
```java
Provisioning prov = Provisioning.getInstance();
Map<String, Object> attrs = new HashMap<>();
Account newAccount = prov.createAccount("newuser@test.com", "password", attrs);
```

## 🛑 Stopping the Service

To stop the running mailbox service:
```bash
# Find the process
ps aux | grep SampleLocalMailbox

# Kill it
kill <PID>

# Or use Ctrl+C in the Maven exec:java terminal
```

## 📞 Support & Resources

- **Source Code**: soap/, store/, client/ directories
- **WSDL Documentation**: Run `mvn antrun:run@generate-soap-docs`
- **Test Examples**: store/src/test/java/
- **Issue Tracker**: Check CHANGELOG.md for known issues

## ✨ Next Steps

1. Explore the SOAP operation classes in `soap/src/main/java`
2. Look at test examples in `store/src/test/java`
3. Try creating custom operations using the client library
4. Experiment with calendar, contacts, and folder operations
5. Set up IMAP/POP3 clients to connect to the service

Happy coding! 🚀
