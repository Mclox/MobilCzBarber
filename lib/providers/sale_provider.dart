import 'package:flutter/material.dart';
import '../services/sale_service.dart';

class SaleProvider extends ChangeNotifier {
  final SaleService _service = SaleService();
  List<dynamic> sales = [];
  List<dynamic> currentSaleDetails = [];
  bool isLoading = false;
  bool isDetailsLoading = false;

  /// Carga todas las ventas desde la API
  Future<void> loadSales() async {
    isLoading = true;
    notifyListeners();
    sales = await _service.getAll();
    isLoading = false;
    notifyListeners();
  }

  /// Carga los detalles de una venta específica
  Future<void> loadSaleDetails(int saleId) async {
    isDetailsLoading = true;
    currentSaleDetails = [];
    notifyListeners();
    currentSaleDetails = await _service.getDetails(saleId);
    isDetailsLoading = false;
    notifyListeners();
  }

  /// Crea una nueva venta y recarga la lista de ventas
  Future<bool> createSale(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    final success = await _service.create(data);
    if (success) {
      sales = await _service.getAll();
    }
    isLoading = false;
    notifyListeners();
    return success;
  }
}
