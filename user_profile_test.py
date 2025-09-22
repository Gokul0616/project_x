#!/usr/bin/env python3
"""
User Profile Navigation Test Suite for Twitter Clone
Tests user profile endpoints after profile navigation fix
"""

import requests
import json
import time
import sys
from typing import Dict, Any, Optional

class UserProfileTester:
    def __init__(self, base_url: str = "http://localhost:3000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        self.auth_token = None
        self.test_results = []
        
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
        if details and not success:
            print(f"   Details: {details}")
    
    def make_request(self, method: str, endpoint: str, data: Dict = None, headers: Dict = None) -> requests.Response:
        """Make HTTP request with proper error handling"""
        url = f"{self.api_url}{endpoint}"
        default_headers = {"Content-Type": "application/json"}
        
        if self.auth_token:
            default_headers["Authorization"] = f"Bearer {self.auth_token}"
        
        if headers:
            default_headers.update(headers)
        
        try:
            if method.upper() == "GET":
                response = requests.get(url, headers=default_headers, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, json=data, headers=default_headers, timeout=10)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            return response
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise
    
    def test_health_check(self):
        """Test if backend server is running"""
        try:
            response = self.make_request("GET", "/health")
            if response.status_code == 200:
                data = response.json()
                self.log_test("Health Check", True, "Backend server is running", data)
                return True
            else:
                self.log_test("Health Check", False, f"Health check failed with status {response.status_code}")
                return False
        except Exception as e:
            self.log_test("Health Check", False, f"Cannot connect to backend server: {str(e)}")
            return False
    
    def create_test_user(self, username: str, password: str = "password123"):
        """Create a new test user for authentication"""
        import time
        timestamp = str(int(time.time()))
        unique_username = f"{username}_{timestamp}"
        
        register_data = {
            "username": unique_username,
            "email": f"{unique_username}@example.com",
            "password": password,
            "displayName": f"{username.title()} Test"
        }
        
        try:
            register_response = self.make_request("POST", "/auth/register", register_data)
            if register_response.status_code == 201:
                data = register_response.json()
                self.auth_token = data["token"]
                self.test_username = unique_username
                self.log_test(f"Create Test User - {unique_username}", True, f"User {unique_username} created successfully")
                return unique_username
            else:
                error_data = register_response.json() if register_response.headers.get('content-type') == 'application/json' else register_response.text
                self.log_test(f"Create Test User - {unique_username}", False, f"Registration failed with status {register_response.status_code}", error_data)
                return None
        except Exception as e:
            self.log_test(f"Create Test User - {unique_username}", False, f"Registration request failed: {str(e)}")
            return None
    
    def test_user_profile_endpoint(self, username: str):
        """Test GET /api/users/:username endpoint"""
        try:
            response = self.make_request("GET", f"/users/{username}")
            
            if response.status_code == 200:
                data = response.json()
                if "user" in data and data["user"]["username"] == username:
                    user_data = data["user"]
                    required_fields = ["_id", "username", "displayName"]
                    missing_fields = [field for field in required_fields if field not in user_data]
                    
                    if not missing_fields:
                        self.log_test(f"Get User Profile - {username}", True, f"Profile retrieved successfully", {
                            "username": user_data["username"],
                            "displayName": user_data["displayName"],
                            "id": user_data["_id"],
                            "has_profile_image": "profileImage" in user_data,
                            "has_bio": "bio" in user_data
                        })
                        return True
                    else:
                        self.log_test(f"Get User Profile - {username}", False, f"Missing required fields: {missing_fields}", data)
                        return False
                else:
                    self.log_test(f"Get User Profile - {username}", False, "Missing user data or username mismatch", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Get User Profile - {username}", False, f"Profile retrieval failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test(f"Get User Profile - {username}", False, f"Profile request failed: {str(e)}")
            return False
    
    def test_user_tweets_endpoint(self, username: str):
        """Test GET /api/users/:username/tweets endpoint"""
        try:
            response = self.make_request("GET", f"/users/{username}/tweets")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    # Check if tweets have proper structure
                    valid_tweets = True
                    tweet_details = []
                    
                    for tweet in data[:3]:  # Check first 3 tweets
                        if not all(field in tweet for field in ["_id", "content", "author"]):
                            valid_tweets = False
                            break
                        
                        tweet_details.append({
                            "id": tweet["_id"],
                            "content": tweet["content"][:50] + "..." if len(tweet["content"]) > 50 else tweet["content"],
                            "author": tweet["author"]["username"] if "username" in tweet["author"] else "unknown",
                            "has_user_flags": "isLiked" in tweet and "isRetweeted" in tweet
                        })
                    
                    if valid_tweets:
                        self.log_test(f"Get User Tweets - {username}", True, f"Retrieved {len(data)} tweets successfully", {
                            "tweets_count": len(data),
                            "sample_tweets": tweet_details
                        })
                        return True
                    else:
                        self.log_test(f"Get User Tweets - {username}", False, "Tweets missing required fields", data[:2])
                        return False
                else:
                    self.log_test(f"Get User Tweets - {username}", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Get User Tweets - {username}", False, f"User tweets retrieval failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test(f"Get User Tweets - {username}", False, f"User tweets request failed: {str(e)}")
            return False
    
    def create_test_tweet(self, content: str):
        """Create a test tweet for testing purposes"""
        try:
            tweet_data = {"content": content}
            response = self.make_request("POST", "/tweets", tweet_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data:
                    self.log_test("Create Test Tweet", True, f"Test tweet created successfully", {
                        "tweet_id": data["_id"],
                        "content": content[:50] + "..." if len(content) > 50 else content
                    })
                    return data["_id"]
            
            self.log_test("Create Test Tweet", False, f"Tweet creation failed with status {response.status_code}")
            return None
        except Exception as e:
            self.log_test("Create Test Tweet", False, f"Tweet creation failed: {str(e)}")
            return None
    
    def run_user_profile_tests(self):
        """Run comprehensive user profile navigation tests"""
        print("🚀 Starting User Profile Navigation Tests...")
        print("=" * 60)
        
        # Test 1: Health check
        if not self.test_health_check():
            print("❌ Backend server is not running. Aborting tests.")
            return False
        
        # Test 2: Create test user for authentication
        test_username = self.create_test_user("gokul")
        if not test_username:
            print("❌ Failed to create test user. Aborting tests.")
            return False
        
        # Test 3: Create a test tweet to ensure user has content
        self.create_test_tweet("Testing user profile navigation after Enhanced Tweet Card fix! 🚀 #testing")
        
        # Test 4: Test user profile endpoints for existing users
        test_users = [test_username, "testuser123"]  # Use our created user and existing user
        profile_tests_passed = 0
        tweets_tests_passed = 0
        
        for username in test_users:
            # Test profile retrieval
            if self.test_user_profile_endpoint(username):
                profile_tests_passed += 1
            
            # Test user tweets retrieval
            if self.test_user_tweets_endpoint(username):
                tweets_tests_passed += 1
        
        # Summary
        print("\n" + "=" * 60)
        print("📊 USER PROFILE NAVIGATION TEST SUMMARY")
        print("=" * 60)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["success"])
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {total_tests - passed_tests}")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        print("\n📋 DETAILED RESULTS:")
        for result in self.test_results:
            status = "✅" if result["success"] else "❌"
            print(f"{status} {result['test']}: {result['message']}")
        
        # Specific focus on user profile endpoints
        print(f"\n🎯 USER PROFILE ENDPOINTS FOCUS:")
        print(f"✅ Profile Retrieval Tests: {profile_tests_passed}/{len(test_users)} passed")
        print(f"✅ User Tweets Tests: {tweets_tests_passed}/{len(test_users)} passed")
        
        if profile_tests_passed == len(test_users) and tweets_tests_passed == len(test_users):
            print("\n🎉 ALL USER PROFILE NAVIGATION ENDPOINTS WORKING CORRECTLY!")
            print("✅ Enhanced Tweet Card profile navigation should work properly")
            return True
        else:
            print("\n⚠️  SOME USER PROFILE ENDPOINTS HAVE ISSUES")
            print("❌ Enhanced Tweet Card profile navigation may not work properly")
            return False

def main():
    """Main function to run user profile tests"""
    tester = UserProfileTester()
    success = tester.run_user_profile_tests()
    
    if success:
        print("\n🚀 User profile navigation endpoints are ready for Enhanced Tweet Card!")
        sys.exit(0)
    else:
        print("\n❌ User profile navigation endpoints need attention.")
        sys.exit(1)

if __name__ == "__main__":
    main()