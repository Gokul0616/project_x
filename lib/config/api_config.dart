class ApiConfig {
  // Different base URLs for different environments
  static const String _localhost = 'http://192.168.1.19:3000/api';
  static const String _androidEmulator = 'http://10.0.2.2:3000/api';
  static const String _iosSimulator = 'http://localhost:3000/api';

  // You can change this based on your testing environment
  static const String baseUrl = _localhost;

  // Alternative URLs you can try if localhost doesn't work:
  // 1. For Android Emulator: http://10.0.2.2:8001/api
  // 2. For physical device: http://YOUR_COMPUTER_IP:8001/api (e.g., http://192.168.1.19:8001/api)
  // 3. For iOS Simulator: http://localhost:8001/api

  static String get tweetsEndpoint => '$baseUrl/tweets';
  static String get authEndpoint => '$baseUrl/auth';
  static String get notificationsEndpoint => '$baseUrl/notifications';

  static String getTweetRepliesEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/replies';
  static String getLikeTweetEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/like';
  static String getRetweetEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/retweet';
  static String getReplyToTweetEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/reply';
}
