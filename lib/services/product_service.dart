import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class ProductService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Api.baseUrl));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<dynamic>> getAll() async {
    final token = await _getToken();
    final response = await _dio.get('/products', 
        options: Options(headers: {"Authorization": "Bearer $token"}));
    return response.data['data'];
  }

  Future<bool> create(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await _dio.post('/products', 
        data: data, 
        options: Options(headers: {"Authorization": "Bearer $token"}));
    return response.statusCode == 201;
  }

  Future<bool> update(int id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await _dio.put('/products/$id', 
        data: data, 
        options: Options(headers: {"Authorization": "Bearer $token"}));
    return response.statusCode == 200 || response.statusCode == 204 || (response.data != null && response.data['success'] == true);
  }

  Future<bool> delete(int id) async {
    final token = await _getToken();
    final response = await _dio.delete('/products/$id', 
        options: Options(headers: {"Authorization": "Bearer $token"}));
    return response.statusCode == 200 || response.statusCode == 204 || (response.data != null && response.data['success'] == true);
  }
}