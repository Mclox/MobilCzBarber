import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/api.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import 'product_detail_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).loadProducts());
  }

  /// Helper para resolver correctamente la URL de la imagen del producto
  String _resolveImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    
    // Reemplazar barras invertidas con barras diagonales
    String cleanPath = imageUrl.replaceAll('\\', '/');
    // Quitar barra diagonal inicial si existe
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    // Obtener la URL base y remover /api si está presente
    String serverUrl = Api.baseUrl.replaceAll('/api', '');
    // Asegurar que no quede un slash final en serverUrl
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }
    
    return "$serverUrl/$cleanPath";
  }



  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Productos"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.products.isEmpty
              ? const Center(child: Text("No hay productos"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length,
                  itemBuilder: (_, index) {
                    final p = provider.products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p),
                            ),
                          );
                        },
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Precio: \$${p.price.toStringAsFixed(2)} · Stock: ${p.stock}"),
                      ),
                    );
                  },
                ),
    );
  }

}