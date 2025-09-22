import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Moment> _moments = [];
  List<Moment> _featuredMoments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreAll = true;
  bool _hasMoreFeatured = true;
  int _allPage = 1;
  int _featuredPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMoments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMoments() async {
    await _loadFeaturedMoments(refresh: true);
    await _loadAllMoments(refresh: true);
  }

  Future<void> _loadFeaturedMoments({bool refresh = false}) async {
    if (refresh) {
      _featuredPage = 1;
      _hasMoreFeatured = true;
      _featuredMoments.clear();
    }

    if (!_hasMoreFeatured && !refresh) return;

    setState(() {
      _isLoading = refresh;
      _isLoadingMore = !refresh && _featuredMoments.isNotEmpty;
    });

    try {
      final moments = await ApiService.getMoments(
        type: 'featured',
        page: _featuredPage,
        limit: 20,
      );

      if (moments.isEmpty) {
        _hasMoreFeatured = false;
      } else {
        final newMoments = moments.map((moment) => Moment.fromJson(moment)).toList();
        if (refresh) {
          _featuredMoments = newMoments;
        } else {
          _featuredMoments.addAll(newMoments);
        }
        _featuredPage++;
      }

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading featured moments: $e')),
      );
    }
  }

  Future<void> _loadAllMoments({bool refresh = false}) async {
    if (refresh) {
      _allPage = 1;
      _hasMoreAll = true;
      _moments.clear();
    }

    if (!_hasMoreAll && !refresh) return;

    try {
      final moments = await ApiService.getMoments(
        type: 'all',
        page: _allPage,
        limit: 20,
      );

      if (moments.isEmpty) {
        _hasMoreAll = false;
      } else {
        final newMoments = moments.map((moment) => Moment.fromJson(moment)).toList();
        if (refresh) {
          _moments = newMoments;
        } else {
          _moments.addAll(newMoments);
        }
        _allPage++;
      }

      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading moments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Moments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search moments feature')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.twitterBlue,
          labelColor: AppTheme.twitterBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'All Moments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMomentsTab(_featuredMoments, isFeatured: true, onLoadMore: () => _loadFeaturedMoments()),
          _buildMomentsTab(_moments, isFeatured: false, onLoadMore: () => _loadAllMoments()),
        ],
      ),
    );
  }

  Widget _buildMomentsTab(List<Moment> moments, {required bool isFeatured, VoidCallback? onLoadMore}) {
    if (_isLoading && moments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (moments.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flash_on_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFeatured ? 'No featured moments' : 'No moments available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Moments will appear here when there are trending topics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => isFeatured ? await _loadFeaturedMoments(refresh: true) : await _loadAllMoments(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: moments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == moments.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final moment = moments[index];
          return _buildMomentCard(moment, isFeatured: isFeatured);
        },
      ),
    );
  }

  Widget _buildMomentCard(Moment moment, {required bool isFeatured}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isFeatured ? 8 : 2,
      child: InkWell(
        onTap: () => _viewMoment(moment),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image or Placeholder
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                color: AppTheme.twitterBlue.withOpacity(0.1),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.flash_on,
                      size: 60,
                      color: AppTheme.twitterBlue.withOpacity(0.5),
                    ),
                  ),
                  // Live indicator
                  if (moment.isLive)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Featured badge
                  if (isFeatured)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.twitterBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and timestamp
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.twitterBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          moment.category,
                          style: TextStyle(
                            color: AppTheme.twitterBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatRelativeTime(moment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    moment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    moment.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Stats
                  Row(
                    children: [
                      Icon(Icons.message, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatNumber(moment.tweetCount)} tweets',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatNumber(moment.participantCount)} people',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewMoment(Moment moment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(moment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(moment.description),
            const SizedBox(height: 16),
            Text('${moment.tweetCount} tweets • ${moment.participantCount} people'),
            Text('Category: ${moment.category}'),
            if (moment.isLive) 
              const Text('🔴 LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final momentData = await ApiService.getMoment(moment.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing ${moment.title} moment')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading moment: $e')),
                );
              }
            },
            child: const Text('View Moment'),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
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
class Moment {
  final String id;
  final String title;
  final String description;
  final int tweetCount;
  final int participantCount;
  final DateTime createdAt;
  final String category;
  final bool isLive;

  Moment({
    required this.id,
    required this.title,
    required this.description,
    required this.tweetCount,
    required this.participantCount,
    required this.createdAt,
    required this.category,
    required this.isLive,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      tweetCount: json['tweetCount'] ?? 0,
      participantCount: json['participantCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'] ?? 'Other',
      isLive: json['isLive'] ?? false,
    );
  }
}