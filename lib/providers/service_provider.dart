import 'package:flutter/material.dart';
import '../services/service_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceService _service = ServiceService();
  List<dynamic> services = [];
  bool isLoading = false;

  Future<void> loadServices() async {
    isLoading = true;
    notifyListeners();
    try {
      services = await _service.getAll();
    } catch (e) {
      debugPrint("Error loading services in ServiceProvider: $e");
      services = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createService(Map<String, dynamic> data) async {
    final success = await _service.create(data);
    if (success) await loadServices();
    return success;
  }
}