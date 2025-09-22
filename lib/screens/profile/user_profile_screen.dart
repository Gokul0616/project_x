import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../models/tweet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/tweet_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/tweet_card.dart';
import '../../widgets/reply_tweet_card.dart';
import '../messages/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  List<Tweet> _userTweets = [];
  List<Tweet> _userReplies = [];
  List<Tweet> _userLikes = [];
  bool _isLoading = true;
  bool _isLoadingTweets = false;
  bool _isLoadingReplies = false;
  bool _isLoadingLikes = false;
  bool _isFollowing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getUserProfile(widget.username);
      
      if (response['user'] != null) {
        setState(() {
          _user = User.fromJson(response['user']);
          _isLoading = false;
        });

        // Load user's tweets, replies, and likes
        await _loadUserTweets();
        await _loadUserReplies();
        await _loadUserLikes();
      } else {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserTweets() async {
    setState(() => _isLoadingTweets = true);
    try {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      final tweets = await tweetProvider.getUserTweets(widget.username);
      setState(() {
        _userTweets = tweets;
        _isLoadingTweets = false;
      });
    } catch (e) {
      setState(() => _isLoadingTweets = false);
      print('Error loading user tweets: $e');
    }
  }

  Future<void> _loadUserReplies() async {
    setState(() => _isLoadingReplies = true);
    try {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      final replies = await tweetProvider.getUserReplies(widget.username);
      setState(() {
        _userReplies = replies;
        _isLoadingReplies = false;
      });
    } catch (e) {
      setState(() => _isLoadingReplies = false);
      print('Error loading user replies: $e');
    }
  }

  Future<void> _loadUserLikes() async {
    setState(() => _isLoadingLikes = true);
    try {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      final likes = await tweetProvider.getUserLikedTweets(widget.username);
      setState(() {
        _userLikes = likes;
        _isLoadingLikes = false;
      });
    } catch (e) {
      setState(() => _isLoadingLikes = false);
      print('Error loading user likes: $e');
    }
  }

  Future<void> _startConversation() async {
    if (_user == null) return;

    try {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final conversation = await messageProvider.createConversationWithUser(_user!.id);
      
      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isCurrentUser() {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    return currentUser?.username == widget.username;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('@${widget.username}'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('@${widget.username}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('@${widget.username}'),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Profile Header
          SliverAppBar(
            expandedHeight: 350,
            floating: false,
            pinned: true,
            title: innerBoxIsScrolled ? Text(_user!.displayName) : null,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                children: [
                  // Cover Photo Area
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.twitterBlue,
                            AppTheme.twitterBlue.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Profile Picture
                  Positioned(
                    top: 150 - 40,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: AppTheme.twitterBlue,
                        backgroundImage: _user!.profileImage != null
                            ? CachedNetworkImageProvider(_user!.profileImage!)
                            : null,
                        child: _user!.profileImage == null
                            ? Text(
                                _user!.displayName.isNotEmpty
                                    ? _user!.displayName[0].toUpperCase()
                                    : _user!.username.isNotEmpty
                                        ? _user!.username[0].toUpperCase()
                                        : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Profile Info Section
                  Positioned(
                    top: 150,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action Buttons Row
                          Row(
                            children: [
                              const SizedBox(width: 80), // Space for profile pic
                              const Spacer(),
                              if (_isCurrentUser()) ...[
                                OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Edit profile coming soon!'),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color ??
                                          Colors.black,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Edit profile'),
                                ),
                              ] else ...[
                                // Message Button
                                OutlinedButton.icon(
                                  onPressed: _startConversation,
                                  icon: const Icon(Icons.message_outlined, size: 18),
                                  label: const Text('Message'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppTheme.twitterBlue,
                                    ),
                                    foregroundColor: AppTheme.twitterBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Follow Button
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Follow feature coming soon!'),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? Theme.of(context).cardColor
                                        : AppTheme.twitterBlue,
                                    foregroundColor: _isFollowing
                                        ? Theme.of(context).textTheme.bodyLarge?.color
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(_isFollowing ? 'Following' : 'Follow'),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          // User Name and Username
                          Text(
                            _user!.displayName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            '@${_user!.username}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          // Bio
                          if (_user!.bio != null && _user!.bio!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _user!.bio!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          // Join Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Joined ${_formatJoinDate(_user!.createdAt ?? DateTime.now())}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Following and Followers
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to following screen
                                },
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${_user!.followingCount ?? 0} ',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Following',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to followers screen
                                },
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${_user!.followersCount ?? 0} ',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Followers',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabsDelegate(
              tabController: _tabController,
              theme: Theme.of(context),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildTweetsTab(),
            _buildRepliesTab(),
            _buildLikesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTweetsTab() {
    if (_isLoadingTweets) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tweets...'),
          ],
        ),
      );
    }

    if (_userTweets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _isCurrentUser() ? 'No tweets yet' : '@${widget.username} hasn\'t tweeted yet',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_isCurrentUser() 
                ? 'Start tweeting to see your posts here!' 
                : 'When they do, their tweets will show up here.'),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _userTweets.length,
      itemBuilder: (context, index) {
        return TweetCard(tweet: _userTweets[index]);
      },
    );
  }

  Widget _buildRepliesTab() {
    if (_isLoadingReplies) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading replies...'),
          ],
        ),
      );
    }

    if (_userReplies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reply_all_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _isCurrentUser() ? 'No replies yet' : '@${widget.username} hasn\'t replied yet',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_isCurrentUser() 
                ? 'Your replies will show up here' 
                : 'When they reply to tweets, those replies will show up here.'),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _userReplies.length,
      itemBuilder: (context, index) {
        return ReplyTweetCard(tweet: _userReplies[index]);
      },
    );
  }

  Widget _buildLikesTab() {
    if (_isLoadingLikes) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading likes...'),
          ],
        ),
      );
    }

    if (_userLikes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _isCurrentUser() ? 'No likes yet' : '@${widget.username} hasn\'t liked any tweets yet',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_isCurrentUser() 
                ? 'Tap the heart on any Tweet to show it some love' 
                : 'When they like tweets, those tweets will show up here.'),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _userLikes.length,
      itemBuilder: (context, index) {
        return TweetCard(tweet: _userLikes[index]);
      },
    );
  }

  String _formatJoinDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _ProfileTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final ThemeData theme;

  _ProfileTabsDelegate({required this.tabController, required this.theme});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppTheme.twitterBlue,
        labelColor: AppTheme.twitterBlue,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        tabs: const [
          Tab(text: 'Tweets'),
          Tab(text: 'Replies'),
          Tab(text: 'Likes'),
        ],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        indicatorWeight: 3,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}