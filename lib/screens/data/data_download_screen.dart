import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class DataDownloadScreen extends StatefulWidget {
  const DataDownloadScreen({super.key});

  @override
  State<DataDownloadScreen> createState() => _DataDownloadScreenState();
}

class _DataDownloadScreenState extends State<DataDownloadScreen> {
  bool _isRequesting = false;
  String? _lastRequestDate;

  @override
  void initState() {
    super.initState();
    _loadLastRequestDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Your Data'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildDataTypesSection(),
          const SizedBox(height: 24),
          _buildRequestSection(),
          const SizedBox(height: 24),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Data Download Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You can request a copy of your Pulse data, including your tweets, profile information, and account activity. This process may take up to 24 hours to complete.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your data will be provided in JSON format and will be available for download for 7 days.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Included',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDataTypeItem(
          icon: Icons.article_outlined,
          title: 'Tweets and Replies',
          description: 'All your tweets, replies, and retweets',
        ),
        _buildDataTypeItem(
          icon: Icons.person_outline,
          title: 'Profile Information',
          description: 'Your display name, bio, and profile settings',
        ),
        _buildDataTypeItem(
          icon: Icons.favorite_outline,
          title: 'Likes and Bookmarks',
          description: 'Tweets you\'ve liked and bookmarked',
        ),
        _buildDataTypeItem(
          icon: Icons.people_outline,
          title: 'Following and Followers',
          description: 'Lists of accounts you follow and that follow you',
        ),
        _buildDataTypeItem(
          icon: Icons.message_outlined,
          title: 'Direct Messages',
          description: 'Your direct message conversations',
        ),
        _buildDataTypeItem(
          icon: Icons.settings_outlined,
          title: 'Account Settings',
          description: 'Your privacy and notification settings',
        ),
      ],
    );
  }

  Widget _buildDataTypeItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.twitterBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Your Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ready to download your data?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll prepare your data and send you a notification when it\'s ready for download.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestDataDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.twitterBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Request Data Download',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Download History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _lastRequestDate != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Request: $_lastRequestDate',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: Completed',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No download requests yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _requestDataDownload() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      // TODO: Implement data download request API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      setState(() {
        _lastRequestDate = DateTime.now().toString().split(' ')[0];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data download request submitted successfully! You\'ll receive a notification when it\'s ready.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request data download: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  void _loadLastRequestDate() {
    // TODO: Load last request date from local storage or API
    // For now, we'll leave it as null
  }
}