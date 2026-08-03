import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../core/app_theme.dart';
import '../../core/api.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // 🔥 Asegura que cargue los productos solo una vez
    if (productProvider.products.isEmpty && !productProvider.isLoading) {
      productProvider.loadProducts();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo de Productos"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: productProvider.isLoading
          ? const LoadingWidget()
          : productProvider.products.isEmpty
              ? const Center(
                  child: Text(
                    "No hay productos disponibles.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85, // Adjusted for removed button
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];

                    // Resolver la imagen
                    String resolvedUrl = 'https://via.placeholder.com/150';
                    if (product.imageUrl.isNotEmpty) {
                      if (product.imageUrl.startsWith('http')) {
                        resolvedUrl = product.imageUrl;
                      } else {
                        String cleanPath = product.imageUrl.replaceAll('\\', '/');
                        if (cleanPath.startsWith('/')) {
                          cleanPath = cleanPath.substring(1);
                        }
                        String serverUrl = Api.baseUrl.replaceAll('/api', '');
                        if (serverUrl.endsWith('/')) {
                          serverUrl = serverUrl.substring(0, serverUrl.length - 1);
                        }
                        resolvedUrl = "$serverUrl/$cleanPath";
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Imagen
                           Expanded( // Use Expanded to fill space nicely
                             child: Container(
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 borderRadius: const BorderRadius.vertical(
                                     top: Radius.circular(12)),
                                 image: DecorationImage(
                                   image: NetworkImage(resolvedUrl),
                                   fit: BoxFit.fitHeight,
                                 ),
                               ),
                             ),
                           ),

                          // Información del producto
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  "\$${product.price.toStringAsFixed(0)} COP",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
