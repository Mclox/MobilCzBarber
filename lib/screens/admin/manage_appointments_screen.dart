import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';
import '../../providers/barber_appointment_provider.dart';
import '../client/booking_screen.dart';
import '../../core/whatsapp_helper.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});
  @override
  State<ManageAppointmentsScreen> createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.wait([
      initializeDateFormatting('es_ES', null),
      initializeDateFormatting('es', null),
    ]).then((_) {
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    }).catchError((e) {
      debugPrint("Error initializing date formatting: $e");
    });
    Future.microtask(() => Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments());
  }

  // Obtiene las citas correspondientes a un día específico
  List<dynamic> _getAppointmentsForDay(DateTime day) {
    final provider = Provider.of<BarberAppointmentProvider>(context, listen: false);
    return provider.appointments.where((c) {
      if (c['fecha'] == null) return false;
      try {
        final date = DateTime.parse(c['fecha'].toString());
        return isSameDay(date, day);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // Obtiene los nombres de todos los servicios asociados a una cita
  List<String> _getServiceNames(dynamic c, List<dynamic> allServices) {
    final List<String> names = [];
    if (c['detalles_json'] != null) {
      try {
        dynamic details;
        if (c['detalles_json'] is String) {
          details = jsonDecode(c['detalles_json']);
        } else {
          details = c['detalles_json'];
        }
        if (details != null && details['servicios'] != null) {
          final ids = List<dynamic>.from(details['servicios']);
          for (final id in ids) {
            final s = allServices.firstWhere(
              (x) => (x['id_servicio'] ?? 0).toString() == id.toString(),
              orElse: () => null,
            );
            if (s != null) {
              names.add(s['nombre']?.toString() ?? 'Servicio');
            }
          }
        }
      } catch (e) {
        debugPrint("Error al decodificar detalles_json de servicios: $e");
      }
    }
    if (names.isEmpty) {
      names.add(c['servicio_nombre'] ?? 'Sin servicio');
    }
    return names;
  }

  // Obtiene el precio total calculado para una cita en base a todos sus servicios
  double _calculateTotalPrice(dynamic c, List<dynamic> allServices) {
    double total = 0.0;
    if (c['detalles_json'] != null) {
      try {
        dynamic details;
        if (c['detalles_json'] is String) {
          details = jsonDecode(c['detalles_json']);
        } else {
          details = c['detalles_json'];
        }
        if (details != null && details['servicios'] != null) {
          final ids = List<dynamic>.from(details['servicios']);
          for (final id in ids) {
            final s = allServices.firstWhere(
              (x) => (x['id_servicio'] ?? 0).toString() == id.toString(),
              orElse: () => null,
            );
            if (s != null) {
              total += double.tryParse(s['precio_neto']?.toString() ?? '0') ?? 0.0;
            }
          }
          return total;
        }
      } catch (_) {}
    }
    // Fallback
    return double.tryParse(c['precio_neto']?.toString() ?? '0') ?? 0.0;
  }

  String _formatCurrency(double amount) {
    final valueStr = amount.toStringAsFixed(0);
    return '\$' + valueStr.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr.toString().split('T')[0];
    }
  }

  String _parseTime(dynamic timeStr) {
    if (timeStr == null) return "09:00";
    final s = timeStr.toString();
    if (s.contains('T')) {
      try {
        final timePart = s.split('T')[1]; // "09:00:00.000Z"
        final hhMm = timePart.substring(0, 5); // "09:00"
        return hhMm;
      } catch (_) {
        return "09:00";
      }
    }
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length >= 2) {
        return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
      }
    }
    return s;
  }

  String _calculateHoraFin(String horaInicio) {
    try {
      final parts = horaInicio.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      minute += 30;
      if (minute >= 60) {
        hour += 1;
        minute -= 60;
      }
      return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "10:00";
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.blue;
    }
  }

  // Abre diálogo modal con los detalles de la cita
  void _showAppointmentDetails(dynamic appointment, List<dynamic> allServices) {
    final servicesList = _getServiceNames(appointment, allServices);
    final totalPrice = _calculateTotalPrice(appointment, allServices);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Detalle de Cita", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Cliente: ${appointment['cliente_nombre'] ?? 'Sin nombre'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text("Barbero: ${appointment['barbero_nombre'] ?? 'Sin nombre'}", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text("Fecha: ${_formatDate(appointment['fecha'])}", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text("Hora: ${_parseTime(appointment['hora_inicio'])} - ${_parseTime(appointment['hora_fin'])}", style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              const Divider(),
              const Text("Servicios Agendados:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              ...servicesList.map((sName) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(sName, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )).toList(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Precio Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Estado: ", style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['estado']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (appointment['estado'] ?? 'pendiente').toString().toUpperCase(),
                      style: TextStyle(color: _getStatusColor(appointment['estado']), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.chat, color: Colors.white, size: 16),
            label: const Text("WhatsApp Cliente"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final clientPhone = (appointment['cliente_telefono'] ?? appointment['telefono_cliente'] ?? '').toString();
              final clientName = (appointment['cliente_nombre'] ?? 'Cliente').toString();
              final timeStr = (appointment['hora_inicio'] ?? '09:00').toString();
              final barberName = (appointment['barbero_nombre'] ?? 'Barbero').toString();
              final serviceName = servicesList.isNotEmpty ? servicesList.first : 'Servicio';

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
          ElevatedButton.icon(
            icon: const Icon(Icons.chat, color: Colors.white, size: 16),
            label: const Text("WhatsApp Barbero"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final barberPhone = (appointment['barbero_telefono'] ?? appointment['telefono_barbero'] ?? '').toString();
              final barberName = (appointment['barbero_nombre'] ?? 'Barbero').toString();
              final clientName = (appointment['cliente_nombre'] ?? 'Cliente').toString();
              final timeStr = (appointment['hora_inicio'] ?? '09:00').toString();
              final serviceName = servicesList.isNotEmpty ? servicesList.first : 'Servicio';

              final message = WhatsAppHelper.build30MinBarberReminder(
                barberName: barberName,
                clientName: clientName,
                timeStr: timeStr,
                serviceName: serviceName,
              );

              await WhatsAppHelper.openWhatsApp(
                phone: barberPhone,
                message: message,
                context: context,
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          )
        ],
      ),
    );
  }

  // Selector rápido para cambiar el estado de una cita
  void _openStatusSelector(BarberAppointmentProvider provider, dynamic appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cambiar Estado de la Cita", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.blue),
              title: const Text("Pendiente"),
              onTap: () async {
                await provider.updateAppointmentStatus(appointment['id_cita'], 'pendiente');
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.green),
              title: const Text("Completada"),
              onTap: () async {
                await provider.updateAppointmentStatus(appointment['id_cita'], 'completada');
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text("Cancelada"),
              onTap: () async {
                await provider.updateAppointmentStatus(appointment['id_cita'], 'cancelada');
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BarberAppointmentProvider>(context);
    final dayAppointments = _selectedDay != null ? _getAppointmentsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Agenda de Citas"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
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
          if (mounted) {
            provider.loadAppointments();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Widget Calendario de TableCalendar
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: _localeInitialized ? 'es_ES' : 'en_US', // Configurado localmente con fallback
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getAppointmentsForDay,
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Citas de: ${_selectedDay != null ? DateFormat('dd/MM/yyyy').format(_selectedDay!) : 'Hoy'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Listado de citas de este día
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dayAppointments.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay citas programadas para esta fecha.",
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: dayAppointments.length,
                        itemBuilder: (context, index) {
                          final c = dayAppointments[index];
                          final serviceNames = _getServiceNames(c, provider.servicios);
                          final mainService = serviceNames.isNotEmpty ? serviceNames[0] : 'Sin servicio';
                          final additionalCount = serviceNames.length - 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: ListTile(
                              onTap: () => _showAppointmentDetails(c, provider.servicios),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      additionalCount > 0 ? "$mainService (+ $additionalCount)" : mainService,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(c['estado']).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (c['estado'] ?? 'pendiente').toString().toUpperCase(),
                                      style: TextStyle(color: _getStatusColor(c['estado']), fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  )
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  "Hora: ${_parseTime(c['hora_inicio'])} - ${_parseTime(c['hora_fin'])}\nCliente: ${c['cliente_nombre'] ?? 'Sin nombre'}\nBarbero: ${c['barbero_nombre'] ?? 'Sin nombre'}",
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.change_circle_outlined, color: Colors.teal),
                                    tooltip: "Cambiar Estado",
                                    onPressed: () => _openStatusSelector(provider, c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: "Editar",
                                    onPressed: () => _openForm(provider, appointment: c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Eliminar",
                                    onPressed: () async {
                                      final confirm = await ConfirmationHelper.showDeleteConfirmation(
                                        context: context,
                                        title: "¿Eliminar Cita?",
                                        message: "¿Realmente deseas eliminar la cita del cliente ${c['cliente_nombre']}?",
                                      );
                                      if (confirm) {
                                        await provider.deleteAppointment(c['id_cita']);
                                      }
                                    },
                                  ),
                                ],
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

  // Abre el formulario en modo Creación o Edición
  void _openForm(BarberAppointmentProvider provider, {Map<String, dynamic>? appointment}) {
    int? selectedClientId = appointment?['id_cliente'];
    int? selectedBarberId = appointment?['id_barbero'];
    
    final List<String> timeSlots = ["08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00"];
    String selectedHour = appointment != null ? _parseTime(appointment['hora_inicio']) : "09:00";
    if (!timeSlots.contains(selectedHour)) {
      timeSlots.add(selectedHour);
      timeSlots.sort();
    }

    DateTime selectedDate = appointment?['fecha'] != null 
        ? DateTime.parse(appointment!['fecha'].toString())
        : (_selectedDay ?? DateTime.now());

    // Cargar servicios seleccionados (multiselección)
    final List<int> selectedServiceIds = [];
    if (appointment != null) {
      if (appointment['detalles_json'] != null) {
        try {
          dynamic details;
          if (appointment['detalles_json'] is String) {
            details = jsonDecode(appointment['detalles_json']);
          } else {
            details = appointment['detalles_json'];
          }
          if (details != null && details['servicios'] != null) {
            selectedServiceIds.addAll(List<int>.from(details['servicios']));
          }
        } catch (_) {}
      }
      if (selectedServiceIds.isEmpty && appointment['id_servicio'] != null) {
        selectedServiceIds.add(appointment['id_servicio'] as int);
      }
    } else if (provider.servicios.isNotEmpty) {
      // Por defecto un servicio seleccionado
      selectedServiceIds.add(provider.servicios[0]['id_servicio'] as int);
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModal) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(appointment == null ? "Nueva Cita" : "Editar Cita", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CLIENTE
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Selecciona Cliente"),
                  value: selectedClientId,
                  items: provider.clientes.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                    value: (c['id_cliente'] ?? 0) as int, 
                    child: Text(c['nombre_final']?.toString() ?? 'Sin nombre') 
                  )).toList(),
                  onChanged: (v) => setModal(() => selectedClientId = v),
                ),
                const SizedBox(height: 10),
                // BARBERO
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Selecciona Barbero"),
                  value: selectedBarberId,
                  items: provider.barberos.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(
                    value: (b['id_barbero'] ?? b['id_usuario'] ?? 0) as int, 
                    child: Text(b['nombre']?.toString() ?? 'Sin nombre')
                  )).toList(),
                  onChanged: (v) => setModal(() => selectedBarberId = v),
                ),
                const SizedBox(height: 14),
                // FECHA (Solo lectura, se selecciona desde el calendario principal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Fecha Seleccionada (Calendario)",
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // HORA
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Hora de Inicio"),
                  value: selectedHour,
                  items: timeSlots
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedHour = v!),
                ),
                const SizedBox(height: 16),
                
                // MULTISELECCION DE SERVICIOS
                const Text("Seleccionar Servicios:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: provider.servicios.map<Widget>((s) {
                    final id = s['id_servicio'] as int;
                    final isSelected = selectedServiceIds.contains(id);
                    return FilterChip(
                      label: Text(s['nombre']?.toString() ?? 'Servicio', style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary.withOpacity(0.25),
                      checkmarkColor: AppTheme.primary,
                      onSelected: (selected) {
                        setModal(() {
                          if (selected) {
                            selectedServiceIds.add(id);
                          } else {
                            if (selectedServiceIds.length > 1) {
                              selectedServiceIds.remove(id);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (selectedClientId == null || selectedBarberId == null || selectedServiceIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Por favor completa los campos obligatorios"),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                
                final payload = {
                  "id_cliente": selectedClientId,
                  "id_barbero": selectedBarberId,
                  "id_servicio": selectedServiceIds.first,
                  "fecha": DateFormat('yyyy-MM-dd').format(selectedDate),
                  "hora_inicio": selectedHour,
                  "hora_fin": _calculateHoraFin(selectedHour),
                  "detalles_json": {"servicios": selectedServiceIds}
                };

                bool ok = false;
                if (appointment == null) {
                  ok = await provider.createAppointment(payload);
                } else {
                  ok = await provider.editAppointment(appointment['id_cita'], payload);
                }
                
                if (ok && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      }),
    );
  }
}