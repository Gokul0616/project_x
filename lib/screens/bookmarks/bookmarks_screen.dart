import 'package:flutter/material.dart';
import '../../models/tweet_model.dart';
import '../../widgets/tweet_card.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Tweet> _bookmarkedTweets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _sortBy = 'date'; // date, author, engagement
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBookmarks(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200.0) {
      _loadMoreBookmarks();
    }
  }

  void _loadBookmarks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _bookmarkedTweets.clear();
    }

    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = refresh || _bookmarkedTweets.isEmpty;
      _isLoadingMore = !refresh && _bookmarkedTweets.isNotEmpty;
    });

    try {
      final newBookmarks = await ApiService.getBookmarks(
        page: _currentPage,
        limit: 20,
        sortBy: _sortBy,
      );

      if (newBookmarks.isEmpty) {
        _hasMore = false;
      } else {
        if (refresh) {
          _bookmarkedTweets = newBookmarks;
        } else {
          _bookmarkedTweets.addAll(newBookmarks);
        }
        _currentPage++;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading bookmarks: $e')));
    }
  }

  void _loadMoreBookmarks() {
    if (!_isLoadingMore && _hasMore) {
      _loadBookmarks();
    }
  }

  void _sortTweets(String newSortBy) {
    if (_sortBy != newSortBy) {
      setState(() {
        _sortBy = newSortBy;
      });
      _loadBookmarks(refresh: true);
    }
  }

  void _removeBookmark(String tweetId) async {
    try {
      final result = await ApiService.removeBookmark(tweetId);
      if (result['success']) {
        setState(() {
          _bookmarkedTweets.removeWhere((tweet) => tweet.id == tweetId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing bookmark: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'sort_date':
                  _sortTweets('date');
                  break;
                case 'sort_author':
                  _sortTweets('author');
                  break;
                case 'sort_engagement':
                  _sortTweets('engagement');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: _sortBy == 'date' ? AppTheme.twitterBlue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Date',
                      style: TextStyle(
                        color: _sortBy == 'date' ? AppTheme.twitterBlue : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_author',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 18,
                      color: _sortBy == 'author' ? AppTheme.twitterBlue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Author',
                      style: TextStyle(
                        color: _sortBy == 'author'
                            ? AppTheme.twitterBlue
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_engagement',
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 18,
                      color: _sortBy == 'engagement'
                          ? AppTheme.twitterBlue
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Engagement',
                      style: TextStyle(
                        color: _sortBy == 'engagement'
                            ? AppTheme.twitterBlue
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading && _bookmarkedTweets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedTweets.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Sort indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Sorted by: ${_getSortDisplayName(_sortBy)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        '${_bookmarkedTweets.length} bookmark${_bookmarkedTweets.length != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Tweets list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _loadBookmarks(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _bookmarkedTweets.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _bookmarkedTweets.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.twitterBlue,
                                ),
                              ),
                            ),
                          );
                        }

                        final tweet = _bookmarkedTweets[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: TweetCard(
                            tweet: tweet,
                            onTweetUpdated: (updatedTweet) {
                              setState(() {
                                final index = _bookmarkedTweets.indexWhere(
                                  (t) => t.id == updatedTweet.id,
                                );
                                if (index != -1) {
                                  _bookmarkedTweets[index] = updatedTweet;
                                }
                              });
                            },
                            showBookmarkAction: true,
                            isBookmarked: true,
                            onBookmarkToggle: () => _removeBookmark(tweet.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on any tweet\nto save it for later',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.twitterBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Explore Tweets'),
          ),
        ],
      ),
    );
  }

  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'date':
        return 'Date Added';
      case 'author':
        return 'Author';
      case 'engagement':
        return 'Engagement';
      default:
        return 'Date Added';
    }
  }
}
