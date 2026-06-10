import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  List<dynamic> products = [];
  bool isLoading = false;

  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();
    products = await _service.getAll();
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final success = await _service.create(data);
    if (success) {
      await loadProducts();
    }
    return success;
  }
}