import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        // Verify token with backend
        final userData = await _apiService.getCurrentUser(_token!);
        if (userData != null) {
          _user = User.fromJson(userData);
          _isAuthenticated = true;
        } else {
          await _clearAuthData();
        }
      }
    } catch (e) {
      debugPrint('Error loading auth data: $e');
      await _clearAuthData();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.login(email, password);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        _token = data['access_token'];
        _user = User.fromJson(data['user']);
        _isAuthenticated = true;

        // Save token to persistent storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String name,
    required String password,
    required String phone,
    required String address,
    List<String> roles = const ['guest'],
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.register(
        email: email,
        name: name,
        password: password,
        phone: phone,
        address: address,
        roles: roles,
      );
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        _token = data['access_token'];
        _user = User.fromJson(data['user']);
        _isAuthenticated = true;

        // Save token to persistent storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _clearAuthData();
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    _user = null;
    _token = null;
    _isAuthenticated = false;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
