import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../screens/media/full_screen_media_viewer.dart';
import '../utils/app_theme.dart';
import '../config/api_config.dart';

class MediaGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> mediaFiles;
  final Function(int)? onRemove;
  final bool showRemoveButton;
  final bool enableTap;
  final double? maxPreviewSize;

  const MediaGridWidget({
    super.key,
    required this.mediaFiles,
    this.onRemove,
    this.showRemoveButton = false,
    this.enableTap = true,
    this.maxPreviewSize,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaFiles.isEmpty) return const SizedBox.shrink();

    return _buildMediaGrid(context);
  }

  Widget _buildMediaGrid(BuildContext context) {
    final itemCount = mediaFiles.length > 4 ? 4 : mediaFiles.length;

    if (itemCount == 1) {
      return _buildSingleMedia(context, 0);
    } else if (itemCount == 2) {
      return Row(
        children: [
          Expanded(child: _buildMediaItem(context, 0)),
          const SizedBox(width: 4),
          Expanded(child: _buildMediaItem(context, 1)),
        ],
      );
    } else if (itemCount == 3) {
      return Column(
        children: [
          _buildMediaItem(context, 0),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildMediaItem(context, 1)),
              const SizedBox(width: 4),
              Expanded(child: _buildMediaItem(context, 2)),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMediaItem(context, 0)),
              const SizedBox(width: 4),
              Expanded(child: _buildMediaItem(context, 1)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildMediaItem(context, 2)),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMediaItem(
                  context,
                  3,
                  showOverlay: mediaFiles.length > 4,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSingleMedia(BuildContext context, int index) {
    return Container(
      height: 200,
      width: double.infinity,
      child: _buildMediaItem(context, index),
    );
  }

  Widget _buildMediaItem(
    BuildContext context,
    int index, {
    bool showOverlay = false,
  }) {
    final media = mediaFiles[index];
    final isLocal = media['isLocal'] ?? false;
    final isVideo = media['type'] == 'video';

    return GestureDetector(
      onTap: enableTap ? () => _openFullScreen(context, index) : null,
      child: Container(
        height: mediaFiles.length == 1 ? 200 : 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: Stack(
          children: [
            // Media content
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isLocal
                  ? _buildLocalMedia(media['url'], isVideo)
                  : _buildNetworkMedia(media['url'], isVideo),
            ),

            // Video play icon
            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

            // Overlay for additional items (+X)
            if (showOverlay)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black54,
                ),
                child: Center(
                  child: Text(
                    '+${mediaFiles.length - 4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Remove button
            if (showRemoveButton && onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => onRemove!(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalMedia(String path, bool isVideo) {
    if (isVideo) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam, color: Colors.white, size: 32),
        ),
      );
    } else {
      return Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    }
  }

  Widget _buildNetworkMedia(String url, bool isVideo) {
    final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    if (isVideo) {
      // First check if there's a thumbnailUrl for this video
      final media = mediaFiles.where((m) => m['url'] == url).first;
      final thumbnailUrl = media['thumbnailUrl'];

      if (thumbnailUrl != null) {
        final fullThumbnailUrl = thumbnailUrl.startsWith('http')
            ? thumbnailUrl
            : '${ApiConfig.baseUrl}$thumbnailUrl';
        return CachedNetworkImage(
          imageUrl: fullThumbnailUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white, size: 32),
              ),
            );
          },
        );
      } else {
        // Fallback to video icon if no thumbnail
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.videocam, color: Colors.white, size: 32),
          ),
        );
      }
    } else {
      return CachedNetworkImage(
        imageUrl: fullUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    }
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMediaViewer(
          mediaFiles: mediaFiles,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
