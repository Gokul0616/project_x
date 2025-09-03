// lib/features/home/widgets/desktop_home_layout.dart
import 'package:flutter/material.dart';
import 'package:project_x/features/home/widgets/side_navigation_bar.dart';
import 'package:project_x/features/home/widgets/tweet_card.dart';
import 'package:project_x/features/home/widgets/tweet_composer.dart';
import 'package:project_x/features/home/widgets/trends_section.dart';

class DesktopHomeLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const DesktopHomeLayout({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left navigation sidebar
          SizedBox(
            width: 280,
            child: SideNavigationBar(
              currentIndex: currentIndex,
              onItemSelected: onItemSelected,
            ),
          ),

          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[800]!, width: 0.5),
                  right: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Home'),
                    centerTitle: false,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.autorenew),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  // const TweetComposer(onTweet: null),
                  TweetComposer(
                    onTweet: (text) {
                      print("Tweeted: $text");
                    },
                  ),

                  const Divider(height: 1, color: Colors.grey),
                  Expanded(
                    child: ListView(
                      children: const [
                        TweetCard(
                          username: "John Doe",
                          handle: "johndoe",
                          content:
                              "Just built a Flutter app with a responsive layout! #FlutterDev",
                          time: "2h",
                          likes: 24,
                          retweets: 5,
                          replies: 3,
                          imageUrl: "https://via.placeholder.com/500x300",
                        ),
                        TweetCard(
                          username: "Jane Smith",
                          handle: "janesmith",
                          content: "Beautiful day for coding outside! ☀️",
                          time: "4h",
                          likes: 42,
                          retweets: 12,
                          replies: 7,
                        ),
                        TweetCard(
                          username: "Tech News",
                          handle: "technews",
                          content:
                              "New Flutter update brings exciting features for developers",
                          time: "6h",
                          likes: 128,
                          retweets: 45,
                          replies: 23,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right sidebar with trends
          SizedBox(
            width: 350,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TrendsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
