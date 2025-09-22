import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../config/api_config.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final List<Map<String, dynamic>> mediaFiles;
  final int initialIndex;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaFiles,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;
  Map<int, VideoPlayerController?> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Set full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize video controllers for video files
    _initializeVideoControllers();

    // Auto-play initial video if applicable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playCurrentVideo();
    });
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose video controllers
    _videoControllers.values.forEach((controller) {
      controller?.dispose();
    });

    _pageController.dispose();
    super.dispose();
  }

  void _initializeVideoControllers() {
    for (int i = 0; i < widget.mediaFiles.length; i++) {
      final media = widget.mediaFiles[i];
      if (media['type'] == 'video') {
        final isLocal = media['isLocal'] ?? false;
        String url;

        if (isLocal) {
          url = media['url'];
        } else {
          final videoUrl = media['url'];
          url = videoUrl.startsWith('http')
              ? videoUrl
              : '${ApiConfig.baseUrl}${videoUrl}';
        }

        if (isLocal) {
          _videoControllers[i] = VideoPlayerController.file(File(url));
        } else {
          _videoControllers[i] = VideoPlayerController.network(
            url,
            httpHeaders: {'User-Agent': 'TwitterCloneApp'},
          );
        }

        _videoControllers[i]
            ?.initialize()
            .then((_) {
              // Set looping for Twitter-like behavior
              _videoControllers[i]?.setLooping(true);
              if (mounted) setState(() {});
            })
            .catchError((error) {
              print(
                'Error initializing video controller for index $i: $error',
              ); // Debug log
            });
      }
    }
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Pause all videos
    _videoControllers.values.forEach((controller) {
      controller?.pause();
    });

    // Auto-play the new current video if applicable
    _playCurrentVideo();
  }

  void _playCurrentVideo() {
    final currentMedia = widget.mediaFiles[_currentIndex];
    if (currentMedia['type'] == 'video') {
      final controller = _videoControllers[_currentIndex];
      if (controller != null && controller.value.isInitialized) {
        controller.play();
      }
    }
  }

  String _getMediaUrl(Map<String, dynamic> media) {
    final isLocal = media['isLocal'] ?? false;
    final url = media['url'];

    if (isLocal) {
      return url;
    } else {
      return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            // Media Gallery
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.mediaFiles.length,
              onPageChanged: _onPageChanged,
              builder: (context, index) {
                final media = widget.mediaFiles[index];
                final isVideo = media['type'] == 'video';

                if (isVideo) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: _buildVideoPlayer(index),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                } else {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: _getImageProvider(media),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: 'media_$index',
                    ),
                  );
                }
              },
            ),

            // Overlay with controls
            if (_showOverlay) ...[
              // Top overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      if (widget.mediaFiles.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.mediaFiles.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Implement download/share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download/Share coming soon!'),
                              backgroundColor: AppTheme.twitterBlue,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom overlay with media indicators
              if (widget.mediaFiles.length > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      top: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.mediaFiles.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(controller),
            // Video controls overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: controller.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Video progress bar
            if (_showOverlay)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppTheme.twitterBlue,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(Map<String, dynamic> media) {
    final isLocal = media['isLocal'] ?? false;
    final url = _getMediaUrl(media);

    if (isLocal) {
      return FileImage(File(url));
    } else {
      return CachedNetworkImageProvider(url);
    }
  }
}
