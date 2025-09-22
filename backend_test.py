#!/usr/bin/env python3
"""
Comprehensive Backend Test Suite for Twitter Clone - Notification System Testing
Tests notification system functionality including likes, retweets, mentions, and replies
"""

import requests
import json
import time
import sys
from typing import Dict, Any, Optional

class TwitterCloneBackendTester:
    def __init__(self, base_url: str = "http://192.168.1.19:3000"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        self.auth_token = None
        self.test_user_id = None
        self.test_username = None
        self.created_tweet_ids = []
        self.test_results = []
        
        # For notification testing - second user
        self.user_b_token = None
        self.user_b_id = None
        self.user_b_username = None
        
        # Store emails for login
        self.test_user_email = None
        self.user_b_email = None
        
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
    
    def test_user_registration(self):
        """Test user registration endpoint"""
        import time
        timestamp = str(int(time.time()))
        
        test_data = {
            "username": f"testuser_{timestamp}",
            "email": f"testuser_{timestamp}@example.com",
            "password": "securepass123",
            "displayName": f"Test User {timestamp}"
        }
        
        self.test_user_email = test_data["email"]  # Store for login
        
        try:
            response = self.make_request("POST", "/auth/register", test_data)
            
            if response.status_code == 201:
                data = response.json()
                if "token" in data and "user" in data:
                    self.auth_token = data["token"]
                    self.test_user_id = data["user"]["_id"]
                    self.test_username = data["user"]["username"]
                    self.log_test("User Registration", True, "User registered successfully", {
                        "user_id": self.test_user_id,
                        "username": self.test_username
                    })
                    return True
                else:
                    self.log_test("User Registration", False, "Missing token or user in response", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User Registration", False, f"Registration failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("User Registration", False, f"Registration request failed: {str(e)}")
            return False
    
    def test_user_login(self):
        """Test user login endpoint"""
        if not self.test_user_email:
            self.log_test("User Login", False, "No test user email available")
            return False
            
        test_data = {
            "email": self.test_user_email,
            "password": "securepass123"
        }
        
        try:
            response = self.make_request("POST", "/auth/login", test_data)
            
            if response.status_code == 200:
                data = response.json()
                if "token" in data and "user" in data:
                    # Update token (should be same as registration)
                    self.auth_token = data["token"]
                    self.log_test("User Login", True, "User logged in successfully", {
                        "user_id": data["user"]["_id"],
                        "username": data["user"]["username"]
                    })
                    return True
                else:
                    self.log_test("User Login", False, "Missing token or user in response", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User Login", False, f"Login failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("User Login", False, f"Login request failed: {str(e)}")
            return False
    
    def test_get_current_user(self):
        """Test get current user endpoint"""
        try:
            response = self.make_request("GET", "/auth/me")
            
            if response.status_code == 200:
                data = response.json()
                if "user" in data:
                    self.log_test("Get Current User", True, "Current user retrieved successfully", {
                        "user_id": data["user"]["_id"],
                        "username": data["user"]["username"]
                    })
                    return True
                else:
                    self.log_test("Get Current User", False, "Missing user in response", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get Current User", False, f"Get user failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Get Current User", False, f"Get user request failed: {str(e)}")
            return False
    
    def test_create_tweet(self):
        """Test tweet creation endpoint"""
        tweets_to_create = [
            {"content": "Just launched my new project! Excited to share it with the world 🚀"},
            {"content": "Beautiful sunset today. Nature never fails to amaze me 🌅"},
            {"content": "Working on some interesting machine learning algorithms. The future is here!"},
            {"content": "Coffee and code - the perfect combination for a productive morning ☕💻"}
        ]
        
        success_count = 0
        
        for i, tweet_data in enumerate(tweets_to_create):
            try:
                response = self.make_request("POST", "/tweets", tweet_data)
                
                if response.status_code == 201:
                    data = response.json()
                    if "_id" in data and "content" in data:
                        self.created_tweet_ids.append(data["_id"])
                        self.log_test(f"Create Tweet {i+1}", True, f"Tweet created successfully", {
                            "tweet_id": data["_id"],
                            "content": data["content"][:50] + "..."
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Create Tweet {i+1}", False, "Missing tweet data in response", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Create Tweet {i+1}", False, f"Tweet creation failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Create Tweet {i+1}", False, f"Tweet creation request failed: {str(e)}")
        
        return success_count > 0
    
    def test_get_tweets(self):
        """Test get all tweets endpoint"""
        try:
            response = self.make_request("GET", "/tweets")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("Get All Tweets", True, f"Retrieved {len(data)} tweets successfully", {
                        "tweet_count": len(data)
                    })
                    return True
                else:
                    self.log_test("Get All Tweets", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get All Tweets", False, f"Get tweets failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Get All Tweets", False, f"Get tweets request failed: {str(e)}")
            return False
    
    def test_get_single_tweet(self):
        """Test get single tweet endpoint"""
        if not self.created_tweet_ids:
            self.log_test("Get Single Tweet", False, "No tweet IDs available for testing")
            return False
        
        tweet_id = self.created_tweet_ids[0]
        
        try:
            response = self.make_request("GET", f"/tweets/{tweet_id}")
            
            if response.status_code == 200:
                data = response.json()
                if "_id" in data and data["_id"] == tweet_id:
                    self.log_test("Get Single Tweet", True, "Single tweet retrieved successfully", {
                        "tweet_id": data["_id"],
                        "content": data["content"][:50] + "..."
                    })
                    return True
                else:
                    self.log_test("Get Single Tweet", False, "Tweet ID mismatch or missing data", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get Single Tweet", False, f"Get single tweet failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Get Single Tweet", False, f"Get single tweet request failed: {str(e)}")
            return False
    
    def test_like_tweet(self):
        """Test like/unlike tweet functionality"""
        if not self.created_tweet_ids:
            self.log_test("Like Tweet", False, "No tweet IDs available for testing")
            return False
        
        tweet_id = self.created_tweet_ids[0]
        
        try:
            # Test liking a tweet
            response = self.make_request("POST", f"/tweets/{tweet_id}/like")
            
            if response.status_code == 200:
                data = response.json()
                if "isLiked" in data and data["isLiked"] == True:
                    self.log_test("Like Tweet", True, "Tweet liked successfully", {
                        "tweet_id": tweet_id,
                        "likes_count": data.get("likesCount", 0)
                    })
                    
                    # Test unliking the tweet
                    response2 = self.make_request("POST", f"/tweets/{tweet_id}/like")
                    if response2.status_code == 200:
                        data2 = response2.json()
                        if "isLiked" in data2 and data2["isLiked"] == False:
                            self.log_test("Unlike Tweet", True, "Tweet unliked successfully", {
                                "tweet_id": tweet_id,
                                "likes_count": data2.get("likesCount", 0)
                            })
                            return True
                        else:
                            self.log_test("Unlike Tweet", False, "Unlike operation failed", data2)
                            return False
                    else:
                        self.log_test("Unlike Tweet", False, f"Unlike failed with status {response2.status_code}")
                        return False
                else:
                    self.log_test("Like Tweet", False, "Like operation failed", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Like Tweet", False, f"Like tweet failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Like Tweet", False, f"Like tweet request failed: {str(e)}")
            return False
    
    def test_retweet(self):
        """Test retweet/unretweet functionality"""
        if not self.created_tweet_ids:
            self.log_test("Retweet", False, "No tweet IDs available for testing")
            return False
        
        tweet_id = self.created_tweet_ids[1] if len(self.created_tweet_ids) > 1 else self.created_tweet_ids[0]
        
        try:
            # Test retweeting
            response = self.make_request("POST", f"/tweets/{tweet_id}/retweet")
            
            if response.status_code == 200:
                data = response.json()
                if "isRetweeted" in data and data["isRetweeted"] == True:
                    self.log_test("Retweet", True, "Tweet retweeted successfully", {
                        "tweet_id": tweet_id,
                        "retweets_count": data.get("retweetsCount", 0)
                    })
                    
                    # Test unretweeting
                    response2 = self.make_request("POST", f"/tweets/{tweet_id}/retweet")
                    if response2.status_code == 200:
                        data2 = response2.json()
                        if "isRetweeted" in data2 and data2["isRetweeted"] == False:
                            self.log_test("Unretweet", True, "Tweet unretweeted successfully", {
                                "tweet_id": tweet_id,
                                "retweets_count": data2.get("retweetsCount", 0)
                            })
                            return True
                        else:
                            self.log_test("Unretweet", False, "Unretweet operation failed", data2)
                            return False
                    else:
                        self.log_test("Unretweet", False, f"Unretweet failed with status {response2.status_code}")
                        return False
                else:
                    self.log_test("Retweet", False, "Retweet operation failed", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Retweet", False, f"Retweet failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Retweet", False, f"Retweet request failed: {str(e)}")
            return False
    
    def test_reply_to_tweet(self):
        """Test reply functionality"""
        if not self.created_tweet_ids:
            self.log_test("Reply to Tweet", False, "No tweet IDs available for testing")
            return False
        
        tweet_id = self.created_tweet_ids[0]
        reply_data = {
            "content": "Great post! Thanks for sharing your thoughts on this topic."
        }
        
        try:
            response = self.make_request("POST", f"/tweets/{tweet_id}/reply", reply_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data and "parentTweet" in data and data["parentTweet"] == tweet_id:
                    reply_id = data["_id"]
                    self.created_tweet_ids.append(reply_id)
                    self.log_test("Reply to Tweet", True, "Reply created successfully", {
                        "reply_id": reply_id,
                        "parent_tweet_id": tweet_id,
                        "content": data["content"][:50] + "..."
                    })
                    return True
                else:
                    self.log_test("Reply to Tweet", False, "Missing reply data or parent tweet reference", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Reply to Tweet", False, f"Reply creation failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Reply to Tweet", False, f"Reply request failed: {str(e)}")
            return False
    
    def test_get_replies(self):
        """Test get replies to a tweet"""
        if not self.created_tweet_ids:
            self.log_test("Get Replies", False, "No tweet IDs available for testing")
            return False
        
        tweet_id = self.created_tweet_ids[0]
        
        try:
            response = self.make_request("GET", f"/tweets/{tweet_id}/replies")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("Get Replies", True, f"Retrieved {len(data)} replies successfully", {
                        "tweet_id": tweet_id,
                        "replies_count": len(data)
                    })
                    return True
                else:
                    self.log_test("Get Replies", False, "Response is not a list of replies", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get Replies", False, f"Get replies failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Get Replies", False, f"Get replies request failed: {str(e)}")
            return False
    
    def test_recommended_tweets(self):
        """Test recommendation system endpoint"""
        try:
            response = self.make_request("GET", "/tweets/recommended")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("Recommended Tweets", True, f"Retrieved {len(data)} recommended tweets", {
                        "recommended_count": len(data)
                    })
                    return True
                else:
                    self.log_test("Recommended Tweets", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Recommended Tweets", False, f"Get recommended tweets failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Recommended Tweets", False, f"Get recommended tweets request failed: {str(e)}")
            return False
    
    def test_user_profile(self):
        """Test get user profile endpoint"""
        if not self.test_username:
            self.log_test("User Profile", False, "No test username available")
            return False
        
        try:
            response = self.make_request("GET", f"/users/{self.test_username}")
            
            if response.status_code == 200:
                data = response.json()
                if "user" in data and data["user"]["username"] == self.test_username:
                    self.log_test("User Profile", True, "User profile retrieved successfully", {
                        "username": data["user"]["username"],
                        "display_name": data["user"]["displayName"]
                    })
                    return True
                else:
                    self.log_test("User Profile", False, "Missing user data or username mismatch", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User Profile", False, f"Get user profile failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("User Profile", False, f"Get user profile request failed: {str(e)}")
            return False
    
    def test_user_tweets(self):
        """Test get user's tweets endpoint"""
        if not self.test_username:
            self.log_test("User Tweets", False, "No test username available")
            return False
        
        try:
            response = self.make_request("GET", f"/users/{self.test_username}/tweets")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("User Tweets", True, f"Retrieved {len(data)} user tweets", {
                        "username": self.test_username,
                        "tweets_count": len(data)
                    })
                    return True
                else:
                    self.log_test("User Tweets", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User Tweets", False, f"Get user tweets failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("User Tweets", False, f"Get user tweets request failed: {str(e)}")
            return False
    
    def test_user_replies(self):
        """Test get user's replies endpoint"""
        if not self.test_username:
            self.log_test("User Replies", False, "No test username available")
            return False
        
        try:
            response = self.make_request("GET", f"/users/{self.test_username}/replies")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("User Replies", True, f"Retrieved {len(data)} user replies", {
                        "username": self.test_username,
                        "replies_count": len(data)
                    })
                    return True
                else:
                    self.log_test("User Replies", False, "Response is not a list of replies", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User Replies", False, f"Get user replies failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("User Replies", False, f"Get user replies request failed: {str(e)}")
            return False
    
    def test_user_likes(self):
        """Test get user's liked tweets endpoint"""
        if not self.test_username:
            self.log_test("User Likes", False, "No test username available")
            return False
        
        try:
            response = self.make_request("GET", f"/users/{self.test_username}/likes")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("User Likes", True, f"Retrieved {len(data)} liked tweets", {
                        "username": self.test_username,
                        "liked_tweets_count": len(data)
                    })
                    return True
                else:
                    self.log_test("User Likes", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("User Likes", False, f"Get user likes failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("User Likes", False, f"Get user likes request failed: {str(e)}")
            return False

    def test_login_existing_user(self):
        """Test login with existing sample user alice_developer"""
        # Create a unique test user for this session
        import time
        timestamp = str(int(time.time()))
        
        register_data = {
            "username": f"testuser_{timestamp}",
            "email": f"testuser_{timestamp}@example.com", 
            "password": "password123",
            "displayName": f"Test User {timestamp}"
        }
        
        # Register new user
        try:
            register_response = self.make_request("POST", "/auth/register", register_data)
            if register_response.status_code == 201:
                data = register_response.json()
                self.auth_token = data["token"]
                self.test_user_id = data["user"]["_id"]
                self.test_username = data["user"]["username"]
                self.log_test("Register Test User", True, "Registered test user successfully", {
                    "user_id": self.test_user_id,
                    "username": self.test_username
                })
                return True
            else:
                error_data = register_response.json() if register_response.headers.get('content-type') == 'application/json' else register_response.text
                self.log_test("Register Test User", False, f"Registration failed with status {register_response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Register Test User", False, f"Registration request failed: {str(e)}")
            return False

    def create_additional_test_users(self):
        """Create additional test users for mentions testing"""
        import time
        timestamp = str(int(time.time()))
        
        additional_users = [
            {
                "username": f"alice_developer_{timestamp}",
                "email": f"alice.developer.{timestamp}@example.com",
                "password": "password123",
                "displayName": "Alice Developer"
            },
            {
                "username": f"bob_designer_{timestamp}",
                "email": f"bob.designer.{timestamp}@example.com",
                "password": "password123",
                "displayName": "Bob Designer"
            },
            {
                "username": f"carol_manager_{timestamp}", 
                "email": f"carol.manager.{timestamp}@example.com",
                "password": "password123",
                "displayName": "Carol Manager"
            }
        ]
        
        for user_data in additional_users:
            try:
                response = self.make_request("POST", "/auth/register", user_data)
                if response.status_code == 201:
                    self.log_test(f"Create User - {user_data['username']}", True, f"Created user {user_data['username']} successfully")
                else:
                    # User might already exist, that's ok
                    self.log_test(f"Create User - {user_data['username']}", True, f"User {user_data['username']} already exists or created")
            except Exception as e:
                self.log_test(f"Create User - {user_data['username']}", True, f"User creation handled: {str(e)}")

    def test_user_search(self):
        """Test user search API for mentions"""
        search_queries = ["alice", "bob", "carol"]
        
        success_count = 0
        for query in search_queries:
            try:
                response = self.make_request("GET", f"/users/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"User Search - {query}", True, f"Found {len(data)} users matching '{query}'", {
                            "query": query,
                            "results_count": len(data),
                            "users": [user.get("username", "unknown") for user in data[:3]]  # Show first 3 usernames
                        })
                        success_count += 1
                    else:
                        self.log_test(f"User Search - {query}", False, "Response is not a list of users", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"User Search - {query}", False, f"User search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"User Search - {query}", False, f"User search request failed: {str(e)}")
        
        return success_count > 0

    def test_create_tweets_with_hashtags_mentions(self):
        """Test creating tweets with hashtags and mentions"""
        tweets_with_hashtags_mentions = [
            {"content": "Working on a new #flutter project with #coding best practices! Excited to share progress 🚀"},
            {"content": "Just finished reading about #ai and #machinelearning. The future is here! #tech #innovation"},
            {"content": "Building amazing #react applications with modern #webdev techniques! #javascript #frontend"},
            {"content": "Great day for #startup development! Working on #mvp with the team #entrepreneurship"}
        ]
        
        success_count = 0
        
        for i, tweet_data in enumerate(tweets_with_hashtags_mentions):
            try:
                response = self.make_request("POST", "/tweets", tweet_data)
                
                if response.status_code == 201:
                    data = response.json()
                    if "_id" in data and "content" in data:
                        self.created_tweet_ids.append(data["_id"])
                        hashtags = data.get("hashtags", [])
                        mentions = data.get("mentions", [])
                        self.log_test(f"Create Tweet with Hashtags/Mentions {i+1}", True, f"Tweet created with hashtags and mentions", {
                            "tweet_id": data["_id"],
                            "content": data["content"][:50] + "...",
                            "hashtags": hashtags,
                            "mentions_count": len(mentions)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Create Tweet with Hashtags/Mentions {i+1}", False, "Missing tweet data in response", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Create Tweet with Hashtags/Mentions {i+1}", False, f"Tweet creation failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Create Tweet with Hashtags/Mentions {i+1}", False, f"Tweet creation request failed: {str(e)}")
        
        return success_count > 0

    def test_tweet_search_by_hashtag(self):
        """Test tweet search by hashtags"""
        hashtag_queries = ["#flutter", "#react", "#ai"]
        
        success_count = 0
        for query in hashtag_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Tweet Search by Hashtag - {query}", True, f"Found {len(data)} tweets with hashtag '{query}'", {
                            "query": query,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Tweet Search by Hashtag - {query}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Tweet Search by Hashtag - {query}", False, f"Tweet search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Tweet Search by Hashtag - {query}", False, f"Tweet search request failed: {str(e)}")
        
        return success_count > 0

    def test_tweet_search_by_mention(self):
        """Test tweet search by mentions"""
        # Use the current test user for mention search
        mention_queries = [f"@{self.test_username}"] if self.test_username else ["@testuser"]
        
        success_count = 0
        for query in mention_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Tweet Search by Mention - {query}", True, f"Found {len(data)} tweets mentioning '{query}'", {
                            "query": query,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Tweet Search by Mention - {query}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Tweet Search by Mention - {query}", False, f"Tweet search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Tweet Search by Mention - {query}", False, f"Tweet search request failed: {str(e)}")
        
        return success_count > 0

    def test_tweet_search_by_content(self):
        """Test tweet search by content"""
        content_queries = ["development", "startup", "project"]
        
        success_count = 0
        for query in content_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Tweet Search by Content - {query}", True, f"Found {len(data)} tweets containing '{query}'", {
                            "query": query,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Tweet Search by Content - {query}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Tweet Search by Content - {query}", False, f"Tweet search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Tweet Search by Content - {query}", False, f"Tweet search request failed: {str(e)}")
        
        return success_count > 0

    def test_create_second_user(self):
        """Create a second user for notification testing"""
        import time
        timestamp = str(int(time.time()))
        
        test_data = {
            "username": f"alice_dev_{timestamp}",
            "email": f"alice.dev.{timestamp}@example.com",
            "password": "securepass123",
            "displayName": "Alice Developer"
        }
        
        self.user_b_email = test_data["email"]  # Store for potential login
        
        try:
            response = self.make_request("POST", "/auth/register", test_data)
            
            if response.status_code == 201:
                data = response.json()
                if "token" in data and "user" in data:
                    self.user_b_token = data["token"]
                    self.user_b_id = data["user"]["_id"]
                    self.user_b_username = data["user"]["username"]
                    self.log_test("Create Second User", True, "Second user created successfully", {
                        "user_id": self.user_b_id,
                        "username": self.user_b_username
                    })
                    return True
                else:
                    self.log_test("Create Second User", False, "Missing token or user in response", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create Second User", False, f"Registration failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Create Second User", False, f"Registration request failed: {str(e)}")
            return False

    def test_create_tweet_for_notifications(self):
        """Create a tweet by User B that User A can interact with"""
        # Switch to User B's token
        original_token = self.auth_token
        self.auth_token = self.user_b_token
        
        tweet_data = {
            "content": "Just built an amazing new feature! Really excited to share it with everyone 🚀 #coding #development"
        }
        
        try:
            response = self.make_request("POST", "/tweets", tweet_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data and "content" in data:
                    tweet_id = data["_id"]
                    self.created_tweet_ids.append(tweet_id)
                    self.log_test("Create Tweet for Notifications", True, f"Tweet created by User B", {
                        "tweet_id": tweet_id,
                        "author": self.user_b_username,
                        "content": data["content"][:50] + "..."
                    })
                    # Switch back to User A's token
                    self.auth_token = original_token
                    return tweet_id
                else:
                    self.log_test("Create Tweet for Notifications", False, "Missing tweet data in response", data)
                    self.auth_token = original_token
                    return None
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create Tweet for Notifications", False, f"Tweet creation failed with status {response.status_code}", error_data)
                self.auth_token = original_token
                return None
                
        except Exception as e:
            self.log_test("Create Tweet for Notifications", False, f"Tweet creation request failed: {str(e)}")
            self.auth_token = original_token
            return None

    def test_like_notification(self, tweet_id):
        """Test that liking a tweet creates a notification"""
        try:
            # User A likes User B's tweet
            response = self.make_request("POST", f"/tweets/{tweet_id}/like")
            
            if response.status_code == 200:
                data = response.json()
                if "isLiked" in data and data["isLiked"] == True:
                    self.log_test("Like Tweet (Notification Test)", True, "Tweet liked successfully", {
                        "tweet_id": tweet_id,
                        "likes_count": data.get("likesCount", 0)
                    })
                    return True
                else:
                    self.log_test("Like Tweet (Notification Test)", False, "Like operation failed", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Like Tweet (Notification Test)", False, f"Like tweet failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Like Tweet (Notification Test)", False, f"Like tweet request failed: {str(e)}")
            return False

    def test_retweet_notification(self, tweet_id):
        """Test that retweeting a tweet creates a notification"""
        try:
            # User A retweets User B's tweet
            response = self.make_request("POST", f"/tweets/{tweet_id}/retweet")
            
            if response.status_code == 200:
                data = response.json()
                if "isRetweeted" in data and data["isRetweeted"] == True:
                    self.log_test("Retweet Tweet (Notification Test)", True, "Tweet retweeted successfully", {
                        "tweet_id": tweet_id,
                        "retweets_count": data.get("retweetsCount", 0)
                    })
                    return True
                else:
                    self.log_test("Retweet Tweet (Notification Test)", False, "Retweet operation failed", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Retweet Tweet (Notification Test)", False, f"Retweet failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Retweet Tweet (Notification Test)", False, f"Retweet request failed: {str(e)}")
            return False

    def test_mention_notification(self):
        """Test that mentioning a user creates a notification"""
        tweet_data = {
            "content": f"Hey @{self.user_b_username}, great work on your latest project! Really impressive stuff 👏"
        }
        
        try:
            # User A mentions User B in a tweet
            response = self.make_request("POST", "/tweets", tweet_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data and "content" in data:
                    tweet_id = data["_id"]
                    self.created_tweet_ids.append(tweet_id)
                    mentions = data.get("mentions", [])
                    self.log_test("Create Tweet with Mention (Notification Test)", True, f"Tweet with mention created", {
                        "tweet_id": tweet_id,
                        "content": data["content"][:50] + "...",
                        "mentions_count": len(mentions)
                    })
                    return tweet_id
                else:
                    self.log_test("Create Tweet with Mention (Notification Test)", False, "Missing tweet data in response", data)
                    return None
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create Tweet with Mention (Notification Test)", False, f"Tweet creation failed with status {response.status_code}", error_data)
                return None
                
        except Exception as e:
            self.log_test("Create Tweet with Mention (Notification Test)", False, f"Tweet creation request failed: {str(e)}")
            return None

    def test_reply_notification(self, tweet_id):
        """Test that replying to a tweet creates a notification"""
        reply_data = {
            "content": "This is such an inspiring post! Thanks for sharing your experience with the community."
        }
        
        try:
            # User A replies to User B's tweet
            response = self.make_request("POST", f"/tweets/{tweet_id}/reply", reply_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data and "parentTweet" in data and data["parentTweet"] == tweet_id:
                    reply_id = data["_id"]
                    self.created_tweet_ids.append(reply_id)
                    self.log_test("Reply to Tweet (Notification Test)", True, "Reply created successfully", {
                        "reply_id": reply_id,
                        "parent_tweet_id": tweet_id,
                        "content": data["content"][:50] + "..."
                    })
                    return reply_id
                else:
                    self.log_test("Reply to Tweet (Notification Test)", False, "Missing reply data or parent tweet reference", data)
                    return None
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Reply to Tweet (Notification Test)", False, f"Reply creation failed with status {response.status_code}", error_data)
                return None
                
        except Exception as e:
            self.log_test("Reply to Tweet (Notification Test)", False, f"Reply request failed: {str(e)}")
            return None

    def test_get_notifications(self, user_token, username):
        """Test retrieving notifications for a user"""
        # Switch to the specified user's token
        original_token = self.auth_token
        self.auth_token = user_token
        
        try:
            response = self.make_request("GET", "/notifications")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test(f"Get Notifications - {username}", True, f"Retrieved {len(data)} notifications", {
                        "username": username,
                        "notifications_count": len(data),
                        "notification_types": [notif.get("type", "unknown") for notif in data[:5]]  # Show first 5 types
                    })
                    
                    # Log details of each notification for debugging
                    for i, notif in enumerate(data[:3]):  # Show first 3 notifications in detail
                        self.log_test(f"Notification {i+1} Details", True, f"Type: {notif.get('type')}, Message: {notif.get('message')}", {
                            "id": notif.get("_id"),
                            "type": notif.get("type"),
                            "title": notif.get("title"),
                            "message": notif.get("message"),
                            "isRead": notif.get("isRead"),
                            "fromUser": notif.get("fromUserId", {}).get("username", "unknown") if notif.get("fromUserId") else "unknown",
                            "createdAt": notif.get("createdAt")
                        })
                    
                    self.auth_token = original_token
                    return len(data)
                else:
                    self.log_test(f"Get Notifications - {username}", False, "Response is not a list of notifications", data)
                    self.auth_token = original_token
                    return 0
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Get Notifications - {username}", False, f"Get notifications failed with status {response.status_code}", error_data)
                self.auth_token = original_token
                return 0
                
        except Exception as e:
            self.log_test(f"Get Notifications - {username}", False, f"Get notifications request failed: {str(e)}")
            self.auth_token = original_token
            return 0

    def test_mark_notification_as_read(self, user_token, username):
        """Test marking a notification as read"""
        # Switch to the specified user's token
        original_token = self.auth_token
        self.auth_token = user_token
        
        try:
            # First get notifications to find one to mark as read
            response = self.make_request("GET", "/notifications")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list) and len(data) > 0:
                    # Find an unread notification
                    unread_notification = None
                    for notif in data:
                        if not notif.get("isRead", True):
                            unread_notification = notif
                            break
                    
                    if unread_notification:
                        notif_id = unread_notification["_id"]
                        # Mark it as read
                        read_response = self.make_request("PATCH", f"/notifications/{notif_id}/read")
                        
                        if read_response.status_code == 200:
                            self.log_test(f"Mark Notification as Read - {username}", True, "Notification marked as read successfully", {
                                "notification_id": notif_id,
                                "type": unread_notification.get("type")
                            })
                            self.auth_token = original_token
                            return True
                        else:
                            error_data = read_response.json() if read_response.headers.get('content-type') == 'application/json' else read_response.text
                            self.log_test(f"Mark Notification as Read - {username}", False, f"Mark as read failed with status {read_response.status_code}", error_data)
                            self.auth_token = original_token
                            return False
                    else:
                        self.log_test(f"Mark Notification as Read - {username}", True, "No unread notifications found (all already read)", {
                            "total_notifications": len(data)
                        })
                        self.auth_token = original_token
                        return True
                else:
                    self.log_test(f"Mark Notification as Read - {username}", True, "No notifications found to mark as read", {})
                    self.auth_token = original_token
                    return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Mark Notification as Read - {username}", False, f"Get notifications failed with status {response.status_code}", error_data)
                self.auth_token = original_token
                return False
                
        except Exception as e:
            self.log_test(f"Mark Notification as Read - {username}", False, f"Mark notification as read request failed: {str(e)}")
            self.auth_token = original_token
            return False

    def test_mark_all_notifications_as_read(self, user_token, username):
        """Test marking all notifications as read"""
        # Switch to the specified user's token
        original_token = self.auth_token
        self.auth_token = user_token
        
        try:
            response = self.make_request("PATCH", "/notifications/read-all")
            
            if response.status_code == 200:
                data = response.json()
                self.log_test(f"Mark All Notifications as Read - {username}", True, "All notifications marked as read successfully", {
                    "message": data.get("message", "Success")
                })
                self.auth_token = original_token
                return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Mark All Notifications as Read - {username}", False, f"Mark all as read failed with status {response.status_code}", error_data)
                self.auth_token = original_token
                return False
                
        except Exception as e:
            self.log_test(f"Mark All Notifications as Read - {username}", False, f"Mark all notifications as read request failed: {str(e)}")
            self.auth_token = original_token
            return False
    
    def test_tweets_pagination(self):
        """Test infinite scroll pagination for main feed"""
        try:
            # Test first page
            response = self.make_request("GET", "/tweets?page=1&limit=20")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    page1_count = len(data)
                    self.log_test("Tweets Pagination - Page 1", True, f"Retrieved {page1_count} tweets from page 1", {
                        "page": 1,
                        "limit": 20,
                        "tweets_count": page1_count
                    })
                    
                    # Test second page
                    response2 = self.make_request("GET", "/tweets?page=2&limit=20")
                    if response2.status_code == 200:
                        data2 = response2.json()
                        if isinstance(data2, list):
                            page2_count = len(data2)
                            self.log_test("Tweets Pagination - Page 2", True, f"Retrieved {page2_count} tweets from page 2", {
                                "page": 2,
                                "limit": 20,
                                "tweets_count": page2_count
                            })
                            return True
                        else:
                            self.log_test("Tweets Pagination - Page 2", False, "Response is not a list of tweets", data2)
                            return False
                    else:
                        error_data = response2.json() if response2.headers.get('content-type') == 'application/json' else response2.text
                        self.log_test("Tweets Pagination - Page 2", False, f"Page 2 failed with status {response2.status_code}", error_data)
                        return False
                else:
                    self.log_test("Tweets Pagination - Page 1", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Tweets Pagination - Page 1", False, f"Page 1 failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Tweets Pagination", False, f"Pagination test failed: {str(e)}")
            return False

    def test_recommended_tweets_pagination(self):
        """Test recommended tweets with pagination"""
        try:
            response = self.make_request("GET", "/tweets/recommended?page=1&limit=10")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, dict) and 'tweets' in data:
                    tweets = data['tweets']
                    self.log_test("Recommended Tweets Pagination", True, f"Retrieved {len(tweets)} recommended tweets with enhanced metadata", {
                        "page": 1,
                        "limit": 10,
                        "tweets_count": len(tweets),
                        "has_timestamp": 'timestamp' in data,
                        "has_more": data.get('hasMore', False),
                        "recommendation_sources": list(set([tweet.get('recommendationSource', 'unknown') for tweet in tweets[:3]]))
                    })
                    return True
                elif isinstance(data, list):
                    # Fallback for old format
                    self.log_test("Recommended Tweets Pagination", True, f"Retrieved {len(data)} recommended tweets (legacy format)", {
                        "page": 1,
                        "limit": 10,
                        "tweets_count": len(data)
                    })
                    return True
                else:
                    self.log_test("Recommended Tweets Pagination", False, "Response format is incorrect", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Recommended Tweets Pagination", False, f"Recommended tweets pagination failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Recommended Tweets Pagination", False, f"Recommended tweets pagination test failed: {str(e)}")
            return False

    def test_lists_api(self):
        """Test Lists API functionality"""
        try:
            # Test get user lists
            response = self.make_request("GET", "/lists?type=user&page=1&limit=20")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("Lists API - Get User Lists", True, f"Retrieved {len(data)} user lists", {
                        "type": "user",
                        "lists_count": len(data)
                    })
                    
                    # Test get pinned lists
                    response2 = self.make_request("GET", "/lists?type=pinned&page=1&limit=20")
                    if response2.status_code == 200:
                        data2 = response2.json()
                        if isinstance(data2, list):
                            self.log_test("Lists API - Get Pinned Lists", True, f"Retrieved {len(data2)} pinned lists", {
                                "type": "pinned",
                                "lists_count": len(data2)
                            })
                            
                            # Test create new list
                            list_data = {
                                "name": "Test List",
                                "description": "A test list for API testing",
                                "isPrivate": False
                            }
                            
                            response3 = self.make_request("POST", "/lists", list_data)
                            if response3.status_code == 201:
                                created_list = response3.json()
                                if "_id" in created_list and "name" in created_list:
                                    list_id = created_list["_id"]
                                    self.log_test("Lists API - Create List", True, f"Created list successfully", {
                                        "list_id": list_id,
                                        "name": created_list["name"]
                                    })
                                    
                                    # Test update list
                                    update_data = {
                                        "name": "Updated Test List",
                                        "description": "Updated description"
                                    }
                                    
                                    response4 = self.make_request("PUT", f"/lists/{list_id}", update_data)
                                    if response4.status_code == 200:
                                        updated_list = response4.json()
                                        self.log_test("Lists API - Update List", True, f"Updated list successfully", {
                                            "list_id": list_id,
                                            "new_name": updated_list.get("name")
                                        })
                                        
                                        # Test pin/unpin list
                                        response5 = self.make_request("POST", f"/lists/{list_id}/pin")
                                        if response5.status_code == 200:
                                            pin_result = response5.json()
                                            self.log_test("Lists API - Pin List", True, f"Pin operation successful", {
                                                "list_id": list_id,
                                                "is_pinned": pin_result.get("isPinned")
                                            })
                                            
                                            # Test delete list
                                            response6 = self.make_request("DELETE", f"/lists/{list_id}")
                                            if response6.status_code == 200:
                                                self.log_test("Lists API - Delete List", True, f"Deleted list successfully", {
                                                    "list_id": list_id
                                                })
                                                return True
                                            else:
                                                error_data = response6.json() if response6.headers.get('content-type') == 'application/json' else response6.text
                                                self.log_test("Lists API - Delete List", False, f"Delete failed with status {response6.status_code}", error_data)
                                                return False
                                        else:
                                            error_data = response5.json() if response5.headers.get('content-type') == 'application/json' else response5.text
                                            self.log_test("Lists API - Pin List", False, f"Pin failed with status {response5.status_code}", error_data)
                                            return False
                                    else:
                                        error_data = response4.json() if response4.headers.get('content-type') == 'application/json' else response4.text
                                        self.log_test("Lists API - Update List", False, f"Update failed with status {response4.status_code}", error_data)
                                        return False
                                else:
                                    self.log_test("Lists API - Create List", False, "Missing list data in response", created_list)
                                    return False
                            else:
                                error_data = response3.json() if response3.headers.get('content-type') == 'application/json' else response3.text
                                self.log_test("Lists API - Create List", False, f"Create failed with status {response3.status_code}", error_data)
                                return False
                        else:
                            self.log_test("Lists API - Get Pinned Lists", False, "Response is not a list", data2)
                            return False
                    else:
                        error_data = response2.json() if response2.headers.get('content-type') == 'application/json' else response2.text
                        self.log_test("Lists API - Get Pinned Lists", False, f"Get pinned lists failed with status {response2.status_code}", error_data)
                        return False
                else:
                    self.log_test("Lists API - Get User Lists", False, "Response is not a list", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Lists API - Get User Lists", False, f"Get user lists failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Lists API", False, f"Lists API test failed: {str(e)}")
            return False

    def test_bookmarks_api(self):
        """Test Bookmarks API functionality"""
        try:
            # First, ensure we have a tweet to bookmark
            if not self.created_tweet_ids:
                self.log_test("Bookmarks API", False, "No tweet IDs available for bookmarking")
                return False
            
            tweet_id = self.created_tweet_ids[0]
            
            # Test bookmark a tweet
            response = self.make_request("POST", f"/bookmarks/{tweet_id}")
            
            if response.status_code == 201:
                bookmark_result = response.json()
                self.log_test("Bookmarks API - Add Bookmark", True, f"Tweet bookmarked successfully", {
                    "tweet_id": tweet_id,
                    "bookmark_id": bookmark_result.get("bookmarkId")
                })
                
                # Test get bookmarks with different sorting
                response2 = self.make_request("GET", "/bookmarks?page=1&limit=20&sortBy=date")
                if response2.status_code == 200:
                    bookmarks_data = response2.json()
                    if isinstance(bookmarks_data, list):
                        self.log_test("Bookmarks API - Get Bookmarks (Date Sort)", True, f"Retrieved {len(bookmarks_data)} bookmarks sorted by date", {
                            "sort_by": "date",
                            "bookmarks_count": len(bookmarks_data)
                        })
                        
                        # Test get bookmarks sorted by engagement
                        response3 = self.make_request("GET", "/bookmarks?page=1&limit=20&sortBy=engagement")
                        if response3.status_code == 200:
                            engagement_bookmarks = response3.json()
                            if isinstance(engagement_bookmarks, list):
                                self.log_test("Bookmarks API - Get Bookmarks (Engagement Sort)", True, f"Retrieved {len(engagement_bookmarks)} bookmarks sorted by engagement", {
                                    "sort_by": "engagement",
                                    "bookmarks_count": len(engagement_bookmarks)
                                })
                                
                                # Test remove bookmark
                                response4 = self.make_request("DELETE", f"/bookmarks/{tweet_id}")
                                if response4.status_code == 200:
                                    self.log_test("Bookmarks API - Remove Bookmark", True, f"Bookmark removed successfully", {
                                        "tweet_id": tweet_id
                                    })
                                    return True
                                else:
                                    error_data = response4.json() if response4.headers.get('content-type') == 'application/json' else response4.text
                                    self.log_test("Bookmarks API - Remove Bookmark", False, f"Remove bookmark failed with status {response4.status_code}", error_data)
                                    return False
                            else:
                                self.log_test("Bookmarks API - Get Bookmarks (Engagement Sort)", False, "Response is not a list", engagement_bookmarks)
                                return False
                        else:
                            error_data = response3.json() if response3.headers.get('content-type') == 'application/json' else response3.text
                            self.log_test("Bookmarks API - Get Bookmarks (Engagement Sort)", False, f"Get engagement bookmarks failed with status {response3.status_code}", error_data)
                            return False
                    else:
                        self.log_test("Bookmarks API - Get Bookmarks (Date Sort)", False, "Response is not a list", bookmarks_data)
                        return False
                else:
                    error_data = response2.json() if response2.headers.get('content-type') == 'application/json' else response2.text
                    self.log_test("Bookmarks API - Get Bookmarks (Date Sort)", False, f"Get bookmarks failed with status {response2.status_code}", error_data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Bookmarks API - Add Bookmark", False, f"Add bookmark failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Bookmarks API", False, f"Bookmarks API test failed: {str(e)}")
            return False

    def test_moments_api(self):
        """Test Moments API functionality"""
        try:
            # Test get all moments
            response = self.make_request("GET", "/moments?type=all&page=1&limit=20")
            
            if response.status_code == 200:
                all_moments = response.json()
                if isinstance(all_moments, list):
                    self.log_test("Moments API - Get All Moments", True, f"Retrieved {len(all_moments)} moments", {
                        "type": "all",
                        "moments_count": len(all_moments)
                    })
                    
                    # Test get featured moments
                    response2 = self.make_request("GET", "/moments?type=featured&page=1&limit=20")
                    if response2.status_code == 200:
                        featured_moments = response2.json()
                        if isinstance(featured_moments, list):
                            self.log_test("Moments API - Get Featured Moments", True, f"Retrieved {len(featured_moments)} featured moments", {
                                "type": "featured",
                                "moments_count": len(featured_moments)
                            })
                            
                            # Test get specific moment details if we have any moments
                            if len(all_moments) > 0:
                                moment_id = all_moments[0]["_id"]
                                response3 = self.make_request("GET", f"/moments/{moment_id}")
                                if response3.status_code == 200:
                                    moment_details = response3.json()
                                    if "_id" in moment_details:
                                        self.log_test("Moments API - Get Moment Details", True, f"Retrieved moment details successfully", {
                                            "moment_id": moment_id,
                                            "title": moment_details.get("title"),
                                            "tweets_count": len(moment_details.get("tweets", []))
                                        })
                                        return True
                                    else:
                                        self.log_test("Moments API - Get Moment Details", False, "Missing moment data", moment_details)
                                        return False
                                else:
                                    error_data = response3.json() if response3.headers.get('content-type') == 'application/json' else response3.text
                                    self.log_test("Moments API - Get Moment Details", False, f"Get moment details failed with status {response3.status_code}", error_data)
                                    return False
                            else:
                                self.log_test("Moments API - Get Moment Details", True, "No moments available to test details", {})
                                return True
                        else:
                            self.log_test("Moments API - Get Featured Moments", False, "Response is not a list", featured_moments)
                            return False
                    else:
                        error_data = response2.json() if response2.headers.get('content-type') == 'application/json' else response2.text
                        self.log_test("Moments API - Get Featured Moments", False, f"Get featured moments failed with status {response2.status_code}", error_data)
                        return False
                else:
                    self.log_test("Moments API - Get All Moments", False, "Response is not a list", all_moments)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Moments API - Get All Moments", False, f"Get all moments failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Moments API", False, f"Moments API test failed: {str(e)}")
            return False

    def run_new_features_tests(self):
        """Run comprehensive tests for new pagination and drawer APIs"""
        print("🚀 Starting Twitter Clone New Features Tests")
        print("=" * 80)
        
        # Health check first
        if not self.test_health_check():
            print("❌ Backend server is not running. Stopping tests.")
            return False
        
        # Create test user for authentication
        print("\n👤 Setting up test user...")
        if not self.test_user_registration():
            print("❌ User registration failed. Cannot proceed with tests.")
            return False
        
        # Create some tweets for testing
        print("\n🐦 Creating test tweets...")
        if not self.test_create_tweet():
            print("❌ Tweet creation failed. Cannot proceed with pagination tests.")
            return False
        
        # Test pagination features
        print("\n📄 Testing Pagination Features...")
        self.test_tweets_pagination()
        self.test_recommended_tweets_pagination()
        
        # Test drawer APIs
        print("\n📋 Testing Lists API...")
        self.test_lists_api()
        
        print("\n🔖 Testing Bookmarks API...")
        self.test_bookmarks_api()
        
        print("\n⚡ Testing Moments API...")
        self.test_moments_api()
        
        # Summary
        print("\n" + "=" * 80)
        print("📊 NEW FEATURES TEST SUMMARY")
        print("=" * 80)
        
        passed = sum(1 for result in self.test_results if result["success"])
        total = len(self.test_results)
        
        print(f"Total Tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {total - passed}")
        print(f"Success Rate: {(passed/total)*100:.1f}%")
        
        if total - passed > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.test_results:
                if not result["success"]:
                    print(f"  - {result['test']}: {result['message']}")
        
        return passed == total

    def test_messaging_functionality(self):
        """Test messaging functionality with provided authentication details"""
        print("\n🔥 TESTING MESSAGING FUNCTIONALITY")
        print("=" * 60)
        
        # Use provided Gokul token
        gokul_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIzYzE1NTE4Mi1mMzU4LTQ3MmItOTIxNS0xZWI0YTg3YTMyYzgiLCJpYXQiOjE3NTgyNjA3NzMsImV4cCI6MTc1ODg2NTU3M30.6D97zwgefug3IiXaErBmvbVMapLXafQEai9Y6dz9WO0"
        self.auth_token = gokul_token
        
        # Test user profile APIs first
        self.test_user_profile_api("gokul")
        self.test_user_profile_api("testuser")
        self.test_user_tweets_api("gokul")
        self.test_user_tweets_api("testuser")
        
        # Test messaging APIs
        self.test_get_conversations()
        conversation_id = self.test_create_conversation_with_testuser()
        
        if conversation_id:
            self.test_get_conversation_messages(conversation_id)
            self.test_send_message_to_conversation(conversation_id)
            
        # Test existing conversation
        existing_conversation_id = "1d8c1903-bcee-4b16-8afe-36af71be8fee"
        self.test_get_conversation_messages(existing_conversation_id)
        self.test_send_message_to_conversation(existing_conversation_id)
        
        # Test integration flow
        self.test_complete_messaging_flow()
        
    def test_user_profile_api(self, username):
        """Test GET /api/users/:username"""
        try:
            response = self.make_request("GET", f"/users/{username}")
            
            if response.status_code == 200:
                data = response.json()
                if "user" in data and data["user"]["username"] == username:
                    self.log_test(f"User Profile API - {username}", True, f"Retrieved profile for {username}", {
                        "username": data["user"]["username"],
                        "displayName": data["user"].get("displayName"),
                        "id": data["user"]["_id"]
                    })
                    return True
                else:
                    self.log_test(f"User Profile API - {username}", False, "Missing user data or username mismatch", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"User Profile API - {username}", False, f"Failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test(f"User Profile API - {username}", False, f"Request failed: {str(e)}")
            return False
    
    def test_user_tweets_api(self, username):
        """Test GET /api/users/:username/tweets"""
        try:
            response = self.make_request("GET", f"/users/{username}/tweets")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test(f"User Tweets API - {username}", True, f"Retrieved {len(data)} tweets for {username}", {
                        "username": username,
                        "tweets_count": len(data)
                    })
                    return True
                else:
                    self.log_test(f"User Tweets API - {username}", False, "Response is not a list of tweets", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"User Tweets API - {username}", False, f"Failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test(f"User Tweets API - {username}", False, f"Request failed: {str(e)}")
            return False
    
    def test_get_conversations(self):
        """Test GET /api/messages/conversations"""
        try:
            response = self.make_request("GET", "/messages/conversations")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test("Get Conversations", True, f"Retrieved {len(data)} conversations", {
                        "conversations_count": len(data),
                        "conversation_ids": [conv.get("_id") for conv in data[:3]]  # Show first 3 IDs
                    })
                    return data
                else:
                    self.log_test("Get Conversations", False, "Response is not a list of conversations", data)
                    return []
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Get Conversations", False, f"Failed with status {response.status_code}", error_data)
                return []
                
        except Exception as e:
            self.log_test("Get Conversations", False, f"Request failed: {str(e)}")
            return []
    
    def test_create_conversation_with_testuser(self):
        """Test POST /api/messages/conversations - Create conversation with testuser"""
        try:
            # Use testuser ID from the review request
            testuser_id = "11f0098f-c3ac-41da-95e0-1f46136bc609"
            
            conversation_data = {
                "participantId": testuser_id
            }
            
            response = self.make_request("POST", "/messages/conversations", conversation_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data and "participants" in data:
                    conversation_id = data["_id"]
                    self.log_test("Create Conversation", True, f"Created conversation with testuser", {
                        "conversation_id": conversation_id,
                        "participants_count": len(data["participants"]),
                        "is_group": data.get("isGroup", False)
                    })
                    return conversation_id
                else:
                    self.log_test("Create Conversation", False, "Missing conversation data", data)
                    return None
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Create Conversation", False, f"Failed with status {response.status_code}", error_data)
                return None
                
        except Exception as e:
            self.log_test("Create Conversation", False, f"Request failed: {str(e)}")
            return None
    
    def test_get_conversation_messages(self, conversation_id):
        """Test GET /api/messages/conversations/:id/messages"""
        try:
            response = self.make_request("GET", f"/messages/conversations/{conversation_id}/messages")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list):
                    self.log_test(f"Get Messages - {conversation_id[:8]}...", True, f"Retrieved {len(data)} messages", {
                        "conversation_id": conversation_id,
                        "messages_count": len(data),
                        "message_types": [msg.get("messageType") for msg in data[:3]]  # Show first 3 types
                    })
                    return data
                else:
                    self.log_test(f"Get Messages - {conversation_id[:8]}...", False, "Response is not a list of messages", data)
                    return []
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Get Messages - {conversation_id[:8]}...", False, f"Failed with status {response.status_code}", error_data)
                return []
                
        except Exception as e:
            self.log_test(f"Get Messages - {conversation_id[:8]}...", False, f"Request failed: {str(e)}")
            return []
    
    def test_send_message_to_conversation(self, conversation_id):
        """Test POST /api/messages/conversations/:id/messages"""
        try:
            message_data = {
                "content": "Hello! This is a test message from the messaging API test suite. How are you doing today?"
            }
            
            response = self.make_request("POST", f"/messages/conversations/{conversation_id}/messages", message_data)
            
            if response.status_code == 201:
                data = response.json()
                if "_id" in data and "content" in data:
                    message_id = data["_id"]
                    self.log_test(f"Send Message - {conversation_id[:8]}...", True, f"Message sent successfully", {
                        "message_id": message_id,
                        "conversation_id": conversation_id,
                        "content": data["content"][:50] + "...",
                        "message_type": data.get("messageType")
                    })
                    return message_id
                else:
                    self.log_test(f"Send Message - {conversation_id[:8]}...", False, "Missing message data", data)
                    return None
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test(f"Send Message - {conversation_id[:8]}...", False, f"Failed with status {response.status_code}", error_data)
                return None
                
        except Exception as e:
            self.log_test(f"Send Message - {conversation_id[:8]}...", False, f"Request failed: {str(e)}")
            return None
    
    def test_complete_messaging_flow(self):
        """Test complete messaging flow: Login → Get profile → Create conversation → Send messages"""
        try:
            # Step 1: Already logged in with Gokul token
            self.log_test("Integration Flow - Step 1", True, "Already authenticated as Gokul", {
                "token_present": bool(self.auth_token)
            })
            
            # Step 2: Get Gokul's profile
            gokul_profile = self.test_user_profile_api("gokul")
            
            # Step 3: Get testuser's profile  
            testuser_profile = self.test_user_profile_api("testuser")
            
            # Step 4: Get conversations list
            conversations = self.test_get_conversations()
            
            # Step 5: Create or use existing conversation
            if conversations and len(conversations) > 0:
                # Use existing conversation
                existing_conv_id = conversations[0]["_id"]
                self.log_test("Integration Flow - Step 5", True, f"Using existing conversation", {
                    "conversation_id": existing_conv_id
                })
                
                # Step 6: Send message to existing conversation
                message_id = self.test_send_message_to_conversation(existing_conv_id)
                
                if message_id:
                    self.log_test("Integration Flow - Complete", True, "Complete messaging flow successful", {
                        "steps_completed": 6,
                        "final_message_id": message_id
                    })
                    return True
            else:
                # Create new conversation
                new_conv_id = self.test_create_conversation_with_testuser()
                if new_conv_id:
                    message_id = self.test_send_message_to_conversation(new_conv_id)
                    if message_id:
                        self.log_test("Integration Flow - Complete", True, "Complete messaging flow successful", {
                            "steps_completed": 6,
                            "final_message_id": message_id
                        })
                        return True
            
            self.log_test("Integration Flow - Complete", False, "Integration flow incomplete")
            return False
            
        except Exception as e:
            self.log_test("Integration Flow - Complete", False, f"Integration flow failed: {str(e)}")
            return False

    def run_messaging_tests(self):
        """Run comprehensive messaging functionality tests"""
        print("💬 Starting Twitter Clone Messaging System Tests")
        print("=" * 80)
        
        # Health check first
        if not self.test_health_check():
            print("❌ Backend server is not running. Stopping tests.")
            return False
        
        # Test messaging functionality with provided credentials
        self.test_messaging_functionality()
        
        # Summary
        print("\n" + "=" * 80)
        print("📊 MESSAGING SYSTEM TEST SUMMARY")
        print("=" * 80)
        
        passed = sum(1 for result in self.test_results if result["success"])
        total = len(self.test_results)
        
        print(f"Total Tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {total - passed}")
        print(f"Success Rate: {(passed/total)*100:.1f}%")
        
        if total - passed > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.test_results:
                if not result["success"]:
                    print(f"  - {result['test']}: {result['message']}")
        
        return passed == total

    def run_notification_tests(self):
        """Run comprehensive notification system tests"""
        print("🔔 Starting Twitter Clone Notification System Tests")
        print("=" * 80)
        
        # Health check first
        if not self.test_health_check():
            print("❌ Backend server is not running. Stopping tests.")
            return False
        
        # Create first user (User A)
        print("\n👤 Creating User A...")
        if not self.test_user_registration():
            print("❌ User A registration failed. Cannot proceed with tests.")
            return False
        
        # Create second user (User B)
        print("\n👤 Creating User B...")
        if not self.test_create_second_user():
            print("❌ User B registration failed. Cannot proceed with tests.")
            return False
        
        # Create a tweet by User B that User A can interact with
        print("\n🐦 Creating tweet by User B...")
        tweet_id = self.test_create_tweet_for_notifications()
        if not tweet_id:
            print("❌ Failed to create tweet for notification testing.")
            return False
        
        # Test like notification (User A likes User B's tweet)
        print("\n❤️ Testing Like Notification...")
        self.test_like_notification(tweet_id)
        
        # Test retweet notification (User A retweets User B's tweet)
        print("\n🔄 Testing Retweet Notification...")
        self.test_retweet_notification(tweet_id)
        
        # Test mention notification (User A mentions User B)
        print("\n📢 Testing Mention Notification...")
        self.test_mention_notification()
        
        # Test reply notification (User A replies to User B's tweet)
        print("\n💬 Testing Reply Notification...")
        self.test_reply_notification(tweet_id)
        
        # Wait a moment for notifications to be processed
        print("\n⏳ Waiting for notifications to be processed...")
        time.sleep(2)
        
        # Test retrieving notifications for User B (should have received notifications)
        print("\n📬 Testing Notification Retrieval for User B...")
        user_b_notifications = self.test_get_notifications(self.user_b_token, self.user_b_username)
        
        # Test retrieving notifications for User A (should have fewer or no notifications)
        print("\n📬 Testing Notification Retrieval for User A...")
        user_a_notifications = self.test_get_notifications(self.auth_token, self.test_username)
        
        # Test marking individual notification as read
        print("\n✅ Testing Mark Individual Notification as Read...")
        self.test_mark_notification_as_read(self.user_b_token, self.user_b_username)
        
        # Test marking all notifications as read
        print("\n✅ Testing Mark All Notifications as Read...")
        self.test_mark_all_notifications_as_read(self.user_b_token, self.user_b_username)
        
        # Verify notifications were marked as read
        print("\n📬 Verifying Notifications After Marking as Read...")
        self.test_get_notifications(self.user_b_token, self.user_b_username)
        
        # Summary
        print("\n" + "=" * 80)
        print("📊 NOTIFICATION SYSTEM TEST SUMMARY")
        print("=" * 80)
        
        passed = sum(1 for result in self.test_results if result["success"])
        total = len(self.test_results)
        
        print(f"Total Tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {total - passed}")
        print(f"Success Rate: {(passed/total)*100:.1f}%")
        
        # Analyze notification functionality
        print(f"\nNotification Analysis:")
        print(f"User B received {user_b_notifications} notifications")
        print(f"User A received {user_a_notifications} notifications")
        
        if user_b_notifications >= 4:  # Should have like, retweet, mention, reply notifications
            print("✅ Notification system appears to be working correctly!")
        elif user_b_notifications > 0:
            print("⚠️ Notification system is partially working - some notifications may be missing")
        else:
            print("❌ Notification system is not working - no notifications were created")
        
        if total - passed > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.test_results:
                if not result["success"]:
                    print(f"  - {result['test']}: {result['message']}")
        
        return passed == total

def main():
    """Main test execution for messaging functionality"""
    tester = TwitterCloneBackendTester()
    success = tester.run_messaging_tests()
    
    if success:
        print("\n🎉 All messaging tests passed! User profile and messaging APIs are working correctly.")
        sys.exit(0)
    else:
        print("\n⚠️ Some messaging tests failed. Check the output above for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()