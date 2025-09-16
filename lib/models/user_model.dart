class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? bio;
  final String? profileImage;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.bio,
    this.profileImage,
    this.followersCount = 0,
    this.followingCount = 0,
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
        followersCount: json['followersCount'] ?? 0,
        followingCount: json['followingCount'] ?? 0,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing user from JSON: $e');
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
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}