import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';

class MessageReactions extends StatefulWidget {
  final Message message;
  final String currentUserId;
  final Function(String emoji) onReact;
  final bool isOwnMessage;

  const MessageReactions({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReact,
    required this.isOwnMessage,
  });

  @override
  State<MessageReactions> createState() => _MessageReactionsState();
}

class _MessageReactionsState extends State<MessageReactions> {
  bool _showReactionPicker = false;
  final List<String> _quickReactions = [
    '❤️',
    '👍',
    '👎',
    '😂',
    '😮',
    '😢',
    '😡',
    '🎉',
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.message.hasReactions) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _toggleReactionPicker,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: widget.message.groupedReactions.entries.map((entry) {
            final emoji = entry.key;
            final reactions = entry.value;
            final count = reactions.length;
            final hasUserReacted = reactions.any(
              (r) => r.userId == widget.currentUserId,
            );

            return GestureDetector(
              onTap: () => _handleReactionTap(emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasUserReacted
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: hasUserReacted
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasUserReacted
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleReactionPicker() {
    setState(() {
      _showReactionPicker = !_showReactionPicker;
    });

    if (_showReactionPicker) {
      // Show reaction picker overlay
      _showReactionPickerOverlay();
    }
  }

  void _showReactionPickerOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // Backdrop to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Reaction picker
          Positioned(
            left: offset.dx + size.width / 2 - 150, // Center horizontally
            top: offset.dy - 60, // Position above the message
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _quickReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _handleReactionTap(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _showReactionPicker = false;
      });
    });
  }

  void _handleReactionTap(String emoji) {
    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Check if user already reacted with this emoji
    final hasUserReacted = widget.message.hasUserReaction(
      widget.currentUserId,
      emoji,
    );

    if (hasUserReacted) {
      // If already reacted, remove the reaction (toggle off)
      widget.onReact(emoji);
    } else {
      // Add the reaction
      widget.onReact(emoji);
    }
  }
}

// Widget for adding a new reaction to a message
class AddReactionButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddReactionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Icon(
          Icons.add_reaction_outlined,
          size: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
