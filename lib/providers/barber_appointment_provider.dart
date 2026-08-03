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

  Future<bool> editAppointment(int id, Map<String, dynamic> data) async {
    final success = await _service.update(id, data);
    if (success) await loadAppointments();
    return success;
  }

  Future<bool> updateAppointmentStatus(int id, String status) async {
    final success = await _service.updateStatus(id, status);
    if (success) await loadAppointments();
    return success;
  }
}