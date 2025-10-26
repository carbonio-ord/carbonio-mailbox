#!/usr/bin/env python3
"""
Demo script to interact with Carbonio Mailbox SOAP API
This shows how to authenticate and perform basic operations.
"""

import requests
import xml.etree.ElementTree as ET
from typing import Dict, Optional

# Service configuration
SERVICE_URL = "http://localhost:8080/service/soap"
ADMIN_URL = "http://localhost:8080/service/admin/soap"

# Default test accounts (created by SampleLocalMailbox)
TEST_USER = "test@test.com"
TEST_PASSWORD = "password"
ADMIN_USER = "admin@test.com"
ADMIN_PASSWORD = "password"


class CarbonioClient:
    """Simple client for Carbonio Mailbox SOAP API"""

    def __init__(self, service_url: str = SERVICE_URL):
        self.service_url = service_url
        self.auth_token = None
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/soap+xml; charset=utf-8'
        })

    def _make_soap_request(self, body: str) -> ET.Element:
        """Make a SOAP request and return the response"""
        envelope = f'''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
    <soap:Header>
        {f'<context xmlns="urn:zimbra"><authToken>{self.auth_token}</authToken></context>' if self.auth_token else ''}
    </soap:Header>
    <soap:Body>
        {body}
    </soap:Body>
</soap:Envelope>'''

        print(f"\n📤 Request to {self.service_url}:")
        print(f"Body: {body[:200]}..." if len(body) > 200 else body)

        response = self.session.post(self.service_url, data=envelope)
        print(f"\n📥 Response Status: {response.status_code}")

        if response.status_code != 200:
            print(f"Response: {response.text}")
            raise Exception(f"HTTP {response.status_code}: {response.text}")

        return ET.fromstring(response.text)

    def authenticate(self, username: str, password: str) -> Dict:
        """Authenticate with username and password"""
        print(f"\n🔐 Authenticating as: {username}")

        auth_request = f'''
<AuthRequest xmlns="urn:zimbraAccount">
    <account by="name">{username}</account>
    <password>{password}</password>
</AuthRequest>'''

        response = self._make_soap_request(auth_request)

        # Parse auth token from response
        ns = {'soap': 'http://www.w3.org/2003/05/soap-envelope',
              'zimbra': 'urn:zimbraAccount'}

        auth_response = response.find('.//zimbra:AuthResponse', ns)
        if auth_response is not None:
            self.auth_token = auth_response.find('zimbra:authToken', ns).text
            lifetime = auth_response.find('zimbra:lifetime', ns).text

            print(f"✅ Authentication successful!")
            print(f"   Token: {self.auth_token[:30]}...")
            print(f"   Lifetime: {lifetime}ms")

            return {
                'authToken': self.auth_token,
                'lifetime': lifetime
            }
        else:
            # Check for fault
            fault = response.find('.//soap:Fault', ns)
            if fault:
                reason = fault.find('.//soap:Text', ns)
                error_msg = reason.text if reason is not None else "Unknown error"
                print(f"❌ Authentication failed: {error_msg}")
                raise Exception(f"Auth failed: {error_msg}")

    def get_info(self) -> Dict:
        """Get account information"""
        print(f"\n📋 Getting account info...")

        if not self.auth_token:
            raise Exception("Not authenticated. Call authenticate() first.")

        request = '<GetInfoRequest xmlns="urn:zimbraAccount"/>'
        response = self._make_soap_request(request)

        ns = {'soap': 'http://www.w3.org/2003/05/soap-envelope',
              'zimbra': 'urn:zimbraAccount'}

        info_response = response.find('.//zimbra:GetInfoResponse', ns)
        if info_response is not None:
            name = info_response.find('zimbra:name', ns)
            quota_used = info_response.find('zimbra:used', ns)

            print(f"✅ Account Info Retrieved:")
            print(f"   Name: {name.text if name is not None else 'N/A'}")
            print(f"   Quota Used: {quota_used.text if quota_used is not None else 'N/A'} bytes")

            return {
                'name': name.text if name is not None else None,
                'quotaUsed': quota_used.text if quota_used is not None else None
            }

        return {}

    def get_folder_list(self) -> None:
        """Get folder list"""
        print(f"\n📁 Getting folder list...")

        if not self.auth_token:
            raise Exception("Not authenticated. Call authenticate() first.")

        request = '<GetFolderRequest xmlns="urn:zimbraMail"/>'
        response = self._make_soap_request(request)

        ns = {'soap': 'http://www.w3.org/2003/05/soap-envelope',
              'zimbra': 'urn:zimbraMail'}

        folder_response = response.find('.//zimbra:GetFolderResponse', ns)
        if folder_response is not None:
            folders = folder_response.findall('.//zimbra:folder', ns)
            print(f"✅ Folders found: {len(folders)}")
            for folder in folders[:5]:  # Show first 5
                name = folder.get('name', 'N/A')
                folder_id = folder.get('id', 'N/A')
                print(f"   - {name} (ID: {folder_id})")

    def send_message(self, to: str, subject: str, body: str) -> None:
        """Send a simple email message"""
        print(f"\n📧 Sending message...")
        print(f"   To: {to}")
        print(f"   Subject: {subject}")

        if not self.auth_token:
            raise Exception("Not authenticated. Call authenticate() first.")

        request = f'''
<SendMsgRequest xmlns="urn:zimbraMail">
    <m>
        <e t="t" a="{to}"/>
        <su>{subject}</su>
        <mp ct="text/plain">
            <content>{body}</content>
        </mp>
    </m>
</SendMsgRequest>'''

        response = self._make_soap_request(request)

        ns = {'soap': 'http://www.w3.org/2003/05/soap-envelope',
              'zimbra': 'urn:zimbraMail'}

        send_response = response.find('.//zimbra:SendMsgResponse', ns)
        if send_response is not None:
            msg_id = send_response.find('zimbra:m', ns)
            if msg_id is not None:
                print(f"✅ Message sent successfully!")
                print(f"   Message ID: {msg_id.get('id', 'N/A')}")
        else:
            print(f"⚠️  Response: {ET.tostring(response, encoding='unicode')[:500]}")


