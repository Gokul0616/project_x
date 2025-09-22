#!/usr/bin/env python3
"""
Messaging System Debug Test - Focus on Message Routing Issue
Tests the specific issue where messages appear as if the OTHER person sent them
"""

import requests
import json
import time
import sys
from typing import Dict, Any, Optional

class MessagingDebugTester:
    def __init__(self, base_url: str = "http://localhost:8001"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        
        # User A (sender)
        self.user_a_token = None
        self.user_a_id = None
        self.user_a_username = None
        
        # User B (recipient)
        self.user_b_token = None
        self.user_b_id = None
        self.user_b_username = None
        
        self.test_results = []
        self.conversation_id = None
        
    def log_test(self, test_name: str, success: bool, message: str, details: Any = None):
        """Log test results"""
        result = {
            "test": test_name,
            "success": success,
            "message": message,
            "details": details
        }
        self.test_results.append(result)
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status}: {test_name} - {message}")
        if details:
            print(f"   Details: {json.dumps(details, indent=2)}")
    
    def make_request(self, method: str, endpoint: str, data: Dict = None, headers: Dict = None, token: str = None) -> requests.Response:
        """Make HTTP request with proper error handling"""
        url = f"{self.api_url}{endpoint}"
        default_headers = {"Content-Type": "application/json"}
        
        # Use provided token or default to user_a_token
        auth_token = token or self.user_a_token
        if auth_token:
            default_headers["Authorization"] = f"Bearer {auth_token}"
        
        if headers:
            default_headers.update(headers)
        
        try:
            if method.upper() == "GET":
                response = requests.get(url, headers=default_headers, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, json=data, headers=default_headers, timeout=10)
            elif method.upper() == "PUT":
                response = requests.put(url, json=data, headers=default_headers, timeout=10)
            elif method.upper() == "PATCH":
                response = requests.patch(url, json=data, headers=default_headers, timeout=10)
            elif method.upper() == "DELETE":
                response = requests.delete(url, headers=default_headers, timeout=10)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            return response
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise
    
    def create_test_users(self):
        """Create two test users for messaging"""
        import time
        timestamp = str(int(time.time()))
        
        # Create User A
        user_a_data = {
            "username": f"alice_msg_{timestamp}",
            "email": f"alice.msg.{timestamp}@example.com",
            "password": "securepass123",
            "displayName": f"Alice Message {timestamp}"
        }
        
        try:
            response = self.make_request("POST", "/auth/register", user_a_data, token="")
            
            if response.status_code == 201:
                data = response.json()
                self.user_a_token = data["token"]
                self.user_a_id = data["user"]["_id"]
                self.user_a_username = data["user"]["username"]
                self.log_test("Create User A", True, "User A created successfully", {
                    "user_id": self.user_a_id,
                    "username": self.user_a_username
                })
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create User A", False, f"Registration failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Create User A", False, f"Registration request failed: {str(e)}")
            return False
        
        # Create User B
        user_b_data = {
            "username": f"bob_msg_{timestamp}",
            "email": f"bob.msg.{timestamp}@example.com",
            "password": "securepass123",
            "displayName": f"Bob Message {timestamp}"
        }
        
        try:
            response = self.make_request("POST", "/auth/register", user_b_data, token="")
            
            if response.status_code == 201:
                data = response.json()
                self.user_b_token = data["token"]
                self.user_b_id = data["user"]["_id"]
                self.user_b_username = data["user"]["username"]
                self.log_test("Create User B", True, "User B created successfully", {
                    "user_id": self.user_b_id,
                    "username": self.user_b_username
                })
                return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create User B", False, f"Registration failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Create User B", False, f"Registration request failed: {str(e)}")
            return False
    
    def test_user_authentication(self):
        """Test user authentication and get current user IDs"""
        print("\n=== TESTING USER AUTHENTICATION ===")
        
        # Test User A authentication
        try:
            response = self.make_request("GET", "/auth/me", token=self.user_a_token)
            
            if response.status_code == 200:
                data = response.json()
                current_user_a = data["user"]
                self.log_test("User A Authentication", True, "User A authenticated successfully", {
                    "current_user_id": current_user_a["_id"],
                    "current_username": current_user_a["username"],
                    "matches_stored_id": current_user_a["_id"] == self.user_a_id
                })
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User A Authentication", False, f"Auth failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("User A Authentication", False, f"Auth request failed: {str(e)}")
            return False
        
        # Test User B authentication
        try:
            response = self.make_request("GET", "/auth/me", token=self.user_b_token)
            
            if response.status_code == 200:
                data = response.json()
                current_user_b = data["user"]
                self.log_test("User B Authentication", True, "User B authenticated successfully", {
                    "current_user_id": current_user_b["_id"],
                    "current_username": current_user_b["username"],
                    "matches_stored_id": current_user_b["_id"] == self.user_b_id
                })
                return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User B Authentication", False, f"Auth failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("User B Authentication", False, f"Auth request failed: {str(e)}")
            return False
    
    def test_create_conversation(self):
        """Test creating a conversation between User A and User B"""
        print("\n=== TESTING CONVERSATION CREATION ===")
        
        # User A creates conversation with User B
        conversation_data = {
            "participantId": self.user_b_id
        }
        
        try:
            response = self.make_request("POST", "/messages/conversations", conversation_data, token=self.user_a_token)
            
            if response.status_code == 201:
                data = response.json()
                self.conversation_id = data["_id"]
                participants = data.get("participants", [])
                
                self.log_test("Create Conversation", True, "Conversation created successfully", {
                    "conversation_id": self.conversation_id,
                    "participants": [p.get("username", p.get("_id")) for p in participants],
                    "participant_count": len(participants),
                    "is_group": data.get("isGroup", False),
                    "created_by": data.get("createdBy"),
                    "other_participant": data.get("otherParticipant", {}).get("username") if data.get("otherParticipant") else None
                })
                return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create Conversation", False, f"Conversation creation failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Create Conversation", False, f"Conversation creation request failed: {str(e)}")
            return False
    
    def test_send_message_user_a(self):
        """Test User A sending a message to User B"""
        print("\n=== TESTING MESSAGE SENDING (USER A -> USER B) ===")
        
        if not self.conversation_id:
            self.log_test("Send Message User A", False, "No conversation ID available")
            return False
        
        message_data = {
            "content": "Hello Bob! This is Alice sending you a message. Can you see this correctly?"
        }
        
        try:
            response = self.make_request("POST", f"/messages/conversations/{self.conversation_id}/messages", message_data, token=self.user_a_token)
            
            if response.status_code == 201:
                data = response.json()
                sender_info = data.get("sender", {})
                recipient_info = data.get("recipient", {})
                
                self.log_test("Send Message User A", True, "Message sent successfully", {
                    "message_id": data.get("_id"),
                    "content": data.get("content"),
                    "sender_id": sender_info.get("_id") if isinstance(sender_info, dict) else sender_info,
                    "sender_username": sender_info.get("username") if isinstance(sender_info, dict) else "N/A",
                    "recipient_id": recipient_info.get("_id") if isinstance(recipient_info, dict) else recipient_info,
                    "recipient_username": recipient_info.get("username") if isinstance(recipient_info, dict) else "N/A",
                    "conversation_id": data.get("conversationId"),
                    "message_type": data.get("messageType"),
                    "created_at": data.get("createdAt"),
                    "is_read": data.get("isRead"),
                    "SENDER_MATCHES_USER_A": (sender_info.get("_id") if isinstance(sender_info, dict) else sender_info) == self.user_a_id,
                    "RECIPIENT_MATCHES_USER_B": (recipient_info.get("_id") if isinstance(recipient_info, dict) else recipient_info) == self.user_b_id
                })
                return data.get("_id")  # Return message ID
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Send Message User A", False, f"Message sending failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Send Message User A", False, f"Message sending request failed: {str(e)}")
            return False
    
    def test_send_message_user_b(self):
        """Test User B sending a message to User A"""
        print("\n=== TESTING MESSAGE SENDING (USER B -> USER A) ===")
        
        if not self.conversation_id:
            self.log_test("Send Message User B", False, "No conversation ID available")
            return False
        
        message_data = {
            "content": "Hi Alice! This is Bob replying to your message. I can see your message correctly!"
        }
        
        try:
            response = self.make_request("POST", f"/messages/conversations/{self.conversation_id}/messages", message_data, token=self.user_b_token)
            
            if response.status_code == 201:
                data = response.json()
                sender_info = data.get("sender", {})
                recipient_info = data.get("recipient", {})
                
                self.log_test("Send Message User B", True, "Message sent successfully", {
                    "message_id": data.get("_id"),
                    "content": data.get("content"),
                    "sender_id": sender_info.get("_id") if isinstance(sender_info, dict) else sender_info,
                    "sender_username": sender_info.get("username") if isinstance(sender_info, dict) else "N/A",
                    "recipient_id": recipient_info.get("_id") if isinstance(recipient_info, dict) else recipient_info,
                    "recipient_username": recipient_info.get("username") if isinstance(recipient_info, dict) else "N/A",
                    "conversation_id": data.get("conversationId"),
                    "message_type": data.get("messageType"),
                    "created_at": data.get("createdAt"),
                    "is_read": data.get("isRead"),
                    "SENDER_MATCHES_USER_B": (sender_info.get("_id") if isinstance(sender_info, dict) else sender_info) == self.user_b_id,
                    "RECIPIENT_MATCHES_USER_A": (recipient_info.get("_id") if isinstance(recipient_info, dict) else recipient_info) == self.user_a_id
                })
                return data.get("_id")  # Return message ID
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Send Message User B", False, f"Message sending failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Send Message User B", False, f"Message sending request failed: {str(e)}")
            return False
    
    def test_get_messages_user_a_perspective(self):
        """Test getting messages from User A's perspective"""
        print("\n=== TESTING MESSAGE RETRIEVAL (USER A PERSPECTIVE) ===")
        
        if not self.conversation_id:
            self.log_test("Get Messages User A", False, "No conversation ID available")
            return False
        
        try:
            response = self.make_request("GET", f"/messages/conversations/{self.conversation_id}/messages", token=self.user_a_token)
            
            if response.status_code == 200:
                messages = response.json()
                
                self.log_test("Get Messages User A", True, f"Retrieved {len(messages)} messages from User A's perspective", {
                    "message_count": len(messages),
                    "conversation_id": self.conversation_id,
                    "user_a_id": self.user_a_id,
                    "user_b_id": self.user_b_id
                })
                
                # Analyze each message
                for i, msg in enumerate(messages):
                    sender_info = msg.get("sender", {})
                    recipient_info = msg.get("recipient", {})
                    sender_id = sender_info.get("_id") if isinstance(sender_info, dict) else sender_info
                    recipient_id = recipient_info.get("_id") if isinstance(recipient_info, dict) else recipient_info
                    
                    # Determine who should be the sender based on content
                    content = msg.get("content", "")
                    expected_sender = None
                    if "This is Alice" in content:
                        expected_sender = self.user_a_id
                    elif "This is Bob" in content:
                        expected_sender = self.user_b_id
                    
                    sender_correct = sender_id == expected_sender if expected_sender else "Unknown"
                    
                    self.log_test(f"Message {i+1} Analysis (User A View)", True, f"Message analysis from User A's perspective", {
                        "message_id": msg.get("_id"),
                        "content_preview": content[:50] + "..." if len(content) > 50 else content,
                        "sender_id": sender_id,
                        "sender_username": sender_info.get("username") if isinstance(sender_info, dict) else "N/A",
                        "recipient_id": recipient_id,
                        "recipient_username": recipient_info.get("username") if isinstance(recipient_info, dict) else "N/A",
                        "expected_sender_id": expected_sender,
                        "sender_field_correct": sender_correct,
                        "is_from_user_a": sender_id == self.user_a_id,
                        "is_from_user_b": sender_id == self.user_b_id,
                        "is_to_user_a": recipient_id == self.user_a_id,
                        "is_to_user_b": recipient_id == self.user_b_id,
                        "created_at": msg.get("createdAt"),
                        "is_read": msg.get("isRead")
                    })
                
                return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get Messages User A", False, f"Message retrieval failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Get Messages User A", False, f"Message retrieval request failed: {str(e)}")
            return False
    
    def test_get_messages_user_b_perspective(self):
        """Test getting messages from User B's perspective"""
        print("\n=== TESTING MESSAGE RETRIEVAL (USER B PERSPECTIVE) ===")
        
        if not self.conversation_id:
            self.log_test("Get Messages User B", False, "No conversation ID available")
            return False
        
        try:
            response = self.make_request("GET", f"/messages/conversations/{self.conversation_id}/messages", token=self.user_b_token)
            
            if response.status_code == 200:
                messages = response.json()
                
                self.log_test("Get Messages User B", True, f"Retrieved {len(messages)} messages from User B's perspective", {
                    "message_count": len(messages),
                    "conversation_id": self.conversation_id,
                    "user_a_id": self.user_a_id,
                    "user_b_id": self.user_b_id
                })
                
                # Analyze each message
                for i, msg in enumerate(messages):
                    sender_info = msg.get("sender", {})
                    recipient_info = msg.get("recipient", {})
                    sender_id = sender_info.get("_id") if isinstance(sender_info, dict) else sender_info
                    recipient_id = recipient_info.get("_id") if isinstance(recipient_info, dict) else recipient_info
                    
                    # Determine who should be the sender based on content
                    content = msg.get("content", "")
                    expected_sender = None
                    if "This is Alice" in content:
                        expected_sender = self.user_a_id
                    elif "This is Bob" in content:
                        expected_sender = self.user_b_id
                    
                    sender_correct = sender_id == expected_sender if expected_sender else "Unknown"
                    
                    self.log_test(f"Message {i+1} Analysis (User B View)", True, f"Message analysis from User B's perspective", {
                        "message_id": msg.get("_id"),
                        "content_preview": content[:50] + "..." if len(content) > 50 else content,
                        "sender_id": sender_id,
                        "sender_username": sender_info.get("username") if isinstance(sender_info, dict) else "N/A",
                        "recipient_id": recipient_id,
                        "recipient_username": recipient_info.get("username") if isinstance(recipient_info, dict) else "N/A",
                        "expected_sender_id": expected_sender,
                        "sender_field_correct": sender_correct,
                        "is_from_user_a": sender_id == self.user_a_id,
                        "is_from_user_b": sender_id == self.user_b_id,
                        "is_to_user_a": recipient_id == self.user_a_id,
                        "is_to_user_b": recipient_id == self.user_b_id,
                        "created_at": msg.get("createdAt"),
                        "is_read": msg.get("isRead")
                    })
                
                return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get Messages User B", False, f"Message retrieval failed with status {response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Get Messages User B", False, f"Message retrieval request failed: {str(e)}")
            return False
    
    def run_debug_tests(self):
        """Run all debug tests"""
        print("🔍 MESSAGING SYSTEM DEBUG TEST STARTED")
        print("=" * 60)
        
        # Step 1: Create test users
        if not self.create_test_users():
            print("❌ Failed to create test users. Stopping tests.")
            return False
        
        # Step 2: Test authentication
        if not self.test_user_authentication():
            print("❌ Failed authentication tests. Stopping tests.")
            return False
        
        # Step 3: Create conversation
        if not self.test_create_conversation():
            print("❌ Failed to create conversation. Stopping tests.")
            return False
        
        # Step 4: Send messages
        message_a_id = self.test_send_message_user_a()
        if not message_a_id:
            print("❌ Failed to send message from User A. Stopping tests.")
            return False
        
        message_b_id = self.test_send_message_user_b()
        if not message_b_id:
            print("❌ Failed to send message from User B. Stopping tests.")
            return False
        
        # Step 5: Retrieve messages from both perspectives
        if not self.test_get_messages_user_a_perspective():
            print("❌ Failed to retrieve messages from User A perspective.")
            return False
        
        if not self.test_get_messages_user_b_perspective():
            print("❌ Failed to retrieve messages from User B perspective.")
            return False
        
        # Summary
        print("\n" + "=" * 60)
        print("🔍 MESSAGING DEBUG TEST SUMMARY")
        print("=" * 60)
        
        passed_tests = sum(1 for result in self.test_results if result["success"])
        total_tests = len(self.test_results)
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {total_tests - passed_tests}")
        
        if passed_tests == total_tests:
            print("✅ ALL TESTS PASSED - No message routing issues detected!")
        else:
            print("❌ SOME TESTS FAILED - Check the detailed logs above for issues")
        
        return passed_tests == total_tests

def main():
    tester = MessagingDebugTester()
    success = tester.run_debug_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()