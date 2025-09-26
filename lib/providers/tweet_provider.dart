import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../models/tweet_model.dart';
import '../services/api_service.dart';

class TweetProvider with ChangeNotifier {
  List<Tweet> _tweets = [];
  List<Tweet> _recommendedTweets = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNewTweets = false;
  bool _hasMoreTweets = true;
  bool _hasMoreRecommended = true;
  int _currentPage = 1;
  int _currentRecommendedPage = 1;
  String? _error;
  Timer? _refreshTimer;
  DateTime? _lastFeedTimestamp;
  String? _lastTweetId;
  
  // Store individual tweets and their replies for detail screens
  Map<String, Tweet> _tweetDetails = {};
  Map<String, List<Tweet>> _tweetReplies = {};

  List<Tweet> get tweets => _tweets;
  List<Tweet> get recommendedTweets => _recommendedTweets; 
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNewTweets => _hasNewTweets;
  bool get hasMoreTweets => _hasMoreTweets;
  bool get hasMoreContent => _hasMoreTweets || _hasMoreRecommended; // New getter for combined content
  String? get error => _error;
  
  // Get a specific tweet with latest data
  Tweet? getTweetById(String tweetId) {
    return _tweetDetails[tweetId];
  }
  
  // Get replies for a specific tweet with latest data
  List<Tweet> getRepliesById(String tweetId) {
    return _tweetReplies[tweetId] ?? [];
  }

