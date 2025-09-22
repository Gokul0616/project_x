import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/tweet_model.dart';
import '../../providers/tweet_provider.dart';
import '../../utils/app_theme.dart';

class ReplyTweetScreen extends StatefulWidget {
  final Tweet parentTweet;

  const ReplyTweetScreen({super.key, required this.parentTweet});

  @override
  State<ReplyTweetScreen> createState() => _ReplyTweetScreenState();
}

class _ReplyTweetScreenState extends State<ReplyTweetScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _postReply() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your reply')));
      return;
    }
    if (text.length > 280) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply cannot exceed 280 characters')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final result = await Provider.of<TweetProvider>(
        context,
        listen: false,
      ).replyToTweet(widget.parentTweet.id, text);

      if (result['success']) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply posted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to post reply')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _contentController.text.length;
    final progress = textLength / 280;
    Color progressColor = AppTheme.twitterBlue;
    if (textLength > 260) progressColor = Colors.yellow;
    if (textLength > 280) progressColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.twitterBlue),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: (_isPosting || textLength == 0 || textLength > 280)
                  ? null
                  : _postReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.twitterBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Reply'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Parent Tweet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parent tweet author avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.twitterBlue,
                  backgroundImage:
                      widget.parentTweet.author.profileImage != null
                      ? CachedNetworkImageProvider(
                          widget.parentTweet.author.profileImage!,
                        )
                      : null,
                  child: widget.parentTweet.author.profileImage == null
                      ? Text(
                          widget.parentTweet.author.displayName.isNotEmpty
                              ? widget.parentTweet.author.displayName[0]
                                    .toUpperCase()
                              : widget.parentTweet.author.username.isNotEmpty
                              ? widget.parentTweet.author.username[0]
                                    .toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author info
                      Row(
                        children: [
                          Text(
                            widget.parentTweet.author.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '@${widget.parentTweet.author.username}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tweet content
                      Text(
                        widget.parentTweet.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // "Replying to" text
                      Text(
                        'Replying to @${widget.parentTweet.author.username}',
                        style: TextStyle(
                          color: AppTheme.twitterBlue,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reply composition area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current user avatar (placeholder)
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.twitterBlue,
                        child: Text(
                          'U', // You would get this from current user
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          maxLength: 280,
                          decoration: InputDecoration(
                            hintText: 'Post your reply',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          autofocus: true,
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Divider(color: AppTheme.darkGray.withOpacity(0.5)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image upload coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.image_outlined,
                          color: AppTheme.twitterBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('GIF search coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.gif_box_outlined,
                          color: AppTheme.twitterBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Poll creation coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.poll_outlined,
                          color: AppTheme.twitterBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Emoji picker coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppTheme.twitterBlue,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location tagging coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.twitterBlue,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                              backgroundColor: AppTheme.darkGray.withOpacity(
                                0.3,
                              ),
                            ),
                            if (textLength > 260)
                              Text(
                                '${280 - textLength}',
                                style: const TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
