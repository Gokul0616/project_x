import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../profile/user_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  final String initialQuery;
  
  const UserSearchScreen({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _searchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search people',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          onSubmitted: (_) => _searchUsers(),
          autofocus: true,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                  _hasSearched = false;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchUsers,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_searchResults[index]);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for people',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a name or username to find people',
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

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check spelling',
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

  Widget _buildUserTile(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        leading: GestureDetector(
          onTap: () => _navigateToUserProfile(user),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: user.profileImage != null
                ? CachedNetworkImageProvider(user.profileImage!)
                : null,
            child: user.profileImage == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
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
          onTap: () => _navigateToUserProfile(user),
          child: Text(
            user.displayName,
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
              onTap: () => _navigateToUserProfile(user),
              child: Text(
                '@${user.username}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.bio!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${user.followersCount ?? 0} followers',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: _buildFollowButton(user),
      ),
    );
  }

  Widget _buildFollowButton(User user) {
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

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final result = await ApiService.searchUsers(query);
      if (result['success'] == true) {
        final List<dynamic> userData = result['data'] ?? [];
        setState(() {
          _searchResults = userData.map((json) => User.fromJson(json)).toList();
        });
      } else {
        throw Exception(result['message'] ?? 'Search failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}