import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  List<Map<String, dynamic>> _blockedUsers = [
    {
      'id': '1',
      'username': 'spammer123',
      'displayName': 'Spam Account',
      'profileImage': null,
      'blockedAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': '2',
      'username': 'trolluser',
      'displayName': 'Troll User',
      'profileImage': null,
      'blockedAt': DateTime.now().subtract(const Duration(days: 12)),
    },
  ];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Accounts'),
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

    if (_blockedUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshBlockedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final user = _blockedUsers[index];
          return _buildBlockedUserTile(user);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No blocked accounts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you block accounts, they\'ll be listed here.',
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

  Widget _buildBlockedUserTile(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            child: user['profileImage'] != null
                ? null
                : Text(
                    user['displayName'][0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '@${user['username']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blocked ${_formatDate(user['blockedAt'])}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showUnblockDialog(user),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.twitterBlue),
              foregroundColor: AppTheme.twitterBlue,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Recently';
    }
  }

  void _showUnblockDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock @${user['username']}?'),
        content: Text(
          'This will allow ${user['displayName']} to follow you, view your tweets, and send you direct messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unblockUser(user['id']);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.twitterBlue),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(String userId) async {
    try {
      // TODO: Implement API call to unblock user
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == userId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unblocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshBlockedUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to fetch blocked users
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Simulate refreshed data
      setState(() {
        // _blockedUsers = fetchedUsers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}