  TweetProvider() {
    // Auto-refresh every 45 seconds to check for new tweets (enhanced from 30s)
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _checkForNewTweets();
    });
  }

  Future<void> _checkForNewTweets() async {
    if (_tweets.isEmpty || _lastFeedTimestamp == null) return;

    try {
      // Use the new backend endpoint to check for new tweets
      final response = await ApiService.checkForNewTweets(_lastFeedTimestamp!);
      
      if (response['hasNewTweets'] == true && !_hasNewTweets) {
        _hasNewTweets = true;
        notifyListeners();
      }
    } catch (e) {
      Logger('TweetProvider').severe('Auto-refresh error', e);
    }
  }

  void clearNewTweetsFlag() {
    _hasNewTweets = false;
    notifyListeners();
  }

  Future<void> loadTweets({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreTweets = true;
      _tweets.clear();
    }
    
    if (!_hasMoreTweets && !refresh) return;

    // Only set loading states if this is the main call, not a sub-call from loadMoreTweets
    final shouldSetLoadingState = !_isLoadingMore;
    
    if (shouldSetLoadingState) {
      _isLoading = refresh || _tweets.isEmpty;
      _isLoadingMore = !refresh && _tweets.isNotEmpty;
    }
    
    _error = null;
    _hasNewTweets = false;  // Clear the flag when manually refreshing
    
    if (shouldSetLoadingState) {
      notifyListeners();
    }

    try {
      final response = await ApiService.getTweetsWithMetadata(
        page: _currentPage, 
        limit: 20,
        refresh: refresh,
        lastTweetId: _lastTweetId,
      );
      
      final newTweets = response['tweets'] as List<Tweet>? ?? [];
      _lastFeedTimestamp = DateTime.tryParse(response['timestamp'] ?? '');
      
      if (newTweets.isEmpty) {
        _hasMoreTweets = false;
      } else {
        if (refresh) {
          _tweets = newTweets;
          if (newTweets.isNotEmpty) {
            _lastTweetId = newTweets.first.id;
          }
        } else {
          _tweets.addAll(newTweets);
        }
        _currentPage++;
      }
      
      if (shouldSetLoadingState) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (shouldSetLoadingState) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadRecommendedTweets({bool refresh = false}) async {
    if (refresh) {
      _currentRecommendedPage = 1;
      _hasMoreRecommended = true;
      _recommendedTweets.clear();
    }
    
    if (!_hasMoreRecommended && !refresh) return;

    // Prevent multiple simultaneous calls
    if (_isLoadingMore && !refresh) return;

    try {
      final response = await ApiService.getEnhancedRecommendations(
        page: _currentRecommendedPage, 
        limit: 10,
        refresh: refresh,
      );
      
      final newRecommended = response['tweets'] as List<Tweet>? ?? [];
      
      if (newRecommended.isEmpty) {
        _hasMoreRecommended = false;
      } else {
        if (refresh) {
          _recommendedTweets = newRecommended;
        } else {
          _recommendedTweets.addAll(newRecommended);
        }
        _currentRecommendedPage++;
      }
      
      notifyListeners();
    } catch (e) {
      Logger('TweetProvider').severe('Error loading recommended tweets', e);
    }
  }

  Future<void> loadMoreTweets() async {
    if (_isLoadingMore) return;
    
    // Check if we need to load more tweets or recommendations based on the pattern
    final shouldLoadRegular = _hasMoreTweets;
    final shouldLoadRecommended = _hasMoreRecommended;
    
    if (!shouldLoadRegular && !shouldLoadRecommended) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      // Load both types in parallel for better UX
      final futures = <Future>[];
      
      if (shouldLoadRegular) {
        futures.add(loadTweets(refresh: false));
      }
      
      if (shouldLoadRecommended) {
        futures.add(loadRecommendedTweets(refresh: false));
      }
      
      await Future.wait(futures);
    } catch (e) {
      Logger('TweetProvider').severe('Error loading more tweets', e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshTweets() async {
    await Future.wait([
      loadTweets(refresh: true),
      loadRecommendedTweets(refresh: true),
    ]);
  }

  Future<Map<String, dynamic>> createTweet(String content, {List<Map<String, dynamic>>? mediaFiles}) async {
    try {
      final result = await ApiService.createTweet(content, mediaFiles: mediaFiles);
      
      if (result['success']) {
        // Add new tweet to the beginning of the list
        _tweets.insert(0, result['tweet']);
        
        // Update last tweet ID
        _lastTweetId = result['tweet'].id;
        
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Failed to create tweet: $e'};
    }
  }

  // Enhanced interaction tracking
  Future<void> _trackInteraction(String tweetId, String interactionType) async {
    try {
      await ApiService.trackInteraction(tweetId, interactionType);
    } catch (e) {
      Logger('TweetProvider').severe('Error tracking interaction', e);
    }
  }

  Future<void> likeTweet(String tweetId) async {
    // Helper function to update a tweet
    Tweet updateTweetLike(Tweet tweet) {
      return Tweet(
        id: tweet.id,
        content: tweet.content,
        author: tweet.author,
        createdAt: tweet.createdAt,
        likesCount: tweet.isLiked ? tweet.likesCount - 1 : tweet.likesCount + 1,
        retweetsCount: tweet.retweetsCount,
        repliesCount: tweet.repliesCount,
        isLiked: !tweet.isLiked,
        isRetweeted: tweet.isRetweeted,
        imageUrl: tweet.imageUrl,
        mediaFiles: tweet.mediaFiles,
        parentTweetId: tweet.parentTweetId,
        parentTweet: tweet.parentTweet,
      );
    }

    // OPTIMISTIC UPDATE - Update UI immediately
    final index = _tweets.indexWhere((tweet) => tweet.id == tweetId);
    if (index != -1) {
      _tweets[index] = updateTweetLike(_tweets[index]);
    }

    final recIndex = _recommendedTweets.indexWhere((tweet) => tweet.id == tweetId);
    if (recIndex != -1) {
      _recommendedTweets[recIndex] = updateTweetLike(_recommendedTweets[recIndex]);
    }

    if (_tweetDetails.containsKey(tweetId)) {
      _tweetDetails[tweetId] = updateTweetLike(_tweetDetails[tweetId]!);
    }

    _tweetReplies.forEach((parentId, replies) {
      final replyIndex = replies.indexWhere((reply) => reply.id == tweetId);
      if (replyIndex != -1) {
        _tweetReplies[parentId]![replyIndex] = updateTweetLike(replies[replyIndex]);
      }
    });

    // Notify listeners immediately for instant UI update
    notifyListeners();

    // Track interaction for enhanced recommendations
    await _trackInteraction(tweetId, 'like');

    // Then make the API call
    try {
      final result = await ApiService.likeTweet(tweetId);
      
      if (!result['success']) {
        // If API fails, revert the optimistic update
        final revertIndex = _tweets.indexWhere((tweet) => tweet.id == tweetId);
        if (revertIndex != -1) {
          _tweets[revertIndex] = updateTweetLike(_tweets[revertIndex]);
        }

        final revertRecIndex = _recommendedTweets.indexWhere((tweet) => tweet.id == tweetId);
        if (revertRecIndex != -1) {
          _recommendedTweets[revertRecIndex] = updateTweetLike(_recommendedTweets[revertRecIndex]);
        }

        if (_tweetDetails.containsKey(tweetId)) {
          _tweetDetails[tweetId] = updateTweetLike(_tweetDetails[tweetId]!);
        }

        _tweetReplies.forEach((parentId, replies) {
          final replyIndex = replies.indexWhere((reply) => reply.id == tweetId);
          if (replyIndex != -1) {
            _tweetReplies[parentId]![replyIndex] = updateTweetLike(replies[replyIndex]);
          }
        });

        notifyListeners();
        Logger('TweetProvider').severe('Error liking tweet: ${result['message']}');
      }
    } catch (e) {
      // If network error, revert the optimistic update
      final revertIndex = _tweets.indexWhere((tweet) => tweet.id == tweetId);
      if (revertIndex != -1) {
        _tweets[revertIndex] = updateTweetLike(_tweets[revertIndex]);
      }

      final revertRecIndex = _recommendedTweets.indexWhere((tweet) => tweet.id == tweetId);
      if (revertRecIndex != -1) {
        _recommendedTweets[revertRecIndex] = updateTweetLike(_recommendedTweets[revertRecIndex]);
      }

      if (_tweetDetails.containsKey(tweetId)) {
        _tweetDetails[tweetId] = updateTweetLike(_tweetDetails[tweetId]!);
      }

      _tweetReplies.forEach((parentId, replies) {
        final replyIndex = replies.indexWhere((reply) => reply.id == tweetId);
        if (replyIndex != -1) {
          _tweetReplies[parentId]![replyIndex] = updateTweetLike(replies[replyIndex]);
        }
      });

      notifyListeners();
      Logger('TweetProvider').severe('Error liking tweet', e);
    }
  }

  Future<void> retweetTweet(String tweetId) async {
    // Helper function to update a tweet
    Tweet updateTweetRetweet(Tweet tweet) {
      return Tweet(
        id: tweet.id,
        content: tweet.content,
        author: tweet.author,
        createdAt: tweet.createdAt,
        likesCount: tweet.likesCount,
        retweetsCount: tweet.isRetweeted ? tweet.retweetsCount - 1 : tweet.retweetsCount + 1,
        repliesCount: tweet.repliesCount,
        isLiked: tweet.isLiked,
        isRetweeted: !tweet.isRetweeted,
        imageUrl: tweet.imageUrl,
        mediaFiles: tweet.mediaFiles,
        parentTweetId: tweet.parentTweetId,
        parentTweet: tweet.parentTweet,
      );
    }

    // OPTIMISTIC UPDATE - Update UI immediately
    final index = _tweets.indexWhere((tweet) => tweet.id == tweetId);
    if (index != -1) {
      _tweets[index] = updateTweetRetweet(_tweets[index]);
    }

    final recIndex = _recommendedTweets.indexWhere((tweet) => tweet.id == tweetId);
    if (recIndex != -1) {
      _recommendedTweets[recIndex] = updateTweetRetweet(_recommendedTweets[recIndex]);
    }

    if (_tweetDetails.containsKey(tweetId)) {
      _tweetDetails[tweetId] = updateTweetRetweet(_tweetDetails[tweetId]!);
    }

    _tweetReplies.forEach((parentId, replies) {
      final replyIndex = replies.indexWhere((reply) => reply.id == tweetId);
      if (replyIndex != -1) {
        _tweetReplies[parentId]![replyIndex] = updateTweetRetweet(replies[replyIndex]);
      }
    });

    // Notify listeners immediately for instant UI update
    notifyListeners();

    // Track interaction for enhanced recommendations
    await _trackInteraction(tweetId, 'retweet');

    // Then make the API call
    try {
      final result = await ApiService.retweetTweet(tweetId);
      
      if (!result['success']) {
        // If API fails, revert the optimistic update
        final revertIndex = _tweets.indexWhere((tweet) => tweet.id == tweetId);
        if (revertIndex != -1) {
          _tweets[revertIndex] = updateTweetRetweet(_tweets[revertIndex]);
        }

        final revertRecIndex = _recommendedTweets.indexWhere((tweet) => tweet.id == tweetId);
        if (revertRecIndex != -1) {
          _recommendedTweets[revertRecIndex] = updateTweetRetweet(_recommendedTweets[revertRecIndex]);
        }

        if (_tweetDetails.containsKey(tweetId)) {
          _tweetDetails[tweetId] = updateTweetRetweet(_tweetDetails[tweetId]!);
        }

        _tweetReplies.forEach((parentId, replies) {
          final replyIndex = replies.indexWhere((reply) => reply.id == tweetId);
          if (replyIndex != -1) {
            _tweetReplies[parentId]![replyIndex] = updateTweetRetweet(replies[replyIndex]);
          }
        });

        notifyListeners();
        Logger('TweetProvider').severe('Error retweeting: ${result['message']}');
      }
    } catch (e) {
      // If network error, revert the optimistic update
      final revertIndex = _tweets.indexWhere((tweet) => tweet.id == tweetId);
      if (revertIndex != -1) {
        _tweets[revertIndex] = updateTweetRetweet(_tweets[revertIndex]);
      }

      final revertRecIndex = _recommendedTweets.indexWhere((tweet) => tweet.id == tweetId);
      if (revertRecIndex != -1) {
        _recommendedTweets[revertRecIndex] = updateTweetRetweet(_recommendedTweets[revertRecIndex]);
      }

      if (_tweetDetails.containsKey(tweetId)) {
        _tweetDetails[tweetId] = updateTweetRetweet(_tweetDetails[tweetId]!);
      }

      _tweetReplies.forEach((parentId, replies) {
        final replyIndex = replies.indexWhere((reply) => reply.id == tweetId);
        if (replyIndex != -1) {
          _tweetReplies[parentId]![replyIndex] = updateTweetRetweet(replies[replyIndex]);
        }
      });

      notifyListeners();
      Logger('TweetProvider').severe('Error retweeting', e);
    }
  }

  Future<Map<String, dynamic>> replyToTweet(String tweetId, String content) async {
    try {
      // Track interaction
      await _trackInteraction(tweetId, 'reply');
      
      final result = await ApiService.replyToTweet(tweetId, content);
      
      if (result['success']) {
        // Update the replies count for the parent tweet
        final index = _tweets.indexWhere((tweet) => tweet.id == tweetId);
        if (index != -1) {
          final tweet = _tweets[index];
          final updatedTweet = Tweet(
            id: tweet.id,
            content: tweet.content,
            author: tweet.author,
            createdAt: tweet.createdAt,
            likesCount: tweet.likesCount,
            retweetsCount: tweet.retweetsCount,
            repliesCount: tweet.repliesCount + 1,
            isLiked: tweet.isLiked,
            isRetweeted: tweet.isRetweeted,
            imageUrl: tweet.imageUrl,
            mediaFiles: tweet.mediaFiles,
            parentTweetId: tweet.parentTweetId,
            parentTweet: tweet.parentTweet,
          );
          _tweets[index] = updatedTweet;
          notifyListeners();
        }
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Failed to reply to tweet: $e'};
    }
  }

  Future<List<Tweet>> getTweetReplies(String tweetId) async {
    try {
      final replies = await ApiService.getTweetReplies(tweetId);
      // Cache the replies for future updates
      _tweetReplies[tweetId] = replies;
      notifyListeners();
      return replies;
    } catch (e) {
      Logger('TweetProvider').severe('Error loading replies', e);
      return [];
    }
  }
  
  // Method to update tweet details cache when viewing detail screen
  void cacheTweetDetails(Tweet tweet) {
    _tweetDetails[tweet.id] = tweet;
    
    // Track view interaction
    _trackInteraction(tweet.id, 'view');
  }

  // User-specific tweet methods
  Future<List<Tweet>> getUserTweets(String username) async {
    try {
      return await ApiService.getUserTweets(username);
    } catch (e) {
      Logger('TweetProvider').severe('Error loading user tweets', e);
      return [];
    }
  }

  Future<List<Tweet>> getUserReplies(String username) async {
    try {
      return await ApiService.getUserReplies(username);
    } catch (e) {
      Logger('TweetProvider').severe('Error loading user replies', e);
      return [];
    }
  }

  Future<List<Tweet>> getUserLikedTweets(String username) async {
    try {
      return await ApiService.getUserLikedTweets(username);
    } catch (e) {
      Logger('TweetProvider').severe('Error loading user liked tweets', e);
      return [];
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}