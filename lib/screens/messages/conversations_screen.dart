import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/conversation_model.dart';
import '../../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(context, listen: false).loadConversations(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showNewMessageDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Direct Messages',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Conversations list
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                if (messageProvider.isLoadingConversations && messageProvider.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messageProvider.conversationsError != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          messageProvider.conversationsError!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            messageProvider.loadConversations(refresh: true);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final conversations = _searchQuery.isEmpty
                    ? messageProvider.conversations
                    : messageProvider.searchConversations(_searchQuery);

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No messages yet'
                              : 'No conversations found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Start a conversation by tapping the compose button'
                              : 'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => messageProvider.loadConversations(refresh: true),
                  child: ListView.builder(
                    itemCount: conversations.length + (messageProvider.hasMoreConversations ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == conversations.length) {
                        // Load more indicator
                        if (!messageProvider.isLoadingConversations) {
                          messageProvider.loadConversations();
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final conversation = conversations[index];
                      return ConversationTile(
                        conversation: conversation,
                        onTap: () => _openChat(conversation),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: const Text(
          'To start a new conversation, go to a user\'s profile and tap the message button, or select a conversation from your existing messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}