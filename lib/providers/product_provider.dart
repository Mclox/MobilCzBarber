import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  List<Product> products = [];
  bool isLoading = false;

  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      final List rawData = await _service.getAll();
      products = rawData.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print('Error al cargar productos en ProductProvider: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final success = await _service.create(data);
    if (success) {
      await loadProducts();
    }
    return success;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    final success = await _service.update(id, data);
    if (success) {
      await loadProducts();
    }
    return success;
  }

  Future<bool> deleteProduct(int id) async {
    final success = await _service.delete(id);
    if (success) {
      await loadProducts();
    }
    return success;
  }
}