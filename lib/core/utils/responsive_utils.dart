import 'package:flutter/material.dart';
import 'package:project_x/core/constants/app_constants.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint && 
           width < AppConstants.tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint;
  }
  
  static T responsiveValue<T>(BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }
  
  static double responsivePadding(BuildContext context) {
    return responsiveValue<double>(
      context,
      mobile: AppConstants.paddingM,
      tablet: AppConstants.paddingL,
      desktop: AppConstants.paddingXL,
    );
  }
  
  static double responsiveFontSize(BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  static EdgeInsets responsivePaddingAll(BuildContext context, {
    double multiplier = 1.0,
  }) {
    final basePadding = responsivePadding(context);
    return EdgeInsets.all(basePadding * multiplier);
  }
  
  static EdgeInsets responsivePaddingHorizontal(BuildContext context, {
    double multiplier = 1.0,
  }) {
    final basePadding = responsivePadding(context);
    return EdgeInsets.symmetric(horizontal: basePadding * multiplier);
  }
  
  static EdgeInsets responsivePaddingVertical(BuildContext context, {
    double multiplier = 1.0,
  }) {
    final basePadding = responsivePadding(context);
    return EdgeInsets.symmetric(vertical: basePadding * multiplier);
  }
  
  static double responsiveIconSize(BuildContext context, {
    double mobile = 24,
    double tablet = 28,
    double desktop = 32,
  }) {
    return responsiveValue<double>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}