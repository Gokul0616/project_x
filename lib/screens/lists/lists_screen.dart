import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<TwitterList> _userLists = [];
  List<TwitterList> _pinnedLists = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreUser = true;
  bool _hasMorePinned = true;
  int _userPage = 1;
  int _pinnedPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadLists() async {
    await _loadUserLists(refresh: true);
    await _loadPinnedLists(refresh: true);
  }

  Future<void> _loadUserLists({bool refresh = false}) async {
    if (refresh) {
      _userPage = 1;
      _hasMoreUser = true;
      _userLists.clear();
    }

    if (!_hasMoreUser && !refresh) return;

    setState(() {
      _isLoading = refresh;
      _isLoadingMore = !refresh && _userLists.isNotEmpty;
    });

    try {
      final lists = await ApiService.getLists(
        type: 'user',
        page: _userPage,
        limit: 20,
      );

      if (lists.isEmpty) {
        _hasMoreUser = false;
      } else {
        final newLists = lists
            .map((list) => TwitterList.fromJson(list))
            .toList();
        if (refresh) {
          _userLists = newLists;
        } else {
          _userLists.addAll(newLists);
        }
        _userPage++;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading lists: $e')));
    }
  }

  Future<void> _loadPinnedLists({bool refresh = false}) async {
    if (refresh) {
      _pinnedPage = 1;
      _hasMorePinned = true;
      _pinnedLists.clear();
    }

    if (!_hasMorePinned && !refresh) return;

    try {
      final lists = await ApiService.getLists(
        type: 'pinned',
        page: _pinnedPage,
        limit: 20,
      );

      if (lists.isEmpty) {
        _hasMorePinned = false;
      } else {
        final newLists = lists
            .map((list) => TwitterList.fromJson(list))
            .toList();
        if (refresh) {
          _pinnedLists = newLists;
        } else {
          _pinnedLists.addAll(newLists);
        }
        _pinnedPage++;
      }

      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading pinned lists: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lists',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateListDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            width: screenWidth > 600 ? 600 : screenWidth,
            alignment: Alignment.center,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.twitterBlue,
              labelColor: AppTheme.twitterBlue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Your Lists'),
                Tab(text: 'Pinned'),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListsTab(
                _userLists,
                showCreateButton: true,
                onLoadMore: () => _loadUserLists(),
              ),
              _buildListsTab(
                _pinnedLists,
                showCreateButton: false,
                onLoadMore: () => _loadPinnedLists(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListsTab(
    List<TwitterList> lists, {
    required bool showCreateButton,
    VoidCallback? onLoadMore,
  }) {
    if (_isLoading && lists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lists.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              showCreateButton ? 'No lists yet' : 'No pinned lists',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              showCreateButton
                  ? 'Create your first list to organize posts'
                  : 'Pin lists to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showCreateListDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.twitterBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Create List'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => showCreateButton
          ? await _loadUserLists(refresh: true)
          : await _loadPinnedLists(refresh: true),
      child: ListView.builder(
        itemCount: lists.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == lists.length) {
            onLoadMore?.call();
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final list = lists[index];
          return _buildListTile(list);
        },
      ),
    );
  }

  Widget _buildListTile(TwitterList list) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.twitterBlue,
          child: Text(
            list.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                list.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (list.isPrivate) const SizedBox(width: 4),
            if (list.isPrivate)
              const Icon(Icons.lock, size: 16, color: Colors.grey),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (list.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                list.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${list.memberCount} members',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${list.subscriberCount} subscribers',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleListAction(value, list),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View List')),
            const PopupMenuItem(value: 'edit', child: Text('Edit List')),
            const PopupMenuItem(value: 'pin', child: Text('Pin List')),
            const PopupMenuItem(value: 'delete', child: Text('Delete List')),
          ],
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
        ),
        onTap: () => _showListDetails(list),
      ),
    );
  }

  void _handleListAction(String action, TwitterList list) {
    switch (action) {
      case 'view':
        _showListDetails(list);
        break;
      case 'edit':
        _showEditListDialog(list);
        break;
      case 'pin':
        _pinList(list);
        break;
      case 'delete':
        _deleteList(list);
        break;
    }
  }

  void _showListDetails(TwitterList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(list.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(list.description),
            const SizedBox(height: 16),
            Text(
              '${list.memberCount} members • ${list.subscriberCount} subscribers',
            ),
            if (list.isPrivate)
              const Text(
                '🔒 Private list',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateListDialog(
        onListCreated: (newList) {
          setState(() {
            _userLists.insert(0, newList);
          });
        },
      ),
    );
  }

  void _showEditListDialog(TwitterList list) {
    showDialog(
      context: context,
      builder: (context) => EditListDialog(
        list: list,
        onListUpdated: (updatedList) {
          setState(() {
            final index = _userLists.indexWhere((l) => l.id == list.id);
            if (index != -1) {
              _userLists[index] = updatedList;
            }
          });
        },
      ),
    );
  }

  void _pinList(TwitterList list) async {
    try {
      final result = await ApiService.pinList(list.id);
      if (result['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        _loadPinnedLists(refresh: true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error pinning list: $e')));
    }
  }

  void _deleteList(TwitterList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await ApiService.deleteList(list.id);
                if (result['success']) {
                  setState(() {
                    _userLists.removeWhere((l) => l.id == list.id);
                    _pinnedLists.removeWhere((l) => l.id == list.id);
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result['message'])));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${result['message']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting list: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class TwitterList {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int subscriberCount;
  final bool isPrivate;
  final DateTime createdAt;

  TwitterList({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.subscriberCount,
    required this.isPrivate,
    required this.createdAt,
  });

  factory TwitterList.fromJson(Map<String, dynamic> json) {
    return TwitterList(
      id: json['_id'],
      name: json['name'],
      description: json['description'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      subscriberCount: json['subscriberCount'] ?? 0,
      isPrivate: json['isPrivate'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CreateListDialog extends StatefulWidget {
  final Function(TwitterList) onListCreated;

  const CreateListDialog({super.key, required this.onListCreated});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create List'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List name',
                hintText: 'Enter list name',
              ),
              maxLength: 25,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description (optional)',
              ),
              maxLength: 100,
              maxLines: 3,
            ),
            CheckboxListTile(
              title: const Text('Private list'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_nameController.text.trim().isEmpty || _isLoading)
              ? null
              : _createList,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.twitterBlue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  void _createList() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createList(
        _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPrivate: _isPrivate,
      );

      if (result['success']) {
        final newList = TwitterList.fromJson(result['list']);
        widget.onListCreated(newList);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating list: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class EditListDialog extends StatefulWidget {
  final TwitterList list;
  final Function(TwitterList) onListUpdated;

  const EditListDialog({
    super.key,
    required this.list,
    required this.onListUpdated,
  });

  @override
  State<EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<EditListDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isPrivate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.name);
    _descriptionController = TextEditingController(
      text: widget.list.description,
    );
    _isPrivate = widget.list.isPrivate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit List'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'List name'),
              maxLength: 25,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLength: 100,
              maxLines: 3,
            ),
            CheckboxListTile(
              title: const Text('Private list'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateList,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.twitterBlue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  void _updateList() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.updateList(
        widget.list.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPrivate: _isPrivate,
      );

      if (result['success']) {
        final updatedList = TwitterList.fromJson(result['list']);
        widget.onListUpdated(updatedList);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating list: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
