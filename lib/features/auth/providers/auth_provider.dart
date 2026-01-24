import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';


class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnectionError = false;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isConnectionError => _isConnectionError;
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
    
    final result = await _authRepository.login(email, password);
    
    _isLoading = false;
    
    if (result['success'] == true) {
      _user = result['user'];
      _errorMessage = null;
      _isConnectionError = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'];
      _isConnectionError = result['isConnectionError'] == true;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
  }
}