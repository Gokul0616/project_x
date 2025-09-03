import 'package:flutter/material.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/theme/text_styles.dart';
import 'package:project_x/core/utils/responsive_utils.dart';

class OnboardingPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  
  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with responsive sizing
          Expanded(
            flex: ResponsiveUtils.isDesktop(context) ? 2 : 1,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingXL),
          
          // Text content
          Text(
            title,
            style: TextStyles.displayLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.paddingM),
          
          Text(
            description,
            style: TextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}