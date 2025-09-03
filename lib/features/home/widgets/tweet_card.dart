// lib/features/home/widgets/tweet_card.dart
import 'package:flutter/material.dart';
import 'package:project_x/core/theme/app_theme.dart';

class TweetCard extends StatelessWidget {
  final String username;
  final String handle;
  final String content;
  final String time;
  final int likes;
  final int retweets;
  final int replies;
  final String? imageUrl;

  const TweetCard({
    super.key,
    required this.username,
    required this.handle,
    required this.content,
    required this.time,
    required this.likes,
    required this.retweets,
    required this.replies,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://via.placeholder.com/48'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: AppTheme.darkTheme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@$handle · $time',
                      style: AppTheme.darkTheme.textTheme.bodyMedium!.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content, style: AppTheme.darkTheme.textTheme.bodyLarge),
                if (imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(Icons.chat_bubble_outline, replies),
                    _buildActionButton(Icons.repeat, retweets),
                    _buildActionButton(Icons.favorite_border, likes),
                    _buildActionButton(Icons.share, 0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(count.toString(), style: const TextStyle(color: Colors.grey)),
        ],
      ],
    );
  }
}
