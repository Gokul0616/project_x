import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tweet_model.dart';
import '../providers/tweet_provider.dart';
import '../utils/app_theme.dart';
import '../screens/tweet/tweet_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../widgets/media_grid_widget.dart';

class EnhancedTweetCard extends StatefulWidget {
  final Tweet tweet;
  final Function(Tweet)? onTweetUpdated;
  final bool showBookmarkAction;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onDoubleTap;

  const EnhancedTweetCard({
    super.key,
    required this.tweet,
    this.onTweetUpdated,
    this.showBookmarkAction = false,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.onDoubleTap,
  });

  @override
  _EnhancedTweetCardState createState() => _EnhancedTweetCardState();
}

class _EnhancedTweetCardState extends State<EnhancedTweetCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showQuickActions = false;
  late AnimationController _likeAnimationController;
  late AnimationController _retweetAnimationController;
  late AnimationController _quickActionsController;
  late Animation<double> _likeAnimation;
  late Animation<double> _retweetAnimation;
  late Animation<Offset> _quickActionsAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _retweetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _quickActionsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _retweetAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _retweetAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _quickActionsAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _quickActionsController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _retweetAnimationController.dispose();
    _quickActionsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  void _handleLike() {
    // Trigger animation
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Call provider
    Provider.of<TweetProvider>(
      context,
      listen: false,
    ).likeTweet(widget.tweet.id);
  }

  void _handleRetweet() {
    // Trigger animation
    _retweetAnimationController.forward().then((_) {
      _retweetAnimationController.reverse();
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Call provider
    Provider.of<TweetProvider>(
      context,
      listen: false,
    ).retweetTweet(widget.tweet.id);
  }

  void _handleDoubleTap() {
    widget.onDoubleTap?.call();
    _handleLike();
  }

  void _showQuickActionsMenu() {
    setState(() {
      _showQuickActions = true;
    });
    _quickActionsController.forward();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showQuickActions) {
        _hideQuickActions();
      }
    });
  }

  void _hideQuickActions() {
    _quickActionsController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showQuickActions = false;
        });
      }
    });
  }

  void _handleNotInterested() {
    _hideQuickActions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thanks for your feedback. You\'ll see fewer posts like this.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleShowLessOften() {
    _hideQuickActions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You\'ll see less from @${widget.tweet.author.username}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxLines = 3;
    const maxContentLength = 280;

    return Semantics(
      label:
          'Tweet by ${widget.tweet.author.displayName}, ${widget.tweet.content}',
      button: true,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TweetDetailScreen(tweet: widget.tweet),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          username: widget.tweet.author.username,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.twitterBlue,
                    backgroundImage:
                        widget.tweet.author.profileImage != null
                        ? CachedNetworkImageProvider(
                            widget.tweet.author.profileImage!,
                          )
                        : null,
                    child: widget.tweet.author.profileImage == null
                        ? Text(
                            widget.tweet.author.displayName.isNotEmpty
                                ? widget.tweet.author.displayName[0]
                                    .toUpperCase()
                                : widget.tweet.author.username.isNotEmpty
                                ? widget.tweet.author.username[0]
                                    .toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Tweet Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info and Time
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(
                                      username: widget.tweet.author.username,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.tweet.author.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Placeholder for verified badge
                          if (widget.tweet.author.isVerified)
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppTheme.twitterBlue,
                            ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '@${widget.tweet.author.username}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '·',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.tweet.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          // Three dots menu
                          GestureDetector(
                            onTap: () {
                              // Show bottom sheet menu
                            },
                            child: Icon(
                              Icons.more_horiz,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Tweet Text
                      RichTweetText(
                        text: widget.tweet.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          height: 1.4,
                        ),
                      ),

                      // Media content
                      if (widget.tweet.mediaFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        MediaGridWidget(
                          mediaFiles: widget.tweet.mediaFiles
                              .map(
                                (media) => {
                                  'url': media.url,
                                  'type': media.type,
                                  'isLocal': false,
                                  'filename': media.filename,
                                  'size': media.size,
                                  'thumbnailUrl': media.thumbnailUrl,
                                },
                              )
                              .toList(),
                          enableTap: true,
                        ),
                      ] else if (widget.tweet.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.tweet.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: Colors.grey[200],
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionButton(
                            icon: Icons.chat_bubble_outline,
                            count: widget.tweet.repliesCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TweetDetailScreen(
                                    tweet: widget.tweet,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.repeat,
                            count: widget.tweet.retweetsCount,
                            isActive: widget.tweet.isRetweeted,
                            activeColor: Colors.green,
                            onTap: _handleRetweet,
                          ),
                          _buildActionButton(
                            icon: widget.tweet.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            count: widget.tweet.likesCount,
                            isActive: widget.tweet.isLiked,
                            activeColor: Colors.red,
                            onTap: _handleLike,
                          ),
                          _buildActionButton(
                            icon: Icons.share_outlined,
                            onTap: () {
                              // Share functionality
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int? count,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? activeColor : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RichTweetText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isClickable;
  final int? maxLines;
  final TextOverflow? overflow;

  const RichTweetText({
    super.key,
    required this.text,
    this.style,
    this.isClickable = true,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: buildTextSpan(
        context: context,
        text: text,
        style: style,
        isClickable: isClickable,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  static TextSpan buildTextSpan({
    required BuildContext context,
    required String text,
    TextStyle? style,
    bool isClickable = true,
  }) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'(#\w+|@\w+)');

    int lastEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: style,
          ),
        );
      }

      final String matchedText = match.group(0)!;
      final bool isHashtag = matchedText.startsWith('#');
      final bool isMention = matchedText.startsWith('@');

      spans.add(
        TextSpan(
          text: matchedText,
          style: const TextStyle(
            color: AppTheme.twitterBlue,
            fontWeight: FontWeight.w500,
          ),
          recognizer: isClickable
              ? (TapGestureRecognizer()
                ..onTap = () {
                  if (isHashtag || isMention) {
                    _handleTap(context, matchedText);
                  }
                })
              : null,
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: style,
        ),
      );
    }

    if (spans.isEmpty) {
      return TextSpan(
        text: text,
        style: style,
      );
    }

    return TextSpan(children: spans);
  }

  static void _handleTap(BuildContext context, String text) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen(initialQuery: text)),
    );
  }
}
