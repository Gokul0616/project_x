import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Push Notifications
  bool _pushNotificationsEnabled = true;
  bool _likesNotifications = true;
  bool _retweetsNotifications = true;
  bool _repliesNotifications = true;
  bool _mentionsNotifications = true;
  bool _followsNotifications = true;
  bool _directMessagesNotifications = true;
  
  // Email Notifications
  bool _emailNotificationsEnabled = false;
  bool _emailDigest = false;
  bool _emailMentions = false;
  bool _emailDirectMessages = false;
  
  // Sound & Vibration
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedSound = 'Default';
  
  final List<String> _availableSounds = [
    'Default',
    'Gentle',
    'Tweet',
    'Pop',
    'Ding',
    'None',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
        _buildSectionHeader('Push Notifications'),
        _buildMasterSwitch(
          title: 'Push Notifications',
          subtitle: 'Receive notifications on this device',
          value: _pushNotificationsEnabled,
          onChanged: (value) {
            setState(() {
              _pushNotificationsEnabled = value;
            });
          },
        ),
        if (_pushNotificationsEnabled) ...[
          const SizedBox(height: 16),
          _buildSubSectionHeader('Interaction Notifications'),
          _buildSwitchTile(
            title: 'Likes',
            subtitle: 'When someone likes your tweet',
            value: _likesNotifications,
            onChanged: (value) {
              setState(() {
                _likesNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Retweets',
            subtitle: 'When someone retweets your tweet',
            value: _retweetsNotifications,
            onChanged: (value) {
              setState(() {
                _retweetsNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Replies',
            subtitle: 'When someone replies to your tweet',
            value: _repliesNotifications,
            onChanged: (value) {
              setState(() {
                _repliesNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Mentions',
            subtitle: 'When someone mentions you',
            value: _mentionsNotifications,
            onChanged: (value) {
              setState(() {
                _mentionsNotifications = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildSubSectionHeader('Social Notifications'),
          _buildSwitchTile(
            title: 'New Followers',
            subtitle: 'When someone follows you',
            value: _followsNotifications,
            onChanged: (value) {
              setState(() {
                _followsNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Direct Messages',
            subtitle: 'When you receive a direct message',
            value: _directMessagesNotifications,
            onChanged: (value) {
              setState(() {
                _directMessagesNotifications = value;
              });
            },
          ),
        ],
        
        const SizedBox(height: 24),
        _buildSectionHeader('Email Notifications'),
        _buildMasterSwitch(
          title: 'Email Notifications',
          subtitle: 'Receive notifications via email',
          value: _emailNotificationsEnabled,
          onChanged: (value) {
            setState(() {
              _emailNotificationsEnabled = value;
            });
          },
        ),
        if (_emailNotificationsEnabled) ...[
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Daily Digest',
            subtitle: 'Daily summary of your activity',
            value: _emailDigest,
            onChanged: (value) {
              setState(() {
                _emailDigest = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Mentions',
            subtitle: 'When someone mentions you',
            value: _emailMentions,
            onChanged: (value) {
              setState(() {
                _emailMentions = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Direct Messages',
            subtitle: 'When you receive important messages',
            value: _emailDirectMessages,
            onChanged: (value) {
              setState(() {
                _emailDirectMessages = value;
              });
            },
          ),
        ],
        
        const SizedBox(height: 24),
        _buildSectionHeader('Sound & Vibration'),
        _buildSwitchTile(
          title: 'Sound',
          subtitle: 'Play sound for notifications',
          value: _soundEnabled,
          onChanged: (value) {
            setState(() {
              _soundEnabled = value;
            });
          },
        ),
        if (_soundEnabled) ...[
          _buildSoundSelector(),
        ],
        _buildSwitchTile(
          title: 'Vibration',
          subtitle: 'Vibrate for notifications',
          value: _vibrationEnabled,
          onChanged: (value) {
            setState(() {
              _vibrationEnabled = value;
            });
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

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildMasterSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.twitterBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.twitterBlue.withOpacity(0.3)),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.twitterBlue,
        contentPadding: EdgeInsets.zero,
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

  Widget _buildSoundSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Sound',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSound,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _availableSounds.map((sound) {
              return DropdownMenuItem(
                value: sound,
                child: Text(sound),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSound = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveNotificationSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.twitterBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Save Notification Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveNotificationSettings() async {
    try {
      // TODO: Implement API call to save notification settings
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved successfully'),
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