import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class EnhancedNewTweetsBanner extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onTap;
  final DateTime? lastRefreshTime;

  const EnhancedNewTweetsBanner({
    super.key,
    required this.isVisible,
    required this.onTap,
    this.lastRefreshTime,
  });

  @override
  State<EnhancedNewTweetsBanner> createState() => _EnhancedNewTweetsBannerState();
}

class _EnhancedNewTweetsBannerState extends State<EnhancedNewTweetsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void didUpdateWidget(EnhancedNewTweetsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTimeAgo() {
    if (widget.lastRefreshTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(widget.lastRefreshTime!);
    
    if (difference.inMinutes < 1) {
      return 'Updated just now';
    } else if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Updated ${difference.inHours}h ago';
    } else {
      return 'Updated ${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 60),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(25),
                color: AppTheme.twitterBlue,
                shadowColor: AppTheme.twitterBlue.withOpacity(0.3),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.twitterBlue,
                          AppTheme.twitterBlue.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'See new posts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.lastRefreshTime != null)
                              Text(
                                _getTimeAgo(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: AppTheme.twitterBlue,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}