import 'package:flutter/material.dart';
import 'dart:async';
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
  
  // Store individual tweets and their replies for detail screens
  Map<String, Tweet> _tweetDetails = {};
  Map<String, List<Tweet>> _tweetReplies = {};

  List<Tweet> get tweets => _tweets;
  List<Tweet> get recommendedTweets => _recommendedTweets; 
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNewTweets => _hasNewTweets;
  bool get hasMoreTweets => _hasMoreTweets;
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
    // Auto-refresh every 30 seconds to check for new tweets
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForNewTweets();
    });
  }

  Future<void> _checkForNewTweets() async {
    if (_tweets.isEmpty) return;

    try {
      final newTweets = await ApiService.getTweets(page: 1, limit: 20);
      final latestTweetId = _tweets.isNotEmpty ? _tweets.first.id : '';
      
      // Check if there are new tweets
      bool hasNew = false;
      for (var tweet in newTweets) {
        if (tweet.id == latestTweetId) break;
        hasNew = true;
        break;
      }

      if (hasNew && !_hasNewTweets) {
        _hasNewTweets = true;
        notifyListeners();
      }
    } catch (e) {
      print('Auto-refresh error: $e');
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

    _isLoading = refresh || _tweets.isEmpty;
    _isLoadingMore = !refresh && _tweets.isNotEmpty;
    _error = null;
    _hasNewTweets = false;  // Clear the flag when manually refreshing
    notifyListeners();

    try {
      final newTweets = await ApiService.getTweets(page: _currentPage, limit: 20);
      
      if (newTweets.isEmpty) {
        _hasMoreTweets = false;
      } else {
        if (refresh) {
          _tweets = newTweets;
        } else {
          _tweets.addAll(newTweets);
        }
        _currentPage++;
      }
      
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendedTweets({bool refresh = false}) async {
    if (refresh) {
      _currentRecommendedPage = 1;
      _hasMoreRecommended = true;
      _recommendedTweets.clear();
    }
    
    if (!_hasMoreRecommended && !refresh) return;

    try {
      final newRecommended = await ApiService.getRecommendedTweets(
        page: _currentRecommendedPage, 
        limit: 10
      );
      
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
      print('Error loading recommended tweets: $e');
    }
  }

  Future<void> loadMoreTweets() async {
    if (_isLoadingMore || !_hasMoreTweets) return;
    
    await loadTweets(refresh: false);
  }

  Future<void> refreshTweets() async {
    await loadTweets(refresh: true);
    await loadRecommendedTweets(refresh: true);
  }

  Future<Map<String, dynamic>> createTweet(String content, {List<Map<String, dynamic>>? mediaFiles}) async {
    try {
      final result = await ApiService.createTweet(content, mediaFiles: mediaFiles);
      
      if (result['success']) {
        // Add new tweet to the beginning of the list
        _tweets.insert(0, result['tweet']);
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Failed to create tweet: $e'};
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
        print('Error liking tweet: ${result['message']}');
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
      print('Error liking tweet: $e');
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
        print('Error retweeting: ${result['message']}');
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
      print('Error retweeting: $e');
    }
  }

  Future<Map<String, dynamic>> replyToTweet(String tweetId, String content) async {
    try {
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
      print('Error loading replies: $e');
      return [];
    }
  }
  
  // Method to update tweet details cache when viewing detail screen
  void cacheTweetDetails(Tweet tweet) {
    _tweetDetails[tweet.id] = tweet;
  }

  // User-specific tweet methods
  Future<List<Tweet>> getUserTweets(String username) async {
    try {
      return await ApiService.getUserTweets(username);
    } catch (e) {
      print('Error loading user tweets: $e');
      return [];
    }
  }

  Future<List<Tweet>> getUserReplies(String username) async {
    try {
      return await ApiService.getUserReplies(username);
    } catch (e) {
      print('Error loading user replies: $e');
      return [];
    }
  }

  Future<List<Tweet>> getUserLikedTweets(String username) async {
    try {
      return await ApiService.getUserLikedTweets(username);
    } catch (e) {
      print('Error loading user liked tweets: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}