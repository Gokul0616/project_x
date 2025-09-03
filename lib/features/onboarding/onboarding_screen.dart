import 'package:flutter/material.dart';
import 'package:project_x/core/constants/asset_constants.dart';
import 'package:provider/provider.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/constants/route_constants.dart';
import 'package:project_x/core/utils/responsive_utils.dart';
import 'package:project_x/features/onboarding/onboarding_viewmodel.dart';
import 'package:project_x/features/onboarding/widgets/onboarding_page.dart';
import 'package:project_x/features/onboarding/widgets/page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: _buildResponsiveLayout(context),
        ),
      ),
    );
  }
  
  Widget _buildResponsiveLayout(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewModel, child) {
        if (ResponsiveUtils.isDesktop(context)) {
          return _buildDesktopLayout(context, viewModel);
        } else if (ResponsiveUtils.isTablet(context)) {
          return _buildTabletLayout(context, viewModel);
        } else {
          return _buildMobileLayout(context, viewModel);
        }
      },
    );
  }
  
  Widget _buildMobileLayout(BuildContext context, OnboardingViewModel viewModel) {
    return Column(
      children: [
        // Page view area
        Expanded(
          flex: 3,
          child: PageView(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onPageChanged,
            children: const [
              OnboardingPage(
                imagePath: AssetConstants.onboarding1,
                title: 'See what\'s happening',
                description: 'Follow your interests and stay updated on what matters to you.',
              ),
              OnboardingPage(
                imagePath: AssetConstants.onboarding2,
                title: 'Join the conversation',
                description: 'Be part of the discussion and connect with people who share your interests.',
              ),
              OnboardingPage(
                imagePath: AssetConstants.onboarding3,
                title: 'Discover more',
                description: 'Explore trending topics and find communities that inspire you.',
              ),
            ],
          ),
        ),
        
        // Indicators and buttons
        _buildControlsSection(context, viewModel),
      ],
    );
  }
  
  Widget _buildDesktopLayout(BuildContext context, OnboardingViewModel viewModel) {
    return Row(
      children: [
        // Left side with content
        Expanded(
          child: PageView(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onPageChanged,
            children: const [
              OnboardingPage(
                imagePath: AssetConstants.onboarding1,
                title: 'See what\'s happening',
                description: 'Follow your interests and stay updated on what matters to you.',
              ),
              OnboardingPage(
                imagePath: AssetConstants.onboarding2,
                title: 'Join the conversation',
                description: 'Be part of the discussion and connect with people who share your interests.',
              ),
              OnboardingPage(
                imagePath: AssetConstants.onboarding3,
                title: 'Discover more',
                description: 'Explore trending topics and find communities that inspire you.',
              ),
            ],
          ),
        ),
        
        // Right side with controls
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          child: _buildControlsSection(context, viewModel),
        ),
      ],
    );
  }
  
  Widget _buildTabletLayout(BuildContext context, OnboardingViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onPageChanged,
            children: const [
              OnboardingPage(
                imagePath: AssetConstants.onboarding1,
                title: 'See what\'s happening',
                description: 'Follow your interests and stay updated on what matters to you.',
              ),
              OnboardingPage(
                imagePath: AssetConstants.onboarding2,
                title: 'Join the conversation',
                description: 'Be part of the discussion and connect with people who share your interests.',
              ),
              OnboardingPage(
                imagePath: AssetConstants.onboarding3,
                title: 'Discover more',
                description: 'Explore trending topics and find communities that inspire you.',
              ),
            ],
          ),
        ),
        _buildControlsSection(context, viewModel),
      ],
    );
  }
  
  Widget _buildControlsSection(BuildContext context, OnboardingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          PageIndicator(
            pageCount: viewModel.pageCount,
            currentPage: viewModel.currentPage.value,
          ),
          
          const SizedBox(height: AppConstants.paddingXL),
          
          // Action buttons
          ValueListenableBuilder<int>(
            valueListenable: viewModel.currentPage,
            builder: (context, currentPage, child) {
              if (currentPage < viewModel.pageCount - 1) {
                return Row(
                  children: [
                    // Skip button
                    TextButton(
                      onPressed: viewModel.skipToEnd,
                      child: const Text('Skip'),
                    ),
                    
                    const Spacer(),
                    
                    // Next button
                    ElevatedButton(
                      onPressed: viewModel.nextPage,
                      child: const Text('Next'),
                    ),
                  ],
                );
              } else {
                // Get started button on the last page
                return ElevatedButton(
                  onPressed: () async {
                    await viewModel.completeOnboarding();
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, RouteConstants.login);
                  },
                  child: const Text('Get Started'),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}