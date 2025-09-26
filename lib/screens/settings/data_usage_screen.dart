import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  bool _autoplayVideos = false;
  bool _highQualityImages = true;
  bool _highQualityVideos = false;
  bool _preloadContent = true;
  bool _syncOnMobileData = false;
  bool _downloadMedia = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data usage'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Data Usage Overview
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.data_usage,
                      color: AppTheme.twitterBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Data usage overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Control how Pulse uses your network data. Lower quality settings help reduce data usage.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Media Quality Settings
          _buildSectionHeader('Media Quality'),
          _buildSwitchItem(
            title: 'High quality images',
            subtitle: 'Load images in high quality when connected to Wi-Fi',
            value: _highQualityImages,
            onChanged: (value) => setState(() => _highQualityImages = value),
          ),
          _buildSwitchItem(
            title: 'High quality videos',
            subtitle: 'Load videos in high quality (uses more data)',
            value: _highQualityVideos,
            onChanged: (value) => setState(() => _highQualityVideos = value),
          ),
          _buildSwitchItem(
            title: 'Autoplay videos',
            subtitle: 'Automatically play videos in timeline',
            value: _autoplayVideos,
            onChanged: (value) => setState(() => _autoplayVideos = value),
          ),

          // Data Usage Settings
          _buildSectionHeader('Data Usage'),
          _buildSwitchItem(
            title: 'Preload content',
            subtitle: 'Download content in advance for faster loading',
            value: _preloadContent,
            onChanged: (value) => setState(() => _preloadContent = value),
          ),
          _buildSwitchItem(
            title: 'Sync on mobile data',
            subtitle: 'Allow syncing when not connected to Wi-Fi',
            value: _syncOnMobileData,
            onChanged: (value) => setState(() => _syncOnMobileData = value),
          ),
          _buildSwitchItem(
            title: 'Download media automatically',
            subtitle: 'Automatically download images and videos',
            value: _downloadMedia,
            onChanged: (value) => setState(() => _downloadMedia = value),
          ),

          // Storage Management
          _buildSectionHeader('Storage'),
          _buildActionItem(
            title: 'Clear cache',
            subtitle: 'Free up storage space by clearing cached data',
            icon: Icons.cleaning_services,
            onTap: () => _showClearCacheDialog(),
          ),
          _buildActionItem(
            title: 'Storage usage',
            subtitle: 'View how much storage Pulse is using',
            icon: Icons.storage,
            onTap: () => _showStorageUsage(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.twitterBlue,
        ),
        onTap: () => onChanged(!value),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildActionItem({
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
        leading: Icon(
          icon,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text(
          'This will clear all cached images, videos, and other temporary files. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showStorageUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStorageItem('Images', '45.2 MB'),
            _buildStorageItem('Videos', '23.1 MB'),
            _buildStorageItem('Cache', '12.8 MB'),
            _buildStorageItem('Other', '5.3 MB'),
            const Divider(),
            _buildStorageItem('Total', '86.4 MB', isTotal: true),
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

  Widget _buildStorageItem(String label, String size, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            size,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.twitterBlue : null,
            ),
          ),
        ],
      ),
    );
  }
}
