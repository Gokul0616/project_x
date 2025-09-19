import 'package:Pulse/models/tweet_model.dart';
import 'package:Pulse/widgets/enhanced_tweet_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/tweet_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/enhanced_new_tweets_banner.dart';
import '../../widgets/tweet_card.dart';
import '../tweet/enhanced_compose_tweet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  static const double _scrollThreshold = 200.0;

  // Keep track of last refresh time for better UX
  DateTime? _lastRefreshTime;

  // Timeline state
  int _selectedTimelineIndex = 0; // 0 = For You, 1 = Following

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();

    // Initialize tab controller for timeline switching
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTimelineChanged);

    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);

    // Load tweets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      tweetProvider.loadTweets(refresh: true);
      tweetProvider.loadRecommendedTweets(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.removeListener(_onTimelineChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTimelineChanged() {
    if (_selectedTimelineIndex != _tabController.index) {
      setState(() {
        _selectedTimelineIndex = _tabController.index;
      });
      // Refresh content when switching timelines
      _refreshTweets();
    }
  }

  void _onScroll() {
    // Enhanced infinite scroll with better threshold detection
    if (_scrollController.position.extentAfter < _scrollThreshold) {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);

      // Only trigger load more if we have more content available and not currently loading
      if (tweetProvider.hasMoreContent && !tweetProvider.isLoadingMore) {
        tweetProvider.loadMoreTweets();
      }
    }
  }

  Future<void> _refreshTweets() async {
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
    _lastRefreshTime = DateTime.now();
    await tweetProvider.refreshTweets();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // X-style scroll to top and refresh behavior
  void scrollToTopAndRefresh() {
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);

    // Clear the new tweets flag immediately for better UX
    tweetProvider.clearNewTweetsFlag();

    if (_scrollController.hasClients && _scrollController.offset > 0) {
      // If user is scrolled down, scroll to top first, then refresh
      _scrollToTop();

      // Refresh after scroll animation completes
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          _refreshTweets();
        }
      });
    } else {
      // If already at top, just refresh
      _refreshTweets();
    }
  }

  void _onNewTweetsBannerTap() {
    scrollToTopAndRefresh();
  }

  // Build timeline-specific content
  Widget _buildTimelineContent(TweetProvider tweetProvider) {
    if (_selectedTimelineIndex == 0) {
      // For You timeline - Mixed algorithmic feed
      return _buildForYouTimeline(tweetProvider);
    } else {
      // Following timeline - Chronological from followed users only
      return _buildFollowingTimeline(tweetProvider);
    }
  }

  Widget _buildForYouTimeline(TweetProvider tweetProvider) {
    // Enhanced algorithm: Create combined list of regular tweets and recommended tweets
    final allTweets = <Tweet>[];
    final tweets = tweetProvider.tweets;
    final recommendedTweets = tweetProvider.recommendedTweets;

    // Interleave tweets with recommended tweets using enhanced pattern
    // First 3 are regular tweets, then 1 recommended, then repeat
    int regularIndex = 0;
    int recommendedIndex = 0;
    int pattern = 0; // 0,1,2 = regular tweets, 3 = recommended tweet

    while (regularIndex < tweets.length ||
        recommendedIndex < recommendedTweets.length) {
      if (pattern < 3 && regularIndex < tweets.length) {
        // Add regular tweet
        allTweets.add(tweets[regularIndex]);
        regularIndex++;
        pattern++;
      } else if (pattern == 3 && recommendedIndex < recommendedTweets.length) {
        // Add recommended tweet
        allTweets.add(recommendedTweets[recommendedIndex]);
        recommendedIndex++;
        pattern = 0; // Reset pattern
      } else if (regularIndex < tweets.length) {
        // If no more recommended tweets, add remaining regular tweets
        allTweets.add(tweets[regularIndex]);
        regularIndex++;
      } else {
        // If no more regular tweets, add remaining recommended tweets
        allTweets.add(recommendedTweets[recommendedIndex]);
        recommendedIndex++;
      }
    }

    return _buildTweetsList(allTweets, tweetProvider);
  }

  Widget _buildFollowingTimeline(TweetProvider tweetProvider) {
    // Following timeline - Only regular tweets in chronological order
    final tweets = tweetProvider.tweets;
    return _buildTweetsList(tweets, tweetProvider);
  }

  Widget _buildTweetsList(List<Tweet> tweets, TweetProvider tweetProvider) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount:
          tweets.length +
          (tweetProvider.isLoadingMore && tweetProvider.hasMoreContent ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the bottom
        if (index == tweets.length) {
          return Container(
            padding: const EdgeInsets.all(20.0),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
              ),
            ),
          );
        }

        return EnhancedTweetCard(
          tweet: tweets[index],
          onDoubleTap: () {
            // Double-tap to like (X-style)
            Provider.of<TweetProvider>(
              context,
              listen: false,
            ).likeTweet(tweets[index].id);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        if (tweetProvider.isLoading && tweetProvider.tweets.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
            ),
          );
        }

        if (tweetProvider.error != null && tweetProvider.tweets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading tweets',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  tweetProvider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshTweets,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (tweetProvider.tweets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _selectedTimelineIndex == 0
                      ? 'Welcome to X'
                      : 'No tweets yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTimelineIndex == 0
                      ? 'Your personalized timeline will appear here'
                      : 'Follow accounts to see their tweets',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const EnhancedComposeTweetScreen(),
                      ),
                    );
                  },
                  child: const Text('Compose Tweet'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // X-style top bar with timeline tabs
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Timeline tabs
                  Container(
                    height: 50,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'For You'),
                        Tab(text: 'Following'),
                      ],
                      indicatorColor: AppTheme.twitterBlue,
                      indicatorWeight: 3,
                      labelColor: Theme.of(context).textTheme.bodyLarge?.color,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // Divider
                  Divider(height: 0.5, color: Theme.of(context).dividerColor),
                ],
              ),
            ),
            // Enhanced new tweets banner with X-like animation
            EnhancedNewTweetsBanner(
              isVisible: tweetProvider.hasNewTweets,
              onTap: _onNewTweetsBannerTap,
              lastRefreshTime: _lastRefreshTime,
            ),
            // Tweets list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshTweets,
                color: AppTheme.twitterBlue,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                displacement: 40,
                child: _buildTimelineContent(tweetProvider),
              ),
            ),
          ],
        );
      },
    );
  }
}
