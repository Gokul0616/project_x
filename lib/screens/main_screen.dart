import 'package:Pulse/screens/tweet/enhanced_compose_tweet_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/message_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tweet_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/upload_progress_fab.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'help/help_center_screen.dart';
import 'home/home_screen.dart';
import 'lists/lists_screen.dart';
import 'messages/conversations_screen.dart';
import 'moments/moments_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'trends/trends_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // GlobalKey for HomeScreen to access its methods
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  // Screens with proper keys
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    // Initialize screens with keys
    _screens = [
      HomeScreen(key: _homeScreenKey),
      const SearchScreen(),
      const ConversationsScreen(),
      const NotificationsScreen(),
    ];
    
    // Load notifications and refresh user data when main screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();
      Provider.of<AuthProvider>(context, listen: false).refreshUserData();
    });
  }

  // Handle home button tap - Twitter-like behavior
  void _handleHomeTap() {
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
    
    if (_currentIndex == 0) {
      // Already on home tab - scroll to top and refresh
      _homeScreenKey.currentState?.scrollToTopAndRefresh();
    } else {
      // Switch to home tab
      setState(() {
        _currentIndex = 0;
      });
      
      // Scroll to top after a brief delay to ensure screen is built
      Future.delayed(const Duration(milliseconds: 100), () {
        _homeScreenKey.currentState?.scrollToTopAndRefresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildClassicDrawer(context),
      appBar: _buildAppBar(context),
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: UploadProgressFAB(
        onCompose: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedComposeTweetScreen(),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          key: const Key('classic_bottom_nav'),
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 0) {
              // Home button - special Twitter-like behavior
              _handleHomeTap();
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppTheme.twitterBlue,
          unselectedItemColor:
              Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: Consumer<TweetProvider>(
                builder: (context, tweetProvider, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.home_outlined, size: 26),
                      if (tweetProvider.hasNewTweets)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.twitterBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              activeIcon: Consumer<TweetProvider>(
                builder: (context, tweetProvider, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.home, size: 26),
                      if (tweetProvider.hasNewTweets)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.twitterBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined, size: 26),
              activeIcon: Icon(Icons.search, size: 26),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.mail_outlined, size: 26),
                      if (messageProvider.totalUnreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              messageProvider.totalUnreadCount > 9
                                  ? '9+'
                                  : messageProvider.totalUnreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              activeIcon: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.mail, size: 26),
                      if (messageProvider.totalUnreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              messageProvider.totalUnreadCount > 9
                                  ? '9+'
                                  : messageProvider.totalUnreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 26),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationProvider.unreadCount > 9
                                  ? '9+'
                                  : notificationProvider.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              activeIcon: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, size: 26),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationProvider.unreadCount > 9
                                  ? '9+'
                                  : notificationProvider.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final currentIndex = _currentIndex;
    Widget? leading;
    Widget? titleWidget;
    List<Widget>? actions;

    switch (currentIndex) {
      case 0: // Home
        leading = GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.profileImage != null
                      ? CachedNetworkImageProvider(user!.profileImage!)
                      : null,
                  child: user?.profileImage == null
                      ? Text(
                          user != null && user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        );
        titleWidget = const Text(
          'Home',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
        actions = [
          IconButton(
            icon: const Icon(Icons.trending_up, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrendsScreen()),
              );
            },
          ),
        ];
        break;

      case 1: // Search
        leading = null;
        titleWidget = null;
        actions = null;
        break;

      case 2: // Messages
        leading = GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.profileImage != null
                      ? CachedNetworkImageProvider(user!.profileImage!)
                      : null,
                  child: user?.profileImage == null
                      ? Text(
                          user != null && user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        );
        titleWidget = const Text(
          'Messages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
        actions = [];
        break;

      case 3: // Notifications
        leading = GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.profileImage != null
                      ? CachedNetworkImageProvider(user!.profileImage!)
                      : null,
                  child: user?.profileImage == null
                      ? Text(
                          user != null && user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        );
        titleWidget = const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
        actions = [];
        break;
    }

    return AppBar(
      leading: leading,
      title: titleWidget,
      centerTitle: currentIndex == 1 ? false : true,
      backgroundColor: currentIndex == 1
          ? Colors.transparent
          : Theme.of(context).scaffoldBackgroundColor,
      elevation: currentIndex == 1 ? 0 : 0,
      actions: actions,
      automaticallyImplyLeading: leading != null,
      toolbarHeight: currentIndex == 1 ? 0 : kToolbarHeight,
    );
  }

  Widget _buildClassicDrawer(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
                color: AppTheme.twitterBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.profileImage != null
                            ? CachedNetworkImageProvider(user!.profileImage!)
                            : null,
                        child: user?.profileImage == null
                            ? Text(
                                user != null && user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppTheme.twitterBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${user?.username ?? 'username'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${user?.followingCount ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          ' Following',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${user?.followersCount ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          ' Followers',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Drawer Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildClassicDrawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildClassicDrawerItem(
                      icon: Icons.list_alt_outlined,
                      title: 'Lists',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildClassicDrawerItem(
                      icon: Icons.bookmark_border,
                      title: 'Bookmarks',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookmarksScreen(),
                          ),
                        );
                      },
                    ),
                    _buildClassicDrawerItem(
                      icon: Icons.flash_on_outlined,
                      title: 'Moments',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MomentsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildClassicDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings and privacy',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildClassicDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _buildClassicDrawerItem(
                          icon: themeProvider.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          title: themeProvider.isDarkMode
                              ? 'Light mode'
                              : 'Dark mode',
                          onTap: () {
                            themeProvider.toggleTheme();
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildClassicDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  authProvider.logout();
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassicDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).textTheme.bodyLarge?.color,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      dense: true,
    );
  }
}