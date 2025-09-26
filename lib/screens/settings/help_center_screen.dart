import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Search Help
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for help...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Browse our help topics or search for specific questions',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Popular Topics
          _buildSectionHeader(context, 'Popular Topics'),
          _buildHelpItem(
            context: context,
            title: 'Getting Started',
            subtitle: 'Learn the basics of using Pulse',
            icon: Icons.play_circle_outline,
            onTap: () => _showTopicDetails(context, 'Getting Started'),
          ),
          _buildHelpItem(
            context: context,
            title: 'Privacy and Safety',
            subtitle: 'Manage your privacy settings and stay safe',
            icon: Icons.security,
            onTap: () => _showTopicDetails(context, 'Privacy and Safety'),
          ),
          _buildHelpItem(
            context: context,
            title: 'Account Settings',
            subtitle: 'Manage your account and preferences',
            icon: Icons.settings,
            onTap: () => _showTopicDetails(context, 'Account Settings'),
          ),
          _buildHelpItem(
            context: context,
            title: 'Troubleshooting',
            subtitle: 'Fix common issues and problems',
            icon: Icons.build,
            onTap: () => _showTopicDetails(context, 'Troubleshooting'),
          ),

          // Account & Support
          _buildSectionHeader(context, 'Account & Support'),
          _buildHelpItem(
            context: context,
            title: 'Contact Support',
            subtitle: 'Get help from our support team',
            icon: Icons.support,
            onTap: () => _showContactSupport(context),
          ),
          _buildHelpItem(
            context: context,
            title: 'Report a Problem',
            subtitle: 'Let us know about bugs or issues',
            icon: Icons.bug_report,
            onTap: () => _showReportProblem(context),
          ),
          _buildHelpItem(
            context: context,
            title: 'Community Guidelines',
            subtitle: 'Learn about our community standards',
            icon: Icons.people,
            onTap: () => _showCommunityGuidelines(context),
          ),

          // Legal & Policies
          _buildSectionHeader(context, 'Legal & Policies'),
          _buildHelpItem(
            context: context,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            icon: Icons.description,
            onTap: () => _showTermsOfService(context),
          ),
          _buildHelpItem(
            context: context,
            title: 'Privacy Policy',
            subtitle: 'Learn how we protect your data',
            icon: Icons.privacy_tip,
            onTap: () => _showPrivacyPolicy(context),
          ),
          _buildHelpItem(
            context: context,
            title: 'Cookie Policy',
            subtitle: 'Information about cookies and tracking',
            icon: Icons.cookie,
            onTap: () => _showCookiePolicy(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.twitterBlue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showTopicDetails(BuildContext context, String topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scrollController) =>
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        topic,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: _getTopicContent(topic),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  List<Widget> _getTopicContent(String topic) {
    switch (topic) {
      case 'Getting Started':
        return [
          _buildContentSection(
            'Welcome to Pulse!',
            'Pulse is a social media platform that connects you with friends, family, and communities around the world.',
          ),
          _buildContentSection(
            'Creating Your Profile',
            'Set up your profile by adding a profile picture, bio, and personal information to help others find and connect with you.',
          ),
          _buildContentSection(
            'Posting Content',
            'Share your thoughts, photos, and videos with your followers. Use hashtags to make your posts discoverable.',
          ),
          _buildContentSection(
            'Interacting with Others',
            'Like, retweet, and reply to posts from people you follow. Build meaningful connections through conversations.',
          ),
        ];
      case 'Privacy and Safety':
        return [
          _buildContentSection(
            'Account Privacy',
            'Control who can see your posts, profile information, and contact you through privacy settings.',
          ),
          _buildContentSection(
            'Blocking Users',
            'Block users who you don\'t want to interact with. Blocked users cannot see your profile or contact you.',
          ),
          _buildContentSection(
            'Reporting Content',
            'Report inappropriate content or behavior to help keep Pulse safe for everyone.',
          ),
        ];
      case 'Account Settings':
        return [
          _buildContentSection(
            'Profile Settings',
            'Edit your profile information, change your username, and manage your account details.',
          ),
          _buildContentSection(
            'Notification Settings',
            'Choose what notifications you want to receive and how you want to be notified.',
          ),
          _buildContentSection(
            'Security Settings',
            'Manage your password, two-factor authentication, and other security features.',
          ),
        ];
      case 'Troubleshooting':
        return [
          _buildContentSection(
            'App Not Loading',
            'Try restarting the app, clearing cache, or checking your internet connection.',
          ),
          _buildContentSection(
            'Can\'t Post Content',
            'Check your internet connection and make sure you have the necessary permissions.',
          ),
          _buildContentSection(
            'Notifications Not Working',
            'Check your notification settings and make sure notifications are enabled in your device settings.',
          ),
        ];
      default:
        return [
          _buildContentSection(
            'Help',
            'For more help, please contact our support team.',
          ),
        ];
    }
  }

  Widget _buildContentSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How can we help you today?'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showEmailSupport(context),
              icon: const Icon(Icons.email),
              label: const Text('Email Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.twitterBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showHelpWebsite(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Visit Help Website'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportProblem(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Report a Problem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the problem you\'re experiencing:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your report!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.twitterBlue,
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunityGuidelines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Community Guidelines',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildGuidelineItem(
                    'Be Respectful',
                    'Treat others with kindness and respect. Harassment, bullying, and hate speech are not tolerated.',
                  ),
                  _buildGuidelineItem(
                    'Share Authentically',
                    'Post content that is genuine and original. Avoid spreading misinformation or spam.',
                  ),
                  _buildGuidelineItem(
                    'Protect Privacy',
                    'Respect others\' privacy and do not share personal information without consent.',
                  ),
                  _buildGuidelineItem(
                    'Follow the Law',
                    'Do not post content that is illegal, promotes violence, or violates intellectual property rights.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'These Terms of Service govern your use of Pulse. By using our service, you agree to these terms...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'We respect your privacy and are committed to protecting your personal information...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCookiePolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Cookie Policy',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'This policy explains how we use cookies and similar technologies...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailSupport(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email support@pulse-app.com for assistance'),
        backgroundColor: AppTheme.twitterBlue,
      ),
    );
  }

  void _showHelpWebsite(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit our help website for more information'),
        backgroundColor: AppTheme.twitterBlue,
      ),
    );
  }
}
