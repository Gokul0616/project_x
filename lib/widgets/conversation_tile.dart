import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.id;
    final messageProvider = Provider.of<MessageProvider>(context);

    // Get the other participant for direct messages
    final otherParticipant = conversation.isGroup
        ? null
        : conversation.getOtherParticipant(currentUserId ?? '');

    // Determine display info
    final String displayName = conversation.isGroup
        ? (conversation.groupName ?? 'Group Chat')
        : (otherParticipant?.displayName ?? 'Unknown User');

    final String displayImage = conversation.isGroup
        ? (conversation.groupImage ?? '')
        : (otherParticipant?.profileImage ?? '');

    // Format last activity time
    final String timeText = _formatTime(conversation.lastActivity);

    // Get typing indicator
    final typingUsers = messageProvider.getTypingUsers(conversation.id);
    final isTyping = typingUsers.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: displayImage.isNotEmpty
                      ? CachedNetworkImageProvider(displayImage)
                      : null,
                  child: displayImage.isEmpty
                      ? Icon(
                          conversation.isGroup ? Icons.group : Icons.person,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
                // Online indicator (if available)
                if (!conversation.isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Display name
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Time
                      Text(
                        timeText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      // Last message or typing indicator
                      Expanded(
                        child: isTyping
                            ? Row(
                                children: [
                                  Text(
                                    _getTypingText(typingUsers, conversation),
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                conversation.lastMessagePreview,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: conversation.unreadCount > 0
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color
                                          : Colors.grey.shade600,
                                      fontWeight: conversation.unreadCount > 0
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                      ),

                      // Unread count badge
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('M/d/yy').format(dateTime);
    } else if (difference.inDays > 0) {
      return DateFormat('EEE').format(dateTime); // Mon, Tue, etc.
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _getTypingText(Set<String> typingUsers, Conversation conversation) {
    if (typingUsers.isEmpty) return '';

    if (conversation.isGroup) {
      if (typingUsers.length == 1) {
        // Try to find the user who is typing
        try {
          final typingUser = conversation.participants.firstWhere(
            (user) => typingUsers.contains(user.id),
          );
          return '${typingUser.displayName} is typing...';
        } catch (e) {
          return 'Someone is typing...';
        }
      } else {
        return 'Multiple people are typing...';
      }
    } else {
      return 'typing...';
    }
  }
}
