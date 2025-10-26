#!/bin/bash
# Simple API test for macOS

SERVICE_URL="http://localhost:8080/service/soap"

echo "=========================================="
echo "🔐 Testing Authentication"
echo "=========================================="
echo ""

curl -s -X POST "$SERVICE_URL" \
  -H "Content-Type: application/soap+xml; charset=utf-8" \
  -d '<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Body>
        <AuthRequest xmlns="urn:zimbraAccount">
            <account by="name">test@test.com</account>
            <password>password</password>
        </AuthRequest>
    </soap:Body>
</soap:Envelope>' | xmllint --format -

echo ""
echo "=========================================="
echo "✅ Authentication Response Received!"
echo "=========================================="
echo ""
echo "Copy the <authToken> value from above to use in subsequent requests."
echo ""
echo "Example: Get Account Info"
echo "Replace YOUR_AUTH_TOKEN with the token from above:"
echo ""
echo 'curl -s -X POST "'$SERVICE_URL'" \'
echo '  -H "Content-Type: application/soap+xml; charset=utf-8" \'
echo "  -d '<?xml version=\"1.0\"?>"
echo '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">'
echo '    <soap:Header>'
echo '        <context xmlns="urn:zimbra">'
echo '            <authToken>YOUR_AUTH_TOKEN</authToken>'
echo '        </context>'
echo '    </soap:Header>'
echo '    <soap:Body>'
echo '        <GetInfoRequest xmlns="urn:zimbraAccount"/>'
echo '    </soap:Body>'
echo "</soap:Envelope>' | xmllint --format -"
echo ""