def demo_basic_operations():
    """Demonstrate basic operations"""
    print("=" * 70)
    print("🚀 Carbonio Mailbox API Demo")
    print("=" * 70)

    # Create client
    client = CarbonioClient()

    # 1. Authenticate
    try:
        client.authenticate(TEST_USER, TEST_PASSWORD)
    except Exception as e:
        print(f"\n❌ Failed to authenticate: {e}")
        return

    # 2. Get account info
    try:
        client.get_info()
    except Exception as e:
        print(f"\n⚠️  Failed to get info: {e}")

    # 3. Get folder list
    try:
        client.get_folder_list()
    except Exception as e:
        print(f"\n⚠️  Failed to get folders: {e}")

    # 4. Send a test message
    try:
        client.send_message(
            to="admin@test.com",
            subject="Test Message from API",
            body="Hello! This is a test message sent via SOAP API."
        )
    except Exception as e:
        print(f"\n⚠️  Failed to send message: {e}")

    print("\n" + "=" * 70)
    print("✨ Demo completed!")
    print("=" * 70)


def demo_admin_operations():
    """Demonstrate admin operations"""
    print("\n" + "=" * 70)
    print("🔧 Admin Operations Demo")
    print("=" * 70)

    admin_client = CarbonioClient(ADMIN_URL)

    try:
        # Admin authentication uses admin namespace
        print(f"\n🔐 Authenticating as admin: {ADMIN_USER}")

        auth_request = f'''
<AuthRequest xmlns="urn:zimbraAdmin">
    <name>{ADMIN_USER}</name>
    <password>{ADMIN_PASSWORD}</password>
</AuthRequest>'''

        response = admin_client._make_soap_request(auth_request)

        ns = {'soap': 'http://www.w3.org/2003/05/soap-envelope',
              'zimbra': 'urn:zimbraAdmin'}

        auth_response = response.find('.//zimbra:AuthResponse', ns)
        if auth_response is not None:
            admin_client.auth_token = auth_response.find('zimbra:authToken', ns).text
            print(f"✅ Admin authentication successful!")
            print(f"   Token: {admin_client.auth_token[:30]}...")

    except Exception as e:
        print(f"\n❌ Admin auth failed: {e}")
        return

    print("\n" + "=" * 70)


if __name__ == "__main__":
    print("\n🔍 Testing Carbonio Mailbox Service")
    print("   Service URL:", SERVICE_URL)
    print("   Test User:", TEST_USER)
    print()

    # Run demos
    demo_basic_operations()
    demo_admin_operations()

    print("\n💡 Tips:")
    print("   - The service is running at: http://localhost:8080")
    print("   - SOAP endpoint: http://localhost:8080/service/soap")
    print("   - Admin endpoint: http://localhost:8080/service/admin/soap")
    print("   - Test account: test@test.com / password")
    print("   - Admin account: admin@test.com / password")
    print()
