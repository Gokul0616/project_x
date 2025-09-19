import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Message? previousMessage;
  final Message? nextMessage;
  final String currentUserId;
  final Function(String) onReact;
  final VoidCallback onReply;

  const MessageBubble({
    super.key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
    required this.currentUserId,
    required this.onReact,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    // Fix: Ensure proper comparison by trimming and handling null cases
    final isOwnMessage = message.senderId.trim() == currentUserId.trim();
    final showAvatar = _shouldShowAvatar();
    final showTimestamp = _shouldShowTimestamp();

    // Debug logging
    print('MessageBubble DEBUG:');
    print('  message.senderId: "${message.senderId}"');
    print('  currentUserId: "${currentUserId}"');
    print('  isOwnMessage: $isOwnMessage');
    print('  senderDisplayName: "${message.senderDisplayName}"');

    return Container(
      margin: EdgeInsets.only(
        left: isOwnMessage ? 64 : 16,
        right: isOwnMessage ? 16 : 64,
        bottom: showTimestamp ? 16 : 4,
      ),
      child: Column(
        crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwnMessage && showAvatar) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOwnMessage
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                        bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply to message (if applicable)
                        if (message.replyToId != null) ...[
                          _buildReplyPreview(context, isOwnMessage),
                          const SizedBox(height: 8),
                        ],

                        // Media content
                        if (message.mediaFiles.isNotEmpty) ...[
                          _buildMediaContent(context),
                          if (message.content.isNotEmpty) const SizedBox(height: 8),
                        ],

                        // Text content
                        if (message.content.isNotEmpty)
                          Text(
                            message.content,
                            style: TextStyle(
                              color: isOwnMessage ? Colors.white : null,
                              fontSize: 16,
                            ),
                          ),

                        // Reactions
                        if (message.reactions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildReactions(context),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (isOwnMessage && showAvatar) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),

          // Timestamp and read status
          if (showTimestamp) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTimestamp(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isOwnMessage) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? Colors.blue : Colors.grey.shade600,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: message.senderProfileImage != null
          ? CachedNetworkImageProvider(message.senderProfileImage!)
          : null,
      child: message.senderProfileImage == null
          ? Text(
              (message.senderDisplayName ?? message.senderUsername ?? '').isNotEmpty 
                  ? (message.senderDisplayName ?? message.senderUsername ?? '')[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isOwnMessage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isOwnMessage ? Colors.white : Colors.grey.shade200).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isOwnMessage ? Colors.white : Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Reply to message', // TODO: Fetch original message content using replyToId
        style: TextStyle(
          color: isOwnMessage ? Colors.white70 : Colors.grey.shade700,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: message.mediaFiles.map((media) {
        return GestureDetector(
          onTap: () => _showMediaViewer(context, media),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: media.type == 'image'
                  ? CachedNetworkImage(
                      imageUrl: media.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        if (media.thumbnailUrl != null)
                          CachedNetworkImage(
                            imageUrl: media.thumbnailUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactions(BuildContext context) {
    final reactionGroups = <String, List<MessageReaction>>{};
    
    // Group reactions by emoji
    for (final reaction in message.reactions) {
      final emoji = reaction.emoji;
      reactionGroups[emoji] ??= [];
      reactionGroups[emoji]!.add(reaction);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactionGroups.entries.map((entry) {
        final emoji = entry.key;
        final reactions = entry.value;
        final hasUserReacted = reactions.any((r) => r.userId == currentUserId);

        return GestureDetector(
          onTap: () => onReact(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasUserReacted
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: hasUserReacted
                  ? Border.all(color: Theme.of(context).primaryColor)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                if (reactions.length > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${reactions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasUserReacted
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _shouldShowAvatar() {
    if (message.senderId == currentUserId) return false;
    
    return nextMessage == null || 
           nextMessage!.senderId != message.senderId ||
           _isDifferentTimeGroup(message.createdAt, nextMessage!.createdAt);
  }

  bool _shouldShowTimestamp() {
    return nextMessage == null || 
           _isDifferentTimeGroup(message.createdAt, nextMessage!.createdAt);
  }

  bool _isDifferentTimeGroup(DateTime time1, DateTime time2) {
    return time1.difference(time2).inMinutes.abs() > 5;
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('Add reaction'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy text'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement copy text
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReactionPicker(BuildContext context) {
    final commonEmojis = ['❤️', '👍', '👎', '😂', '😮', '😢', '😡', '🎉'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('React to message'),
          content: Wrap(
            children: commonEmojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReact(emoji);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showMediaViewer(BuildContext context, MediaFile media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: media.type == 'image'
                ? Hero(
                    tag: media.url,
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: media.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                        errorWidget: (context, url, error) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.white, size: 64),
                            SizedBox(height: 16),
                            Text('Failed to load image', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 80),
                      const SizedBox(height: 16),
                      const Text('Video Player', style: TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(media.url, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video player coming soon!')),
                          );
                        },
                        child: const Text('Play Video'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}