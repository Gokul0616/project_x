import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && !JwtDecoder.isExpired(token)) {
        // Get user data from backend
        final result = await ApiService.getCurrentUser();
        if (result['success'] == true) {
          _user = result['user'];
          _isAuthenticated = true;
        } else {
          // Invalid token, remove it 
          await prefs.remove('token');
          _isAuthenticated = false;
          _user = null;
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      print('Error checking auth status: $e');
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);
      
      if (result['success'] == true) {
        _user = result['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String displayName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.register(username, email, password, displayName);
      
      if (result['success'] == true) {
        _user = result['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    try {
      final result = await ApiService.getCurrentUser(); 
      if (result['success'] == true) {
        _user = result['user'];
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
}