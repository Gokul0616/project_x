import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final User user;
  
  const FollowersScreen({
    super.key,
    required this.user,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<User> _followers = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
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
              '${widget.user.followersCount} followers',
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

    if (_followers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFollowers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          return _buildFollowerTile(_followers[index]);
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
            'Failed to load followers',
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
            onPressed: _loadFollowers,
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.username == 'current_user' // TODO: Check if current user
                ? 'You don\'t have any followers yet'
                : '${widget.user.displayName} doesn\'t have any followers yet',
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
                ? 'When people follow you, they\'ll appear here.'
                : 'When people follow them, they\'ll appear here.',
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

  Widget _buildFollowerTile(User follower) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        leading: GestureDetector(
          onTap: () => _navigateToUserProfile(follower),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: follower.profileImage != null
                ? CachedNetworkImageProvider(follower.profileImage!)
                : null,
            child: follower.profileImage == null
                ? Text(
                    follower.displayName.isNotEmpty
                        ? follower.displayName[0].toUpperCase()
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
          onTap: () => _navigateToUserProfile(follower),
          child: Text(
            follower.displayName,
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
              onTap: () => _navigateToUserProfile(follower),
              child: Text(
                '@${follower.username}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            if (follower.bio != null && follower.bio!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                follower.bio!,
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
        trailing: _buildFollowButton(follower),
      ),
    );
  }

  Widget _buildFollowButton(User user) {
    // TODO: Implement follow/unfollow functionality
    return OutlinedButton(
      onPressed: () => _toggleFollow(user),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.twitterBlue),
        foregroundColor: AppTheme.twitterBlue,
        minimumSize: const Size(80, 32),
      ),
      child: const Text(
        'Follow',
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

  void _toggleFollow(User user) {
    // TODO: Implement follow/unfollow API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Follow functionality not implemented yet'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // TODO: Implement API call to load followers
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Mock data for demonstration
      final mockFollowers = <User>[
        User(
          id: '1',
          username: 'follower1',
          email: 'follower1@example.com',
          displayName: 'John Doe',
          bio: 'Flutter developer and tech enthusiast',
          createdAt: DateTime.now(),
        ),
        User(
          id: '2',
          username: 'follower2',
          email: 'follower2@example.com',
          displayName: 'Jane Smith',
          bio: 'UI/UX Designer who loves creating beautiful interfaces',
          createdAt: DateTime.now(),
        ),
        User(
          id: '3',
          username: 'follower3',
          email: 'follower3@example.com',
          displayName: 'Mike Johnson',
          bio: null,
          createdAt: DateTime.now(),
        ),
      ];
      
      setState(() {
        _followers = mockFollowers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFollowers() async {
    await _loadFollowers();
  }
}