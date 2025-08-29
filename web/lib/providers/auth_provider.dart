import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Mock user data
      _user = User(
        id: '1',
        email: email,
        name: 'John Doe',
        phone: '+6281234567890',
        address: 'Jakarta, Indonesia',
        cooperativeId: 'coop-1',
        roles: ['member', 'investor'],
        kycStatus: 'verified',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone, String address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Mock user data
      _user = User(
        id: '1',
        email: email,
        name: name,
        phone: phone,
        address: address,
        cooperativeId: null,
        roles: ['guest'],
        kycStatus: 'pending',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile(User updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
