import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class NotificationService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Api.baseUrl));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<dynamic>> getRecentNotifications([String? role]) async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/notifications', options: Options(headers: {"Authorization": "Bearer $token"}));
      if (res.statusCode == 200) {
        final List<dynamic> list = res.data['data'] ?? [];
        final userRole = (role ?? '').toLowerCase();

        // Si es Admin, retornar todas las notificaciones
        if (userRole == 'admin' || userRole == 'administrador') {
          return list;
        }

        // Para Cliente y Barbero, filtrar notificaciones administrativas que no corresponden a su rol
        return list.where((n) {
          final msg = (n['mensaje'] ?? n['titulo'] ?? '').toString().toLowerCase();

          // Filtrar notificaciones administrativas puras que solo le interesan al Administrador
          if (msg.contains('empleado/barbero') ||
              msg.contains('se actualizó el rol') ||
              msg.contains('se creó el servicio') ||
              msg.contains('se eliminó el servicio') ||
              msg.contains('se creó el producto') ||
              msg.contains('stock') ||
              msg.contains('devolución')) {
            return false;
          }

          return true;
        }).toList();
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
    return [];
  }

  Future<bool> markAllAsRead() async {
    try {
      final token = await _getToken();
      final res = await _dio.put('/notifications/read-all', options: Options(headers: {"Authorization": "Bearer $token"}));
      return res.statusCode == 200;
    } catch (e) {
      print("Error marking notifications as read: $e");
    }
    return false;
  }
}
