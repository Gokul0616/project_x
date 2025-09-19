import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Message? previousMessage;
  final Message? nextMessage;
  final String currentUserId;
  final Function(String) onReact;
  final Function(Message) onReply;  // Changed to pass the message object

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
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _replyIconAnimation;
  
  bool _isSwipeInProgress = false;
  double _swipeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.15, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _replyIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced user ID comparison with better error handling
    final cleanSenderId = widget.message.senderId.trim();
    final cleanCurrentUserId = widget.currentUserId.trim();
    final isOwnMessage = cleanSenderId.isNotEmpty && 
                        cleanCurrentUserId.isNotEmpty && 
                        cleanSenderId == cleanCurrentUserId;
    
    final showAvatar = _shouldShowAvatar();
    final showTimestamp = _shouldShowTimestamp();

    // Enhanced debug logging
    print('MessageBubble DEBUG:');
    print('  message.senderId: "$cleanSenderId"');
    print('  currentUserId: "$cleanCurrentUserId"');
    print('  isOwnMessage: $isOwnMessage');
    print('  senderDisplayName: "${widget.message.senderDisplayName}"');
    print('  message.content: "${widget.message.content}"');

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _isSwipeInProgress = true;
        _swipeProgress = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_isSwipeInProgress) return;
        
        // Only allow swipe to reply from right to left
        final deltaX = details.delta.dx;
        if (deltaX < 0) {
          _swipeProgress = (_swipeProgress - deltaX / 100).clamp(0.0, 1.0);
          _animationController.value = _swipeProgress;
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isSwipeInProgress) return;
        
        _isSwipeInProgress = false;
        
        // Trigger reply if swipe progress is significant
        if (_swipeProgress > 0.3) {
          _triggerReply();
        }
        
        // Reset animation
        _animationController.reverse().then((_) {
          _swipeProgress = 0.0;
        });
      },
      child: Stack(
        children: [
          // Reply icon that appears during swipe
          if (_swipeProgress > 0.1)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _replyIconAnimation,
                builder: (context, child) {
                  return Center(
                    child: Transform.scale(
                      scale: _replyIconAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.reply,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Main message content with slide animation
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimation.value * 100, // Convert to pixels
                child: Container(
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
                                    if (widget.message.replyToId != null) ...[
                                      _buildReplyPreview(context, isOwnMessage),
                                      const SizedBox(height: 8),
                                    ],

                                    // Media content
                                    if (widget.message.mediaFiles.isNotEmpty) ...[
                                      _buildMediaContent(context),
                                      if (widget.message.content.isNotEmpty) const SizedBox(height: 8),
                                    ],

                                    // Text content
                                    if (widget.message.content.isNotEmpty)
                                      Text(
                                        widget.message.content,
                                        style: TextStyle(
                                          color: isOwnMessage ? Colors.white : null,
                                          fontSize: 16,
                                        ),
                                      ),

                                    // Reactions
                                    if (widget.message.reactions.isNotEmpty) ...[
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
                              _formatTimestamp(widget.message.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (isOwnMessage) ...[
                              const SizedBox(width: 4),
                              Icon(
                                widget.message.isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: widget.message.isRead ? Colors.blue : Colors.grey.shade600,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _triggerReply() {
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Trigger reply with the message object
    widget.onReply(widget.message);
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: widget.message.senderProfileImage != null
          ? CachedNetworkImageProvider(widget.message.senderProfileImage!)
          : null,
      child: widget.message.senderProfileImage == null
          ? Text(
              (widget.message.senderDisplayName ?? widget.message.senderUsername ?? '').isNotEmpty 
                  ? (widget.message.senderDisplayName ?? widget.message.senderUsername ?? '')[0].toUpperCase()
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to ${widget.message.senderDisplayName ?? widget.message.senderUsername ?? 'Unknown'}',
            style: TextStyle(
              color: isOwnMessage ? Colors.white70 : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Original message content', // TODO: Fetch original message content using replyToId
            style: TextStyle(
              color: isOwnMessage ? Colors.white70 : Colors.grey.shade700,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.message.mediaFiles.map((media) {
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
    for (final reaction in widget.message.reactions) {
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
        final hasUserReacted = reactions.any((r) => r.userId == widget.currentUserId);

        return GestureDetector(
          onTap: () => widget.onReact(emoji),
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
    if (widget.message.senderId == widget.currentUserId) return false;
    
    return widget.nextMessage == null || 
           widget.nextMessage!.senderId != widget.message.senderId ||
           _isDifferentTimeGroup(widget.message.createdAt, widget.nextMessage!.createdAt);
  }

  bool _shouldShowTimestamp() {
    return widget.nextMessage == null || 
           _isDifferentTimeGroup(widget.message.createdAt, widget.nextMessage!.createdAt);
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
                  widget.onReply(widget.message);
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
                  _copyMessageText();
                },
              ),
              if (widget.message.senderId == widget.currentUserId) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete message', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement delete message functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete message feature coming soon!')),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _copyMessageText() {
    if (widget.message.content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    }
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
                  widget.onReact(emoji);
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