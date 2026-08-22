import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class ServiceService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Api.baseUrl));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<dynamic>> getAll() async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/services', options: Options(headers: {"Authorization": "Bearer $token"}));
      if (res.data is Map && res.data['data'] is List) {
        return List<dynamic>.from(res.data['data']);
      } else if (res.data is List) {
        return List<dynamic>.from(res.data);
      }
    } catch (e) {
      print("Error loading services in ServiceService: $e");
    }
    return [];
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final res = await _dio.post('/services', data: data, options: Options(headers: {"Authorization": "Bearer $token"}));
      return res.statusCode == 201;
    } catch (e) {
      print("Error creating service in ServiceService: $e");
      return false;
    }
  }
}