import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnectionError = false;
  
  // --- NUEVAS VARIABLES PARA EL FLUJO DE VERIFICACIÓN ---
  bool _isPendingVerification = false;
  String? _pendingEmail;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isConnectionError => _isConnectionError;
  
  // --- NUEVOS GETTERS ---
  bool get isPendingVerification => _isPendingVerification;
  String? get pendingEmail => _pendingEmail;
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    _isPendingVerification = false; // Reiniciamos el estado
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
      // VERIFICAMOS SI EL BACKEND NOS DICE QUE FALTA ACTIVAR LA CUENTA
      if (result['status'] == 'pending_verification') {
        _isPendingVerification = true;
        _pendingEmail = result['email'] ?? email;
      }
      
      _errorMessage = result['error'] ?? result['message'];
      _isConnectionError = result['isConnectionError'] == true;
      notifyListeners();
      return false; // Retornamos falso porque no entró, pero la UI sabrá que está pendiente
    }
  }

  // --- NUEVO MÉTODO: REGISTRO ---
  Future<bool> register(String nombre, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    _isPendingVerification = false;
    notifyListeners();

    final result = await _authRepository.register(nombre, email, password);

    _isLoading = false;

    // Si el registro fue exitoso y el estado es pendiente
    if (result['success'] == true || result['status'] == 'pending_verification') {
      _isPendingVerification = true;
      _pendingEmail = email;
      _errorMessage = null; 
      notifyListeners();
      return true; 
    } else {
      _errorMessage = result['error'] ?? result['message'] ?? 'Error desconocido';
      _isConnectionError = result['isConnectionError'] == true;
      notifyListeners();
      return false;
    }
  }

  // VERIFICAR CÓDIGO
  Future<bool> verifyCode(String email, String codigo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.verifyCode(email, codigo);

    _isLoading = false;

    if (result['success'] == true) {
      // El backend nos devuelve el usuario y token tras verificar con éxito
      _user = result['user']; 
      _isPendingVerification = false;
      _pendingEmail = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] ?? result['message'] ?? 'Código inválido';
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _errorMessage = null;
    _isConnectionError = false;
    _isPendingVerification = false;
    _pendingEmail = null;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
  }
}