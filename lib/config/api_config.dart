class ApiConfig {
  // Environment-based configuration
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Different base URLs for different environments
  static const String _developmentUrl = 'http://192.168.1.19:3000/api';
  static const String _productionUrl = 'https://your-production-domain.com/api';
  static const String _stagingUrl = 'https://staging.your-domain.com/api';

  // Platform-specific URLs for development
  static const String _iosSimulator = 'http://localhost:8001/api';

  // Get base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return _productionUrl;
      case 'staging':
        return _stagingUrl;
      case 'development':
      default:
        // Auto-detect platform for development
        return _getDevelopmentUrl();
    }
  }

  static String _getDevelopmentUrl() {
    // Try to detect platform automatically
    try {
      // This is a simple way to detect platform during development
      // In a real app, you might use Platform.isAndroid, Platform.isIOS, etc.
      return _developmentUrl;
    } catch (e) {
      // Fallback to localhost
      return _iosSimulator;
    }
  }

  // API endpoint getters
  static String get tweetsEndpoint => '$baseUrl/tweets';
  static String get authEndpoint => '$baseUrl/auth';
  static String get notificationsEndpoint => '$baseUrl/notifications';

  // Dynamic endpoint methods
  static String getTweetRepliesEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/replies';
  static String getLikeTweetEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/like';
  static String getRetweetEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/retweet';
  static String getReplyToTweetEndpoint(String tweetId) =>
      '$baseUrl/tweets/$tweetId/reply';
}
