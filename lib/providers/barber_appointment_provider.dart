import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class BarberAppointmentProvider extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();
  List<dynamic> appointments = [];
  List<dynamic> clientes = [];
  List<dynamic> barberos = [];
  List<dynamic> servicios = [];
  bool isLoading = false;

  Future<void> loadAppointments() async {
    isLoading = true;
    notifyListeners();
    final data = await Future.wait([
      _service.getAll(),
      _service.getClientes(),
      _service.getBarberos(),
      _service.getServicios()
    ]);
    
    appointments = data[0];
    clientes = data[1];
    barberos = data[2];
    servicios = data[3];
    
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createAppointment(Map<String, dynamic> data) async {
    final success = await _service.create(data);
    if (success) await loadAppointments();
    return success;
  }

  // MÉTODO ÚNICO (Sin duplicados)
  Future<void> deleteAppointment(int id) async {
    final success = await _service.delete(id);
    if (success) {
      appointments.removeWhere((a) => a['id_cita'] == id);
      notifyListeners();
    }
  }

  // Placeholder para edición
  Future<void> editAppointment(Map<String, dynamic> data, int id) async {
    // Si tu backend requiere un PUT, agrégalo al service y llámalo aquí
    await loadAppointments();
  }
}