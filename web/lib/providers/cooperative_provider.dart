import 'package:flutter/material.dart';

class CooperativeProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _cooperatives = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get cooperatives => _cooperatives;

  Future<void> fetchCooperatives() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      _cooperatives = [];
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
