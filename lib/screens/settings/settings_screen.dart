import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';
import '../debug/notification_debug_screen.dart';
import 'account_settings_screen.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'blocked_accounts_screen.dart';
import '../data/data_download_screen.dart';
import 'language_settings_screen.dart';
import 'accessibility_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings and privacy'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'Your account'),
          _buildSettingItem(
            context,
            icon: Icons.person_outline,
            title: 'Account information',
            subtitle: 'See your account information like your phone number and email address.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.security,
            title: 'Change your password',
            subtitle: 'Change your password at any time.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.download,
            title: 'Download an archive of your data',
            subtitle: 'Get insights into the type of information stored for your account.',
            onTap: () {
              // TODO: Navigate to data download
              _showComingSoon(context);
            },
          ),
          
          // Privacy and Safety Section
          _buildSectionHeader(context, 'Privacy and safety'),
          _buildSettingItem(
            context,
            icon: Icons.security_outlined,
            title: 'Privacy and safety',
            subtitle: 'Manage what information you see and share on Pulse.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Select the kinds of notifications you get about your activities and recommendations.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.block,
            title: 'Blocked accounts',
            subtitle: 'Manage the accounts that you\'ve blocked.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedAccountsScreen(),
                ),
              );
            },
          ),
          
          // General Section
          _buildSectionHeader(context, 'General'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSettingItem(
                context,
                icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                title: 'Display',
                subtitle: 'Manage your font size, color, and background.',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      themeProvider.isDarkMode ? 'Dark' : 'Light',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: AppTheme.twitterBlue,
                    ),
                  ],
                ),
                onTap: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.language,
            title: 'Languages',
            subtitle: 'Manage which languages are used to personalize your Pulse experience.',
            onTap: () {
              // TODO: Navigate to language settings
              _showComingSoon(context);
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.data_usage,
            title: 'Data usage',
            subtitle: 'Limit how Pulse uses some of your network data.',
            onTap: () {
              // TODO: Navigate to data usage settings
              _showComingSoon(context);
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.accessibility,
            title: 'Accessibility',
            subtitle: 'Manage aspects of your Pulse experience such as limiting color contrast and motion.',
            onTap: () {
              // TODO: Navigate to accessibility settings
              _showComingSoon(context);
            },
          ),
          
          // Support Section
          _buildSectionHeader(context, 'Support'),
          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Find answers to your questions and get support.',
            onTap: () {
              // TODO: Navigate to help center
              _showComingSoon(context);
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Learn more about Pulse app.',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          
          // Debug Section (for testing)
          _buildSectionHeader(context, 'Debug'),
          _buildSettingItem(
            context,
            icon: Icons.bug_report,
            title: 'Notification Debug',
            subtitle: 'Debug notification system issues.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationDebugScreen(),
                ),
              );
            },
          ),
          
          // Logout Section
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () {
                _showLogoutDialog(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.headlineMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
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
        leading: Icon(
          icon,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: AppTheme.twitterBlue,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.twitterBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.twitter,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About Pulse'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pulse - A Twitter-like Social Media App'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('Built with Flutter and powered by passion for connecting people through meaningful conversations.'),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of Pulse?'),
        content: const Text('You can always log back in at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings screen
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}