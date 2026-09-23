import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Api.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  User? currentUser;
  String? token;

  /// 🔐 LOGIN REAL (Node.js + SQL Server)
  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        "email": email,
        // OJO: Tu backend en Node.js espera el campo 'contrasena', no 'password'
        "contrasena": password, 
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        
        token = data['token'];
        // Mapeamos el JSON de Node al modelo de Flutter
        currentUser = User.fromJson(data['user']);

        // Guardamos en el celular para que no tenga que loguearse cada vez
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token!);
        await prefs.setInt('user_id', currentUser!.id ?? 0);
        await prefs.setString('user_role', currentUser!.role);

        return currentUser;
      }
      return null;
    } on DioException catch (e) {
      print('Error Login API: ${e.response?.data['message'] ?? e.message}');
      return null;
    } catch (e) {
      print('Error Login general: $e');
      return null;
    }
  }

  /// 📝 REGISTER REAL (Node.js + SQL Server)
  Future<bool> register(User newUser) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        "nombre": newUser.name,
        "email": newUser.email,
        "password": newUser.password, // El backend lo encriptará con Bcrypt
        "telefono": newUser.phone ?? "",
      });

      return response.statusCode == 201 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    currentUser = null;
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }
}