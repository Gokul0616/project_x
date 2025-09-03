import 'package:flutter/material.dart';
import 'package:project_x/shared/services/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/constants/route_constants.dart';

class OnboardingViewModel with ChangeNotifier {
  final PageController pageController = PageController();
  final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
  final int pageCount = AppConstants.onboardingPageCount;
  
  void nextPage() {
    if (currentPage.value < pageCount - 1) {
      pageController.nextPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    }
  }
  
  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    }
  }
  
  void skipToEnd() {
    pageController.animateToPage(
      pageCount - 1,
      duration: AppConstants.animationDurationLong,
      curve: Curves.easeInOut,
    );
  }
  
  void onPageChanged(int page) {
    currentPage.value = page;
    notifyListeners();
  }
  
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
    
    // Navigate to login screen
    NavigationService.navigatorKey.currentState?.pushReplacementNamed(RouteConstants.login);
  }
  
  @override
  void dispose() {
    pageController.dispose();
    currentPage.dispose();
    super.dispose();
  }
}