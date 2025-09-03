// lib/features/home/widgets/tweet_composer.dart
import 'package:flutter/material.dart';
import 'package:project_x/core/theme/app_theme.dart';

class TweetComposer extends StatelessWidget {
  final Function(String) onTweet;

  const TweetComposer({super.key, required this.onTweet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://via.placeholder.com/40'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "What's happening?",
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
              ),
              maxLines: null,
              style: AppTheme.darkTheme.textTheme.bodyLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {
              // Implement tweet functionality
            },
          ),
        ],
      ),
    );
  }
}
