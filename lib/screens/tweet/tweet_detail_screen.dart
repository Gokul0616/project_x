import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../search/search_screen.dart';

import '../../models/tweet_model.dart';
import '../../providers/tweet_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/media_grid_widget.dart';
import '../../widgets/reply_tweet_card.dart';
import 'reply_tweet_screen.dart';

class TweetDetailScreen extends StatefulWidget {
  final Tweet tweet;

  const TweetDetailScreen({super.key, required this.tweet});

  @override
  State<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends State<TweetDetailScreen> {
  List<Tweet> _replies = [];
  bool _isLoadingReplies = false;
  Tweet? _currentTweet; // Track the current tweet with latest state
  bool _isContentExpanded = false; // Track "Show more" state

  @override
  void initState() {
    super.initState();
    _currentTweet = widget.tweet;
    Provider.of<TweetProvider>(
      context,
      listen: false,
    ).cacheTweetDetails(widget.tweet);
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _isLoadingReplies = true;
    });

    try {
      final replies = await Provider.of<TweetProvider>(
        context,
        listen: false,
      ).getTweetReplies(widget.tweet.id);

      setState(() {
        _replies = replies ?? [];
        _isLoadingReplies = false;
      });
    } catch (e) {
      setState(() {
        _replies = [];
        _isLoadingReplies = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading replies: $e')));
    }
  }

  Future<void> _replyToTweet() async {
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);
    final currentTweet =
        tweetProvider.getTweetById(widget.tweet.id) ??
        _currentTweet ??
        widget.tweet;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyTweetScreen(parentTweet: currentTweet),
      ),
    );

    if (result == true) {
      await _loadReplies();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${date.minute.toString().padLeft(2, '0')} $amPm · ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showTweetOptions(BuildContext context, Tweet tweet) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isOwnTweet = currentUser?.id == tweet.author.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            if (isOwnTweet) ...[
              _buildTweetOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete',
                subtitle: 'Remove this tweet',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, tweet);
                },
              ),
              _buildTweetOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit',
                subtitle: 'Edit this tweet',
                onTap: () {
                  Navigator.pop(context);
                  _editTweet(context, tweet);
                },
              ),
            ] else ...[
              _buildTweetOptionTile(
                icon: Icons.person_add_disabled_outlined,
                title: 'Unfollow @${tweet.author.username}',
                subtitle: 'Stop seeing tweets from this account',
                onTap: () {
                  Navigator.pop(context);
                  _unfollowUser(context, tweet.author);
                },
              ),
              _buildTweetOptionTile(
                icon: Icons.block_outlined,
                title: 'Block @${tweet.author.username}',
                subtitle: 'Block this account',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(context, tweet.author);
                },
              ),
              _buildTweetOptionTile(
                icon: Icons.flag_outlined,
                title: 'Report Tweet',
                subtitle: 'Report this tweet for review',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _reportTweet(context, tweet);
                },
              ),
            ],

            // Common options for all tweets
            _buildTweetOptionTile(
              icon: Icons.bookmark_border_outlined,
              title: 'Bookmark',
              subtitle: 'Save this tweet for later',
              onTap: () {
                Navigator.pop(context);
                _bookmarkTweet(context, tweet);
              },
            ),
            _buildTweetOptionTile(
              icon: Icons.share_outlined,
              title: 'Share Tweet',
              subtitle: 'Share this tweet with others',
              onTap: () {
                Navigator.pop(context);
                _shareTweet(context, tweet);
              },
            ),
            _buildTweetOptionTile(
              icon: Icons.copy_outlined,
              title: 'Copy Link',
              subtitle: 'Copy link to this tweet',
              onTap: () {
                Navigator.pop(context);
                _copyTweetLink(context, tweet);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTweetOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Tweet tweet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tweet?'),
        content: const Text(
          'This can\'t be undone and it will be removed from your profile, the timeline of any accounts that follow you, and from search results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTweet(context, tweet);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTweet(BuildContext context, Tweet tweet) {
    // TODO: Implement delete tweet API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete tweet functionality not implemented yet'),
      ),
    );
  }

  void _editTweet(BuildContext context, Tweet tweet) {
    // TODO: Navigate to edit tweet screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit tweet functionality not implemented yet'),
      ),
    );
  }

  void _unfollowUser(BuildContext context, user) {
    // TODO: Implement unfollow API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unfollow functionality not implemented yet')),
    );
  }

  void _blockUser(BuildContext context, user) {
    // TODO: Implement block user API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Block functionality not implemented yet')),
    );
  }

  void _reportTweet(BuildContext context, Tweet tweet) {
    // TODO: Implement report tweet functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report functionality not implemented yet')),
    );
  }

  void _bookmarkTweet(BuildContext context, Tweet tweet) {
    // TODO: Implement bookmark tweet API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark functionality not implemented yet'),
      ),
    );
  }

  void _shareTweet(BuildContext context, Tweet tweet) {
    // TODO: Implement share tweet functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality not implemented yet')),
    );
  }

  void _copyTweetLink(BuildContext context, Tweet tweet) {
    // TODO: Implement copy tweet link functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copy link functionality not implemented yet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxLines = 3; // Max lines before truncation
    const maxContentLength = 280; // Twitter-like character limit for truncation
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final displayTweet =
            tweetProvider.getTweetById(widget.tweet.id) ??
            _currentTweet ??
            widget.tweet;
        final providerReplies = tweetProvider.getRepliesById(widget.tweet.id);
        final displayReplies = providerReplies.isNotEmpty
            ? providerReplies
            : _replies;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Post'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Tweet Detail View
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Info
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Navigate to @${displayTweet.author.username} profile - Coming soon!',
                                        ),
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius:
                                        20, // Smaller for Twitter-like aesthetic
                                    backgroundColor: AppTheme.twitterBlue,
                                    backgroundImage:
                                        displayTweet.author.profileImage != null
                                        ? CachedNetworkImageProvider(
                                            displayTweet.author.profileImage!,
                                          )
                                        : null,
                                    child:
                                        displayTweet.author.profileImage == null
                                        ? Text(
                                            displayTweet
                                                    .author
                                                    .displayName
                                                    .isNotEmpty
                                                ? displayTweet
                                                      .author
                                                      .displayName[0]
                                                      .toUpperCase()
                                                : displayTweet
                                                      .author
                                                      .username
                                                      .isNotEmpty
                                                ? displayTweet
                                                      .author
                                                      .username[0]
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
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayTweet.author.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        '@${displayTweet.author.username}',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onPressed: () {
                                    _showTweetOptions(context, displayTweet);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Tweet Content with "Show more"
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final textSpan = RichTweetText.buildTextSpan(
                                  text: displayTweet.content,
                                  style: TextStyle(
                                    fontSize: 18,
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
                                  textDirection: TextDirection.ltr,
                                )..layout(maxWidth: constraints.maxWidth);

                                final isOverflowing =
                                    textPainter.didExceedMaxLines ||
                                    displayTweet.content.length >
                                        maxContentLength;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichTweetText(
                                      text: displayTweet.content,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        height: 1.3,
                                      ),
                                      maxLines: _isContentExpanded
                                          ? null
                                          : maxLines,
                                      overflow: _isContentExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                    ),
                                    if (isOverflowing && !_isContentExpanded)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isContentExpanded = true;
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
                                    if (isOverflowing && _isContentExpanded)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isContentExpanded = false;
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

                            // Tweet Media
                            if (displayTweet.mediaFiles.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              MediaGridWidget(
                                mediaFiles: displayTweet.mediaFiles
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
                            ] else if (displayTweet.imageUrl != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: displayTweet.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    color: Theme.of(context).dividerColor,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.twitterBlue,
                                            ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        height: 200,
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

                            const SizedBox(height: 12),

                            // Tweet Time
                            Text(
                              _formatDate(displayTweet.createdAt),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Engagement Stats
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 0.5,
                                  ),
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (displayTweet.retweetsCount > 0) ...[
                                    Text(
                                      '${_formatCount(displayTweet.retweetsCount)} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Reposts',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Text(
                                    '${_formatCount(displayTweet.repliesCount)} ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Replies',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (displayTweet.likesCount > 0) ...[
                                    Text(
                                      '${_formatCount(displayTweet.likesCount)} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Likes',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Action Buttons
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _DetailActionButton(
                                    icon: Icons.chat_bubble_outline,
                                    count: displayTweet.repliesCount,
                                    onTap: _replyToTweet,
                                  ),
                                  _DetailActionButton(
                                    icon: Icons.repeat,
                                    isActive: displayTweet.isRetweeted,
                                    activeColor: Colors.green,
                                    count: displayTweet.retweetsCount,
                                    onTap: () {
                                      Provider.of<TweetProvider>(
                                        context,
                                        listen: false,
                                      ).retweetTweet(displayTweet.id);
                                    },
                                  ),
                                  _DetailActionButton(
                                    icon: displayTweet.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    isActive: displayTweet.isLiked,
                                    activeColor: Colors.red,
                                    count: displayTweet.likesCount,
                                    onTap: () {
                                      Provider.of<TweetProvider>(
                                        context,
                                        listen: false,
                                      ).likeTweet(displayTweet.id);
                                    },
                                  ),
                                  _DetailActionButton(
                                    icon: Icons.share_outlined,
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

                      // Replies Section
                      if (_isLoadingReplies)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.twitterBlue,
                              ),
                            ),
                          ),
                        )
                      else if (displayReplies.isEmpty &&
                          displayTweet.repliesCount > 0)
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Replies not loaded',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'There are ${displayTweet.repliesCount} replies, but they failed to load. Tap to retry.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadReplies,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.twitterBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (displayReplies.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 60,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No replies yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to reply!',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayReplies.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Most relevant replies',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: displayReplies.length,
                              itemBuilder: (context, index) {
                                return ReplyTweetCard(
                                  tweet: displayReplies[index],
                                  showParent: false,
                                  isInDetailScreen: false,
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Reply Input Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.twitterBlue,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _replyToTweet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[900]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Post your reply',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      onPressed: () {
                        // TODO: Implement image attachment
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;
  final int? count;

  const _DetailActionButton({
    required this.icon,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
    this.count,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = isActive && activeColor != null
        ? activeColor!
        : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count!),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
