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

  /// 📌 Obtener un usuario por su ID
  Future<User?> getUserById(int id) async {
    try {
      final token = await _getToken();
      // Intentamos consultar el endpoint directo por si existe /users/:id
      try {
        final response = await _dio.get('/users/$id', 
          options: Options(headers: {"Authorization": "Bearer $token"}));
        if (response.statusCode == 200 && response.data['success'] == true) {
          if (response.data['data'] != null) {
            return User.fromJson(response.data['data']);
          }
        }
      } catch (e) {
        print('Endpoint directo /users/$id no disponible o error: $e. Usando fallback de lista completa.');
      }

      // Fallback: Obtenemos todos los usuarios y filtramos por ID
      final users = await getAllUsers();
      return users.firstWhere((u) => u.id == id);
    } catch (e) {
      print('Error al obtener usuario $id de la API: $e');
      return null;
    }
  }

  /// 📌 Actualizar la foto de perfil del usuario enviando el Base64 en el campo avatar
  Future<bool> updateProfileImage(int id, String base64Image, User currentUser) async {
    try {
      final token = await _getToken();

      // Formatear el teléfono para cumplir con la validación del backend
      String cleanPhone = currentUser.phone?.trim() ?? "";
      cleanPhone = cleanPhone.replaceAll(RegExp(r'[^\d+]'), '');
      if (cleanPhone.isEmpty) {
        cleanPhone = "+573000000000";
      } else if (!cleanPhone.startsWith('+')) {
        cleanPhone = cleanPhone.length == 10 ? "+57$cleanPhone" : "+$cleanPhone";
      }

      String docType = (currentUser.documentType?.trim().isNotEmpty ?? false) ? currentUser.documentType!.trim() : "CC";
      String docNum = (currentUser.document?.trim().isNotEmpty ?? false) ? currentUser.document!.trim() : "1234567890";
      String name = (currentUser.name.trim().isNotEmpty) ? currentUser.name.trim() : "Cliente";
      String email = (currentUser.email.trim().isNotEmpty) ? currentUser.email.trim() : "cliente@barber.com";

      int resolvedRoleId = currentUser.roleId ??
          (currentUser.role == 'admin' ? 1 : currentUser.role == 'employee' ? 2 : 3);

      final headers = {"Authorization": "Bearer $token"};

      // Payload mínimo: solo imagen (evita validaciones de otros campos)
      final minimalPayload = {
        "avatar": base64Image,
        "img": base64Image,
        "avatarUrl": base64Image,
      };

      // Payload completo con todos los campos del usuario
      final fullPayload = {
        "nombre": name,
        "tipo_documento": docType,
        "documento": docNum,
        "email": email,
        "id_rol": resolvedRoleId,
        "telefono": cleanPhone,
        "direccion": currentUser.address ?? "",
        "avatar": base64Image,
        "img": base64Image,
        "avatarUrl": base64Image,
        "estado": currentUser.state ?? "Activo",
      };

      // Estrategia 1: PATCH mínimo
      try {
        final r = await _dio.patch('/users/$id',
            data: minimalPayload,
            options: Options(headers: headers));
        print("✅ PATCH mínimo OK: ${r.statusCode} ${r.data}");
        if (r.statusCode == 200 || r.statusCode == 201 ||
            (r.data != null && r.data['success'] == true)) return true;
      } on DioException catch (e1) {
        print("⚠️ PATCH mínimo falló: ${e1.response?.statusCode} ${e1.response?.data}");
      }

      // Estrategia 2: PUT completo
      try {
        final r = await _dio.put('/users/$id',
            data: fullPayload,
            options: Options(headers: headers));
        print("✅ PUT completo OK: ${r.statusCode} ${r.data}");
        if (r.statusCode == 200 || r.statusCode == 201 ||
            (r.data != null && r.data['success'] == true)) return true;
      } on DioException catch (e2) {
        print("⚠️ PUT completo falló: ${e2.response?.statusCode} ${e2.response?.data}");
      }

      // Estrategia 3: PATCH completo
      try {
        final r = await _dio.patch('/users/$id',
            data: fullPayload,
            options: Options(headers: headers));
        print("✅ PATCH completo OK: ${r.statusCode} ${r.data}");
        if (r.statusCode == 200 || r.statusCode == 201 ||
            (r.data != null && r.data['success'] == true)) return true;
      } on DioException catch (e3) {
        print("❌ PATCH completo falló: ${e3.response?.statusCode} ${e3.response?.data}");
      }

      print('❌ Todas las estrategias fallaron para usuario $id (role: ${currentUser.role}, roleId: $resolvedRoleId)');
      return false;
    } catch (e) {
      print('Error general al subir imagen de perfil: $e');
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
