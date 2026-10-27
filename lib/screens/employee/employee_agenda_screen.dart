import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barber_appointment_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';
import '../client/booking_screen.dart';
import '../../core/whatsapp_helper.dart';
import 'employee_main_screen.dart';
import 'package:go_router/go_router.dart';
import '../../providers/barber_availability_provider.dart';
import '../../providers/auth_provider.dart';

class EmployeeAgendaScreen extends StatefulWidget {
  const EmployeeAgendaScreen({super.key});

  @override
  State<EmployeeAgendaScreen> createState() => _EmployeeAgendaScreenState();
}

class _EmployeeAgendaScreenState extends State<EmployeeAgendaScreen> {

  // Formatea fecha en YYYY-MM-DD sin alterar por zona horaria
  String _formatCitaFechaClean(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.contains('T')) return str.split('T')[0];
    if (str.contains(' ')) return str.split(' ')[0];
    return str;
  }

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments();
  }

  Color _getStatusColor(String? estado) {
    switch ((estado ?? '').toLowerCase()) {
      case 'confirmada':
      case 'confirmado':
        return Colors.blue;
      case 'en ejecución':
      case 'en ejecucion':
      case 'en_ejecucion':
        return Colors.orange;
      case 'completada':
      case 'completado':
        return Colors.green;
      case 'cancelada':
      case 'cancelado':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.amber;
    }
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return "Lunes";
      case DateTime.tuesday: return "Martes";
      case DateTime.wednesday: return "Miércoles";
      case DateTime.thursday: return "Jueves";
      case DateTime.friday: return "Viernes";
      case DateTime.saturday: return "Sábado";
      case DateTime.sunday: return "Domingo";
      default: return "";
    }
  }

  void _showAppointmentDetails(BuildContext context, dynamic a, BarberAppointmentProvider provider) {
    final estadoStr = (a['estado'] ?? 'pendiente').toString();
    final clientPhone = (a['cliente_telefono'] ?? a['telefono_cliente'] ?? 'Sin teléfono').toString();
    final clientName = (a['cliente_nombre'] ?? 'Cliente').toString();
    final barberName = (a['barbero_nombre'] ?? 'Barbero').toString();
    final serviceName = (a['servicio_nombre'] ?? 'Servicio').toString();
    final fechaStr = (a['fecha'] ?? '').toString();
    final horaStr = "${a['hora_inicio'] ?? ''} ${a['hora_fin'] != null ? '- ${a['hora_fin']}' : ''}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cita #${a['id_cita']}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(estadoStr).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estadoStr.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(estadoStr),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 25),
              _detailRow(Icons.person, "Cliente", clientName),
              _detailRow(Icons.phone, "Teléfono", clientPhone),
              _detailRow(Icons.content_cut, "Servicio", serviceName),
              _detailRow(Icons.calendar_today, "Fecha", fechaStr),
              _detailRow(Icons.access_time, "Horario", horaStr),
              _detailRow(Icons.badge, "Barbero", barberName),
              const SizedBox(height: 20),
              const Text(
                "Cambiar Estado de la Cita:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusButton(context, a['id_cita'], 'pendiente', 'Pendiente', Colors.amber, provider),
                  _statusButton(context, a['id_cita'], 'confirmada', 'Confirmada', Colors.blue, provider),
                  _statusButton(context, a['id_cita'], 'en ejecución', 'En ejecución', Colors.orange, provider),
                  _statusButton(context, a['id_cita'], 'completada', 'Completada', Colors.green, provider),
                  _statusButton(context, a['id_cita'], 'cancelada', 'Cancelada', Colors.red, provider),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    int appointmentId,
    String statusKey,
    String label,
    Color color,
    BarberAppointmentProvider provider,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        final success = await provider.updateAppointmentStatus(appointmentId, statusKey);
        if (context.mounted) {
          Navigator.pop(context); // Cierra bottom sheet
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Estado de la cita actualizado correctamente"),
                backgroundColor: Colors.green,
              ),
            );
            
            // Redirigir al inicio de forma fluida
            final mainScreen = context.findAncestorStateOfType<EmployeeMainScreenState>();
            if (mainScreen != null) {
              mainScreen.selectTab(0);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go("/employee/home");
            }
          }
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BarberAppointmentProvider>(context);
    final appointments = provider.appointments;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Agenda del Día"),
        backgroundColor: AppTheme.primary,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingScreen(),
            ),
          );
          _loadAppointments();
        },
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
                        final estadoStr = (a['estado'] ?? 'pendiente').toString();
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () => _showAppointmentDetails(context, a, provider),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _getStatusColor(estadoStr).withOpacity(0.2),
                                        child: Icon(Icons.content_cut, color: _getStatusColor(estadoStr)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a['servicio_nombre'] ?? 'Servicio',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Hora: ${a['hora_inicio']} | Cliente: ${a['cliente_nombre'] ?? 'N/A'}",
                                              style: const TextStyle(color: Colors.black87),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(estadoStr).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "Estado: $estadoStr".toUpperCase(),
                                                style: TextStyle(
                                                  color: _getStatusColor(estadoStr),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20, thickness: 0.5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: AppTheme.primary),
                                        tooltip: "Ver detalle",
                                        onPressed: () => _showAppointmentDetails(context, a, provider),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: "Editar cita",
                                        onPressed: () => _openAppointmentForm(appointment: a),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                                        tooltip: "Enviar Recordatorio WhatsApp",
                                        onPressed: () async {
                                          final clientPhone = (a['cliente_telefono'] ?? a['telefono_cliente'] ?? '').toString();
                                          final clientName = (a['cliente_nombre'] ?? 'Cliente').toString();
                                          final barberName = (a['barbero_nombre'] ?? 'Barbero').toString();
                                          final timeStr = (a['hora_inicio'] ?? '09:00').toString();
                                          final serviceName = (a['servicio_nombre'] ?? 'Servicio').toString();

                                          final message = WhatsAppHelper.build30MinClientReminder(
                                            clientName: clientName,
                                            timeStr: timeStr,
                                            serviceName: serviceName,
                                            barberName: barberName,
                                          );

                                          await WhatsAppHelper.openWhatsApp(
                                            phone: clientPhone,
                                            message: message,
                                            context: context,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: "Eliminar",
                                        onPressed: () async {
                                          final confirm = await ConfirmationHelper.showDeleteConfirmation(context: context);
                                          if (confirm) {
                                            await provider.deleteAppointment(a['id_cita']);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Cita eliminada correctamente"),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                              
                                              // Redirigir al inicio de forma fluida
                                              final mainScreen = context.findAncestorStateOfType<EmployeeMainScreenState>();
                                              if (mainScreen != null) {
                                                mainScreen.selectTab(0);
                                              } else if (Navigator.canPop(context)) {
                                                Navigator.pop(context);
                                              } else {
                                                context.go("/employee/home");
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  void _openAppointmentForm({dynamic appointment}) {
    final provider = Provider.of<BarberAppointmentProvider>(context, listen: false);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    int? selectedClientId = appointment != null ? (appointment['id_cliente'] as int?) : null;
    int? selectedServiceId = appointment != null ? (appointment['id_servicio'] as int?) : null;
    int? selectedBarberId = appointment != null ? (appointment['id_barbero'] as int?) : null;

    if (selectedClientId == null && provider.clientes.isNotEmpty) {
      selectedClientId = (provider.clientes.first['id_cliente'] ?? provider.clientes.first['id_usuario']) as int?;
    }
    if (selectedServiceId == null && provider.servicios.isNotEmpty) {
      selectedServiceId = (provider.servicios.first['id_servicio'] ?? provider.servicios.first['id']) as int?;
    }
    if (selectedBarberId == null && provider.barberos.isNotEmpty) {
      final currentUserId = auth.user?.id?.toString();
      final myBarber = provider.barberos.firstWhere(
        (b) => (b['id_usuario']?.toString() == currentUserId) ||
               (b['id_barbero']?.toString() == currentUserId) ||
               (b['id_empleado']?.toString() == currentUserId),
        orElse: () => provider.barberos.first,
      );
      selectedBarberId = (myBarber['id_barbero'] ?? myBarber['id_usuario'] ?? myBarber['id_empleado'] ?? 1) as int?;
    }

    DateTime formDate = selectedDate;
    if (appointment != null && appointment['fecha'] != null) {
      try {
        formDate = DateTime.parse(appointment['fecha'].toString());
      } catch (_) {}
    }

    String selectedTime = (appointment != null && appointment['hora_inicio'] != null)
        ? appointment['hora_inicio'].toString()
        : '09:00';

    String selectedEstado = (appointment != null && appointment['estado'] != null)
        ? appointment['estado'].toString().toLowerCase()
        : 'pendiente';

    final List<String> availableTimes = [
      "08:00", "08:30", "09:00", "09:30", "10:00", "10:30",
      "11:00", "11:30", "12:00", "12:30", "13:00", "13:30",
      "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
      "17:00", "17:30", "18:00", "18:30", "19:00", "19:30",
      "20:00", "20:30", "21:00", "21:30", "22:00"
    ];

    if (!availableTimes.contains(selectedTime)) {
      availableTimes.add(selectedTime);
      availableTimes.sort();
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          // Generar listas únicas y seguras para los selectores
          final clientItems = <DropdownMenuItem<int>>[];
          final seenClientIds = <int>{};
          for (final c in provider.clientes) {
            final int id = (c['id_cliente'] ?? c['id_usuario'] ?? 0) as int;
            if (id != 0 && !seenClientIds.contains(id)) {
              seenClientIds.add(id);
              final String displayName = c['nombre_final'] ?? c['nombre'] ?? c['name'] ?? c['nombre_completo'] ?? 'Cliente #$id';
              clientItems.add(DropdownMenuItem(value: id, child: Text(displayName)));
            }
          }

          final serviceItems = <DropdownMenuItem<int>>[];
          final seenServiceIds = <int>{};
          for (final s in provider.servicios) {
            final int id = (s['id_servicio'] ?? s['id'] ?? 0) as int;
            if (id != 0 && !seenServiceIds.contains(id)) {
              seenServiceIds.add(id);
              serviceItems.add(DropdownMenuItem(
                value: id,
                child: Text("${s['nombre']} (\$${s['precio_neto'] ?? 0})"),
              ));
            }
          }

          final barberItems = <DropdownMenuItem<int>>[];
          final seenBarberIds = <int>{};
          for (final b in provider.barberos) {
            final int id = (b['id_barbero'] ?? b['id_usuario'] ?? b['id_empleado'] ?? 0) as int;
            if (id != 0 && !seenBarberIds.contains(id)) {
              seenBarberIds.add(id);
              barberItems.add(DropdownMenuItem(
                value: id,
                child: Text(b['nombre'] ?? 'Barbero #$id'),
              ));
            }
          }

          final effectiveClientId = seenClientIds.contains(selectedClientId) ? selectedClientId : (seenClientIds.isNotEmpty ? seenClientIds.first : null);
          final effectiveServiceId = seenServiceIds.contains(selectedServiceId) ? selectedServiceId : (seenServiceIds.isNotEmpty ? seenServiceIds.first : null);
          final effectiveBarberId = seenBarberIds.contains(selectedBarberId) ? selectedBarberId : (seenBarberIds.isNotEmpty ? seenBarberIds.first : null);

          return AlertDialog(
            title: Text(appointment == null ? "Nueva Cita" : "Editar Cita"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Selector de Cliente
                  DropdownButtonFormField<int>(
                    value: effectiveClientId,
                    decoration: const InputDecoration(
                      labelText: "Cliente",
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: clientItems,
                    onChanged: (v) => setModal(() => selectedClientId = v),
                  ),
                  const SizedBox(height: 12),

                  // 2. Selector de Servicio
                  DropdownButtonFormField<int>(
                    value: effectiveServiceId,
                    decoration: const InputDecoration(
                      labelText: "Servicio",
                      prefixIcon: Icon(Icons.content_cut),
                    ),
                    items: serviceItems,
                    onChanged: (v) => setModal(() => selectedServiceId = v),
                  ),
                  const SizedBox(height: 12),

                  // 3. Selector de Barbero
                  DropdownButtonFormField<int>(
                    value: effectiveBarberId,
                    decoration: const InputDecoration(
                      labelText: "Barbero Asignado",
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: barberItems,
                    onChanged: (v) => setModal(() => selectedBarberId = v),
                  ),
                  const SizedBox(height: 12),

                  // 4. Selector de Fecha
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: formDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModal(() => formDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Fecha de la Cita",
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        "${formDate.year}-${formDate.month.toString().padLeft(2, '0')}-${formDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Selector de Hora Inicio
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: const InputDecoration(
                      labelText: "Hora de Inicio",
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    items: availableTimes.map<DropdownMenuItem<String>>((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setModal(() => selectedTime = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 6. Selector de Estado
                  DropdownButtonFormField<String>(
                    value: selectedEstado,
                    decoration: const InputDecoration(
                      labelText: "Estado de la Cita",
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
                      DropdownMenuItem(value: 'en ejecución', child: Text('En ejecución')),
                      DropdownMenuItem(value: 'completada', child: Text('Completada')),
                      DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => selectedEstado = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (selectedClientId == null || selectedServiceId == null) return;

                  final serviceObj = provider.servicios.firstWhere(
                    (s) => s['id_servicio'] == selectedServiceId,
                    orElse: () => null,
                  );
                  final int duration = (serviceObj != null ? (serviceObj['duracion_minutos'] ?? 30) : 30).toInt();

                  // 1. Validar y auto-extender disponibilidad si es necesario
                  final availabilityProvider = Provider.of<BarberAvailabilityProvider>(context, listen: false);
                  final dayName = _getDayName(formDate);
                  bool availabilityChanged = false;
                  
                  if (availabilityProvider.availability[dayName] == false) {
                    availabilityProvider.toggleDay(dayName, true);
                    availabilityChanged = true;
                  }
                  
                  final timeParts = selectedTime.split(':');
                  final hStart = int.tryParse(timeParts[0]) ?? 9;
                  final mStart = int.tryParse(timeParts.length > 1 ? timeParts[1] : '00') ?? 0;
                  final selectedStart = TimeOfDay(hour: hStart, minute: mStart);
                  
                  final startMins = selectedStart.hour * 60 + selectedStart.minute;
                  final currentStartMins = availabilityProvider.startTime.hour * 60 + availabilityProvider.startTime.minute;
                  if (startMins < currentStartMins) {
                    availabilityProvider.setStartTime(selectedStart);
                    availabilityChanged = true;
                  }
                  
                  final endMins = startMins + duration;
                  final currentEndMins = availabilityProvider.endTime.hour * 60 + availabilityProvider.endTime.minute;
                  if (endMins > currentEndMins) {
                    int endHour = endMins ~/ 60;
                    int endMin = (endMins % 60).toInt();
                    if (endHour >= 24) {
                      endHour = 23;
                      endMin = 59;
                    }
                    availabilityProvider.setEndTime(TimeOfDay(hour: endHour, minute: endMin));
                    availabilityChanged = true;
                  }
                  
                  if (availabilityChanged) {
                    await availabilityProvider.saveAvailability();
                  }

                  // 2. Guardar Cita
                  final dateStr = "${formDate.year}-${formDate.month.toString().padLeft(2, '0')}-${formDate.day.toString().padLeft(2, '0')}";

                  final parts = selectedTime.split(':');
                  int h = int.tryParse(parts[0]) ?? 9;
                  int m = (int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0) + duration;
                  if (m >= 60) {
                    h += 1;
                    m -= 60;
                  }
                  final endTimeStr = "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";

                  final data = {
                    "id_cliente": selectedClientId,
                    "id_barbero": selectedBarberId ?? 1,
                    "id_servicio": selectedServiceId,
                    "fecha": dateStr,
                    "hora_inicio": selectedTime,
                    "hora_fin": endTimeStr,
                    "estado": selectedEstado,
                    "detalles_json": {
                      "servicios": [
                        {
                          "id_servicio": selectedServiceId,
                          "nombre": serviceObj != null ? serviceObj['nombre'] : 'Servicio',
                          "precio": serviceObj != null ? (double.tryParse(serviceObj['precio_neto']?.toString() ?? '0') ?? 0) : 0,
                          "cantidad": 1
                        }
                      ],
                      "productos": []
                    }
                  };

                  bool success = false;
                  if (appointment != null) {
                    success = await provider.editAppointment(appointment['id_cita'], data);
                  } else {
                    success = await provider.createAppointment(data);
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Cierra modal
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(appointment != null ? "Cita editada correctamente" : "Cita creada correctamente"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Redirigir al inicio de forma fluida
                      final mainScreen = context.findAncestorStateOfType<EmployeeMainScreenState>();
                      if (mainScreen != null) {
                        mainScreen.selectTab(0);
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go("/employee/home");
                      }
                    }
                  }
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