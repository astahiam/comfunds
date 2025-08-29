import 'package:flutter/material.dart';

class InvestmentProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _investments = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get investments => _investments;

  Future<void> fetchInvestments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));
      _investments = [];
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
