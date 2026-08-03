import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/sale_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  // Listas cargadas desde servicios/proveedores
  List<dynamic> _clients = [];
  List<dynamic> _barbers = [];
  bool _isInitLoading = true;

  // Datos de cabecera de la venta
  int? _selectedClientId;
  String _selectedPaymentMethod = "Efectivo";

  // Ítems agregados a la venta actual
  final List<Map<String, dynamic>> _addedItems = [];

  // Variables para agregar un nuevo ítem
  String _itemType = "producto"; // 'producto' o 'servicio'
  dynamic _selectedProduct;
  dynamic _selectedService;
  int? _selectedBarberId;
  final TextEditingController _quantityCtrl = TextEditingController(text: "1");

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitLoading = true;
    });

    try {
      // Cargamos productos y servicios de sus proveedores correspondientes
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

      await Future.wait([
        productProvider.loadProducts(),
        serviceProvider.loadServices(),
        _fetchClientsAndBarbers()
      ]);
    } catch (e) {
      debugPrint("Error cargando datos de inicialización: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  Future<void> _fetchClientsAndBarbers() async {
    final clientsData = await _appointmentService.getClientes();
    final barbersData = await _appointmentService.getBarberos();
    setState(() {
      _clients = clientsData;
      _barbers = barbersData;
    });
  }

  String _formatCurrency(double amount) {
    final valueStr = amount.toStringAsFixed(0);
    return '\$' + valueStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // Cálculos de totales
  double get _subtotalNeto {
    return _addedItems.fold(0.0, (sum, item) {
      final price = double.tryParse(item['precio_unitario_neto'].toString()) ?? 0.0;
      final qty = int.tryParse(item['cantidad'].toString()) ?? 0;
      return sum + (price * qty);
    });
  }

  double get _ivaTotal {
    return _addedItems.fold(0.0, (sum, item) {
      final price = double.tryParse(item['precio_unitario_neto'].toString()) ?? 0.0;
      final qty = int.tryParse(item['cantidad'].toString()) ?? 0;
      final ivaPercent = double.tryParse(item['iva_porcentaje'].toString()) ?? 0.0;
      return sum + ((price * ivaPercent / 100) * qty);
    });
  }

  double get _totalBruto => _subtotalNeto + _ivaTotal;

  void _addItem() {
    final qty = int.tryParse(_quantityCtrl.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("La cantidad debe ser mayor que 0"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_itemType == "producto") {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Selecciona un producto"),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Validar stock
      final stock = _selectedProduct['stock'] ?? 0;
      if (qty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Stock insuficiente. Disponible: $stock"),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // Verificar si ya se agregó el producto
      final existingIndex = _addedItems.indexWhere((item) =>
          item['tipo'] == 'producto' && item['id_producto'] == _selectedProduct['id_producto']);

      if (existingIndex != -1) {
        final currentQty = _addedItems[existingIndex]['cantidad'] as int;
        if (currentQty + qty > stock) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("No puedes agregar más de este producto. Stock disponible: $stock"),
            backgroundColor: Colors.red,
          ));
          return;
        }
        setState(() {
          _addedItems[existingIndex]['cantidad'] = currentQty + qty;
        });
      } else {
        setState(() {
          _addedItems.add({
            "tipo": "producto",
            "id_producto": _selectedProduct['id_producto'],
            "id_servicio": null,
            "id_barbero": null,
            "name": _selectedProduct['nombre'],
            "cantidad": qty,
            "precio_unitario_neto": double.tryParse(_selectedProduct['precio_neto'].toString()) ?? 0.0,
            "iva_porcentaje": 0.0, // por defecto sin IVA
            "subtotal_item": (double.tryParse(_selectedProduct['precio_neto'].toString()) ?? 0.0) * qty,
          });
        });
      }
    } else {
      // Servicio
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Selecciona un servicio"),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final existingIndex = _addedItems.indexWhere((item) =>
          item['tipo'] == 'servicio' && item['id_servicio'] == _selectedService['id_servicio']);

      if (existingIndex != -1) {
        setState(() {
          final currentQty = _addedItems[existingIndex]['cantidad'] as int;
          _addedItems[existingIndex]['cantidad'] = currentQty + qty;
        });
      } else {
        setState(() {
          _addedItems.add({
            "tipo": "servicio",
            "id_producto": null,
            "id_servicio": _selectedService['id_servicio'],
            "id_barbero": _selectedBarberId ?? (_barbers.isNotEmpty ? _barbers[0]['id_barbero'] ?? _barbers[0]['id_usuario'] : 1),
            "name": _selectedService['nombre'],
            "cantidad": qty,
            "precio_unitario_neto": double.tryParse(_selectedService['precio_neto'].toString()) ?? 0.0,
            "iva_porcentaje": 0.0,
            "subtotal_item": (double.tryParse(_selectedService['precio_neto'].toString()) ?? 0.0) * qty,
          });
        });
      }
    }

    // Limpiar campos de inserción
    setState(() {
      _selectedProduct = null;
      _selectedService = null;
      _quantityCtrl.text = "1";
    });
  }

  void _removeItem(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
  }

  Future<void> _saveSale() async {
    if (_addedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Debes agregar al menos un producto o servicio"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);

    // El vendedor es el usuario administrador logueado
    final idVendedor = authProvider.user?.id ?? 1;

    final saleData = {
      "id_cliente": _selectedClientId,
      "id_vendedor": idVendedor,
      "metodo_pago": _selectedPaymentMethod,
      "detalles": _addedItems.map((item) => {
        "tipo": item['tipo'],
        "id_producto": item['id_producto'],
        "id_servicio": item['id_servicio'],
        "id_barbero": item['id_barbero'],
        "cantidad": item['cantidad'],
        "precio_unitario_neto": item['precio_unitario_neto'],
        "iva_porcentaje": item['iva_porcentaje']
      }).toList()
    };

    final success = await saleProvider.createSale(saleData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Venta registrada exitosamente"),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error al registrar la venta. Inténtalo de nuevo."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Registrar Venta"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABECERA DE LA VENTA
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Datos Generales",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 12),
                          // CLIENTE
                          DropdownButtonFormField<int>(
                            value: _selectedClientId,
                            decoration: const InputDecoration(
                              labelText: "Cliente",
                              prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text("Consumidor Final (General)"),
                              ),
                              ..._clients.map<DropdownMenuItem<int>>((c) {
                                return DropdownMenuItem<int>(
                                  value: (c['id_cliente'] ?? 0) as int,
                                  child: Text(c['nombre_final']?.toString() ?? 'Sin nombre'),
                                );
                              }).toList()
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedClientId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          // METODO DE PAGO
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: const InputDecoration(
                              labelText: "Método de Pago",
                              prefixIcon: Icon(Icons.credit_card, color: AppTheme.primary),
                            ),
                            items: const [
                              DropdownMenuItem(value: "Efectivo", child: Text("Efectivo")),
                              DropdownMenuItem(value: "Tarjeta", child: Text("Tarjeta")),
                              DropdownMenuItem(value: "Transferencia", child: Text("Transferencia")),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedPaymentMethod = val ?? "Efectivo";
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AGREGAR ÍTEM
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Agregar Ítem a la Venta",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 10),
                          // TIPO DE ÍTEM
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text("Producto", style: TextStyle(fontSize: 14)),
                                  value: "producto",
                                  groupValue: _itemType,
                                  onChanged: (val) {
                                    setState(() {
                                      _itemType = val!;
                                      _selectedProduct = null;
                                      _selectedService = null;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text("Servicio", style: TextStyle(fontSize: 14)),
                                  value: "servicio",
                                  groupValue: _itemType,
                                  onChanged: (val) {
                                    setState(() {
                                      _itemType = val!;
                                      _selectedProduct = null;
                                      _selectedService = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_itemType == "producto") ...[
                            // DROPDOWN PRODUCTO
                            DropdownButtonFormField<dynamic>(
                              value: _selectedProduct,
                              decoration: const InputDecoration(
                                labelText: "Seleccionar Producto",
                                prefixIcon: Icon(Icons.shopping_bag, color: AppTheme.primary),
                              ),
                              isExpanded: true,
                              items: productProvider.products.map<DropdownMenuItem<dynamic>>((p) {
                                return DropdownMenuItem<dynamic>(
                                  value: p,
                                  child: Text("${p['nombre']} (${_formatCurrency(double.tryParse(p['precio_neto'].toString()) ?? 0.0)} · Stock: ${p['stock']})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedProduct = val;
                                });
                              },
                            ),
                          ] else ...[
                            // DROPDOWN SERVICIO
                            DropdownButtonFormField<dynamic>(
                              value: _selectedService,
                              decoration: const InputDecoration(
                                labelText: "Seleccionar Servicio",
                                prefixIcon: Icon(Icons.content_cut, color: AppTheme.primary),
                              ),
                              isExpanded: true,
                              items: serviceProvider.services.map<DropdownMenuItem<dynamic>>((s) {
                                return DropdownMenuItem<dynamic>(
                                  value: s,
                                  child: Text("${s['nombre']} (${_formatCurrency(double.tryParse(s['precio_neto'].toString()) ?? 0.0)})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedService = val;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            // DROPDOWN BARBERO
                            DropdownButtonFormField<int>(
                              value: _selectedBarberId,
                              decoration: const InputDecoration(
                                labelText: "Asignar Barbero",
                                prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                              ),
                              isExpanded: true,
                              items: _barbers.map<DropdownMenuItem<int>>((b) {
                                final id = (b['id_barbero'] ?? b['id_usuario'] ?? 1) as int;
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(b['nombre']?.toString() ?? 'Sin nombre'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedBarberId = val;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 14),
                          // CANTIDAD
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _quantityCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Cantidad",
                                    prefixIcon: Icon(Icons.onetwothree, color: AppTheme.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text("Agregar"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ÍTEMS AGREGADOS
                  const Text(
                    "Ítems en la Venta",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  if (_addedItems.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            "No has agregado ningún producto o servicio todavía.",
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._addedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final icon = item['tipo'] == 'servicio' ? Icons.content_cut : Icons.shopping_bag;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(icon, color: AppTheme.primary),
                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Cant: ${item['cantidad']} · Unit: ${_formatCurrency(item['precio_unitario_neto'])}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatCurrency(item['subtotal_item']),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(idx),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 16),

                  // RESUMEN Y BOTÓN GUARDAR
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Subtotal Neto:", style: TextStyle(fontSize: 14)),
                              Text(_formatCurrency(_subtotalNeto), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("IVA total (0%):", style: TextStyle(fontSize: 14)),
                              Text(_formatCurrency(_ivaTotal), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total a Cobrar:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                _formatCurrency(_totalBruto),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saveSale,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 3,
                              ),
                              child: const Text(
                                "REGISTRAR TRANSACCIÓN",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
