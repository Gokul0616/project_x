class MediaFile {
  final String url;
  final String type; // 'image' or 'video'
  final String filename;
  final int size;
  final String? thumbnailUrl; // For video thumbnails

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

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
}