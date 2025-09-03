// lib/features/home/widgets/trends_section.dart
import 'package:flutter/material.dart';
import 'package:project_x/core/theme/app_theme.dart';

class TrendsSection extends StatelessWidget {
  const TrendsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trends for you",
            style: AppTheme.darkTheme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendItem("Trending in USA", "#FlutterDev", "50.4K posts"),
          _buildTrendItem("Sports", "#SuperBowl", "100K posts"),
          _buildTrendItem("Politics", "#Election2024", "75.2K posts"),
          _buildTrendItem("Technology", "#AI", "45.7K posts"),
          _buildTrendItem("Entertainment", "#NewMovie", "32.1K posts"),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String category, String topic, String posts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            topic,
            style: AppTheme.darkTheme.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(posts, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
