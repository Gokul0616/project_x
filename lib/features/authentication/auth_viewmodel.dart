import 'package:flutter/foundation.dart';
import 'package:project_x/shared/services/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/constants/route_constants.dart';

class AuthViewModel with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setErrorMessage('');
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Validate credentials
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please enter both email and password');
      }
      
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      // Save auth token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, 'simulated_token_$email');
      await prefs.setString(AppConstants.userIdKey, 'user_${email.split('@')[0]}');
      
      // Navigate to home
      NavigationService.navigatorKey.currentState?.pushReplacementNamed(RouteConstants.home);
    } catch (error) {
      _setErrorMessage(error.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signup(String email, String password, String username) async {
    _setLoading(true);
    _setErrorMessage('');
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Validate input
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        throw Exception('Please fill all fields');
      }
      
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      if (username.length < 3) {
        throw Exception('Username must be at least 3 characters');
      }
      
      // Save auth token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, 'simulated_token_$email');
      await prefs.setString(AppConstants.userIdKey, 'user_$username');
      
      // Navigate to home
      NavigationService.navigatorKey.currentState?.pushReplacementNamed(RouteConstants.home);
    } catch (error) {
      _setErrorMessage(error.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    _setErrorMessage('');
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Validate email
      if (email.isEmpty) {
        throw Exception('Please enter your email address');
      }
      
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      
      // Show success message
      _setErrorMessage('Password reset instructions sent to $email');
      
      // Navigate back to login after a delay
      await Future.delayed(const Duration(seconds: 2));
      NavigationService.navigatorKey.currentState?.pop();
    } catch (error) {
      _setErrorMessage(error.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    
    NavigationService.navigatorKey.currentState?.pushReplacementNamed(RouteConstants.login);
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setErrorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }
  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.authTokenKey) != null;
  }
}