import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeviceUtils {
  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMobile => isAndroid || isIOS;

  static bool get isDesktop => isMacOS || isWindows || isLinux;

  // Change these to regular methods instead of getters
  static double statusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double bottomBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // Hide the keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Check if the keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // Set preferred device orientations
  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations(orientations);
  }

  // Set the status bar color with appropriate icon brightness
  static Future<void> setStatusBarColor(Color color) async {
    if (isAndroid || isIOS) {
      // Adjust system UI overlays for Android/iOS
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: color,
          statusBarIconBrightness: color.computeLuminance() > 0.5
              ? Brightness.dark
              : Brightness.light,
        ),
      );
    } else if (isWeb) {
      // Handle status bar for web if needed (e.g., change meta tags, etc.)
      // Currently, no direct API in Flutter to change the web status bar
    }
  }

  // Ensure the status bar is hidden (ideal for intro screens or splash screens)
  static Future<void> hideStatusBar() async {
    if (isAndroid || isIOS) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [],
      );
    }
  }

  // Restore the status bar visibility after intro screen
  static Future<void> restoreStatusBar() async {
    if (isAndroid || isIOS) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }
}
