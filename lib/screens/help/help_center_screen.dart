import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HelpTopic> _filteredTopics = [];
  List<HelpTopic> _allTopics = [];

  @override
  void initState() {
    super.initState();
    _loadHelpTopics();
  }

  void _loadHelpTopics() {
    _allTopics = [
      HelpTopic(
        id: '1',
        title: 'Getting Started',
        description: 'Learn the basics of using the app',
        icon: Icons.play_circle_outline,
        category: 'Basics',
        articleCount: 3,
      ),
      HelpTopic(
        id: '2',
        title: 'Privacy & Safety',
        description: 'Protect your account and control your experience',
        icon: Icons.security,
        category: 'Security',
        articleCount: 5,
      ),
      HelpTopic(
        id: '3',
        title: 'Features & Tools',
        description: 'Make the most of all available features',
        icon: Icons.build_outlined,
        category: 'Features',
        articleCount: 7,
      ),
      HelpTopic(
        id: '4',
        title: 'Troubleshooting',
        description: 'Solutions to common problems',
        icon: Icons.help_outline,
        category: 'Support',
        articleCount: 4,
      ),
      HelpTopic(
        id: '5',
        title: 'Account Management',
        description: 'Manage your profile and account settings',
        icon: Icons.person_outline,
        category: 'Account',
        articleCount: 6,
      ),
    ];

    setState(() {
      _filteredTopics = _allTopics;
    });
  }

  void _filterTopics(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTopics = _allTopics;
      } else {
        _filteredTopics = _allTopics.where((topic) {
          return topic.title.toLowerCase().contains(query.toLowerCase()) ||
              topic.description.toLowerCase().contains(query.toLowerCase()) ||
              topic.category.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_support),
            onPressed: _showContactSupport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search help topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterTopics('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Colors.grey[800],
              ),
              onChanged: _filterTopics,
            ),
          ),
          // Quick Actions
          if (_searchController.text.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _showContactSupport,
                    child: const Text('Contact Support'),
                  ),
                ],
              ),
            ),
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickActionCard(
                    'Report Issue',
                    Icons.report_problem,
                    () => _showReportIssue(),
                  ),
                  _buildQuickActionCard(
                    'Feature Request',
                    Icons.lightbulb_outline,
                    () => _showFeatureRequest(),
                  ),
                  _buildQuickActionCard(
                    'Account Help',
                    Icons.person_outline,
                    () => _showTopicDetail(_allTopics[4]),
                  ),
                  _buildQuickActionCard(
                    'Privacy Guide',
                    Icons.security,
                    () => _showTopicDetail(_allTopics[1]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Help Topics
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTopics.length,
              itemBuilder: (context, index) {
                final topic = _filteredTopics[index];
                return _buildTopicCard(topic);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.twitterBlue),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(HelpTopic topic) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.twitterBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(topic.icon, color: AppTheme.twitterBlue),
        ),
        title: Text(
          topic.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic.description),
            const SizedBox(height: 4),
            Text(
              '${topic.articleCount} articles • ${topic.category}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showTopicDetail(topic),
        isThreeLine: true,
      ),
    );
  }

  void _showTopicDetail(HelpTopic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(topic.icon, color: AppTheme.twitterBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(topic.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic.description),
            const SizedBox(height: 16),
            Text('Category: ${topic.category}'),
            Text('Articles: ${topic.articleCount}'),
            const SizedBox(height: 16),
            const Text(
              'This help topic contains detailed articles about:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...List.generate(topic.articleCount, (index) => 
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• Article ${index + 1}: How to use ${topic.title.toLowerCase()}'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${topic.title} articles')),
              );
            },
            child: const Text('View Articles'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@pulseapp.com'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email client...')),
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.twitter),
              title: const Text('Twitter Support'),
              subtitle: const Text('@PulseSupport'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Twitter...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9 AM - 5 PM PST'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting live chat...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Issue Summary',
                hintText: 'Briefly describe the problem',
              ),
              maxLength: 100,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Details',
                hintText: 'Provide more details about the issue',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue reported successfully!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request a Feature'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Feature Title',
                hintText: 'What feature would you like?',
              ),
              maxLength: 100,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe how this feature would work',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature request submitted!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class HelpTopic {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final int articleCount;

  HelpTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.articleCount,
  });
}