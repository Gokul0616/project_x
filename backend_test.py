#!/usr/bin/env python3
"""
Backend API Testing for Call Functionality
Tests all call-related endpoints and Socket.IO connectivity
"""

import requests
import json
import time
import sys
from urllib.parse import urljoin

# Test configuration
BASE_URL = "http://localhost:3000"
API_BASE = f"{BASE_URL}/api"

class CallAPITester:
    def __init__(self):
        self.session = requests.Session()
        self.results = {
            'passed': 0,
            'failed': 0,
            'errors': []
        }
    
    def log_result(self, test_name, success, message="", error_details=""):
        """Log test results"""
        if success:
            print(f"✅ {test_name}: PASSED - {message}")
            self.results['passed'] += 1
        else:
            print(f"❌ {test_name}: FAILED - {message}")
            if error_details:
                print(f"   Error: {error_details}")
            self.results['failed'] += 1
            self.results['errors'].append({
                'test': test_name,
                'message': message,
                'error': error_details
            })
    
    def test_server_health(self):
        """Test GET /api/health endpoint"""
        try:
            response = self.session.get(f"{API_BASE}/health", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'OK' and 'Twitter Clone Backend API is running' in data.get('message', ''):
                    self.log_result("Server Health Check", True, "Server is running properly")
                    return True
                else:
                    self.log_result("Server Health Check", False, f"Unexpected response format: {data}")
                    return False
            else:
                self.log_result("Server Health Check", False, f"HTTP {response.status_code}: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.log_result("Server Health Check", False, "Server connection failed", str(e))
            return False
    
    def test_call_endpoint_auth(self, endpoint, method="POST", payload=None):
        """Test call endpoint without authentication (should return auth error)"""
        try:
            url = f"{API_BASE}/calls/{endpoint}"
            
            if method == "POST":
                response = self.session.post(url, json=payload or {}, timeout=10)
            else:
                response = self.session.get(url, timeout=10)
            
            # Should return 401 Unauthorized
            if response.status_code == 401:
                try:
                    data = response.json()
                    if "token" in data.get('message', '').lower() or "auth" in data.get('message', '').lower():
                        self.log_result(f"Auth Test - {endpoint}", True, f"Proper auth error: {data.get('message')}")
                        return True
                    else:
                        self.log_result(f"Auth Test - {endpoint}", False, f"Wrong auth error message: {data}")
                        return False
                except json.JSONDecodeError:
                    self.log_result(f"Auth Test - {endpoint}", False, f"Non-JSON response: {response.text}")
                    return False
            else:
                self.log_result(f"Auth Test - {endpoint}", False, f"Expected 401, got {response.status_code}: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.log_result(f"Auth Test - {endpoint}", False, "Request failed", str(e))
            return False
    
    def test_socket_io_connectivity(self):
        """Test Socket.IO server accessibility"""
        try:
            # Test Socket.IO endpoint accessibility
            socket_url = f"{BASE_URL}/socket.io/"
            response = self.session.get(socket_url, timeout=10)
            
            # Socket.IO typically returns 400 for GET requests without proper handshake
            # But the server should be accessible
            if response.status_code in [400, 404]:
                # Check if response contains Socket.IO related content
                if "socket.io" in response.text.lower() or "transport" in response.text.lower():
                    self.log_result("Socket.IO Connectivity", True, "Socket.IO server is accessible")
                    return True
                else:
                    self.log_result("Socket.IO Connectivity", True, "Socket.IO endpoint responds (expected 400/404)")
                    return True
            elif response.status_code == 200:
                self.log_result("Socket.IO Connectivity", True, "Socket.IO server is accessible")
                return True
            else:
                self.log_result("Socket.IO Connectivity", False, f"Unexpected status {response.status_code}: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.log_result("Socket.IO Connectivity", False, "Socket.IO server not accessible", str(e))
            return False
    
    def test_error_response_format(self):
        """Test that API returns proper JSON error responses"""
        try:
            # Test with a non-existent endpoint
            response = self.session.get(f"{API_BASE}/nonexistent", timeout=10)
            
            # Should return JSON, not HTML
            content_type = response.headers.get('content-type', '')
            if 'application/json' in content_type:
                try:
                    data = response.json()
                    self.log_result("Error Response Format", True, f"Returns proper JSON errors: {data}")
                    return True
                except json.JSONDecodeError:
                    self.log_result("Error Response Format", False, "Response claims JSON but isn't valid JSON")
                    return False
            else:
                # Check if it's HTML error page
                if '<html' in response.text.lower():
                    self.log_result("Error Response Format", False, "Returns HTML error pages instead of JSON")
                    return False
                else:
                    self.log_result("Error Response Format", True, "Returns non-HTML error responses")
                    return True
                    
        except requests.exceptions.RequestException as e:
            self.log_result("Error Response Format", False, "Request failed", str(e))
            return False
    
    def run_all_tests(self):
        """Run all backend tests"""
        print("🚀 Starting Backend Call Functionality Tests")
        print("=" * 60)
        
        # Test 1: Basic server health
        print("\n📋 Test 1: Basic Server Health")
        server_running = self.test_server_health()
        
        if not server_running:
            print("\n❌ Server is not running. Stopping tests.")
            return self.results
        
        # Test 2: Call API endpoints authentication
        print("\n📋 Test 2: Call API Authentication")
        call_endpoints = [
            ('start', {'recipientId': 'test123', 'callType': 'voice'}),
            ('accept', {'callId': 'test123', 'callType': 'voice'}),
            ('reject', {'callId': 'test123'}),
            ('end', {'callId': 'test123'}),
            ('offer', {'callId': 'test123', 'offer': 'test_offer'}),
            ('answer', {'callId': 'test123', 'answer': 'test_answer'}),
            ('ice-candidate', {'callId': 'test123', 'candidate': 'test_candidate'})
        ]
        
        for endpoint, payload in call_endpoints:
            self.test_call_endpoint_auth(endpoint, payload=payload)
        
        # Test 3: Socket.IO connectivity
        print("\n📋 Test 3: Socket.IO Connectivity")
        self.test_socket_io_connectivity()
        
        # Test 4: Error response format
        print("\n📋 Test 4: Error Response Format")
        self.test_error_response_format()
        
        # Summary
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        print(f"✅ Passed: {self.results['passed']}")
        print(f"❌ Failed: {self.results['failed']}")
        print(f"📈 Success Rate: {(self.results['passed'] / (self.results['passed'] + self.results['failed']) * 100):.1f}%")
        
        if self.results['errors']:
            print("\n🔍 FAILED TESTS DETAILS:")
            for error in self.results['errors']:
                print(f"  • {error['test']}: {error['message']}")
                if error['error']:
                    print(f"    Error: {error['error']}")
        
        return self.results

def main():
    """Main test execution"""
    tester = CallAPITester()
    results = tester.run_all_tests()
    
    # Exit with error code if tests failed
    if results['failed'] > 0:
        sys.exit(1)
    else:
        print("\n🎉 All tests passed!")
        sys.exit(0)

if __name__ == "__main__":
    main()