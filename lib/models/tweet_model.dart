import 'user_model.dart';
import 'media_file_model.dart';

class Tweet {
  final String id;
  final String content;
  final User author;
  final DateTime createdAt;
  final int likesCount;
  final int retweetsCount;
  final int repliesCount;
  final bool isLiked;
  final bool isRetweeted;
  final String? imageUrl; // Keep for backward compatibility
  final List<MediaFile> mediaFiles; // New multiple media support
  final String? parentTweetId;
  final Tweet? parentTweet;

  Tweet({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.likesCount = 0,
    this.retweetsCount = 0,
    this.repliesCount = 0,
    this.isLiked = false,
    this.isRetweeted = false,
    this.imageUrl,
    this.mediaFiles = const [],
    this.parentTweetId,
    this.parentTweet,
  });

  factory Tweet.fromJson(Map<String, dynamic> json) {
    try {
      return Tweet(
        id: json['_id'] ?? json['id'] ?? '',
        content: json['content'] ?? '',
        author: json['author'] != null 
            ? User.fromJson(json['author']) 
            : User(
                id: '',
                username: 'unknown',
                email: '',
                displayName: 'Unknown User',
                createdAt: DateTime.now(),
              ),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
        likesCount: json['likesCount'] ?? 0,
        retweetsCount: json['retweetsCount'] ?? 0,
        repliesCount: json['repliesCount'] ?? 0,
        isLiked: json['isLiked'] ?? false,
        isRetweeted: json['isRetweeted'] ?? false,
        imageUrl: json['imageUrl'],
        mediaFiles: json['mediaFiles'] != null 
            ? (json['mediaFiles'] as List).map((media) => MediaFile.fromJson(media)).toList()
            : [],
        parentTweetId: json['parentTweet'] is String ? json['parentTweet'] : null,
        parentTweet: json['parentTweet'] is Map<String, dynamic> ? Tweet.fromJson(json['parentTweet']) : null,
      );
    } catch (e) {
      print('Error parsing tweet from JSON: $e');
      // Return a default tweet if parsing fails
      return Tweet(
        id: json['_id'] ?? json['id'] ?? '',
        content: json['content'] ?? 'Unable to load content',
        author: User(
          id: '',
          username: 'unknown',
          email: '',
          displayName: 'Unknown User',
          createdAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        likesCount: 0,
        retweetsCount: 0,
        repliesCount: 0,
        isLiked: false,
        isRetweeted: false,
        imageUrl: json['imageUrl'],
        mediaFiles: [],
        parentTweetId: json['parentTweet'] is String ? json['parentTweet'] : null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'retweetsCount': retweetsCount,
      'repliesCount': repliesCount,
      'isLiked': isLiked,
      'isRetweeted': isRetweeted,
      'imageUrl': imageUrl,
      'mediaFiles': mediaFiles.map((media) => media.toJson()).toList(),
      'parentTweetId': parentTweetId,
      'parentTweet': parentTweet?.toJson(),
    };
  }
}