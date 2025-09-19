import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';

class ReplyComposer extends StatefulWidget {
  final Message replyToMessage;
  final Function(String) onSendReply;
  final VoidCallback onCancelReply;

  const ReplyComposer({
    super.key,
    required this.replyToMessage,
    required this.onSendReply,
    required this.onCancelReply,
  });

  @override
  State<ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<ReplyComposer>
    with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Animate in
    _animationController.forward();
    
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendReply() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSendReply(content);
      
      // Animate out and close
      await _animationController.reverse();
      widget.onCancelReply();
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _cancelReply() async {
    await _animationController.reverse();
    widget.onCancelReply();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replying to ${widget.replyToMessage.displaySenderName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.replyToMessage.content.isNotEmpty
                                  ? widget.replyToMessage.content
                                  : widget.replyToMessage.hasMedia
                                      ? '📎 ${widget.replyToMessage.mediaFiles.length} media file(s)'
                                      : 'Message',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _cancelReply,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                
                // Reply input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Type your reply...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendReply(),
                            maxLines: null,
                            minLines: 1,
                            maxLength: 1000,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                              // Hide the counter unless approaching limit
                              if (maxLength != null && currentLength > maxLength * 0.8) {
                                return Text(
                                  '$currentLength/$maxLength',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: currentLength >= maxLength 
                                        ? Colors.red 
                                        : Colors.grey.shade600,
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Send button
                      Container(
                        decoration: BoxDecoration(
                          color: _textController.text.trim().isNotEmpty && !_isSending
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _sendReply,
                          icon: _isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}