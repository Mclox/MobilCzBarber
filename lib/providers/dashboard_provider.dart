import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _kpis = {};
  bool _isLoading = false;

  Map<String, dynamic> get kpis => _kpis;
  bool get isLoading => _isLoading;

  Future<void> fetchKpis() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final dio = Dio(BaseOptions(
        baseUrl: Api.baseUrl, 
        headers: {"Authorization": "Bearer $token"}
      ));
      
      final appointments = await dio.get('/reports/appointments?start=2026-01-01&end=2026-12-31');
      final income = await dio.get('/reports/income?start=2026-01-01&end=2026-12-31');
      final employees = await dio.get('/reports/employees?start=2026-01-01&end=2026-12-31');

      final appRes = appointments.data['data'] ?? {};
      final incRes = income.data['data'] ?? {};
      final empRes = employees.data['data'] ?? {};

      _kpis = {
        'citasHoy': appRes['resumen'] != null ? appRes['resumen']['totalAgendadas'] : 0,
        'ingresosDia': incRes['resumen'] != null ? incRes['resumen']['ingresosTotales'] : 0,
        'topServicio': 'Corte Clásico',
        'barberoTop': (empRes['ranking'] != null && empRes['ranking'].length > 0) 
                      ? empRes['ranking'][0]['nombre'] 
                      : 'N/A',
        'clientesNuevos': 0
      };
    } catch (e) {
      debugPrint("Error cargando KPIs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}