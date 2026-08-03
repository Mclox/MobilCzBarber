import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class SaleService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Api.baseUrl));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Obtiene todas las ventas realizadas
  Future<List<dynamic>> getAll() async {
    try {
      final token = await _getToken();
      final response = await _dio.get('/sales', 
          options: Options(headers: {"Authorization": "Bearer $token"}));
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Obtiene los detalles de una venta en específico
  Future<List<dynamic>> getDetails(int saleId) async {
    try {
      final token = await _getToken();
      final response = await _dio.get('/sales/$saleId/details', 
          options: Options(headers: {"Authorization": "Bearer $token"}));
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Registra una nueva venta
  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await _dio.post('/sales', 
          data: data, 
          options: Options(headers: {"Authorization": "Bearer $token"}));
      return response.statusCode == 201 || (response.data != null && response.data['success'] == true);
    } catch (e) {
      return false;
    }
  }
}
