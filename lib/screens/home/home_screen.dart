import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tweet_model.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tweet_provider.dart';
import '../../utils/app_theme.dart';
import '../tweet/enhanced_compose_tweet_screen.dart';
import '../../widgets/tweet_card.dart';
import '../../widgets/new_tweets_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _scrollThreshold = 200.0;

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
    await tweetProvider.refreshTweets();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onNewTweetsBannerTap() {
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
    tweetProvider.clearNewTweetsFlag();
    _scrollToTop();
    _refreshTweets();
  }

  @override
  Widget build(BuildContext context) {
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
                        builder: (context) => const EnhancedComposeTweetScreen(),
                      ),
                    );
                  },
                  child: const Text('Compose Tweet'),
                ),
              ],
            ),
          );
        }

        // Create combined list of regular tweets and recommended tweets
        final allTweets = <Tweet>[];
        final tweets = tweetProvider.tweets;
        final recommendedTweets = tweetProvider.recommendedTweets;

        // Interleave tweets with recommended tweets (every 5th tweet is a recommendation)
        for (int i = 0; i < tweets.length; i++) {
          allTweets.add(tweets[i]);

          // Add a recommended tweet every 5 regular tweets
          if ((i + 1) % 5 == 0 && recommendedTweets.isNotEmpty) {
            final recommendedIndex =
                ((i + 1) ~/ 5 - 1) % recommendedTweets.length;
            if (recommendedIndex < recommendedTweets.length) {
              allTweets.add(recommendedTweets[recommendedIndex]);
            }
          }
        }

        return Column(
          children: [
            // New tweets banner
            NewTweetsBanner(
              isVisible: tweetProvider.hasNewTweets,
              onTap: _onNewTweetsBannerTap,
            ),
            // Tweets list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshTweets,
                color: AppTheme.twitterBlue,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: allTweets.length + (tweetProvider.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the bottom
                    if (index == allTweets.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
                          ),
                        ),
                      );
                    }
                    
                    return TweetCard(tweet: allTweets[index]);
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
