import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/api.dart';

class BarberAvailabilityProvider extends ChangeNotifier {
  // Días de la semana con disponibilidad
  Map<String, bool> availability = {
    "Lunes": true,
    "Martes": true,
    "Miércoles": true,
    "Jueves": true,
    "Viernes": true,
    "Sábado": true,
    "Domingo": false,
  };

  // Horario de trabajo
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 21, minute: 0);
  bool isLoading = false;

  BarberAvailabilityProvider() {
    loadAvailability();
  }

  // Cargar disponibilidad desde almacenamiento local y sincronizar con backend
  Future<void> loadAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final day in availability.keys) {
        availability[day] = prefs.getBool('avail_$day') ?? (day != "Domingo");
      }
      final startHour = prefs.getInt('avail_start_hour') ?? 9;
      final startMin = prefs.getInt('avail_start_min') ?? 0;
      startTime = TimeOfDay(hour: startHour, minute: startMin);

      final endHour = prefs.getInt('avail_end_hour') ?? 21;
      final endMin = prefs.getInt('avail_end_min') ?? 0;
      endTime = TimeOfDay(hour: endHour, minute: endMin);
      
      notifyListeners();

      // Consultar horario en el backend para tener los datos reales actualizados
      final token = prefs.getString('jwt_token');
      final currentUserId = prefs.getInt('user_id');

      if (currentUserId != null && currentUserId > 0) {
        final dio = Dio(BaseOptions(
          baseUrl: Api.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));
        if (token != null) {
          dio.options.headers["Authorization"] = "Bearer $token";
        }

        final res = await dio.get('/employees/$currentUserId/schedules');
        if (res.statusCode == 200 && res.data is Map && res.data['data'] != null) {
          final data = res.data['data'];
          
          if (data['generalShift'] is Map) {
            final shift = data['generalShift'];
            if (shift['hora_inicio'] != null) {
              final parts = shift['hora_inicio'].toString().split(':');
              if (parts.length >= 2) {
                final h = int.tryParse(parts[0]) ?? 9;
                final m = int.tryParse(parts[1]) ?? 0;
                startTime = TimeOfDay(hour: h, minute: m);
                await prefs.setInt('avail_start_hour', h);
                await prefs.setInt('avail_start_min', m);
              }
            }
            if (shift['hora_fin'] != null) {
              final parts = shift['hora_fin'].toString().split(':');
              if (parts.length >= 2) {
                final h = int.tryParse(parts[0]) ?? 21;
                final m = int.tryParse(parts[1]) ?? 0;
                endTime = TimeOfDay(hour: h, minute: m);
                await prefs.setInt('avail_end_hour', h);
                await prefs.setInt('avail_end_min', m);
              }
            }
          }

          if (data['schedules'] is List) {
            final List<dynamic> schedList = data['schedules'];
            for (final item in schedList) {
              if (item is Map) {
                final dayName = item['dayName']?.toString();
                final activo = item['activo'] == true;
                if (dayName != null && availability.containsKey(dayName)) {
                  availability[dayName] = activo;
                  await prefs.setBool('avail_$dayName', activo);
                }
              }
            }
          }

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error loading availability from backend: $e");
    }
  }

  // Guardar disponibilidad localmente y en el backend
  Future<bool> saveAvailability({BuildContext? context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar localmente
      for (final day in availability.keys) {
        await prefs.setBool('avail_$day', availability[day]!);
      }
      await prefs.setInt('avail_start_hour', startTime.hour);
      await prefs.setInt('avail_start_min', startTime.minute);
      await prefs.setInt('avail_end_hour', endTime.hour);
      await prefs.setInt('avail_end_min', endTime.minute);
      
      final token = prefs.getString('jwt_token');
      final currentUserId = prefs.getInt('user_id');
      
      if (currentUserId != null && currentUserId > 0) {
        final startStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
        final endStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
        
        final diasLaboralesList = [
          { "dayId": 1, "dayName": "Lunes", "activo": availability["Lunes"] ?? true, "hora_inicio": startStr, "hora_fin": endStr },
          { "dayId": 2, "dayName": "Martes", "activo": availability["Martes"] ?? true, "hora_inicio": startStr, "hora_fin": endStr },
          { "dayId": 3, "dayName": "Miércoles", "activo": availability["Miércoles"] ?? true, "hora_inicio": startStr, "hora_fin": endStr },
          { "dayId": 4, "dayName": "Jueves", "activo": availability["Jueves"] ?? true, "hora_inicio": startStr, "hora_fin": endStr },
          { "dayId": 5, "dayName": "Viernes", "activo": availability["Viernes"] ?? true, "hora_inicio": startStr, "hora_fin": endStr },
          { "dayId": 6, "dayName": "Sábado", "activo": availability["Sábado"] ?? true, "hora_inicio": startStr, "hora_fin": endStr },
          { "dayId": 0, "dayName": "Domingo", "activo": availability["Domingo"] ?? false, "hora_inicio": startStr, "hora_fin": endStr }
        ];

        final payload = {
          "schedules": diasLaboralesList,
          "timeBlocks": [],
          "generalShift": {
            "hora_inicio": startStr,
            "hora_fin": endStr
          }
        };

        final dio = Dio(BaseOptions(
          baseUrl: Api.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));
        if (token != null) {
          dio.options.headers["Authorization"] = "Bearer $token";
        }

        final res = await dio.put('/employees/$currentUserId/schedules', data: payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          debugPrint("Availability saved successfully to backend for user $currentUserId");
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error saving availability to backend: $e");
    }
    notifyListeners();
    return false;
  }

  // Alternar día disponible
  void toggleDay(String day, bool value) {
    availability[day] = value;
    notifyListeners();
  }

  // Cambiar hora de inicio
  void setStartTime(TimeOfDay time) {
    startTime = time;
    notifyListeners();
  }

  // Cambiar hora de fin
  void setEndTime(TimeOfDay time) {
    endTime = time;
    notifyListeners();
  }
}
