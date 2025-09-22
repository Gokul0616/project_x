import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isAccountPrivate = false;
  bool _allowDirectMessages = true;
  bool _showOnlineStatus = true;
  bool _allowTagging = true;
  bool _allowLocationTracking = false;
  bool _shareAnalytics = false;
  bool _allowPersonalization = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Safety'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Account Privacy'),
        _buildSwitchTile(
          title: 'Private Account',
          subtitle: 'Only followers can see your tweets',
          value: _isAccountPrivate,
          onChanged: (value) {
            setState(() {
              _isAccountPrivate = value;
            });
          },
        ),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Direct Messages'),
        _buildSwitchTile(
          title: 'Allow Direct Messages',
          subtitle: 'Anyone can send you direct messages',
          value: _allowDirectMessages,
          onChanged: (value) {
            setState(() {
              _allowDirectMessages = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Show Online Status',
          subtitle: 'Show when you\'re active on the app',
          value: _showOnlineStatus,
          onChanged: (value) {
            setState(() {
              _showOnlineStatus = value;
            });
          },
        ),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Discoverability'),
        _buildSwitchTile(
          title: 'Allow Tagging',
          subtitle: 'Others can tag you in their tweets',
          value: _allowTagging,
          onChanged: (value) {
            setState(() {
              _allowTagging = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Location Tracking',
          subtitle: 'Allow location information in tweets',
          value: _allowLocationTracking,
          onChanged: (value) {
            setState(() {
              _allowLocationTracking = value;
            });
          },
        ),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Data and Analytics'),
        _buildSwitchTile(
          title: 'Share Analytics Data',
          subtitle: 'Help improve the app with usage analytics',
          value: _shareAnalytics,
          onChanged: (value) {
            setState(() {
              _shareAnalytics = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Allow Personalization',
          subtitle: 'Personalize content based on your activity',
          value: _allowPersonalization,
          onChanged: (value) {
            setState(() {
              _allowPersonalization = value;
            });
          },
        ),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Blocked and Muted'),
        _buildActionTile(
          title: 'Blocked Accounts',
          subtitle: 'Manage blocked users',
          icon: Icons.block,
          onTap: () {
            // TODO: Navigate to blocked accounts screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blocked accounts screen not implemented yet')),
            );
          },
        ),
        _buildActionTile(
          title: 'Muted Accounts',
          subtitle: 'Manage muted users',
          icon: Icons.volume_off,
          onTap: () {
            // TODO: Navigate to muted accounts screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Muted accounts screen not implemented yet')),
            );
          },
        ),
        _buildActionTile(
          title: 'Muted Words',
          subtitle: 'Words and phrases you won\'t see',
          icon: Icons.speaker_notes_off,
          onTap: () {
            // TODO: Navigate to muted words screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Muted words screen not implemented yet')),
            );
          },
        ),
        const SizedBox(height: 32),
        
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.twitterBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        leading: Icon(icon, color: AppTheme.twitterBlue),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _savePrivacySettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.twitterBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Save Privacy Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _savePrivacySettings() async {
    try {
      // TODO: Implement API call to save privacy settings
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}