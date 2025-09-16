import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification System Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testApiCall,
                  child: const Text('Test API Call'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _refreshNotifications,
                  child: const Text('Refresh Notifications'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearDebugInfo,
                  child: const Text('Clear Log'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Provider status
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provider Status:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Loading: ${provider.isLoading}'),
                        Text('Error: ${provider.error ?? 'None'}'),
                        Text('Notification count: ${provider.notifications.length}'),
                        Text('Unread count: ${provider.unreadCount}'),
                        if (provider.notifications.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Latest notification:'),
                          Text('  Type: ${provider.notifications.first.type}'),
                          Text('  Title: ${provider.notifications.first.title}'),
                          Text('  Read: ${provider.notifications.first.isRead}'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Debug log
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Log:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _debugInfo.isEmpty ? 'No debug info yet' : _debugInfo,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDebugInfo(String info) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _debugInfo += '[$timestamp] $info\n';
    });
  }

  void _clearDebugInfo() {
    setState(() {
      _debugInfo = '';
    });
  }

  Future<void> _testApiCall() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugInfo('Testing direct API call...');

    try {
      // Test the API call directly
      final notifications = await ApiService.getNotifications();
      _addDebugInfo('API call successful!');
      _addDebugInfo('Received ${notifications.length} notifications');
      
      for (int i = 0; i < notifications.length && i < 3; i++) {
        final notif = notifications[i];
        _addDebugInfo('  $i: ${notif.type} - ${notif.title}');
      }
      
      if (notifications.isEmpty) {
        _addDebugInfo('No notifications found - this might be normal if no interactions occurred');
      }
      
    } catch (e) {
      _addDebugInfo('API call failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugInfo('Refreshing notifications via provider...');

    try {
      await Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      _addDebugInfo('Provider refresh completed');
    } catch (e) {
      _addDebugInfo('Provider refresh failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }
}