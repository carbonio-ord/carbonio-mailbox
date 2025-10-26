#!/bin/bash
# Complete Carbonio Mailbox API Workflow Example
# This demonstrates authentication and multiple operations

set -e  # Exit on error

SERVICE_URL="http://localhost:8080/service/soap"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "🚀 Carbonio Mailbox - Complete Workflow"
echo "=========================================="
echo ""

# Step 1: Authenticate
echo -e "${BLUE}Step 1: Authenticating as test@test.com${NC}"
AUTH_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Body>
        <AuthRequest xmlns="urn:zimbraAccount">
            <account by="name">test@test.com</account>
            <password>password</password>
        </AuthRequest>
    </soap:Body>
</soap:Envelope>')

# Extract auth token (compatible with macOS)
AUTH_TOKEN=$(echo "$AUTH_RESPONSE" | sed -n 's/.*<authToken>\(.*\)<\/authToken>.*/\1/p')

if [ -z "$AUTH_TOKEN" ]; then
    echo -e "${YELLOW}❌ Authentication failed!${NC}"
    echo "Response:"
    echo "$AUTH_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Authenticated successfully!${NC}"
echo "   Token: ${AUTH_TOKEN:0:50}..."
echo ""

# Step 2: Get Account Info
echo -e "${BLUE}Step 2: Getting Account Information${NC}"
INFO_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d "<?xml version=\"1.0\"?>
<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">
    <soap:Header>
        <context xmlns=\"urn:zimbra\">
            <authToken>$AUTH_TOKEN</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <GetInfoRequest xmlns=\"urn:zimbraAccount\"/>
    </soap:Body>
</soap:Envelope>")

# Extract account name
ACCOUNT_NAME=$(echo "$INFO_RESPONSE" | sed -n 's/.*<name>\(.*\)<\/name>.*/\1/p' | head -1)
echo -e "${GREEN}✅ Account Info Retrieved${NC}"
echo "   Name: $ACCOUNT_NAME"
echo ""

# Step 3: Get Folders
echo -e "${BLUE}Step 3: Getting Folder List${NC}"
FOLDER_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d "<?xml version=\"1.0\"?>
<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">
    <soap:Header>
        <context xmlns=\"urn:zimbra\">
            <authToken>$AUTH_TOKEN</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <GetFolderRequest xmlns=\"urn:zimbraMail\"/>
    </soap:Body>
</soap:Envelope>")

# Count folders (rough estimate)
FOLDER_COUNT=$(echo "$FOLDER_RESPONSE" | grep -o '<folder' | wc -l | xargs)
echo -e "${GREEN}✅ Folders Retrieved${NC}"
echo "   Found approximately $FOLDER_COUNT folders"
echo ""

# Step 4: Send a Test Message
echo -e "${BLUE}Step 4: Sending Test Email${NC}"
SEND_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d "<?xml version=\"1.0\"?>
<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">
    <soap:Header>
        <context xmlns=\"urn:zimbra\">
            <authToken>$AUTH_TOKEN</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <SendMsgRequest xmlns=\"urn:zimbraMail\">
            <m>
                <e t=\"t\" a=\"admin@test.com\"/>
                <su>Test Message from API</su>
                <mp ct=\"text/plain\">
                    <content>Hello! This is a test message sent via the SOAP API.

Sent at: $(date)
From: Carbonio Mailbox API Test Script</content>
                </mp>
            </m>
        </SendMsgRequest>
    </soap:Body>
</soap:Envelope>")

# Check if message was sent
if echo "$SEND_RESPONSE" | grep -q "SendMsgResponse"; then
    MSG_ID=$(echo "$SEND_RESPONSE" | sed -n 's/.*<m id=\"\([^"]*\).*/\1/p' | head -1)
    echo -e "${GREEN}✅ Message Sent Successfully!${NC}"
    [ -n "$MSG_ID" ] && echo "   Message ID: $MSG_ID"
else
    echo -e "${YELLOW}⚠️  Message send response:${NC}"
    echo "$SEND_RESPONSE" | head -20
fi
echo ""

# Step 5: Search for Messages
echo -e "${BLUE}Step 5: Searching Inbox${NC}"
SEARCH_RESPONSE=$(curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d "<?xml version=\"1.0\"?>
<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">
    <soap:Header>
        <context xmlns=\"urn:zimbra\">
            <authToken>$AUTH_TOKEN</authToken>
        </context>
    </soap:Header>
    <soap:Body>
        <SearchRequest xmlns=\"urn:zimbraMail\" types=\"message\" limit=\"10\" offset=\"0\">
            <query>in:inbox</query>
        </SearchRequest>
    </soap:Body>
</soap:Envelope>")

# Extract message count
MSG_COUNT=$(echo "$SEARCH_RESPONSE" | grep -o '<m ' | wc -l | xargs)
echo -e "${GREEN}✅ Search Complete${NC}"
echo "   Found $MSG_COUNT messages in inbox"
echo ""

# Summary
echo "=========================================="
echo "✨ Workflow Completed Successfully!"
echo "=========================================="
echo ""
echo "Summary of operations:"
echo "  ✓ Authenticated as test@test.com"
echo "  ✓ Retrieved account information"
echo "  ✓ Listed folders (found ~$FOLDER_COUNT folders)"
echo "  ✓ Sent test email to admin@test.com"
echo "  ✓ Searched inbox (found $MSG_COUNT messages)"
echo ""
echo "You can now:"
echo "  • View full responses in the variables"
echo "  • Modify this script for your own tests"
echo "  • Check API_USAGE_GUIDE.md for more operations"
echo ""
echo "Service running at: $SERVICE_URL"
echo "=========================================="
