enum NotificationType { like, retweet, reply, follow, mention }

class NotificationModel {
  final String id;
  final String userId;
  final String? tweetId;
  final NotificationType type;
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    this.tweetId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      tweetId: json['tweetId'] != null ? json['tweetId']['_id'] : null,
      type: _parseNotificationType(json['type']),
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      data: json['data'],
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'retweet':
        return NotificationType.retweet;
      case 'reply':
        return NotificationType.reply;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.like;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tweetId': tweetId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }
}
