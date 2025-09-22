import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/notification_model.dart';
import '../../widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeTab = 'All'; // All, Mentions

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Notifications'),
      //   automaticallyImplyLeading: false,
      //   actions: [
      //     Consumer<NotificationProvider>(
      //       builder: (context, notificationProvider, child) {
      //         return IconButton(
      //           icon: const Icon(Icons.settings_outlined),
      //           onPressed: () {
      //             // TODO: Navigate to notification settings
      //           },
      //         );
      //       },
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          // Notification Tabs
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                'All',
                'Mentions',
              ].map((tab) => _buildTabItem(tab)).toList(),
            ),
          ),

          // Notifications List
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                if (notificationProvider.isLoading &&
                    notificationProvider.notifications.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.twitterBlue,
                      ),
                    ),
                  );
                }

                if (notificationProvider.error != null &&
                    notificationProvider.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notificationProvider.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredNotifications = _getFilteredNotifications(
                  notificationProvider.notifications,
                );

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When someone likes, retweets, or mentions you, you\'ll see it here',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  color: AppTheme.twitterBlue,
                  child: ListView.builder(
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return NotificationCard(
                        notification: filteredNotifications[index],
                        onTap: () => _handleNotificationTap(
                          filteredNotifications[index],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String tab) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.twitterBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              tab,
              style: TextStyle(
                color: isActive
                    ? AppTheme.twitterBlue
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<NotificationModel> _getFilteredNotifications(
    List<NotificationModel> notifications,
  ) {
    if (_activeTab == 'Mentions') {
      return notifications
          .where((n) => n.type == NotificationType.mention)
          .toList();
    }
    return notifications;
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).markAsRead(notification.id);
    }

    // Navigate to relevant screen based on notification type
    if (notification.tweetId != null) {
      // TODO: Navigate to tweet detail screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to tweet - Coming soon!')),
      );
    }
  }
}
