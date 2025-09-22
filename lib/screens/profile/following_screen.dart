import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'user_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  final User user;
  
  const FollowingScreen({
    super.key,
    required this.user,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<User> _following = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.user.displayName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.user.followingCount} following',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_following.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFollowing,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          return _buildFollowingTile(_following[index]);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load following',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFollowing,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.twitterBlue,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
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
          Icon(
            Icons.person_add_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.username == 'current_user' // TODO: Check if current user
                ? 'You aren\'t following anyone yet'
                : '${widget.user.displayName} isn\'t following anyone yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.username == 'current_user' // TODO: Check if current user
                ? 'When you follow people, they\'ll appear here.'
                : 'When they follow people, they\'ll appear here.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingTile(User followingUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        leading: GestureDetector(
          onTap: () => _navigateToUserProfile(followingUser),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: followingUser.profileImage != null
                ? CachedNetworkImageProvider(followingUser.profileImage!)
                : null,
            child: followingUser.profileImage == null
                ? Text(
                    followingUser.displayName.isNotEmpty
                        ? followingUser.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        title: GestureDetector(
          onTap: () => _navigateToUserProfile(followingUser),
          child: Text(
            followingUser.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _navigateToUserProfile(followingUser),
              child: Text(
                '@${followingUser.username}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            if (followingUser.bio != null && followingUser.bio!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                followingUser.bio!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: _buildUnfollowButton(followingUser),
      ),
    );
  }

  Widget _buildUnfollowButton(User user) {
    return ElevatedButton(
      onPressed: () => _showUnfollowDialog(user),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size(90, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Text(
        'Following',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToUserProfile(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: user.username),
      ),
    );
  }

  void _showUnfollowDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfollow @${user.username}?'),
        content: Text(
          'Their tweets will no longer show up in your home timeline. You can still view their profile, unless their tweets are protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unfollowUser(user);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
  }

  void _unfollowUser(User user) {
    // TODO: Implement unfollow API call
    setState(() {
      _following.removeWhere((u) => u.id == user.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unfollowed @${user.username}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement follow API call
            setState(() {
              _following.add(user);
            });
          },
        ),
      ),
    );
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // TODO: Implement API call to load following
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Mock data for demonstration
      final mockFollowing = <User>[
        User(
          id: '1',
          username: 'techguru',
          email: 'techguru@example.com',
          displayName: 'Tech Guru',
          bio: 'Sharing the latest in technology and innovation',
          createdAt: DateTime.now(),
        ),
        User(
          id: '2',
          username: 'designerlife',
          email: 'designer@example.com',
          displayName: 'Designer Life',
          bio: 'Exploring the world of design and creativity',
          createdAt: DateTime.now(),
        ),
        User(
          id: '3',
          username: 'flutterdev',
          email: 'flutter@example.com',
          displayName: 'Flutter Developer',
          bio: 'Building beautiful apps with Flutter 💙',
          createdAt: DateTime.now(),
        ),
        User(
          id: '4',
          username: 'startupnews',
          email: 'startup@example.com',
          displayName: 'Startup News',
          bio: 'Latest news and insights from the startup world',
          createdAt: DateTime.now(),
        ),
      ];
      
      setState(() {
        _following = mockFollowing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFollowing() async {
    await _loadFollowing();
  }
}