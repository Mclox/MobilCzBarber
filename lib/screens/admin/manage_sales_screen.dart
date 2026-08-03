import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../providers/sale_provider.dart';

class ManageSalesScreen extends StatefulWidget {
  const ManageSalesScreen({super.key});

  @override
  State<ManageSalesScreen> createState() => _ManageSalesScreenState();
}

class _ManageSalesScreenState extends State<ManageSalesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<SaleProvider>(context, listen: false).loadSales());
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '\$0';
    final parsed = double.tryParse(amount.toString()) ?? 0.0;
    // Formato de pesos colombianos u otra divisa con puntos como separadores de miles
    final valueStr = parsed.toStringAsFixed(0);
    return '\$' + valueStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString().split('T')[0];
    }
  }

  void _showSaleDetailsDialog(int saleId, dynamic saleData) {
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    saleProvider.loadSaleDetails(saleId);

    showDialog(
      context: context,
      builder: (_) => Consumer<SaleProvider>(
        builder: (context, provider, _) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Detalle Venta #${saleId}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            content: provider.isDetailsLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vendedor: ${saleData['vendedor_nombre'] ?? 'Desconocido'}",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text("Fecha: ${_formatDate(saleData['fecha'])}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("Método de Pago: ${saleData['metodo_pago'] ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        const Divider(height: 24),
                        const Text("Ítems vendidos:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        if (provider.currentSaleDetails.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("No hay detalles registrados para esta venta.",
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                          )
                        else
                          ...provider.currentSaleDetails.map((det) {
                            final name = det['tipo'] == 'servicio'
                                ? (det['servicio_nombre'] ?? 'Servicio')
                                : (det['producto_nombre'] ?? 'Producto');
                            final icon = det['tipo'] == 'servicio'
                                ? Icons.content_cut
                                : Icons.shopping_bag;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, size: 20, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(
                                            "Cant: ${det['cantidad']} · Unit: ${_formatCurrency(det['precio_unitario_neto'])}",
                                            style: TextStyle(
                                                color: Colors.grey.shade600, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(det['subtotal_item']),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal Neto:", style: TextStyle(fontSize: 13)),
                            Text(_formatCurrency(saleData['total_neto']),
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("IVA Total:", style: TextStyle(fontSize: 13)),
                            Text(_formatCurrency(saleData['iva_total']),
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Bruto:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              _formatCurrency(saleData['total_bruto']),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SaleProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Control de Ventas"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => context.push("/admin/sales/create").then((_) {
          // Recargar ventas al volver de crear venta
          provider.loadSales();
        }),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadSales(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.sales.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          "No hay ventas registradas.",
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.sales.length,
                    itemBuilder: (context, index) {
                      final sale = provider.sales[index];
                      final saleId = sale['id_venta'] ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () => _showSaleDetailsDialog(saleId, sale),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.teal.withOpacity(0.15),
                                  child: const Icon(Icons.receipt_long, color: Colors.teal),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Venta #${saleId}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Método: ${sale['metodo_pago'] ?? 'Efectivo'}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(sale['fecha']),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatCurrency(sale['total_bruto']),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sale['vendedor_nombre'] ?? 'Empleado',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
