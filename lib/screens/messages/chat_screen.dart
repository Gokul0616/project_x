import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_composer.dart';
import '../../widgets/reply_composer.dart';
import '../../services/call_service.dart';
import '../../screens/call/call_screen.dart';

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
  bool _otherUserOnline = false;
  Timer? _onlineStatusTimer;

  // Reply state
  Message? _replyingToMessage;
  bool _showReplyComposer = false;

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

    // Initialize online status checking
    _startOnlineStatusCheck();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _typingTimer?.cancel();
    _onlineStatusTimer?.cancel();

    // Leave the conversation room
    _messageProvider.leaveConversationRoom(widget.conversation.id);

    super.dispose();
  }

  void _startOnlineStatusCheck() {
    // Check online status every 30 seconds
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkOtherUserOnlineStatus();
    });

    // Initial check
    _checkOtherUserOnlineStatus();
  }

  void _checkOtherUserOnlineStatus() {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser != null && !widget.conversation.isGroup) {
      final otherParticipant = widget.conversation.getOtherParticipant(
        currentUser.id,
      );
      if (otherParticipant != null) {
        // Here you would implement actual online status check via WebSocket or API
        // For now, we'll show online when WebSocket is connected
        setState(() {
          _otherUserOnline = _messageProvider.isWebSocketConnected;
        });
      }
    }
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

    // Debug logging
    print('ChatScreen DEBUG:');
    print('  currentUser.id: "${currentUser?.id}"');
    print('  conversation.id: "${widget.conversation.id}"');
    print('  otherParticipant: "${otherParticipant?.displayName}"');

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

                      // Improved online status logic
                      String statusText;
                      Color statusColor;

                      if (widget.conversation.isGroup) {
                        statusText = messageProvider.isWebSocketConnected
                            ? 'Active'
                            : 'Inactive';
                        statusColor = messageProvider.isWebSocketConnected
                            ? Colors.green
                            : Colors.grey.shade600;
                      } else {
                        // For direct messages, show more realistic status
                        if (messageProvider.isWebSocketConnected) {
                          // Check if the other user was recently active
                          final lastActivity = widget.conversation.lastActivity;
                          final timeDiff = DateTime.now().difference(
                            lastActivity,
                          );

                          if (timeDiff.inMinutes < 5) {
                            statusText = 'Online';
                            statusColor = Colors.green;
                          } else if (timeDiff.inMinutes < 60) {
                            statusText = 'Active ${timeDiff.inMinutes}m ago';
                            statusColor = Colors.orange;
                          } else if (timeDiff.inHours < 24) {
                            statusText = 'Active ${timeDiff.inHours}h ago';
                            statusColor = Colors.grey.shade600;
                          } else {
                            statusText = 'Active ${timeDiff.inDays}d ago';
                            statusColor = Colors.grey.shade600;
                          }
                        } else {
                          statusText = 'Offline';
                          statusColor = Colors.grey.shade600;
                        }
                      }

                      return Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(fontSize: 12, color: statusColor),
                          ),
                        ],
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
            onPressed: () => _startVideoCall(),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => _startVoiceCall(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showConversationInfo();
                  break;
                case 'mute':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mute feature coming soon!')),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
                case 'clear':
                  _showClearChatConfirmation();
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
              const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
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
                      onReply: _replyToMessage,
                    );
                  },
                );
              },
            ),
          ),

          // Reply composer (if active)
          if (_showReplyComposer && _replyingToMessage != null)
            ReplyComposer(
              replyToMessage: _replyingToMessage!,
              onSendReply: _sendReply,
              onCancelReply: _cancelReply,
            ),

          // Regular message composer (if not replying)
          if (!_showReplyComposer)
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

    print('Sending message: "$content"');

    _messageProvider.sendMessage(
      widget.conversation.id,
      content,
      mediaFilePaths: mediaFiles,
    );

    _messageController.clear();
    _stopTyping();
  }

  void _sendReply(String content) async {
    if (content.trim().isEmpty || _replyingToMessage == null) return;

    print('Sending reply: "$content" to message: ${_replyingToMessage!.id}');

    final success = await _messageProvider.sendMessage(
      widget.conversation.id,
      content,
      replyToId: _replyingToMessage!.id,
    );

    if (success) {
      // Reply sent successfully
      _cancelReply();

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Scroll to bottom to show new reply
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reply. Please try again.'),
        ),
      );
    }
  }

  void _replyToMessage(Message message) {
    setState(() {
      _replyingToMessage = message;
      _showReplyComposer = true;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    print(
      'Replying to message: ${message.id} from ${message.displaySenderName}',
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
      _showReplyComposer = false;
    });
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

  void _showConversationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.conversation.isGroup) ...[
              Text(
                'Group: ${widget.conversation.groupName ?? "Unnamed Group"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Participants: ${widget.conversation.participants.length}'),
              const SizedBox(height: 16),
              const Text(
                'Members:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...widget.conversation.participants.map(
                (participant) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${participant.displayName}'),
                ),
              ),
            ] else ...[
              // Corrected else block using spread operator
              Builder(
                builder: (context) {
                  final currentUser = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).user;
                  final otherParticipant = widget.conversation
                      .getOtherParticipant(currentUser?.id ?? '');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct message with ${otherParticipant?.displayName ?? "Unknown User"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Username: @${otherParticipant?.username ?? "unknown"}',
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Created: ${widget.conversation.createdAt.toString().split(' ')[0]}',
            ),
            const SizedBox(height: 4),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete conversation feature coming soon!'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clear chat feature coming soon!'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _startVideoCall() async {
    final callService = Provider.of<CallService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get the other participant (not the current user)
    final otherParticipant = widget.conversation.participants.firstWhere(
      (p) => p.id != authProvider.user!.id,
    );

    try {
      final callId = await callService.startCall(
        otherParticipant.id,
        CallType.video,
      );

      if (callId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              remoteUserId: otherParticipant.id,
              remoteUserName: otherParticipant.displayName,
              callType: CallType.video,
              callId: callId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start video call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting video call: $e')));
    }
  }

  Future<void> _startVoiceCall() async {
    final callService = Provider.of<CallService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get the other participant (not the current user)
    final otherParticipant = widget.conversation.participants.firstWhere(
      (p) => p.id != authProvider.user!.id,
    );

    try {
      final callId = await callService.startCall(
        otherParticipant.id,
        CallType.voice,
      );

      if (callId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              remoteUserId: otherParticipant.id,
              remoteUserName: otherParticipant.displayName,
              callType: CallType.voice,
              callId: callId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start voice call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting voice call: $e')));
    }
  }
}
