import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../models/roles.dart';

class RoleService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Api.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// 📌 Obtener todos los roles reales del backend
  Future<List<Role>> getRoles() async {
    try {
      final token = await _getToken();
      final response = await _dio.get('/roles', 
        options: Options(headers: {"Authorization": "Bearer $token"}));
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List listData = response.data['data'] ?? [];
        return listData.map((e) => Role.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error al cargar roles desde API: $e');
      return [];
    }
  }

  /// 📌 Crear rol
  Future<Role?> createRole(Role role) async {
    try {
      final token = await _getToken();
      final response = await _dio.post('/roles', 
        data: {
          "nombre": role.name,
          "descripcion": role.description,
          "estado": role.state ?? "Activo",
          "permisos": role.permissions.map((p) => p.toJson()).toList()
        },
        options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 201 && response.data['success'] == true) {
        return Role.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error al crear rol en API: $e');
      return null;
    }
  }

  /// 📌 Actualizar rol
  Future<Role?> updateRole(Role role) async {
    try {
      final token = await _getToken();
      final response = await _dio.put('/roles/${role.id}', 
        data: {
          "nombre": role.name,
          "descripcion": role.description,
          "estado": role.state ?? "Activo",
          "permisos": role.permissions.map((p) => p.toJson()).toList()
        },
        options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Role.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error al actualizar rol en API: $e');
      return null;
    }
  }

  /// 📌 Eliminar rol (Nota: El backend oficial no expone ruta de eliminación de roles, por lo que este método es preventivo o inactivo)
  Future<void> deleteRole(int id) async {
    try {
      final token = await _getToken();
      await _dio.delete('/roles/$id', 
        options: Options(headers: {"Authorization": "Bearer $token"}));
    } catch (e) {
      print('Error al eliminar rol en API (ruta no soportada): $e');
      throw Exception('El sistema no permite eliminar roles.');
    }
  }
}
