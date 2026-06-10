import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  /// 🔐 LOGIN CONECTADO A NODE.JS
  Future<User?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners(); // Avisamos a la UI que está cargando

    final loggedUser = await _authService.login(email, password);
    
    if (loggedUser != null) {
      _user = loggedUser;
    }
    
    _isLoading = false;
    notifyListeners(); // Avisamos a la UI que terminó de cargar
    return loggedUser;
  }

  /// 📝 REGISTER CONECTADO A NODE.JS
  Future<bool> register(User newUser) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authService.register(newUser);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}