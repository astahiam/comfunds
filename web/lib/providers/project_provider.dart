import 'package:flutter/material.dart';

class ProjectProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _projects = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get projects => _projects;

  Future<void> fetchProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      _projects = [];
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
}
