import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/upload_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/media_grid_widget.dart';

class UploadProgressModal extends StatefulWidget {
  const UploadProgressModal({super.key});

  @override
  State<UploadProgressModal> createState() => _UploadProgressModalState();
}

class _UploadProgressModalState extends State<UploadProgressModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(
                                uploadProvider.isUploading
                                    ? Icons.cloud_upload
                                    : uploadProvider.uploadedTweet != null
                                        ? Icons.check_circle
                                        : Icons.error,
                                color: uploadProvider.isUploading
                                    ? AppTheme.twitterBlue
                                    : uploadProvider.uploadedTweet != null
                                        ? Colors.green
                                        : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  uploadProvider.isUploading
                                      ? 'Uploading Tweet'
                                      : uploadProvider.uploadedTweet != null
                                          ? 'Upload Complete!'
                                          : 'Upload Failed',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!uploadProvider.isUploading)
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    uploadProvider.clearUpload();
                                  },
                                  icon: const Icon(Icons.close),
                                  iconSize: 20,
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Progress indicator
                          if (uploadProvider.isUploading) ...[
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: uploadProvider.uploadProgress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.twitterBlue,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                                Text(
                                  '${(uploadProvider.uploadProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.twitterBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Status text
                          Text(
                            uploadProvider.uploadStatus,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Media preview for uploading files
                          if (uploadProvider.uploadingMediaFiles.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: MediaGridWidget(
                                mediaFiles: uploadProvider.uploadingMediaFiles,
                                showRemoveButton: false,
                                maxPreviewSize: 80,
                              ),
                            ),
                          ],
                          
                          // Tweet preview if completed
                          if (uploadProvider.uploadedTweet != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    uploadProvider.uploadedTweet!.content,
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (uploadProvider.uploadedTweet!.mediaFiles?.isNotEmpty == true) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${uploadProvider.uploadedTweet!.mediaFiles!.length} media file(s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  uploadProvider.clearUpload();
                                  // Navigate to tweet detail or home
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/main',
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.twitterBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('View Tweet'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}