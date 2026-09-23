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
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

  BarberAvailabilityProvider() {
    loadAvailability();
  }

  // Cargar disponibilidad desde almacenamiento local
  Future<void> loadAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final day in availability.keys) {
        availability[day] = prefs.getBool('avail_$day') ?? (day != "Domingo");
      }
      final startHour = prefs.getInt('avail_start_hour') ?? 9;
      final startMin = prefs.getInt('avail_start_min') ?? 0;
      startTime = TimeOfDay(hour: startHour, minute: startMin);

      final endHour = prefs.getInt('avail_end_hour') ?? 18;
      final endMin = prefs.getInt('avail_end_min') ?? 0;
      endTime = TimeOfDay(hour: endHour, minute: endMin);
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading availability: $e");
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
      
      // Guardar en el backend
      final token = prefs.getString('jwt_token');
      final currentUserId = prefs.getInt('user_id');
      
      if (token != null && currentUserId != null) {
        final dio = Dio(BaseOptions(baseUrl: Api.baseUrl));
        dio.options.headers["Authorization"] = "Bearer $token";
        
        final res = await dio.get('/employees');
        List<dynamic> employees = [];
        if (res.data is Map && res.data['data'] is List) {
          employees = res.data['data'];
        } else if (res.data is List) {
          employees = res.data;
        }
        
        final myEmp = employees.firstWhere(
          (e) => e['id_usuario'].toString() == currentUserId.toString(),
          orElse: () => null,
        );
        
        if (myEmp != null) {
          final barberId = myEmp['id_barbero'] ?? myEmp['id_empleado'];
          final startStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00";
          final endStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00";
          
          String phone = (myEmp['telefono'] ?? '').toString();
          if (phone.isNotEmpty && !phone.startsWith('+')) {
            phone = '+57$phone';
          }
          
          final data = {
            "nombre": myEmp['nombre'] ?? 'Barbero',
            "email": myEmp['email'] ?? 'barbero@barber.com',
            "telefono": phone,
            "tipo_documento": myEmp['tipo_documento'] ?? 'CC',
            "documento": myEmp['documento'] ?? '12345678',
            "estado": myEmp['estado'] ?? 'Activo',
            "tipo_esquema": myEmp['tipo_esquema'] ?? 'porcentaje',
            "porcentaje_comision": double.tryParse(myEmp['porcentaje_comision']?.toString() ?? '0') ?? 0,
            "hora_inicio": startStr,
            "hora_fin": endStr
          };
          
          final updateRes = await dio.put('/employees/$barberId', data: data);
          if (updateRes.statusCode == 200) {
            debugPrint("Availability saved successfully to backend for barber $barberId");
            return true;
          }
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
