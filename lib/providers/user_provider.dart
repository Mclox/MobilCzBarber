import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  /// 📌 Cargar usuarios reales del backend
  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _userService.getAllUsers();
      _users = data;
    } catch (e) {
      print('Error cargando usuarios en Provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📌 Crear usuario en backend y actualizar lista local
  Future<bool> createUser(User user) async {
    try {
      final newUser = await _userService.createUser(user);
      if (newUser != null) {
        _users.add(newUser);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creando usuario en Provider: $e');
      return false;
    }
  }

  /// 📌 Actualizar usuario en backend y actualizar lista local
  Future<bool> updateUser(int id, User user) async {
    try {
      final success = await _userService.updateUser(id, user);
      if (success) {
        final index = _users.indexWhere((u) => u.id == id);
        if (index != -1) {
          // Asegurar de mantener el ID en el objeto actualizado
          final updatedUser = User(
            id: id,
            name: user.name,
            email: user.email,
            role: user.role,
            roleId: user.roleId,
            document: user.document,
            documentType: user.documentType,
            phone: user.phone,
            address: user.address,
            state: user.state,
            avatarUrl: user.avatarUrl,
          );
          _users[index] = updatedUser;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error actualizando usuario en Provider: $e');
      return false;
    }
  }

  /// 📌 Eliminar usuario en backend y actualizar lista local
  Future<bool> deleteUser(int id) async {
    try {
      final success = await _userService.deleteUser(id);
      if (success) {
        _users.removeWhere((u) => u.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error eliminando usuario en Provider: $e');
      return false;
    }
  }
}
