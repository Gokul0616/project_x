class MediaFile {
  final String url;
  final String type; // 'image', 'video', 'gif'
  final String filename;
  final int size;
  final String? thumbnailUrl;

  MediaFile({
    required this.url,
    required this.type,
    required this.filename,
    required this.size,
    this.thumbnailUrl,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'filename': filename,
      'size': size,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime createdAt;
  final String? username;
  final String? displayName;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.username,
    this.displayName,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return MessageReaction(
      userId: user is String ? user : user['_id'] ?? '',
      emoji: json['emoji'] ?? '❤️',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      username: user is Map ? user['username'] : null,
      displayName: user is Map ? user['displayName'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content;
  final String messageType; // 'text', 'media', 'system'
  final List<MediaFile> mediaFiles;
  final bool isRead;
  final bool isDeleted;
  final String? replyToId;
  final List<MessageReaction> reactions;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // User data
  final String? senderUsername;
  final String? senderDisplayName;
  final String? senderProfileImage;
  final bool? senderIsVerified;
  
  final String? recipientUsername;
  final String? recipientDisplayName;
  final String? recipientProfileImage;
  final bool? recipientIsVerified;

  // Computed properties
  final int reactionsCount;
  final bool isReadByRecipient;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.messageType,
    required this.mediaFiles,
    required this.isRead,
    required this.isDeleted,
    required this.reactions,
    required this.createdAt,
    required this.updatedAt,
    this.replyToId,
    this.senderUsername,
    this.senderDisplayName,
    this.senderProfileImage,
    this.senderIsVerified,
    this.recipientUsername,
    this.recipientDisplayName,
    this.recipientProfileImage,
    this.recipientIsVerified,
    required this.reactionsCount,
    required this.isReadByRecipient,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final recipient = json['recipient'];
    
    return Message(
      id: json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: sender is String ? sender : sender?['_id'] ?? '',
      recipientId: recipient is String ? recipient : recipient?['_id'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      mediaFiles: (json['mediaFiles'] as List<dynamic>? ?? [])
          .map((media) => MediaFile.fromJson(media))
          .toList(),
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      replyToId: json['replyTo'] is String ? json['replyTo'] : json['replyTo']?['_id'],
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((reaction) => MessageReaction.fromJson(reaction))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      
      // Sender data
      senderUsername: sender is Map ? sender['username'] : null,
      senderDisplayName: sender is Map ? sender['displayName'] : null,
      senderProfileImage: sender is Map ? sender['profileImage'] : null,
      senderIsVerified: sender is Map ? sender['isVerified'] : null,
      
      // Recipient data
      recipientUsername: recipient is Map ? recipient['username'] : null,
      recipientDisplayName: recipient is Map ? recipient['displayName'] : null,
      recipientProfileImage: recipient is Map ? recipient['profileImage'] : null,
      recipientIsVerified: recipient is Map ? recipient['isVerified'] : null,
      
      // Computed properties
      reactionsCount: json['reactionsCount'] ?? 0,
      isReadByRecipient: json['isReadByRecipient'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversationId': conversationId,
      'sender': senderId,
      'recipient': recipientId,
      'content': content,
      'messageType': messageType,
      'mediaFiles': mediaFiles.map((media) => media.toJson()).toList(),
      'isRead': isRead,
      'isDeleted': isDeleted,
      'replyTo': replyToId,
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reactionsCount': reactionsCount,
      'isReadByRecipient': isReadByRecipient,
    };
  }

  // Helper methods
  bool get hasMedia => mediaFiles.isNotEmpty;
  bool get isTextMessage => messageType == 'text';
  bool get isMediaMessage => messageType == 'media';
  bool get isSystemMessage => messageType == 'system';
  bool get hasReactions => reactions.isNotEmpty;
  
  String get displaySenderName => senderDisplayName ?? senderUsername ?? 'Unknown User';
  String get displayRecipientName => recipientDisplayName ?? recipientUsername ?? 'Unknown User';

  // Check if current user has reacted with specific emoji
  bool hasUserReaction(String userId, String emoji) {
    return reactions.any((reaction) => 
      reaction.userId == userId && reaction.emoji == emoji
    );
  }

  // Get reaction count for specific emoji
  int getReactionCount(String emoji) {
    return reactions.where((reaction) => reaction.emoji == emoji).length;
  }

  // Group reactions by emoji
  Map<String, List<MessageReaction>> get groupedReactions {
    final Map<String, List<MessageReaction>> grouped = {};
    for (final reaction in reactions) {
      if (!grouped.containsKey(reaction.emoji)) {
        grouped[reaction.emoji] = [];
      }
      grouped[reaction.emoji]!.add(reaction);
    }
    return grouped;
  }

  // Create a copy with updated properties
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? recipientId,
    String? content,
    String? messageType,
    List<MediaFile>? mediaFiles,
    bool? isRead,
    bool? isDeleted,
    String? replyToId,
    List<MessageReaction>? reactions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderUsername,
    String? senderDisplayName,
    String? senderProfileImage,
    bool? senderIsVerified,
    String? recipientUsername,
    String? recipientDisplayName,
    String? recipientProfileImage,
    bool? recipientIsVerified,
    int? reactionsCount,
    bool? isReadByRecipient,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId ?? this.replyToId,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderUsername: senderUsername ?? this.senderUsername,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      senderIsVerified: senderIsVerified ?? this.senderIsVerified,
      recipientUsername: recipientUsername ?? this.recipientUsername,
      recipientDisplayName: recipientDisplayName ?? this.recipientDisplayName,
      recipientProfileImage: recipientProfileImage ?? this.recipientProfileImage,
      recipientIsVerified: recipientIsVerified ?? this.recipientIsVerified,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      isReadByRecipient: isReadByRecipient ?? this.isReadByRecipient,
    );
  }
}