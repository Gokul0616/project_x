import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tweet_model.dart';
import '../providers/tweet_provider.dart';
import '../utils/app_theme.dart';
import '../screens/tweet/tweet_detail_screen.dart';
import '../screens/tweet/reply_tweet_screen.dart';
import '../screens/profile/user_profile_screen.dart';

class ReplyTweetCard extends StatelessWidget {
  final Tweet tweet;
  final bool showParent;
  final bool isInDetailScreen;

  const ReplyTweetCard({
    super.key, 
    required this.tweet,
    this.showParent = true,
    this.isInDetailScreen = false,
  });

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
    return GestureDetector(
      onTap: () {
        // Always allow navigation to tweet detail screen
        // Each reply tweet should open its own detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TweetDetailScreen(tweet: tweet),
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
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show parent tweet context if this is a reply and showParent is true
              if (showParent && tweet.parentTweet != null)
                GestureDetector(
                  onTap: () {
                    // Navigate to parent tweet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TweetDetailScreen(tweet: tweet.parentTweet!),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[900] 
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to @${tweet.parentTweet!.author.username}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(
                                      username: tweet.parentTweet!.author.username,
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.twitterBlue,
                                backgroundImage: tweet.parentTweet!.author.profileImage != null
                                    ? CachedNetworkImageProvider(tweet.parentTweet!.author.profileImage!)
                                    : null,
                                child: tweet.parentTweet!.author.profileImage == null
                                    ? Text(
                                        tweet.parentTweet!.author.displayName.isNotEmpty
                                            ? tweet.parentTweet!.author.displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => UserProfileScreen(
                                                username: tweet.parentTweet!.author.username,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          tweet.parentTweet!.author.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => UserProfileScreen(
                                                username: tweet.parentTweet!.author.username,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '@${tweet.parentTweet!.author.username}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tweet.parentTweet!.content,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      height: 1.3,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Main tweet content (similar to TweetCard)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            username: tweet.author.username,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.twitterBlue,
                      backgroundImage: tweet.author.profileImage != null
                          ? CachedNetworkImageProvider(tweet.author.profileImage!)
                          : null,
                      child: tweet.author.profileImage == null
                          ? Text(
                              tweet.author.displayName.isNotEmpty
                                  ? tweet.author.displayName[0].toUpperCase()
                                  : tweet.author.username.isNotEmpty
                                  ? tweet.author.username[0].toUpperCase()
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
                  const SizedBox(width: 10),
                  // Tweet Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info and Time
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(
                                      username: tweet.author.username,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                tweet.author.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(
                                      username: tweet.author.username,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                '@${tweet.author.username}',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '·',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(tweet.createdAt),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Tweet Text
                        Text(
                          tweet.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            height: 1.3,
                          ),
                        ),

                        // Tweet Image (if exists)
                        if (tweet.imageUrl != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: tweet.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
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
                                height: 180,
                                color: Theme.of(context).dividerColor,
                                child: Icon(
                                  Icons.error,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        // Action Buttons - Make them properly interactive
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reply Button
                            _ActionButton(
                              icon: Icons.chat_bubble_outline,
                              count: tweet.repliesCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReplyTweetScreen(parentTweet: tweet),
                                  ),
                                );
                              },
                            ),

                            // Retweet Button
                            _ActionButton(
                              icon: Icons.repeat,
                              count: tweet.retweetsCount,
                              isActive: tweet.isRetweeted,
                              activeColor: Colors.green,
                              onTap: () {
                                Provider.of<TweetProvider>(
                                  context,
                                  listen: false,
                                ).retweetTweet(tweet.id);
                              },
                            ),

                            // Like Button
                            _ActionButton(
                              icon: tweet.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              count: tweet.likesCount,
                              isActive: tweet.isLiked,
                              activeColor: Colors.red,
                              onTap: () {
                                Provider.of<TweetProvider>(
                                  context,
                                  listen: false,
                                ).likeTweet(tweet.id);
                              },
                            ),

                            // Share Button
                            _ActionButton(
                              icon: Icons.share_outlined,
                              count: 0,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share feature coming soon!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        : (Theme.of(context).textTheme.bodyMedium?.color ?? AppTheme.darkGray);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}