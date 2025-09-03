import 'package:flutter/material.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/theme/color_palette.dart';

class PageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final double dotSize;
  final double activeDotWidth;
  final double activeDotHeight;
  final Color activeColor;
  final Color inactiveColor;

  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.dotSize = 8.0,
    this.activeDotWidth = 16.0,
    this.activeDotHeight = 8.0,
    this.activeColor = AppColors.blue,
    this.inactiveColor = AppColors.midGray,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: AppConstants.animationDurationShort,
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingXS,
          ),
          width: isActive ? activeDotWidth : dotSize,
          height: isActive ? activeDotHeight : dotSize,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(dotSize),
          ),
        );
      }),
    );
  }
}
