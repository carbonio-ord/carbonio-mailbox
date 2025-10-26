#!/bin/bash
# Carbonio Mailbox API Testing with curl

SERVICE_URL="http://localhost:8080/service/soap"
ADMIN_URL="http://localhost:8080/service/admin/soap"

echo "=========================================="
echo "🚀 Carbonio Mailbox API - curl Examples"
echo "=========================================="
echo ""

# Test credentials
USER="test@test.com"
PASSWORD="password"

echo "1️⃣  Testing Authentication..."
echo "   User: $USER"
echo ""

# Authentication request
AUTH_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Body>
        <AuthRequest xmlns="urn:zimbraAccount">
            <account by="name">'"$USER"'</account>
            <password>'"$PASSWORD"'</password>
        </AuthRequest>
    </soap:Body>
</soap:Envelope>')

echo "Response:"
echo "$AUTH_RESPONSE" | xmllint --format - 2>/dev/null || echo "$AUTH_RESPONSE"
echo ""

# Extract auth token
AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | grep -oP '<authToken>\K[^<]+' | head -1)

if [ -n "$AUTH_TOKEN" ]; then
    echo "✅ Authentication successful!"
    echo "   Token: ${AUTH_TOKEN:0:30}..."
    echo ""

    echo "2️⃣  Getting Account Info..."
    GET_INFO_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
      -H "Content-Type: application/soap+xml; charset=utf-8" \
      -d '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Header>
        <context xmlns="urn:zimbra">
            <authToken>'"$AUTH_TOKEN"'</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <GetInfoRequest xmlns="urn:zimbraAccount"/>
    </soap:Body>
</soap:Envelope>')

    echo "Response:"
    echo "$GET_INFO_RESPONSE" | xmllint --format - 2>/dev/null || echo "$GET_INFO_RESPONSE"
    echo ""

    echo "3️⃣  Getting Folder List..."
    GET_FOLDERS_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
      -H "Content-Type: application/soap+xml; charset=utf-8" \
      -d '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Header>
        <context xmlns="urn:zimbra">
            <authToken>'"$AUTH_TOKEN"'</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <GetFolderRequest xmlns="urn:zimbraMail"/>
    </soap:Body>
</soap:Envelope>')

    echo "Response (truncated):"
    echo "$GET_FOLDERS_RESPONSE" | head -30
    echo ""

else
    echo "❌ Authentication failed!"
    echo ""
fi

echo "=========================================="
echo "📚 Available SOAP Operations:"
echo "=========================================="
echo ""
echo "Account Operations (urn:zimbraAccount):"
echo "  • AuthRequest - Authenticate"
echo "  • GetInfoRequest - Get account information"
echo "  • GetPrefsRequest - Get preferences"
echo "  • ChangePasswordRequest - Change password"
echo "  • GetIdentitiesRequest - Get identities"
echo "  • GetSignaturesRequest - Get signatures"
echo ""
echo "Mail Operations (urn:zimbraMail):"
echo "  • GetFolderRequest - Get folder list"
echo "  • SendMsgRequest - Send message"
echo "  • GetMsgRequest - Get message"
echo "  • SearchRequest - Search mail"
echo "  • CreateFolderRequest - Create folder"
echo "  • GetConvRequest - Get conversation"
echo ""
echo "Admin Operations (urn:zimbraAdmin):"
echo "  • GetAccountRequest - Get account details"
echo "  • CreateAccountRequest - Create account"
echo "  • ModifyAccountRequest - Modify account"
echo "  • DeleteAccountRequest - Delete account"
echo "  • GetAllAccountsRequest - Get all accounts"
echo ""
echo "=========================================="
echo "💡 Documentation:"
echo "   • SOAP API docs in: soap/src/main/java"
echo "   • Example tests in: store/src/test/java"
echo "   • Service endpoint: $SERVICE_URL"
echo "=========================================="
