import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as flutter;
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

class TweetCard extends StatefulWidget {
  final Tweet tweet;
  final Function(Tweet)? onTweetUpdated;
  final bool showBookmarkAction;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  const TweetCard({
    super.key,
    required this.tweet,
    this.onTweetUpdated,
    this.showBookmarkAction = false,
    this.isBookmarked = false,
    this.onBookmarkToggle,
  });

  @override
  _TweetCardState createState() => _TweetCardState();
}

class _TweetCardState extends State<TweetCard> {
  bool _isExpanded = false;

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

  @override
  Widget build(BuildContext context) {
    const maxLines = 3; // Max lines before truncation
    const maxContentLength = 280; // Twitter-like character limit for truncation

    return Semantics(
      label:
          'Tweet by ${widget.tweet.author.displayName}, ${widget.tweet.content}',
      button: true,
      child: Column(
        children: [
          // Main tweet content
          GestureDetector(
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
                  horizontal: 12.0, // Twitter-like compactness
                  vertical: 10.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar - Twitter-like size
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
                        radius: 18, // Smaller for Twitter aesthetic
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
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tweet Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info and Time - Twitter-style
                          Row(
                            children: [
                              Flexible(
                                flex: 2,
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
                                      fontSize: 14, // Smaller for Twitter look
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
                              Flexible(
                                flex: 2,
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
                                    '@${widget.tweet.author.username}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '·',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.tweet.createdAt),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          // Tweet Text with truncation and "Show more"
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final textSpan = RichTweetText.buildTextSpan(
                                text: widget.tweet.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  height: 1.3,
                                ),
                                context: context,
                              );

                              final textPainter = TextPainter(
                                text: textSpan,
                                maxLines: maxLines,
                                textDirection: flutter.TextDirection.ltr,
                              )..layout(maxWidth: constraints.maxWidth);

                              final isOverflowing =
                                  textPainter.didExceedMaxLines ||
                                  widget.tweet.content.length >
                                      maxContentLength;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichTweetText(
                                    text: widget.tweet.content,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      height: 1.3,
                                    ),
                                    maxLines: _isExpanded ? null : maxLines,
                                    overflow: _isExpanded
                                        ? null
                                        : TextOverflow.ellipsis,
                                  ),
                                  if (isOverflowing && !_isExpanded)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = true;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          'Show more',
                                          style: TextStyle(
                                            color: AppTheme.twitterBlue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (isOverflowing && _isExpanded)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = false;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          'Show less',
                                          style: TextStyle(
                                            color: AppTheme.twitterBlue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          // Tweet Media (images/videos)
                          if (widget.tweet.mediaFiles.isNotEmpty) ...[
                            const SizedBox(height: 6),
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
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                12,
                              ), // Twitter-like rounded corners
                              child: CachedNetworkImage(
                                imageUrl: widget.tweet.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 160, // Slightly smaller
                                  color: Theme.of(context).dividerColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.twitterBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 160,
                                  color: Theme.of(context).dividerColor,
                                  child: Icon(
                                    Icons.error,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 6),
                          // Action Buttons - Twitter-like spacing
                          GestureDetector(
                            onTap: () {}, // Prevent parent GestureDetector
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ActionButton(
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
                                _ActionButton(
                                  icon: Icons.repeat,
                                  count: widget.tweet.retweetsCount,
                                  isActive: widget.tweet.isRetweeted,
                                  activeColor: Colors.green,
                                  onTap: () {
                                    Provider.of<TweetProvider>(
                                      context,
                                      listen: false,
                                    ).retweetTweet(widget.tweet.id);
                                  },
                                ),
                                _ActionButton(
                                  icon: widget.tweet.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  count: widget.tweet.likesCount,
                                  isActive: widget.tweet.isLiked,
                                  activeColor: Colors.red,
                                  onTap: () {
                                    Provider.of<TweetProvider>(
                                      context,
                                      listen: false,
                                    ).likeTweet(widget.tweet.id);
                                  },
                                ),
                                widget.showBookmarkAction
                                    ? _ActionButton(
                                        icon: widget.isBookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_outline,
                                        count: 0,
                                        isActive: widget.isBookmarked,
                                        activeColor: AppTheme.twitterBlue,
                                        onTap: widget.onBookmarkToggle ?? () {},
                                      )
                                    : _ActionButton(
                                        icon: Icons.share_outlined,
                                        count: 0,
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Share feature coming soon!',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.count,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive && activeColor != null
        ? activeColor!
        : Theme.of(context).textTheme.bodyMedium?.color ?? AppTheme.darkGray;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 3 : 5,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSmallScreen ? 13 : 15, color: color),
            if (count > 0) ...[
              SizedBox(width: isSmallScreen ? 1 : 2),
              Text(
                count > 999
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: isSmallScreen ? 10 : 11,
                ),
              ),
            ],
          ],
        ),
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
            style:
                style ??
                TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.3,
                ),
          ),
        );
      }

      final String matchedText = match.group(0)!;
      final bool isHashtag = matchedText.startsWith('#');
      final bool isMention = matchedText.startsWith('@');

      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            fontSize: 14,
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
          style:
              style ??
              TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.3,
              ),
        ),
      );
    }

    if (spans.isEmpty) {
      return TextSpan(
        text: text,
        style:
            style ??
            TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.3,
            ),
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
