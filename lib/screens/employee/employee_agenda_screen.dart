import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barber_appointment_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';

class EmployeeAgendaScreen extends StatefulWidget {
  const EmployeeAgendaScreen({super.key});

  @override
  State<EmployeeAgendaScreen> createState() => _EmployeeAgendaScreenState();
}

class _EmployeeAgendaScreenState extends State<EmployeeAgendaScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    // Llamamos al provider para que cargue los datos reales de la BD
    Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BarberAppointmentProvider>(context);
    // Ahora 'appointments' contiene los datos de tu SQL Server
    final appointments = provider.appointments;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Agenda del Día"),
        backgroundColor: AppTheme.primary,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _openAddAppointmentForm,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _dateSelector(),
          const SizedBox(height: 15),
          if (provider.isLoading)
            const Expanded(child: LoadingWidget()),
          if (!provider.isLoading)
            Expanded(
              child: appointments.isEmpty
                  ? const Center(
                      child: Text(
                        "No tienes citas asignadas hoy.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final a = appointments[index];
                        // Usamos los campos que vienen del JSON del backend
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(a['servicio_nombre'] ?? 'Servicio'),
                            subtitle: Text(
                                "Hora: ${a['hora_inicio']}\nCliente: ${a['cliente_nombre'] ?? 'N/A'}\nEstado: ${a['estado']}"),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await ConfirmationHelper.showDeleteConfirmation(context: context);
                                if (confirm) {
                                  provider.deleteAppointment(a['id_cita']);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _dateSelector() {
    return GestureDetector(
      onTap: () async {
        final newDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (newDate != null) {
          setState(() => selectedDate = newDate);
          _loadAppointments();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const Icon(Icons.edit_calendar, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _openAddAppointmentForm() => _openAppointmentForm();

  void _openAppointmentForm({dynamic appointment}) {
    // Usamos variables locales para manejar el estado del formulario
    int? selectedBarberId = appointment != null ? appointment['id_barbero'] : null;
    int? selectedClientId = appointment != null ? appointment['id_cliente'] : null;
    int? selectedServiceId = appointment != null ? appointment['id_servicio'] : null;
    
    final provider = Provider.of<BarberAppointmentProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          return AlertDialog(
            title: Text(appointment == null ? "Nueva Cita" : "Editar Cita"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedClientId,
                    decoration: const InputDecoration(labelText: "Selecciona Cliente"),
                    items: provider.clientes.map<DropdownMenuItem<int>>((c) {
                      final String displayName = c['nombre'] ?? c['name'] ?? c['nombre_completo'] ?? 'Sin nombre';
                      return DropdownMenuItem(
                        value: (c['id_cliente'] ?? 0) as int,
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: (v) => setModal(() => selectedClientId = v),
                  ),
                  const SizedBox(height: 10),
                  // DROPDOWN SERVICIOS REALES
                  DropdownButtonFormField<int>(
                    value: selectedServiceId,
                    decoration: const InputDecoration(labelText: "Selecciona Servicio"),
                    items: provider.servicios.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                      value: s['id_servicio'] as int,
                      child: Text(s['nombre']),
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
                  if (selectedClientId == null || selectedServiceId == null) return;

                  final data = {
                    "id_cliente": selectedClientId,
                    "id_barbero": 1, // ID fijo o selector
                    "id_servicio": selectedServiceId,
                    "fecha": selectedDate.toIso8601String(),
                    "hora_inicio": "09:00",
                    "hora_fin": "10:00"
                  };

                  await provider.createAppointment(data);
                  Navigator.pop(context);
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      ),
    );
  }
}