import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/tweet_card.dart';
import '../../models/tweet_model.dart';
import '../../services/api_service.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Tweet> _searchResults = [];
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _trendingHashtags = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  String _activeTab = 'Top'; // Top, Latest, People, Photos, Videos
  Timer? _debounceTimer;
  Timer? _trendingTimer;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // If there's an initial query, set it and perform search
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      // Delay the search to ensure the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
    
    _loadTrendingHashtags();
    // Set up periodic refresh for trending hashtags (every 30 seconds)
    _trendingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadTrendingHashtags();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _trendingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrendingHashtags() async {
    setState(() {
      _isLoadingTrending = true;
    });

    try {
      final response = await ApiService.getTrendingHashtags();
      if (response['success']) {
        setState(() {
          _trendingHashtags = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        // Silently fail to fallback to static trending topics
        print('Failed to load trending hashtags: ${response['message']}');
      }
    } catch (e) {
      print('Error loading trending hashtags: $e');
      // The UI will automatically fall back to static trending topics
    } finally {
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  void _performSearch(String query) {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();
    
    // Set a new timer for debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // Trim and validate query
      final trimmedQuery = query.trim();
      
      if (trimmedQuery.isEmpty) {
        setState(() {
          _searchResults = [];
          _userResults = [];
          _isSearching = false;
          _lastSearchQuery = '';
        });
        return;
      }

      // Check if this is the same query to avoid redundant searches
      if (trimmedQuery == _lastSearchQuery) {
        return;
      }

      setState(() {
        _isSearching = true;
        _lastSearchQuery = trimmedQuery;
      });

      // Add to search history (avoid duplicates and limit to 10 recent searches)
      _addToSearchHistory(trimmedQuery);

      try {
        Map<String, dynamic> response;
        
        // Handle different tabs with appropriate API calls
        if (_activeTab == 'People') {
          // For People tab, search users instead of tweets
          response = await ApiService.searchUsers(trimmedQuery);
          if (response['success']) {
            setState(() {
              _searchResults = []; // Clear tweet results for people search
              _userResults = List<Map<String, dynamic>>.from(response['data']);
            });
          }
        } else {
          // For all other tabs, search tweets with different parameters
          String? sortBy;
          String? mediaType;
          bool? hasMedia;
          
          switch (_activeTab) {
            case 'Latest':
              sortBy = 'date';
              break;
            case 'Top':
              sortBy = 'engagement';
              break;
            case 'Photos':
              mediaType = 'photo';
              break;
            case 'Videos':
              mediaType = 'video';
              break;
            default: // 'Top' or default
              sortBy = 'relevance';
          }
          
          response = await ApiService.searchTweets(
            trimmedQuery,
            sortBy: sortBy,
            mediaType: mediaType,
            hasMedia: hasMedia,
          );
          
          if (response['success']) {
            setState(() {
              _searchResults = (response['data'] as List)
                  .map((json) => Tweet.fromJson(json))
                  .toList();
              _userResults = []; // Clear user results for tweet search
            });
          }
        }

        if (!response['success']) {
          // Handle API error response
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Search failed: ${response['message'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            _searchResults = [];
            _userResults = [];
          });
        }
      } catch (e) {
        print('Error searching: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error. Please check your connection and try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _searchResults = [];
          _userResults = [];
        });
      } finally {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _addToSearchHistory(String query) {
    setState(() {
      // Remove if already exists to avoid duplicates
      _searchHistory.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      // Add to beginning
      _searchHistory.insert(0, query);
      // Keep only last 10 searches
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  void _onHashtagTap(String hashtag) {
    _searchController.text = '#$hashtag';
    _performSearch('#$hashtag');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 800 ? 800 : double.infinity,
          ),
          child: Column(
            children: [
          // Search Bar at the top - Responsive design
          Container(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width > 600 ? 24 : 16, 
              MediaQuery.of(context).padding.top + 8, 
              MediaQuery.of(context).size.width > 600 ? 24 : 16, 
              8
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.width > 600 ? 44 : 40,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkSurface
                          : AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _performSearch(value.trim());
                        }
                      },
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search Twitter',
                        hintStyle: TextStyle(
                          fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search, 
                          size: MediaQuery.of(context).size.width > 600 ? 22 : 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width > 600 ? 12 : 8,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear, 
                                  size: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                  setState(() {
                                    _lastSearchQuery = '';
                                    _searchResults = [];
                                    _userResults = [];
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Tabs (only show when searching)
          if (_searchController.text.isNotEmpty)
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['Top', 'Latest', 'People', 'Photos', 'Videos']
                    .map((tab) => _buildTabItem(tab))
                    .toList(),
              ),
            ),
          
          // Search Results or Trending
          Expanded(
            child: _buildSearchResults(),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String tab) {
    final isActive = _activeTab == tab;
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
          // Re-perform search with new tab filter when implemented
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 20 : 12, 
            vertical: 12
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.twitterBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            tab,
            style: TextStyle(
              color: isActive 
                  ? AppTheme.twitterBlue 
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return _buildTrendingSection();
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
        ),
      );
    }

    if (_searchResults.isEmpty && _userResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for something else',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results count
        Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
          child: Text(
            _activeTab == 'People'
                ? '${_userResults.length} ${_userResults.length == 1 ? 'person' : 'people'} for "${_searchController.text}"'
                : '${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'} for "${_searchController.text}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        // Search results list
        Expanded(
          child: _activeTab == 'People'
              ? ListView.builder(
                  itemCount: _userResults.length,
                  itemBuilder: (context, index) {
                    final user = _userResults[index];
                    return _buildUserCard(user);
                  },
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return TweetCard(tweet: _searchResults[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return RefreshIndicator(
      onRefresh: _loadTrendingHashtags,
      color: AppTheme.twitterBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent searches section
            if (_searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent searches',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: _clearSearchHistory,
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        color: AppTheme.twitterBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._searchHistory.take(5).map((searchQuery) => 
                _buildRecentSearchItem(searchQuery),
              ),
              const SizedBox(height: 24),
            ],
            
            // Trending section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trends for you',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_isLoadingTrending)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Real-time trending hashtags
            if (_trendingHashtags.isNotEmpty) ...[
              ..._trendingHashtags.asMap().entries.map((entry) {
                final index = entry.key;
                final hashtag = entry.value;
                return _buildTrendingItem(
                  '#${hashtag['hashtag']}',
                  '${hashtag['count']} tweets',
                  index + 1,
                );
              }),
            ] else if (!_isLoadingTrending) ...[
              // Fallback static trending topics if API fails
              ..._getStaticTrendingTopics().asMap().entries.map((entry) {
                final index = entry.key;
                final topic = entry.value;
                return _buildTrendingItem(
                  topic,
                  '${(topic.hashCode % 50000 + 1000)} tweets',
                  index + 1,
                );
              }),
            ],
            
            if (_trendingHashtags.isEmpty && _isLoadingTrending)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _getStaticTrendingTopics() {
    return [
      '#Flutter',
      '#React',
      '#AI',
      '#MachineLearning',
      '#WebDevelopment',
      '#MobileDevelopment',
      '#JavaScript',
      '#Python',
      '#DataScience',
      '#DevOps',
    ];
  }

  Widget _buildTrendingItem(String topic, String tweetCount, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (topic.startsWith('#')) {
            _onHashtagTap(topic.substring(1));
          } else {
            _searchController.text = topic;
            _performSearch(topic);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Trending rank
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.twitterBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.twitterBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Trending content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.twitterBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tweetCount,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              
              // More options
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onPressed: () {
                  _showTrendingOptions(context, topic);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String searchQuery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _searchController.text = searchQuery;
          _performSearch(searchQuery);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                size: 20,
                color: Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  searchQuery,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.twitterBlue,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _searchHistory.remove(searchQuery);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: user['profileImage'] != null
              ? NetworkImage(user['profileImage'])
              : null,
          child: user['profileImage'] == null
              ? Text(
                  user['displayName']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user['displayName'] ?? 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '@${user['username'] ?? 'unknown'}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: OutlinedButton(
          onPressed: () {
            _toggleFollow(user);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Follow'),
        ),
        onTap: () {
          // TODO: Navigate to user profile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigate to @${user['username']} profile'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showTrendingOptions(BuildContext context, String topic) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.not_interested),
              title: const Text('Not interested in this'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hidden: $topic')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reported successfully')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}