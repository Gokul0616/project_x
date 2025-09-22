import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<TrendingTopic> _trendingHashtags = [];
  List<TrendingTopic> _trendingTopics = [];
  bool _isLoading = false;
  String _selectedLocation = 'Global';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTrends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load trending hashtags from API
      final hashtagsResult = await ApiService.getTrendingHashtags();
      if (hashtagsResult['success'] == true) {
        final List<dynamic> hashtagsData = hashtagsResult['data'];
        setState(() {
          _trendingHashtags = hashtagsData.map((item) => TrendingTopic(
            id: item['hashtag'] ?? '',
            title: '#${item['hashtag'] ?? ''}',
            tweetCount: item['count'] ?? 0,
            category: 'Hashtag',
            isPromoted: false,
            changeFromYesterday: (item['count'] ?? 0) > 100 ? 'up' : 'stable',
          )).toList();
        });
      }
    } catch (e) {
      print('Error loading trending hashtags: $e');
    }

    // Load sample trending topics
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      // Sample trending topics if API doesn't provide enough
      if (_trendingHashtags.length < 5) {
        _trendingTopics = [
          TrendingTopic(
            id: '1',
            title: 'Flutter 3.16',
            tweetCount: 15420,
            category: 'Technology',
            isPromoted: false,
            changeFromYesterday: 'up',
          ),
          TrendingTopic(
            id: '2',
            title: 'Mobile Development',
            tweetCount: 8940,
            category: 'Programming',
            isPromoted: false,
            changeFromYesterday: 'up',
          ),
          TrendingTopic(
            id: '3',
            title: 'UI/UX Design',
            tweetCount: 6780,
            category: 'Design',
            isPromoted: true,
            changeFromYesterday: 'up',
          ),
          TrendingTopic(
            id: '4',
            title: 'Artificial Intelligence',
            tweetCount: 12340,
            category: 'Technology',
            isPromoted: false,
            changeFromYesterday: 'up',
          ),
          TrendingTopic(
            id: '5',
            title: 'Remote Work',
            tweetCount: 4560,
            category: 'Lifestyle',
            isPromoted: false,
            changeFromYesterday: 'down',
          ),
        ];
      } else {
        _trendingTopics = _trendingHashtags;
      }

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trends',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.location_on),
            onSelected: (value) {
              setState(() {
                _selectedLocation = value;
              });
              _loadTrends(); // Reload trends for selected location
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Global', child: Text('Global')),
              const PopupMenuItem(value: 'United States', child: Text('United States')),
              const PopupMenuItem(value: 'United Kingdom', child: Text('United Kingdom')),
              const PopupMenuItem(value: 'Canada', child: Text('Canada')),
              const PopupMenuItem(value: 'Australia', child: Text('Australia')),
              const PopupMenuItem(value: 'India', child: Text('India')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.twitterBlue,
          labelColor: AppTheme.twitterBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Location indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Trends for $_selectedLocation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated ${DateFormat.Hm().format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForYouTab(),
                _buildTrendingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        // Top trends section
        if (_trendingTopics.isNotEmpty) ...[
          _buildSectionHeader('Trending Now', Icons.trending_up),
          ..._trendingTopics.take(5).map((topic) => _buildTrendingTopicTile(topic)),
        ],
      ],
    );
  }

  Widget _buildTrendingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _trendingTopics.length,
      itemBuilder: (context, index) {
        final topic = _trendingTopics[index];
        return _buildTrendingTopicTile(topic, showRank: true, rank: index + 1);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.twitterBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTopicTile(TrendingTopic topic, {bool showRank = false, int? rank}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: showRank && rank != null
            ? Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppTheme.twitterBlue : Colors.grey,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                topic.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (topic.isPromoted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.twitterBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Promoted',
                  style: TextStyle(
                    color: AppTheme.twitterBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.category,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${_formatNumber(topic.tweetCount)} Tweets',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  topic.changeFromYesterday == 'up'
                      ? Icons.trending_up
                      : topic.changeFromYesterday == 'down'
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  size: 14,
                  color: topic.changeFromYesterday == 'up'
                      ? Colors.green
                      : topic.changeFromYesterday == 'down'
                          ? Colors.red
                          : Colors.grey,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleTopicAction(value, topic),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'search', child: Text('Search this topic')),
            const PopupMenuItem(value: 'not_interested', child: Text('Not interested')),
            const PopupMenuItem(value: 'report', child: Text('Report')),
          ],
        ),
        onTap: () => _searchTopic(topic.title),
        isThreeLine: true,
      ),
    );
  }

  void _handleTopicAction(String action, TrendingTopic topic) {
    switch (action) {
      case 'search':
        _searchTopic(topic.title);
        break;
      case 'not_interested':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You won\'t see trends about ${topic.title}')),
        );
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for reporting this trend')),
        );
        break;
    }
  }

  void _searchTopic(String topic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $topic')),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Data Models
class TrendingTopic {
  final String id;
  final String title;
  final int tweetCount;
  final String category;
  final bool isPromoted;
  final String changeFromYesterday; // 'up', 'down', 'stable'

  TrendingTopic({
    required this.id,
    required this.title,
    required this.tweetCount,
    required this.category,
    required this.isPromoted,
    required this.changeFromYesterday,
  });
}