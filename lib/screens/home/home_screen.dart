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
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  static const double _scrollThreshold = 200.0;

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
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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

  // scroll to top and refresh behavior
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
                  'Welcome to Pulse',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your timeline will appear here',
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
            EnhancedNewTweetsBanner(
              isVisible: tweetProvider.hasNewTweets,
              onTap: _onNewTweetsBannerTap,
            ),
            // Tweets list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshTweets,
                color: AppTheme.twitterBlue,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                displacement: 40,
                child: _buildTweetsList(tweetProvider.tweets, tweetProvider),
              ),
            ),
          ],
        );
      },
    );
  }
}
