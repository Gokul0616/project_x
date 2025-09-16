import 'package:Pulse/models/tweet_model.dart';
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

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  static const double _scrollThreshold = 200.0;
  
  // Keep track of last refresh time for better UX
  DateTime? _lastRefreshTime;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < _scrollThreshold) {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      tweetProvider.loadMoreTweets();
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

  // Twitter-like scroll to top and refresh behavior
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
                  'No tweets yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to tweet something!',
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

        // Enhanced algorithm: Create combined list of regular tweets and recommended tweets
        final allTweets = <Tweet>[];
        final tweets = tweetProvider.tweets;
        final recommendedTweets = tweetProvider.recommendedTweets;

        // Interleave tweets with recommended tweets using enhanced pattern
        // First 3 are regular tweets, then 1 recommended, then repeat
        int regularIndex = 0;
        int recommendedIndex = 0;
        int pattern = 0; // 0,1,2 = regular tweets, 3 = recommended tweet

        while (regularIndex < tweets.length || recommendedIndex < recommendedTweets.length) {
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

        return Column(
          children: [
            // Enhanced new tweets banner with Twitter-like animation
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
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: allTweets.length + (tweetProvider.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the bottom
                    if (index == allTweets.length) {
                      return Container(
                        padding: const EdgeInsets.all(20.0),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.twitterBlue,
                            ),
                          ),
                        ),
                      );
                    }

                    return TweetCard(
                      tweet: allTweets[index],
                      isRecommended: recommendedTweets.contains(allTweets[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}