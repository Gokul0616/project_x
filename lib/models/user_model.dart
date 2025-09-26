import 'package:logging/logging.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? bio;
  final String? profileImage;
  final String? website;
  final String? location;
  final DateTime? birthDate;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.bio,
    this.profileImage,
    this.website,
    this.location,
    this.birthDate,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['_id'] ?? json['id'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        displayName: json['displayName'] ?? '',
        bio: json['bio'],
        profileImage: json['profileImage'],
        website: json['website'],
        location: json['location'],
        birthDate: json['birthDate'] != null
            ? DateTime.parse(json['birthDate'])
            : null,
        followersCount: json['followersCount'] ?? 0,
        followingCount: json['followingCount'] ?? 0,
        isVerified: json['isVerified'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
    } catch (e) {
      Logger('User').severe('Error parsing user from JSON', e);
      // Return a default user if parsing fails
      return User(
        id: json['_id'] ?? json['id'] ?? '',
        username: json['username'] ?? 'unknown',
        email: json['email'] ?? '',
        displayName: json['displayName'] ?? 'Unknown User',
        bio: json['bio'],
        profileImage: json['profileImage'],
        followersCount: 0,
        followingCount: 0,
        isVerified: false,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'profileImage': profileImage,
      'website': website,
      'location': location,
      'birthDate': birthDate?.toIso8601String(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
