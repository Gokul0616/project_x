import '../models/user_model.dart';
import '../models/message_model.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final List<User> participants;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final String? lastMessageId;
  final Message? lastMessage;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // For direct conversations, the other participant
  final User? otherParticipant;
  
  // Computed properties
  final int participantCount;
  final int totalUnreadMessages;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participants,
    required this.isGroup,
    this.groupName,
    this.groupImage,
    this.lastMessageId,
    this.lastMessage,
    required this.lastActivity,
    required this.unreadCount,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.otherParticipant,
    required this.participantCount,
    required this.totalUnreadMessages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List<dynamic>? ?? [])
        .map((participant) => User.fromJson(participant))
        .toList();

    Message? lastMessage;
    if (json['lastMessage'] != null) {
      lastMessage = Message.fromJson(json['lastMessage']);
    }

    User? otherParticipant;
    if (json['otherParticipant'] != null) {
      otherParticipant = User.fromJson(json['otherParticipant']);
    }

    return Conversation(
      id: json['_id'] ?? '',
      participantIds: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => p is String ? p : p['_id'] as String)
          .toList(),
      participants: participants,
      isGroup: json['isGroup'] ?? false,
      groupName: json['groupName'],
      groupImage: json['groupImage'],
      lastMessageId: json['lastMessage'] is String ? json['lastMessage'] : json['lastMessage']?['_id'],
      lastMessage: lastMessage,
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? '') ?? DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      otherParticipant: otherParticipant,
      participantCount: json['participantCount'] ?? participants.length,
      totalUnreadMessages: json['totalUnreadMessages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participantIds,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
      'lastMessage': lastMessageId,
      'lastActivity': lastActivity.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'participantCount': participantCount,
      'totalUnreadMessages': totalUnreadMessages,
    };
  }

  // Helper methods
  bool get hasUnreadMessages => unreadCount > 0;
  bool get isDirectConversation => !isGroup && participants.length == 2;
  
  String get displayName {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    }
    return otherParticipant?.displayName ?? 'Direct Message';
  }

  String get displayImageUrl {
    if (isGroup) {
      return groupImage ?? '';
    }
    return otherParticipant?.profileImage ?? '';
  }

  String get lastMessagePreview {
    if (lastMessage == null) return '';
    
    if (lastMessage!.isMediaMessage) {
      final mediaCount = lastMessage!.mediaFiles.length;
      if (mediaCount == 1) {
        final mediaType = lastMessage!.mediaFiles.first.type;
        return mediaType == 'image' ? '📷 Photo' : '🎥 Video';
      } else {
        return '📎 $mediaCount media files';
      }
    }
    
    return lastMessage!.content;
  }

  String get formattedLastActivity {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      final month = lastActivity.month.toString().padLeft(2, '0');
      final day = lastActivity.day.toString().padLeft(2, '0');
      return '$month/$day';
    }
  }

  // Find other participant in direct conversation
  User? getOtherParticipant(String currentUserId) {
    if (isGroup) return null;
    return participants.firstWhere(
      (participant) => participant.id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : User(
        id: '', 
        username: 'unknown', 
        displayName: 'Unknown User', 
        email: '', 
        followersCount: 0, 
        followingCount: 0, 
        createdAt: DateTime.now(), 
        profileImage: null,
        bio: null,
      ),
    );
  }

  // Create a copy with updated properties
  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    List<User>? participants,
    bool? isGroup,
    String? groupName,
    String? groupImage,
    String? lastMessageId,
    Message? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? otherParticipant,
    int? participantCount,
    int? totalUnreadMessages,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherParticipant: otherParticipant ?? this.otherParticipant,
      participantCount: participantCount ?? this.participantCount,
      totalUnreadMessages: totalUnreadMessages ?? this.totalUnreadMessages,
    );
  }
}