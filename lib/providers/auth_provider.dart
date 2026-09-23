import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

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

  /// 🔄 Recargar los datos del usuario desde la base de datos (Sincronización Web -> Móvil)
  Future<void> reloadUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = _user?.id;
    if (userId == null || userId == 0) {
      userId = prefs.getInt('user_id');
    }
    if (userId == null || userId == 0) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userService = UserService();
      final updatedUser = await userService.getUserById(userId);
      if (updatedUser != null) {
        final localSavedAvatar = prefs.getString('user_avatar_$userId');
        if ((updatedUser.avatarUrl == null || updatedUser.avatarUrl!.isEmpty) && localSavedAvatar != null && localSavedAvatar.isNotEmpty) {
          _user = User(
            id: updatedUser.id,
            name: updatedUser.name,
            email: updatedUser.email,
            password: updatedUser.password,
            role: updatedUser.role,
            avatarUrl: localSavedAvatar,
            document: updatedUser.document,
            documentType: updatedUser.documentType,
            phone: updatedUser.phone,
            address: updatedUser.address,
            state: updatedUser.state,
            roleId: updatedUser.roleId,
          );
        } else {
          _user = updatedUser;
        }
      }
    } catch (e) {
      print('Error al recargar el usuario en AuthProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📤 Subir y actualizar la foto de perfil en el backend (Sincronización Móvil -> Web)
  Future<bool> uploadProfileImage(String filePath) async {
    if (_user == null || _user!.id == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final extension = filePath.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';

      // ✅ Actualizar UI localmente de inmediato (optimistic update)
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        password: _user!.password,
        role: _user!.role,
        avatarUrl: base64Image,
        document: _user!.document,
        documentType: _user!.documentType,
        phone: _user!.phone,
        address: _user!.address,
        state: _user!.state,
        roleId: _user!.roleId,
      );
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_${_user!.id}', base64Image);

      final userService = UserService();
      final success = await userService.updateProfileImage(_user!.id!, base64Image, _user!);

      if (success) {
        // Recargamos el usuario para obtener la URL final asignada por el backend
        final updatedUser = await userService.getUserById(_user!.id!);
        if (updatedUser != null && updatedUser.avatarUrl != null && updatedUser.avatarUrl!.isNotEmpty) {
          _user = updatedUser;
          await prefs.setString('user_avatar_${_user!.id}', updatedUser.avatarUrl!);
        }
        // Si el backend no devuelve la URL, ya tenemos el base64 aplicado localmente
        notifyListeners();
        return true;
      }
      // Aunque el servidor falló, la imagen ya está aplicada localmente (optimistic update)
      // No revertimos para no frustrar al usuario; la imagen persiste en SharedPreferences
      return false;
    } catch (e) {
      print('Error al subir imagen en AuthProvider: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}