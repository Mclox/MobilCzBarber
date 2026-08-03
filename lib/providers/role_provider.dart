import 'package:flutter/material.dart';
import '../models/roles.dart';
import '../services/role_service.dart';

class RoleProvider with ChangeNotifier {
  final RoleService _roleService = RoleService();

  List<Role> _roles = [];
  bool _isLoading = false;

  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;

  /// 📌 Cargar roles desde el backend
  Future<void> fetchRoles() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _roleService.getRoles();
      _roles = data;
    } catch (e) {
      print('Error cargando roles en Provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📌 Crear rol
  Future<bool> createRole(Role role) async {
    try {
      final newRole = await _roleService.createRole(role);
      if (newRole != null) {
        _roles.add(newRole);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creando rol en Provider: $e');
      return false;
    }
  }

  /// 📌 Eliminar rol (Nota: Puede fallar si la ruta no existe)
  Future<bool> deleteRole(int id) async {
    try {
      await _roleService.deleteRole(id);
      _roles.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error eliminando rol en Provider: $e');
      return false;
    }
  }

  /// 📌 Actualizar rol
  Future<bool> updateRole(Role role) async {
    try {
      final updated = await _roleService.updateRole(role);
      if (updated != null) {
        final index = _roles.indexWhere((r) => r.id == role.id);
        if (index != -1) {
          _roles[index] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error actualizando rol en Provider: $e');
      return false;
    }
  }
}
