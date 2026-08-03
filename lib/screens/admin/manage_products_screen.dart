import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';
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

  void _showProductDetails(BuildContext context, Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        // Resolve image URL
        Widget imageWidget;
        String resolvedUrl = _resolveImageUrl(p.imageUrl);
        if (resolvedUrl.isEmpty) {
          imageWidget = Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
          );
        } else {
          imageWidget = Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Image.network(
                resolvedUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
                },
              ),
            ),
          );
        }

        // Stock status color and message
        Color stockColor = Colors.green;
        String stockLabel = "Disponible";
        if (p.stock == 0) {
          stockColor = Colors.red;
          stockLabel = "Agotado";
        } else if (p.stock <= 5) {
          stockColor = Colors.orange;
          stockLabel = "Stock Bajo";
        }

        // Acquisition translation
        String acquisition = "Compra Directa";
        if (p.acquisitionType == 'consignacion') {
          acquisition = "Consignación";
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image header
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: imageWidget,
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges (Category & Stock Status & State)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.category,
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
                                "$stockLabel (${p.stock})",
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
                                color: (p.state == 'Activo' ? Colors.green : Colors.grey).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.state ?? 'Activo',
                                style: TextStyle(
                                  color: p.state == 'Activo' ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Product Name
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Price
                        Text(
                          "\$${p.price.toStringAsFixed(2)} COP",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        
                        const Divider(height: 32),
                        
                        // Section Details
                        const Text(
                          "Detalles del Producto",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        _buildDetailRow(
                          icon: Icons.description_outlined,
                          title: "Descripción",
                          value: p.description.isEmpty ? "Sin descripción disponible" : p.description,
                        ),
                        
                        // Code
                        _buildDetailRow(
                          icon: Icons.qr_code_outlined,
                          title: "Código de Producto",
                          value: p.code == null || p.code!.isEmpty ? "Sin código asignado" : p.code!,
                        ),
                        
                        // Brand
                        _buildDetailRow(
                          icon: Icons.branding_watermark_outlined,
                          title: "Marca",
                          value: p.brandName == null || p.brandName!.isEmpty ? "Sin marca" : p.brandName!,
                        ),
                        
                        // IVA
                        _buildDetailRow(
                          icon: Icons.percent_outlined,
                          title: "IVA Aplicable",
                          value: "${p.ivaPercentage?.toStringAsFixed(1) ?? '19.0'}%",
                        ),
                        
                        // Acquisition Type
                        _buildDetailRow(
                          icon: Icons.local_shipping_outlined,
                          title: "Tipo de Adquisición",
                          value: acquisition,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Close button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Cerrar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade600),
          const SizedBox(width: 12),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _openForm(provider),
        child: const Icon(Icons.add, color: Colors.white),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openForm(provider, product: p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await ConfirmationHelper.showDeleteConfirmation(
                                  context: context,
                                  title: "¿Eliminar Producto?",
                                  message: "¿Realmente deseas eliminar el producto '${p.name}'?",
                                );
                                if (confirm) {
                                  await provider.deleteProduct(p.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _openForm(ProductProvider provider, {Product? product}) {
    final nameCtrl = TextEditingController(text: product != null ? product.name : '');
    final priceCtrl = TextEditingController(text: product != null ? product.price.toString() : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '');
    final descCtrl = TextEditingController(text: product != null ? product.description : '');
    final codeCtrl = TextEditingController(text: product != null ? product.code : '');
    final ivaCtrl = TextEditingController(text: product != null ? product.ivaPercentage.toString() : '19.0');

    int categoryId = product != null ? (product.idCategory ?? 1) : 1;
    String status = product != null ? (product.state ?? "Activo") : "Activo";
    String acquisitionType = product != null ? (product.acquisitionType ?? "compra_directa") : "compra_directa";

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? "Nuevo Producto" : "Editar Producto"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Precio Neto (Sin IVA)")),
                const SizedBox(height: 8),
                TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Stock")),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Descripción")),
                const SizedBox(height: 8),
                TextField(
                  controller: ivaCtrl,
                  enabled: false,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "IVA (%) (Solo lectura)",
                    filled: true,
                  ),
                ),
                if (product != null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: codeCtrl,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Código de Barra (Solo lectura)",
                      filled: true,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: "Categoría"),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Cuidado Capilar")),
                    DropdownMenuItem(value: 2, child: Text("Cuidado de Barba")),
                  ],
                  onChanged: (value) => setDialogState(() => categoryId = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: "Estado"),
                  items: const [
                    DropdownMenuItem(value: "Activo", child: Text("Activo")),
                    DropdownMenuItem(value: "Inactivo", child: Text("Inactivo")),
                  ],
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: acquisitionType,
                  decoration: const InputDecoration(labelText: "Tipo de Adquisición"),
                  items: const [
                    DropdownMenuItem(value: "compra_directa", child: Text("Compra Directa")),
                    DropdownMenuItem(value: "consignacion", child: Text("Consignación")),
                  ],
                  onChanged: (value) => setDialogState(() => acquisitionType = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                
                final data = {
                  "nombre": nameCtrl.text.trim(),
                  "precio_neto": double.parse(priceCtrl.text),
                  "stock": int.parse(stockCtrl.text),
                  "id_categoria": categoryId,
                  "descripcion": descCtrl.text.trim(),
                  "tipo_adquisicion": acquisitionType,
                  "estado": status,
                  // Si es creación, autogeneramos el código. Si es edición, se conserva el código original.
                  "codigo": product == null
                      ? "PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}"
                      : product.code,
                  // Si es creación, enviamos 19.0 de IVA. Si es edición, enviamos el original.
                  "iva_porcentaje": product == null
                      ? 19.0
                      : product.ivaPercentage ?? 19.0,
                  // Preservamos el valor de la imagen en la BD
                  "img": product == null
                      ? ""
                      : product.imageUrl,
                };
                
                if (product == null) {
                  await provider.createProduct(data);
                } else {
                  await provider.updateProduct(product.id, data);
                }
                
                if (mounted) Navigator.pop(dialogContext);
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}