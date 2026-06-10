import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/barber_appointment_provider.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});
  @override
  State<ManageAppointmentsScreen> createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BarberAppointmentProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Citas"), backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _openForm(provider),
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.appointments.length,
            itemBuilder: (_, index) {
              final c = provider.appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  title: Text(c['servicio_nombre'] ?? 'Sin servicio', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${c['fecha']?.toString().split('T')[0] ?? 'Sin fecha'} · ${c['hora_inicio'] ?? ''}\nCliente: ${c['cliente_nombre'] ?? 'Sin nombre'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => provider.deleteAppointment(c['id_cita']),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _openForm(BarberAppointmentProvider provider) {
    int? selectedBarberId;
    int? selectedClientId;
    int? selectedServiceId;
    
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModal) {
        return AlertDialog(
          title: const Text("Nueva Cita"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Selecciona Cliente"),
                  items: provider.clientes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                  value: (c['id_cliente'] ?? 0) as int, 
                  // Ahora usamos 'nombre_final' tal cual lo envía tu backend:
                  child: Text(c['nombre_final']?.toString() ?? 'Sin nombre') 
                  )).toList(),
                  onChanged: (v) => setModal(() => selectedClientId = v),
                ),
                // DROPDOWN BARBEROS
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Selecciona Barbero"),
                  items: provider.barberos.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(
                    value: (b['id_barbero'] ?? b['id_usuario'] ?? 0) as int, 
                    child: Text(b['nombre']?.toString() ?? 'Sin nombre')
                  )).toList(),
                  onChanged: (v) => setModal(() => selectedBarberId = v),
                ),
                // DROPDOWN SERVICIOS
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Selecciona Servicio"),
                  items: provider.servicios.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                    value: (s['id_servicio'] ?? 0) as int, 
                    child: Text(s['nombre']?.toString() ?? 'Sin servicio')
                  )).toList(),
                  onChanged: (v) => setModal(() => selectedServiceId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (selectedClientId == null || selectedServiceId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor completa los campos"), backgroundColor: Colors.red));
                  return;
                }
                
                // Corrección de sintaxis en el JSON de envío
                await provider.createAppointment({
                  "id_cliente": selectedClientId,
                  "id_barbero": selectedBarberId ?? 1,
                  "id_servicio": selectedServiceId,
                  "fecha": DateTime.now().toIso8601String(),
                  "hora_inicio": "09:00",
                  "hora_fin": "10:00"
                });
                
                if(mounted) Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      }),
    );
  }
}