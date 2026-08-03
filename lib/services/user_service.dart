import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../models/user.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Api.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// 📌 Obtener todos los usuarios reales del backend
  Future<List<User>> getAllUsers() async {
    try {
      final token = await _getToken();
      final response = await _dio.get('/users', 
        options: Options(headers: {"Authorization": "Bearer $token"}));
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List listData = response.data['data'] ?? [];
        return listData.map((e) => User.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error al cargar usuarios desde API: $e');
      return [];
    }
  }

  /// 📌 Crear un usuario real en la base de datos
  Future<User?> createUser(User user) async {
    try {
      final token = await _getToken();
      final response = await _dio.post('/users', 
        data: {
          "nombre": user.name,
          "tipo_documento": user.documentType ?? "CC",
          "documento": user.document ?? "",
          "email": user.email,
          "password": user.password ?? "123456",
          "id_rol": user.roleId ?? 3, // por defecto cliente si no tiene
          "telefono": user.phone ?? "",
          "direccion": user.address ?? "",
          "img": user.avatarUrl ?? "",
        },
        options: Options(headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 201 && response.data['success'] == true) {
        final newId = response.data['data']['id_usuario'];
        return User(
          id: newId,
          name: user.name,
          email: user.email,
          role: user.role,
          roleId: user.roleId ?? 3,
          document: user.document,
          documentType: user.documentType ?? "CC",
          phone: user.phone,
          address: user.address,
          state: user.state ?? "Activo",
          avatarUrl: user.avatarUrl,
        );
      }
      return null;
    } catch (e) {
      print('Error al crear usuario en API: $e');
      return null;
    }
  }

  /// 📌 Actualizar un usuario en la base de datos
  Future<bool> updateUser(int id, User user) async {
    try {
      final token = await _getToken();
      final response = await _dio.put('/users/$id', 
        data: {
          "nombre": user.name,
          "tipo_documento": user.documentType ?? "CC",
          "documento": user.document ?? "",
          "email": user.email,
          "id_rol": user.roleId ?? 3,
          "telefono": user.phone ?? "",
          "direccion": user.address ?? "",
          "img": user.avatarUrl ?? "",
          "estado": user.state ?? "Activo",
        },
        options: Options(headers: {"Authorization": "Bearer $token"}));
      
      return response.statusCode == 200 || (response.data != null && response.data['success'] == true);
    } catch (e) {
      print('Error al actualizar usuario en API: $e');
      return false;
    }
  }

  /// 📌 Eliminar un usuario de la base de datos
  Future<bool> deleteUser(int id) async {
    try {
      final token = await _getToken();
      final response = await _dio.delete('/users/$id', 
        options: Options(headers: {"Authorization": "Bearer $token"}));
      
      return response.statusCode == 200 || (response.data != null && response.data['success'] == true);
    } catch (e) {
      print('Error al eliminar usuario en API: $e');
      return false;
    }
  }
}
