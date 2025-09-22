import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/upload_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/twitter_upload_modal.dart';

class UploadProgressFAB extends StatefulWidget {
  final VoidCallback onCompose;

  const UploadProgressFAB({
    super.key,
    required this.onCompose,
  });

  @override
  State<UploadProgressFAB> createState() => _UploadProgressFABState();
}

class _UploadProgressFABState extends State<UploadProgressFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showUploadModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TwitterUploadModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, child) {
        // Show progress when uploading or just completed
        final shouldShowProgress = uploadProvider.isUploading || 
            (uploadProvider.uploadedTweet != null && uploadProvider.uploadProgress > 0);

        if (shouldShowProgress != _showProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _showProgress = shouldShowProgress;
            });
            
            if (_showProgress) {
              _pulseController.repeat(reverse: true);
            } else {
              _pulseController.stop();
              _pulseController.reset();
            }
          });
        }

        if (_showProgress) {
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final isCompleted = uploadProvider.uploadedTweet != null;
              final isFailed = !uploadProvider.isUploading && uploadProvider.uploadedTweet == null && uploadProvider.uploadStatus.isNotEmpty;
              
              return Transform.scale(
                scale: uploadProvider.isUploading ? _pulseAnimation.value : 1.0,
                child: FloatingActionButton(
                  onPressed: _showUploadModal,
                  backgroundColor: isFailed 
                      ? Colors.red 
                      : isCompleted 
                          ? Colors.green 
                          : AppTheme.twitterBlue,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (uploadProvider.isUploading) ...[
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            value: uploadProvider.uploadProgress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        ),
                        Text(
                          '${(uploadProvider.uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (isCompleted) ...[
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ] else if (isFailed) ...[
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }

        return FloatingActionButton(
          onPressed: widget.onCompose,
          backgroundColor: AppTheme.twitterBlue,
          child: const FaIcon(
            FontAwesomeIcons.feather,
            color: Colors.white,
          ),
        );
      },
    );
  }
}