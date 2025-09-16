// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../providers/auth_provider.dart';
// import '../../providers/theme_provider.dart';
// import '../../providers/tweet_provider.dart';
// import '../../utils/app_theme.dart';
// import '../../widgets/tweet_card.dart';
// import '../settings/settings_screen.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   String _activeTab = 'Tweets'; // Tweets, Replies, Likes

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);

//     // Load tweets when profile screen initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
//       if (tweetProvider.tweets.isEmpty) {
//         tweetProvider.loadTweets();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Consumer<AuthProvider>(
//         builder: (context, authProvider, child) {
//           final user = authProvider.user;

//           // Enhanced null safety check
//           if (user == null || authProvider.isLoading) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Loading profile...'),
//                 ],
//               ),
//             );
//           }

//           // Additional safety check for user properties
//           if (user.id.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, size: 64, color: Colors.red),
//                   SizedBox(height: 16),
//                   Text('Error loading profile data'),
//                   SizedBox(height: 8),
//                   Text('Please try again later'),
//                 ],
//               ),
//             );
//           }

//           return CustomScrollView(
//             slivers: [
//               // Profile Header
//               SliverAppBar(
//                 expandedHeight: 350,
//                 floating: false,
//                 pinned: true,
//                 automaticallyImplyLeading: false,
//                 actions: [
//                   Consumer<ThemeProvider>(
//                     builder: (context, themeProvider, child) {
//                       return IconButton(
//                         icon: Icon(
//                           themeProvider.isDarkMode
//                               ? Icons.light_mode
//                               : Icons.dark_mode,
//                         ),
//                         onPressed: () {
//                           themeProvider.toggleTheme();
//                         },
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.settings_outlined),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const SettingsScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Column(
//                     children: [
//                       // Cover Photo Area
//                       Container(
//                         height: 150,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               AppTheme.twitterBlue,
//                               AppTheme.twitterBlue.withOpacity(0.7),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Profile Info Section
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Profile Picture and Edit Button Row
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 // Profile Picture
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Theme.of(
//                                         context,
//                                       ).scaffoldBackgroundColor,
//                                       width: 4,
//                                     ),
//                                   ),
//                                   child: CircleAvatar(
//                                     radius: 35,
//                                     backgroundColor: AppTheme.twitterBlue,
//                                     backgroundImage: user?.profileImage != null
//                                         ? CachedNetworkImageProvider(
//                                             user!.profileImage!,
//                                           )
//                                         : null,
//                                     child: user?.profileImage == null
//                                         ? Text(
//                                             user != null &&
//                                                     user.displayName.isNotEmpty
//                                                 ? user.displayName[0]
//                                                       .toUpperCase()
//                                                 : user != null &&
//                                                       user.username.isNotEmpty
//                                                 ? user.username[0].toUpperCase()
//                                                 : 'U',
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 24,
//                                             ),
//                                           )
//                                         : null,
//                                   ),
//                                 ),
//                                 const Spacer(),
//                                 // Edit Profile Button
//                                 OutlinedButton(
//                                   onPressed: () {
//                                     // TODO: Navigate to edit profile screen
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text(
//                                           'Edit profile coming soon!',
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   style: OutlinedButton.styleFrom(
//                                     side: BorderSide(
//                                       color:
//                                           Theme.of(
//                                             context,
//                                           ).textTheme.bodyLarge?.color ??
//                                           Colors.black,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                   ),
//                                   child: const Text('Edit profile'),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),

//                             // User Name and Username
//                             Text(
//                               user?.displayName ?? 'User',
//                               style: Theme.of(context).textTheme.headlineMedium,
//                             ),
//                             Text(
//                               '@${user?.username ?? 'username'}',
//                               style: Theme.of(context).textTheme.bodyMedium,
//                             ),
//                             const SizedBox(height: 12),

//                             // Bio
//                             if (user?.bio != null &&
//                                 user.bio != null &&
//                                 user.bio!.isNotEmpty)
//                               Padding(
//                                 padding: const EdgeInsets.only(bottom: 12),
//                                 child: Text(
//                                   user.bio!,
//                                   style: Theme.of(context).textTheme.bodyLarge,
//                                 ),
//                               ),

//                             // Join Date
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.calendar_today,
//                                   size: 16,
//                                   color: Theme.of(
//                                     context,
//                                   ).textTheme.bodyMedium?.color,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   'Joined ${_formatJoinDate(user?.createdAt ?? DateTime.now())}',
//                                   style: Theme.of(context).textTheme.bodyMedium,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),

//                             // Following and Followers
//                             Row(
//                               children: [
//                                 GestureDetector(
//                                   onTap: () {
//                                     // TODO: Navigate to following screen
//                                   },
//                                   child: RichText(
//                                     text: TextSpan(
//                                       children: [
//                                         TextSpan(
//                                           text: '${user?.followingCount ?? 0} ',
//                                           style: TextStyle(
//                                             color: Theme.of(
//                                               context,
//                                             ).textTheme.bodyLarge?.color,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         TextSpan(
//                                           text: 'Following',
//                                           style: Theme.of(
//                                             context,
//                                           ).textTheme.bodyMedium,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 20),
//                                 GestureDetector(
//                                   onTap: () {
//                                     // TODO: Navigate to followers screen
//                                   },
//                                   child: RichText(
//                                     text: TextSpan(
//                                       children: [
//                                         TextSpan(
//                                           text: '${user?.followersCount ?? 0} ',
//                                           style: TextStyle(
//                                             color: Theme.of(
//                                               context,
//                                             ).textTheme.bodyLarge?.color,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         TextSpan(
//                                           text: 'Followers',
//                                           style: Theme.of(
//                                             context,
//                                           ).textTheme.bodyMedium,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Profile Tabs
//               SliverPersistentHeader(
//                 pinned: true,
//                 delegate: _ProfileTabsDelegate(
//                   tabController: _tabController,
//                   theme: Theme.of(context),
//                 ),
//               ),

//               // Tab Content
//               SliverFillRemaining(
//                 child: Consumer<TweetProvider>(
//                   builder: (context, tweetProvider, child) {
//                     return TabBarView(
//                       controller: _tabController,
//                       children: [
//                         _buildTweetsTab(tweetProvider),
//                         _buildRepliesTab(tweetProvider),
//                         _buildLikesTab(tweetProvider),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTweetsTab(TweetProvider tweetProvider) {
//     // Filter tweets by current user
//     final currentUserId = Provider.of<AuthProvider>(
//       context,
//       listen: false,
//     ).user?.id;

//     // Safety check: return empty state if currentUserId is null or tweets is null
//     if (currentUserId == null) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Loading user data...'),
//           ],
//         ),
//       );
//     }

//     final userTweets = tweetProvider.tweets
//         .where((tweet) => tweet.author.id == currentUserId)
//         .toList();

//     if (userTweets.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.article_outlined, size: 80, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'No tweets yet',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             Text('Start tweeting to see your posts here!'),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: userTweets.length,
//       itemBuilder: (context, index) {
//         return TweetCard(tweet: userTweets[index]);
//       },
//     );
//   }

//   Widget _buildRepliesTab(TweetProvider tweetProvider) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.reply_all_outlined, size: 80, color: Colors.grey),
//           SizedBox(height: 16),
//           Text(
//             'No replies yet',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text('Your replies will show up here'),
//         ],
//       ),
//     );
//   }

//   Widget _buildLikesTab(TweetProvider tweetProvider) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.favorite_outline, size: 80, color: Colors.grey),
//           SizedBox(height: 16),
//           Text(
//             'No likes yet',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text('Tap the heart on any Tweet to show it some love'),
//         ],
//       ),
//     );
//   }

//   String _formatJoinDate(DateTime date) {
//     final months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//     return '${months[date.month - 1]} ${date.year}';
//   }
// }

// class _ProfileTabsDelegate extends SliverPersistentHeaderDelegate {
//   final TabController tabController;
//   final ThemeData theme;

//   _ProfileTabsDelegate({required this.tabController, required this.theme});

//   @override
//   double get minExtent => 40;

//   @override
//   double get maxExtent => 40;

//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return Container(
//       color: theme.scaffoldBackgroundColor,
//       child: TabBar(
//         controller: tabController,
//         indicatorColor: AppTheme.twitterBlue,
//         labelColor: AppTheme.twitterBlue,
//         unselectedLabelColor: theme.textTheme.bodyMedium?.color,
//         tabs: const [
//           Tab(text: 'Tweets'),
//           Tab(text: 'Replies'),
//           Tab(text: 'Likes'),
//         ],
//       ),
//     );
//   }

//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
//     return false;
//   }
// }

import 'package:Pulse/models/tweet_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/tweet_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/reply_tweet_card.dart';
import '../../widgets/tweet_card.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Tweet> _userTweets = [];
  List<Tweet> _userReplies = [];
  List<Tweet> _userLikes = [];
  bool _isLoadingTweets = false;
  bool _isLoadingReplies = false;
  bool _isLoadingLikes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load user-specific data when profile screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    // Load general tweets if empty
    if (tweetProvider.tweets.isEmpty) {
      await tweetProvider.loadTweets();
    }

    // Load user-specific tweets, replies, and likes
    await _loadUserTweets(user.username);
    await _loadUserReplies(user.username);
    await _loadUserLikes(user.username);
  }

  Future<void> _loadUserTweets(String username) async {
    setState(() => _isLoadingTweets = true);
    try {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      final tweets = await tweetProvider.getUserTweets(username);
      setState(() {
        _userTweets = tweets;
        _isLoadingTweets = false;
      });
    } catch (e) {
      setState(() => _isLoadingTweets = false);
      print('Error loading user tweets: $e');
    }
  }

  Future<void> _loadUserReplies(String username) async {
    setState(() => _isLoadingReplies = true);
    try {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      final replies = await tweetProvider.getUserReplies(username);
      setState(() {
        _userReplies = replies;
        _isLoadingReplies = false;
      });
    } catch (e) {
      setState(() => _isLoadingReplies = false);
      print('Error loading user replies: $e');
    }
  }

  Future<void> _loadUserLikes(String username) async {
    setState(() => _isLoadingLikes = true);
    try {
      final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
      final likes = await tweetProvider.getUserLikedTweets(username);
      setState(() {
        _userLikes = likes;
        _isLoadingLikes = false;
      });
    } catch (e) {
      setState(() => _isLoadingLikes = false);
      print('Error loading user likes: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          // Enhanced null safety check
          if (user == null || authProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            );
          }

          // Additional safety check for user properties
          if (user.id.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading profile data'),
                  SizedBox(height: 8),
                  Text('Please try again later'),
                ],
              ),
            );
          }

          return NestedScrollView(
            physics: const BouncingScrollPhysics(), // Smooth scrolling
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // Profile Header
              SliverAppBar(
                expandedHeight: 350,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                title: innerBoxIsScrolled
                    ? Text(user.displayName ?? 'User')
                    : null, // Show name when collapsed
                actions: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        onPressed: () {
                          themeProvider.toggleTheme();
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode:
                      CollapseMode.parallax, // Smooth collapse animation
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
                      // Profile Picture (overlapping the cover)
                      Positioned(
                        top: 150 - 40, // Overlap by 40 pixels
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
                            backgroundImage: user.profileImage != null
                                ? CachedNetworkImageProvider(user.profileImage!)
                                : null,
                            child: user.profileImage == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
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
                              // Edit Profile Button Row
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 80,
                                  ), // Space for profile pic
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Edit profile coming soon!',
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            Colors.black,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Edit profile'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // User Name and Username
                              Text(
                                user.displayName ?? 'User',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              Text(
                                '@${user.username ?? 'username'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              // Bio
                              if (user.bio != null && user.bio!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    user.bio!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                              // Join Date
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Joined ${_formatJoinDate(user.createdAt ?? DateTime.now())}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                            text:
                                                '${user.followingCount ?? 0} ',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Following',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
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
                                            text:
                                                '${user.followersCount ?? 0} ',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Followers',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
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
            body: Consumer<TweetProvider>(
              builder: (context, tweetProvider, child) {
                return TabBarView(
                  controller: _tabController,
                  physics:
                      const BouncingScrollPhysics(), // Smooth tab switching
                  children: [
                    _buildTweetsTab(tweetProvider),
                    _buildRepliesTab(tweetProvider),
                    _buildLikesTab(tweetProvider),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTweetsTab(TweetProvider tweetProvider) {
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tweets yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Start tweeting to see your posts here!'),
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

  Widget _buildRepliesTab(TweetProvider tweetProvider) {
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reply_all_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No replies yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Your replies will show up here'),
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

  Widget _buildLikesTab(TweetProvider tweetProvider) {
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No likes yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Tap the heart on any Tweet to show it some love'),
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
