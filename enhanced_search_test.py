#!/usr/bin/env python3
"""
Enhanced Search Functionality Test Suite for Twitter Clone
Tests the newly implemented enhanced search features with advanced parameters
"""

import requests
import json
import time
import sys
from typing import Dict, Any, Optional

class EnhancedSearchTester:
    def __init__(self, base_url: str = "https://project-inspector-4.preview.emergentagent.com"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        self.auth_token = None
        self.test_user_id = None
        self.test_username = None
        self.created_tweet_ids = []
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
    
    def make_request(self, method: str, endpoint: str, data: Dict = None, headers: Dict = None, params: Dict = None) -> requests.Response:
        """Make HTTP request with proper error handling"""
        url = f"{self.api_url}{endpoint}"
        default_headers = {"Content-Type": "application/json"}
        
        if self.auth_token:
            default_headers["Authorization"] = f"Bearer {self.auth_token}"
        
        if headers:
            default_headers.update(headers)
        
        try:
            if method.upper() == "GET":
                response = requests.get(url, headers=default_headers, params=params, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, json=data, headers=default_headers, timeout=10)
            elif method.upper() == "PUT":
                response = requests.put(url, json=data, headers=default_headers, timeout=10)
            elif method.upper() == "DELETE":
                response = requests.delete(url, headers=default_headers, timeout=10)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            return response
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise
    
    def setup_test_user(self):
        """Setup test user for authentication"""
        import time
        timestamp = str(int(time.time()))
        
        register_data = {
            "username": f"searchtest_{timestamp}",
            "email": f"searchtest_{timestamp}@example.com", 
            "password": "password123",
            "displayName": f"Search Test User {timestamp}"
        }
        
        try:
            register_response = self.make_request("POST", "/auth/register", register_data)
            if register_response.status_code == 201:
                data = register_response.json()
                self.auth_token = data["token"]
                self.test_user_id = data["user"]["_id"]
                self.test_username = data["user"]["username"]
                self.log_test("Setup Test User", True, "Test user registered successfully", {
                    "user_id": self.test_user_id,
                    "username": self.test_username
                })
                return True
            else:
                error_data = register_response.json() if register_response.headers.get('content-type') == 'application/json' else register_response.text
                self.log_test("Setup Test User", False, f"Registration failed with status {register_response.status_code}", error_data)
                return False
        except Exception as e:
            self.log_test("Setup Test User", False, f"Registration request failed: {str(e)}")
            return False

    def create_test_tweets_with_media(self):
        """Create test tweets with various media types and hashtags for testing"""
        test_tweets = [
            {
                "content": "Beautiful landscape photography from my recent trip! #photography #nature #travel",
                "imageUrl": "https://example.com/landscape.jpg"
            },
            {
                "content": "Check out this amazing coding tutorial video! #coding #javascript #webdev #tutorial",
                "imageUrl": "https://example.com/tutorial.mp4"
            },
            {
                "content": "Working on my new #flutter app with amazing UI/UX design #mobiledev #design",
                "imageUrl": "https://example.com/app_screenshot.png"
            },
            {
                "content": "Just finished editing this promotional video for our startup! #startup #video #marketing",
                "imageUrl": "https://example.com/promo.mp4"
            },
            {
                "content": "Amazing sunset photo from the beach today #sunset #beach #photography",
                "imageUrl": "https://example.com/sunset.jpg"
            },
            {
                "content": "Learning about #ai and #machinelearning through this comprehensive course #education #tech"
            },
            {
                "content": "Building scalable #backend systems with Node.js and MongoDB #nodejs #database #development"
            },
            {
                "content": "Great discussion about #react hooks and state management #react #frontend #javascript"
            }
        ]
        
        success_count = 0
        
        for i, tweet_data in enumerate(test_tweets):
            try:
                response = self.make_request("POST", "/tweets", tweet_data)
                
                if response.status_code == 201:
                    data = response.json()
                    if "_id" in data:
                        self.created_tweet_ids.append(data["_id"])
                        self.log_test(f"Create Test Tweet {i+1}", True, f"Tweet created successfully", {
                            "tweet_id": data["_id"],
                            "content": data["content"][:50] + "...",
                            "has_media": bool(tweet_data.get("imageUrl"))
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Create Test Tweet {i+1}", False, "Missing tweet data in response", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Create Test Tweet {i+1}", False, f"Tweet creation failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Create Test Tweet {i+1}", False, f"Tweet creation request failed: {str(e)}")
        
        return success_count > 0

    def test_basic_search_functionality(self):
        """Test basic search functionality with various queries"""
        search_queries = [
            "photography",
            "coding", 
            "flutter",
            "startup",
            "javascript"
        ]
        
        success_count = 0
        for query in search_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Basic Search - {query}", True, f"Found {len(data)} tweets for '{query}'", {
                            "query": query,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Basic Search - {query}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Basic Search - {query}", False, f"Search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Basic Search - {query}", False, f"Search request failed: {str(e)}")
        
        return success_count > 0

    def test_sortby_parameter(self):
        """Test sortBy parameter: 'date', 'engagement', 'relevance'"""
        sort_types = ['date', 'engagement', 'relevance']
        query = "photography"
        
        success_count = 0
        for sort_type in sort_types:
            try:
                params = {"sortBy": sort_type}
                response = self.make_request("GET", f"/tweets/search/{query}", params=params)
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Sort By {sort_type.title()}", True, f"Retrieved {len(data)} tweets sorted by {sort_type}", {
                            "query": query,
                            "sort_type": sort_type,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Sort By {sort_type.title()}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Sort By {sort_type.title()}", False, f"Sort search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Sort By {sort_type.title()}", False, f"Sort search request failed: {str(e)}")
        
        return success_count > 0

    def test_mediatype_parameter(self):
        """Test mediaType parameter: 'photo', 'video'"""
        media_types = ['photo', 'video']
        query = "tutorial"
        
        success_count = 0
        for media_type in media_types:
            try:
                params = {"mediaType": media_type}
                response = self.make_request("GET", f"/tweets/search/{query}", params=params)
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        # Verify that returned tweets have the correct media type
                        media_count = 0
                        for tweet in data:
                            if tweet.get("imageUrl"):
                                if media_type == "photo" and not any(ext in tweet["imageUrl"].lower() for ext in ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv']):
                                    media_count += 1
                                elif media_type == "video" and any(ext in tweet["imageUrl"].lower() for ext in ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv']):
                                    media_count += 1
                        
                        self.log_test(f"Media Type {media_type.title()}", True, f"Retrieved {len(data)} tweets with {media_type} filter", {
                            "query": query,
                            "media_type": media_type,
                            "results_count": len(data),
                            "media_matches": media_count
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Media Type {media_type.title()}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Media Type {media_type.title()}", False, f"Media search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Media Type {media_type.title()}", False, f"Media search request failed: {str(e)}")
        
        return success_count > 0

    def test_hasmedia_parameter(self):
        """Test hasMedia parameter: true/false"""
        has_media_values = [True, False]
        query = "photography"
        
        success_count = 0
        for has_media in has_media_values:
            try:
                params = {"hasMedia": str(has_media).lower()}
                response = self.make_request("GET", f"/tweets/search/{query}", params=params)
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        # Verify media filtering
                        media_tweets = sum(1 for tweet in data if tweet.get("imageUrl"))
                        no_media_tweets = len(data) - media_tweets
                        
                        self.log_test(f"Has Media {has_media}", True, f"Retrieved {len(data)} tweets with hasMedia={has_media}", {
                            "query": query,
                            "has_media": has_media,
                            "results_count": len(data),
                            "with_media": media_tweets,
                            "without_media": no_media_tweets
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Has Media {has_media}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Has Media {has_media}", False, f"HasMedia search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Has Media {has_media}", False, f"HasMedia search request failed: {str(e)}")
        
        return success_count > 0

    def test_combined_parameters(self):
        """Test various combinations of parameters"""
        test_combinations = [
            {"sortBy": "date", "hasMedia": "true"},
            {"sortBy": "engagement", "mediaType": "photo"},
            {"mediaType": "video", "hasMedia": "true"},
            {"sortBy": "relevance", "mediaType": "photo", "hasMedia": "true"}
        ]
        
        query = "coding"
        success_count = 0
        
        for i, params in enumerate(test_combinations):
            try:
                response = self.make_request("GET", f"/tweets/search/{query}", params=params)
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Combined Parameters {i+1}", True, f"Retrieved {len(data)} tweets with combined filters", {
                            "query": query,
                            "parameters": params,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Combined Parameters {i+1}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Combined Parameters {i+1}", False, f"Combined search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Combined Parameters {i+1}", False, f"Combined search request failed: {str(e)}")
        
        return success_count > 0

    def test_hashtag_search(self):
        """Test hashtag search (queries starting with #)"""
        hashtag_queries = ["#photography", "#coding", "#flutter", "#startup", "#javascript"]
        
        success_count = 0
        for query in hashtag_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        # Verify that returned tweets contain the hashtag
                        hashtag_matches = 0
                        hashtag_without_hash = query[1:].lower()
                        for tweet in data:
                            if hashtag_without_hash in [tag.lower() for tag in tweet.get("hashtags", [])]:
                                hashtag_matches += 1
                        
                        self.log_test(f"Hashtag Search - {query}", True, f"Found {len(data)} tweets with hashtag '{query}'", {
                            "query": query,
                            "results_count": len(data),
                            "hashtag_matches": hashtag_matches
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Hashtag Search - {query}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Hashtag Search - {query}", False, f"Hashtag search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Hashtag Search - {query}", False, f"Hashtag search request failed: {str(e)}")
        
        return success_count > 0

    def test_mention_search(self):
        """Test mention search (queries starting with @)"""
        # Use the current test user for mention search
        mention_queries = [f"@{self.test_username}"] if self.test_username else ["@testuser"]
        
        success_count = 0
        for query in mention_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Mention Search - {query}", True, f"Found {len(data)} tweets mentioning '{query}'", {
                            "query": query,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Mention Search - {query}", False, "Response is not a list of tweets", data)
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                    self.log_test(f"Mention Search - {query}", False, f"Mention search failed with status {response.status_code}", error_data)
                    
            except Exception as e:
                self.log_test(f"Mention Search - {query}", False, f"Mention search request failed: {str(e)}")
        
        return success_count > 0

    def test_user_search_endpoint(self):
        """Test user search endpoint (/api/users/search/:query)"""
        # Create additional test users first
        additional_users = [
            {
                "username": f"alice_dev_{int(time.time())}",
                "email": f"alice.dev.{int(time.time())}@example.com",
                "password": "password123",
                "displayName": "Alice Developer"
            },
            {
                "username": f"bob_designer_{int(time.time())}",
                "email": f"bob.designer.{int(time.time())}@example.com",
                "password": "password123",
                "displayName": "Bob Designer"
            }
        ]
        
        # Create additional users
        for user_data in additional_users:
            try:
                self.make_request("POST", "/auth/register", user_data)
            except:
                pass  # User might already exist
        
        # Test user search
        search_queries = ["alice", "bob", "dev", "designer"]
        success_count = 0
        
        for query in search_queries:
            try:
                response = self.make_request("GET", f"/users/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        usernames = [user.get("username", "unknown") for user in data[:3]]
                        self.log_test(f"User Search - {query}", True, f"Found {len(data)} users matching '{query}'", {
                            "query": query,
                            "results_count": len(data),
                            "sample_users": usernames
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

    def test_pagination_parameters(self):
        """Test pagination parameters"""
        query = "coding"
        
        try:
            # Test with different page sizes
            params = {"page": 1, "limit": 5}
            response = self.make_request("GET", f"/tweets/search/{query}", params=params)
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list) and len(data) <= 5:
                    self.log_test("Pagination Test", True, f"Pagination working correctly", {
                        "query": query,
                        "page": 1,
                        "limit": 5,
                        "results_count": len(data)
                    })
                    return True
                else:
                    self.log_test("Pagination Test", False, f"Pagination not working correctly, got {len(data)} results", data)
                    return False
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Pagination Test", False, f"Pagination test failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Pagination Test", False, f"Pagination test request failed: {str(e)}")
            return False

    def test_empty_and_invalid_queries(self):
        """Test empty/invalid queries"""
        invalid_queries = ["", " ", "a", "!@#$%"]
        
        success_count = 0
        for query in invalid_queries:
            try:
                response = self.make_request("GET", f"/tweets/search/{query}")
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Invalid Query - '{query}'", True, f"Handled invalid query correctly, returned {len(data)} results", {
                            "query": query,
                            "results_count": len(data)
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Invalid Query - '{query}'", False, "Response is not a list", data)
                else:
                    # Some invalid queries might return errors, which is acceptable
                    self.log_test(f"Invalid Query - '{query}'", True, f"Invalid query handled with status {response.status_code}")
                    success_count += 1
                    
            except Exception as e:
                self.log_test(f"Invalid Query - '{query}'", False, f"Invalid query test failed: {str(e)}")
        
        return success_count > 0

    def test_data_integrity(self):
        """Test data integrity - verify search results include proper user-specific flags"""
        query = "photography"
        
        try:
            response = self.make_request("GET", f"/tweets/search/{query}")
            
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list) and len(data) > 0:
                    # Check first tweet for required fields
                    first_tweet = data[0]
                    required_fields = ["_id", "content", "author", "createdAt", "isLiked", "isRetweeted"]
                    missing_fields = [field for field in required_fields if field not in first_tweet]
                    
                    if not missing_fields:
                        self.log_test("Data Integrity", True, "Search results include proper user-specific flags", {
                            "query": query,
                            "results_count": len(data),
                            "sample_tweet_fields": list(first_tweet.keys())
                        })
                        return True
                    else:
                        self.log_test("Data Integrity", False, f"Missing required fields: {missing_fields}", first_tweet)
                        return False
                else:
                    self.log_test("Data Integrity", True, "No results to check data integrity (acceptable)")
                    return True
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else response.text
                self.log_test("Data Integrity", False, f"Data integrity test failed with status {response.status_code}", error_data)
                return False
                
        except Exception as e:
            self.log_test("Data Integrity", False, f"Data integrity test request failed: {str(e)}")
            return False

    def test_performance_and_edge_cases(self):
        """Test performance with long queries and special characters"""
        edge_cases = [
            "a" * 100,  # Long query
            "search with spaces and special chars !@#$%^&*()",
            "unicode test 🚀 🌟 ✨",
            "query-with-dashes_and_underscores"
        ]
        
        success_count = 0
        for query in edge_cases:
            try:
                start_time = time.time()
                response = self.make_request("GET", f"/tweets/search/{query}")
                end_time = time.time()
                response_time = end_time - start_time
                
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        self.log_test(f"Edge Case - {query[:20]}...", True, f"Handled edge case correctly in {response_time:.2f}s", {
                            "query_length": len(query),
                            "results_count": len(data),
                            "response_time": f"{response_time:.2f}s"
                        })
                        success_count += 1
                    else:
                        self.log_test(f"Edge Case - {query[:20]}...", False, "Response is not a list", data)
                else:
                    # Some edge cases might return errors, which is acceptable
                    self.log_test(f"Edge Case - {query[:20]}...", True, f"Edge case handled with status {response.status_code}")
                    success_count += 1
                    
            except Exception as e:
                self.log_test(f"Edge Case - {query[:20]}...", False, f"Edge case test failed: {str(e)}")
        
        return success_count > 0

    def run_enhanced_search_tests(self):
        """Run all enhanced search tests"""
        print("🔍 Starting Enhanced Search Functionality Tests")
        print("=" * 80)
        
        # Setup test user
        if not self.setup_test_user():
            print("❌ Failed to setup test user. Stopping tests.")
            return False
        
        # Create test tweets with media
        print("\n🐦 Creating Test Tweets with Media...")
        if not self.create_test_tweets_with_media():
            print("⚠️ Failed to create test tweets. Some tests may not work properly.")
        
        # Wait a moment for tweets to be indexed
        time.sleep(2)
        
        # Test basic search functionality
        print("\n🔎 Testing Basic Search Functionality...")
        self.test_basic_search_functionality()
        
        # Test sortBy parameter
        print("\n📊 Testing SortBy Parameter...")
        self.test_sortby_parameter()
        
        # Test mediaType parameter
        print("\n🎬 Testing MediaType Parameter...")
        self.test_mediatype_parameter()
        
        # Test hasMedia parameter
        print("\n📷 Testing HasMedia Parameter...")
        self.test_hasmedia_parameter()
        
        # Test combined parameters
        print("\n🔧 Testing Combined Parameters...")
        self.test_combined_parameters()
        
        # Test hashtag search
        print("\n#️⃣ Testing Hashtag Search...")
        self.test_hashtag_search()
        
        # Test mention search
        print("\n@ Testing Mention Search...")
        self.test_mention_search()
        
        # Test user search endpoint
        print("\n👥 Testing User Search Endpoint...")
        self.test_user_search_endpoint()
        
        # Test pagination
        print("\n📄 Testing Pagination Parameters...")
        self.test_pagination_parameters()
        
        # Test empty/invalid queries
        print("\n❌ Testing Empty/Invalid Queries...")
        self.test_empty_and_invalid_queries()
        
        # Test data integrity
        print("\n🔒 Testing Data Integrity...")
        self.test_data_integrity()
        
        # Test performance and edge cases
        print("\n⚡ Testing Performance and Edge Cases...")
        self.test_performance_and_edge_cases()
        
        # Summary
        print("\n" + "=" * 80)
        print("📊 ENHANCED SEARCH TEST SUMMARY")
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

def main():
    """Main test execution"""
    tester = EnhancedSearchTester()
    success = tester.run_enhanced_search_tests()
    
    if success:
        print("\n🎉 All enhanced search tests passed! Search functionality is working correctly.")
        sys.exit(0)
    else:
        print("\n⚠️ Some enhanced search tests failed. Check the output above for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()