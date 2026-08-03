import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/service_provider.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<ServiceProvider>(context, listen: false).loadServices());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServiceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Servicios"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppTheme.primary,
      //   child: const Icon(Icons.add),
      //   onPressed: () => _openServiceForm(provider),
      // ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.services.length,
              itemBuilder: (_, index) {
                final service = provider.services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.content_cut),
                    title: Text(service['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("\$${service['precio_neto']} · ${service['duracion_minutos']} min"),
                  ),
                );
              },
            ),
    );
  }

  void _openServiceForm(ServiceProvider provider) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final duracionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo Servicio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Precio")),
            TextField(controller: duracionCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Duración (min)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
              await provider.createService({
                "nombre": nameCtrl.text,
                "precio_neto": double.parse(priceCtrl.text),
                "duracion_minutos": int.parse(duracionCtrl.text),
                "iva_porcentaje": 0
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}