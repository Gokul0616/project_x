// lib/features/home/widgets/mobile_home_layout.dart
import 'package:flutter/material.dart';
import 'package:project_x/features/home/widgets/tweet_card.dart';
import 'package:project_x/features/home/widgets/tweet_composer.dart';

class MobileHomeLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const MobileHomeLayout({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.autorenew), onPressed: () {}),
        ],
      ),
      body: _buildCurrentScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show tweet composer
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => TweetComposer(
              onTweet: (text) {
                print("Tweeted: $text");
              },
            ),
            // builder: (context) => const TweetComposer(onTweet: null),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Messages'),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentIndex) {
      case 0:
        return _buildHomeFeed();
      case 1:
        return _buildExploreScreen();
      case 2:
        return _buildNotificationsScreen();
      case 3:
        return _buildMessagesScreen();
      default:
        return _buildHomeFeed();
    }
  }

  Widget _buildHomeFeed() {
    return ListView(
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
          content: "New Flutter update brings exciting features for developers",
          time: "6h",
          likes: 128,
          retweets: 45,
          replies: 23,
        ),
      ],
    );
  }

  Widget _buildExploreScreen() {
    return const Center(child: Text('Explore Screen'));
  }

  Widget _buildNotificationsScreen() {
    return const Center(child: Text('Notifications Screen'));
  }

  Widget _buildMessagesScreen() {
    return const Center(child: Text('Messages Screen'));
  }
}
