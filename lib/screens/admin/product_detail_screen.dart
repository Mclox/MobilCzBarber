import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/api.dart';
import '../../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  String _resolveImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    
    String cleanPath = imageUrl.replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    String serverUrl = Api.baseUrl.replaceAll('/api', '');
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }
    
    return "$serverUrl/$cleanPath";
  }

  @override
  Widget build(BuildContext context) {
    String resolvedUrl = _resolveImageUrl(product.imageUrl);
    
    Widget imageWidget;
    if (resolvedUrl.isEmpty) {
      imageWidget = Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    } else {
      imageWidget = Image.network(
        resolvedUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade100,
            child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
          );
        },
      );
    }

    // Stock status
    Color stockColor = Colors.green;
    String stockLabel = "Disponible";
    if (product.stock == 0) {
      stockColor = Colors.red;
      stockLabel = "Agotado";
    } else if (product.stock <= 5) {
      stockColor = Colors.orange;
      stockLabel = "Stock Bajo";
    }

    String acquisition = "Compra Directa";
    if (product.acquisitionType == 'consignacion') {
      acquisition = "Consignación";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detalle del Producto"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image card container
            Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageWidget,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$stockLabel (${product.stock})",
                          style: TextStyle(
                            color: stockColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (product.state == 'Activo' ? Colors.green : Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.state ?? 'Activo',
                          style: TextStyle(
                            color: product.state == 'Activo' ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    "\$${product.price.toStringAsFixed(2)} COP",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  
                  const Divider(height: 40),
                  
                  // Details Section
                  const Text(
                    "Información de Inventario",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    icon: Icons.description_outlined,
                    title: "Descripción",
                    value: product.description.isEmpty ? "Sin descripción disponible" : product.description,
                  ),
                  _buildDetailRow(
                    icon: Icons.qr_code_outlined,
                    title: "Código de Producto",
                    value: product.code == null || product.code!.isEmpty ? "Sin código asignado" : product.code!,
                  ),
                  _buildDetailRow(
                    icon: Icons.branding_watermark_outlined,
                    title: "Marca",
                    value: product.brandName == null || product.brandName!.isEmpty ? "Sin marca" : product.brandName!,
                  ),
                  _buildDetailRow(
                    icon: Icons.percent_outlined,
                    title: "IVA Aplicable",
                    value: "${product.ivaPercentage?.toStringAsFixed(1) ?? '19.0'}%",
                  ),
                  _buildDetailRow(
                    icon: Icons.local_shipping_outlined,
                    title: "Tipo de Adquisición",
                    value: acquisition,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
