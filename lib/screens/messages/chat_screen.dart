import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_composer.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late MessageProvider _messageProvider;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _messageProvider = Provider.of<MessageProvider>(context, listen: false);

    // Load messages for this conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageProvider.loadMessages(widget.conversation.id, refresh: true);
    });

    // Setup pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _typingTimer?.cancel();

    // Leave the conversation room
    _messageProvider.leaveConversationRoom(widget.conversation.id);

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more messages when reaching the top
      if (_messageProvider.hasMoreMessages(widget.conversation.id) &&
          !_messageProvider.isLoadingMessages(widget.conversation.id)) {
        _messageProvider.loadMessages(widget.conversation.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).user;
    final otherParticipant = widget.conversation.isGroup
        ? null
        : widget.conversation.getOtherParticipant(currentUser?.id ?? '');

    final displayName = widget.conversation.isGroup
        ? (widget.conversation.groupName ?? 'Group Chat')
        : (otherParticipant?.displayName ?? 'Unknown User');

    final displayImage = widget.conversation.isGroup
        ? (widget.conversation.groupImage ?? '')
        : (otherParticipant?.profileImage ?? '');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: displayImage.isNotEmpty
                  ? CachedNetworkImageProvider(displayImage)
                  : null,
              child: displayImage.isEmpty
                  ? Icon(
                      widget.conversation.isGroup ? Icons.group : Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<MessageProvider>(
                    builder: (context, messageProvider, child) {
                      final typingUsers = messageProvider.getTypingUsers(
                        widget.conversation.id,
                      );
                      if (typingUsers.isNotEmpty) {
                        return Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return Text(
                        messageProvider.isWebSocketConnected
                            ? 'Online'
                            : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: messageProvider.isWebSocketConnected
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showConversationInfo();
                  break;
                case 'mute':
                  // TODO: Implement mute
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('Conversation info'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute conversation'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete conversation'),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                final messages = messageProvider.getMessagesForConversation(
                  widget.conversation.id,
                );
                final isLoading = messageProvider.isLoadingMessages(
                  widget.conversation.id,
                );
                final error = messageProvider.getMessageError(
                  widget.conversation.id,
                );

                if (error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            messageProvider.loadMessages(
                              widget.conversation.id,
                              refresh: true,
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (messages.isEmpty && isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation with a message below',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount:
                      messages.length +
                      (messageProvider.hasMoreMessages(widget.conversation.id)
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      // Load more indicator at the top
                      return isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }

                    final message = messages[index];
                    final previousMessage = index < messages.length - 1
                        ? messages[index + 1]
                        : null;
                    final nextMessage = index > 0 ? messages[index - 1] : null;

                    return MessageBubble(
                      message: message,
                      previousMessage: previousMessage,
                      nextMessage: nextMessage,
                      currentUserId: currentUser?.id ?? '',
                      onReact: (emoji) => _reactToMessage(message, emoji),
                      onReply: () => _replyToMessage(message),
                    );
                  },
                );
              },
            ),
          ),

          // Message composer
          MessageComposer(
            controller: _messageController,
            onSendMessage: _sendMessage,
            onTypingChanged: _onTypingChanged,
            conversationId: widget.conversation.id,
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content, {List<String>? mediaFiles}) {
    if (content.trim().isEmpty && (mediaFiles == null || mediaFiles.isEmpty))
      return;

    _messageProvider.sendMessage(
      widget.conversation.id,
      content,
      mediaFilePaths: mediaFiles,
    );

    _messageController.clear();
    _stopTyping();
  }

  void _onTypingChanged(bool isTyping) {
    if (isTyping && !_isTyping) {
      _isTyping = true;
      _messageProvider.startTyping(widget.conversation.id);

      // Stop typing after 3 seconds of inactivity
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _stopTyping();
      });
    } else if (!isTyping && _isTyping) {
      _stopTyping();
    }
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _messageProvider.stopTyping(widget.conversation.id);
      _typingTimer?.cancel();
    }
  }

  void _reactToMessage(Message message, String emoji) {
    _messageProvider.reactToMessageWebSocket(
      message.id,
      widget.conversation.id,
      emoji,
    );
  }

  void _replyToMessage(Message message) {
    // TODO: Implement reply functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reply feature coming soon!')));
  }

  void _showConversationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.conversation.isGroup) ...[
              Text(
                'Group: ${widget.conversation.groupName ?? "Unnamed Group"}',
              ),
              Text('Participants: ${widget.conversation.participants.length}'),
            ] else ...[
              Text(
                'Direct message with ${widget.conversation.getOtherParticipant(Provider.of<AuthProvider>(context, listen: false).user?.id ?? '')?.displayName ?? "Unknown User"}',
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Created: ${widget.conversation.createdAt.toString().split(' ')[0]}',
            ),
            Text('Last activity: ${widget.conversation.formattedLastActivity}'),
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close chat screen
              // TODO: Implement conversation deletion
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
