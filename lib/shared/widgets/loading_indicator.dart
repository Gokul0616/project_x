import 'package:flutter/material.dart';
import 'package:project_x/core/theme/color_palette.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;
  
  const LoadingIndicator({
    super.key,
    this.size = 24,
    this.color = AppColors.blue,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}