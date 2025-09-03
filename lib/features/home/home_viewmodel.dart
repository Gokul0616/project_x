// lib/features/home/home_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:project_x/core/constants/route_constants.dart';
import 'package:project_x/shared/services/navigation_service.dart';

class HomeViewModel with ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void navigateTo(int index) {
    _currentIndex = index;

    switch (index) {
      case 0:
        NavigationService.navigateTo(RouteConstants.home);
        break;
      case 1:
        NavigationService.navigateTo(RouteConstants.search);
        break;
      case 2:
        NavigationService.navigateTo(RouteConstants.notifications);
        break;
      case 3:
        NavigationService.navigateTo(RouteConstants.messages);
        break;
      default:
        NavigationService.navigateTo(RouteConstants.home);
    }

    notifyListeners();
  }
}
