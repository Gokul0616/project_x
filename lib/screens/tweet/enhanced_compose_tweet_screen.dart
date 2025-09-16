import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math';
import '../../providers/tweet_provider.dart';
import '../../providers/upload_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/mention_suggestions.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/media_grid_widget.dart';
import '../../widgets/upload_progress_modal.dart';

class EnhancedComposeTweetScreen extends StatefulWidget {
  const EnhancedComposeTweetScreen({super.key});

  @override
  State<EnhancedComposeTweetScreen> createState() => _EnhancedComposeTweetScreenState();
}

class _EnhancedComposeTweetScreenState extends State<EnhancedComposeTweetScreen> {
  final _tweetController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<File> _selectedMediaFiles = [];
  List<Map<String, dynamic>> _uploadedMediaFiles = [];

  // Mention functionality
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _tweetController.addListener(() {
      setState(() {});
      _handleTextChange();
    });
    NotificationService.initialize();
  }

  @override
  void dispose() {
    _tweetController.dispose();
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _handleTextChange() {
    final text = _tweetController.text;
    final cursorPosition = _tweetController.selection.baseOffset;

    if (cursorPosition > 0) {
      int atIndex = -1;
      for (int i = cursorPosition - 1; i >= 0; i--) {
        if (text[i] == '@') {
          atIndex = i;
          break;
        } else if (text[i] == ' ' || text[i] == '\n') {
          break;
        }
      }

      if (atIndex != -1) {
        final query = text.substring(atIndex + 1, cursorPosition);
        if (!query.contains(' ') && !query.contains('\n')) {
          setState(() {
            _mentionQuery = query;
            _mentionStartIndex = atIndex;
            _showMentionSuggestions = true;
          });
          _showOverlay();
          return;
        }
      }
    }

    if (_showMentionSuggestions) {
      setState(() {
        _showMentionSuggestions = false;
        _mentionQuery = '';
        _mentionStartIndex = -1;
      });
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 200,
        child: Material(
          color: Colors.transparent,
          child: MentionSuggestions(
            query: _mentionQuery,
            onUserSelected: _onUserSelected,
            onClose: _hideSuggestions,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _hideSuggestions() {
    setState(() {
      _showMentionSuggestions = false;
      _mentionQuery = '';
      _mentionStartIndex = -1;
    });
    _hideOverlay();
  }

  void _onUserSelected(String username, String displayName) {
    final text = _tweetController.text;
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(_tweetController.selection.baseOffset);

    final newText = '$beforeMention@$username $afterMention';
    _tweetController.text = newText;

    final newCursorPosition = beforeMention.length + username.length + 2;
    _tweetController.selection = TextSelection.collapsed(
      offset: newCursorPosition,
    );

    _hideSuggestions();
    _focusNode.requestFocus();
  }

  Future<void> _pickMediaFiles() async {
    try {
      // Request permissions
      await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
        allowedExtensions: null,
      );

      if (result != null) {
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        setState(() {
          // Limit to 10 files total
          final totalFiles = _selectedMediaFiles.length + newFiles.length;
          if (totalFiles <= 10) {
            _selectedMediaFiles.addAll(newFiles);
          } else {
            final availableSlots = 10 - _selectedMediaFiles.length;
            if (availableSlots > 0) {
              _selectedMediaFiles.addAll(newFiles.take(availableSlots));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maximum 10 media files allowed. Added ${availableSlots} files.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking media files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeMediaFile(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
    });
  }

  Future<void> _uploadMediaFiles() async {
    if (_selectedMediaFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final notificationId = Random().nextInt(100000);

    try {
      // Show initial upload notification
      await NotificationService.showUploadProgress(
        id: notificationId,
        title: 'Uploading media files...',
        body: 'Uploading ${_selectedMediaFiles.length} files',
        progress: 0,
        maxProgress: 100,
      );

      // Simulate progress updates
      for (int i = 0; i <= 90; i += 10) {
        setState(() {
          _uploadProgress = i / 100;
        });
        await NotificationService.showUploadProgress(
          id: notificationId,
          title: 'Uploading media files...',
          body: 'Progress: $i%',
          progress: i,
          maxProgress: 100,
        );
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Upload files
      final result = await ApiService.uploadMediaFiles(_selectedMediaFiles);

      if (result['success']) {
        setState(() {
          _uploadedMediaFiles = List<Map<String, dynamic>>.from(result['mediaFiles']);
          _selectedMediaFiles.clear();
          _uploadProgress = 1.0;
        });

        // Show completion progress
        await NotificationService.showUploadProgress(
          id: notificationId,
          title: 'Upload complete!',
          body: 'Media files uploaded successfully',
          progress: 100,
          maxProgress: 100,
        );

        await Future.delayed(const Duration(seconds: 1));
        await NotificationService.cancelNotification(notificationId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media files uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await NotificationService.cancelNotification(notificationId);
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      await NotificationService.cancelNotification(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _postTweet() async {
    if (_tweetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to tweet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uploadProvider = Provider.of<UploadProvider>(context, listen: false);
    final tweetProvider = Provider.of<TweetProvider>(context, listen: false);

    // Start upload process
    uploadProvider.startUpload(
      content: _tweetController.text.trim(),
      mediaFiles: _selectedMediaFiles.map((file) => {
        'url': file.path,
        'type': _getFileType(file.path),
        'isLocal': true,
      }).toList(),
    );

    // Close compose screen immediately
    if (mounted) {
      Navigator.pop(context);
    }

    try {
      // Upload media files first if any are selected
      if (_selectedMediaFiles.isNotEmpty) {
        uploadProvider.updateProgress(0.1, 'Uploading media files...');
        
        // Simulate upload progress
        for (int i = 1; i <= 5; i++) {
          await Future.delayed(const Duration(milliseconds: 300));
          uploadProvider.updateProgress(0.1 + (i * 0.1), 'Uploading media files... ${i * 20}%');
        }

        final mediaResult = await ApiService.uploadMediaFiles(_selectedMediaFiles);
        
        if (!mediaResult['success']) {
          uploadProvider.failUpload(mediaResult['message'] ?? 'Media upload failed');
          return;
        }

        final uploadedFiles = List<Map<String, dynamic>>.from(mediaResult['mediaFiles']);
        uploadProvider.updateProgress(0.7, 'Media files uploaded successfully!');
        
        // Create tweet with media
        uploadProvider.updateProgress(0.8, 'Creating tweet...');
        
        final result = await tweetProvider.createTweet(
          _tweetController.text.trim(),
          mediaFiles: uploadedFiles,
        );

        if (result['success']) {
          await NotificationService.showUploadComplete(
            tweetId: result['tweet'].id,
            title: 'Post uploaded!',
            body: 'Your tweet has been posted successfully. Tap to view.',
          );
          uploadProvider.completeUpload(result['tweet']);
        } else {
          uploadProvider.failUpload(result['message'] ?? 'Failed to create tweet');
        }
      } else {
        // Create tweet without media
        uploadProvider.updateProgress(0.5, 'Creating tweet...');
        
        final result = await tweetProvider.createTweet(_tweetController.text.trim());

        if (result['success']) {
          uploadProvider.updateProgress(0.9, 'Almost done...');
          
          await NotificationService.showUploadComplete(
            tweetId: result['tweet'].id,
            title: 'Post uploaded!',
            body: 'Your tweet has been posted successfully. Tap to view.',
          );
          
          uploadProvider.completeUpload(result['tweet']);
        } else {
          uploadProvider.failUpload(result['message'] ?? 'Failed to create tweet');
        }
      }
    } catch (e) {
      uploadProvider.failUpload('Network error: $e');
    }
  }

  void _removeUploadedMedia(int index) {
    setState(() {
      _uploadedMediaFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Tweet'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: (_isLoading || _isUploading) ? null : _postTweet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.twitterBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: (_isLoading || _isUploading)
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Tweet'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tweet Input
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tweetController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: "What's happening?",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 20,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      style: const TextStyle(fontSize: 20),
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),

                  // Upload Progress Bar
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text(
                          'Uploading media files... ${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.twitterBlue),
                        ),
                      ],
                    ),
                  ],

                  // Selected Media Files Preview
                  if (_selectedMediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MediaGridWidget(
                      mediaFiles: _selectedMediaFiles.map((file) => {
                        'url': file.path,
                        'type': _getFileType(file.path),
                        'isLocal': true,
                      }).toList(),
                      onRemove: _removeMediaFile,
                      showRemoveButton: true,
                    ),
                  ],

                  // Uploaded Media Files Preview
                  if (_uploadedMediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MediaGridWidget(
                      mediaFiles: _uploadedMediaFiles.map((media) => {
                        'url': media['url'],
                        'type': media['type'],
                        'isLocal': false,
                      }).toList(),
                      onRemove: _removeUploadedMedia,
                      showRemoveButton: true,
                    ),
                  ],
                ],
              ),
            ),

            // Media and Actions Row
            Row(
              children: [
                IconButton(
                  onPressed: _isUploading ? null : _pickMediaFiles,
                  icon: Icon(
                    Icons.image_outlined,
                    color: _isUploading ? Colors.grey : AppTheme.twitterBlue,
                  ),
                ),
                IconButton(
                  onPressed: _isUploading ? null : _pickMediaFiles,
                  icon: Icon(
                    Icons.videocam_outlined,
                    color: _isUploading ? Colors.grey : AppTheme.twitterBlue,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GIF search coming soon!')),
                    );
                  },
                  icon: const Icon(
                    Icons.gif_box_outlined,
                    color: AppTheme.twitterBlue,
                  ),
                ),
                const Spacer(),
                if (_selectedMediaFiles.isNotEmpty || _uploadedMediaFiles.isNotEmpty)
                  Text(
                    '${_selectedMediaFiles.length + _uploadedMediaFiles.length}/10',
                    style: TextStyle(
                      color: (_selectedMediaFiles.length + _uploadedMediaFiles.length) > 10
                          ? Colors.red
                          : AppTheme.darkGray,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getFileType(String path) {
    final extension = path.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'].contains(extension)) {
      return 'video';
    }
    return 'unknown';
  }
}