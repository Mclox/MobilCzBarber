import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import 'modify_appointment_screen.dart';
import '../../core/whatsapp_helper.dart';

/// Pantalla para gestionar citas pasadas y futuras del cliente conectada al backend real
class MyAppointmentsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MyAppointmentsScreen({super.key, this.onBack});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();
  
  List<dynamic> _allAppointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final list = await _appointmentService.getAll();
      setState(() {
        _allAppointments = list;
      });
    } catch (e) {
      debugPrint("Error loading client appointments: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _upcomingAppointments {
    return _allAppointments.where((a) {
      final status = (a['estado'] ?? 'pendiente').toString().toLowerCase();
      return status == 'pendiente' || 
             status == 'confirmado' || 
             status == 'en ejecución' || 
             status == 'en ejecucion' ||
             status == 'pending' ||
             status == 'confirmed';
    }).toList();
  }

  List<dynamic> get _pastAppointments {
    return _allAppointments.where((a) {
      final status = (a['estado'] ?? 'pendiente').toString().toLowerCase();
      return status == 'completada' || 
             status == 'completado' || 
             status == 'cancelada' || 
             status == 'cancelado' ||
             status == 'completed' ||
             status == 'cancelled';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else if (widget.onBack != null) {
              widget.onBack!();
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Próximas', icon: Icon(Icons.upcoming)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingAppointments(),
                _buildPastAppointments(),
              ],
            ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final list = _upcomingAppointments;
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'No tienes citas programadas',
        subtitle: '¡Reserva tu próxima cita ahora!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final appointment = list[index];
          return _buildAppointmentCard(appointment, isUpcoming: true);
        },
      ),
    );
  }

  Widget _buildPastAppointments() {
    final list = _pastAppointments;
    if (list.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No tienes historial de citas',
        subtitle: 'Tus citas pasadas aparecerán aquí',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final appointment = list[index];
          return _buildAppointmentCard(appointment, isUpcoming: false);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment, {required bool isUpcoming}) {
    final DateTime date = appointment['fecha'] != null 
        ? DateTime.parse(appointment['fecha'].toString())
        : DateTime.now();
    final status = (appointment['estado'] ?? 'pendiente').toString().toLowerCase();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'confirmada':
      case 'confirmado':
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Confirmada';
        statusIcon = Icons.check_circle;
        break;
      case 'pendiente':
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        statusIcon = Icons.schedule;
        break;
      case 'en ejecución':
      case 'en ejecucion':
      case 'in_progress':
        statusColor = Colors.teal;
        statusText = 'En Ejecución';
        statusIcon = Icons.play_circle_fill_outlined;
        break;
      case 'completada':
      case 'completado':
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completada';
        statusIcon = Icons.done_all;
        break;
      case 'cancelada':
      case 'cancelado':
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelada';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status.toUpperCase();
        statusIcon = Icons.help;
    }

    // Obtener detalles del servicio
    final serviceName = appointment['servicio_nombre'] ?? 'Servicio';
    final barberName = appointment['barbero_nombre'] ?? 'Sin barbero asignado';
    final timeStr = appointment['hora_inicio'] ?? '09:00';
    final priceStr = appointment['precio_neto'] ?? '0';

    // Resolver rating de calificacion en detalles_json
    int? currentRating;
    if (appointment['detalles_json'] != null) {
      try {
        dynamic details;
        if (appointment['detalles_json'] is String) {
          details = jsonDecode(appointment['detalles_json']);
        } else {
          details = appointment['detalles_json'];
        }
        if (details != null && details['calificacion'] != null) {
          currentRating = int.tryParse(details['calificacion'].toString());
        }
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  barberName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${double.tryParse(priceStr.toString())?.toStringAsFixed(0) ?? priceStr}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),

                // Botones de acción (solo para citas próximas)
                if (isUpcoming && status != 'cancelada' && status != 'cancelado' && status != 'cancelled') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _modifyAppointment(appointment),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Modificar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelAppointment(appointment),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final barberPhone = (appointment['barbero_telefono'] ?? appointment['telefono_barbero'] ?? '').toString();
                      final barberName = (appointment['barbero_nombre'] ?? 'Barbero').toString();
                      final clientName = (appointment['cliente_nombre'] ?? 'Cliente').toString();
                      final timeStr = (appointment['hora_inicio'] ?? '09:00').toString();
                      final serviceName = (appointment['servicio_nombre'] ?? 'Servicio').toString();

                      final message = WhatsAppHelper.build30MinClientReminder(
                        clientName: clientName,
                        timeStr: timeStr,
                        serviceName: serviceName,
                        barberName: barberName,
                      );

                      await WhatsAppHelper.openWhatsApp(
                        phone: barberPhone,
                        message: message,
                        context: context,
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                    label: const Text('Recordatorio WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ],

                // Botón de reseña (solo para citas completadas/historial)
                if (!isUpcoming && (status == 'completada' || status == 'completado' || status == 'completed')) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  currentRating != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tu calificación: ', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < currentRating! ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _rateAppointment(appointment),
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text('Dejar Reseña'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _modifyAppointment(dynamic appointment) async {
    DateTime parsedDate;
    if (appointment['fecha'] != null) {
      if (appointment['fecha'] is DateTime) {
        parsedDate = appointment['fecha'];
      } else {
        try {
          parsedDate = DateTime.parse(appointment['fecha'].toString());
        } catch (_) {
          parsedDate = DateTime.now();
        }
      }
    } else {
      parsedDate = DateTime.now();
    }

    final Map<String, dynamic> appointmentMap = {
      'id': appointment['id_cita'] ?? appointment['id'],
      'id_cita': appointment['id_cita'] ?? appointment['id'],
      'id_cliente': appointment['id_cliente'],
      'id_barbero': appointment['id_barbero'],
      'id_servicio': appointment['id_servicio'],
      'service': appointment['servicio_nombre'] ?? appointment['servicio'] ?? 'Servicio',
      'barber': appointment['barbero_nombre'] ?? appointment['barbero'] ?? 'Sin barbero',
      'date': parsedDate,
      'time': (appointment['hora_inicio'] ?? appointment['hora'] ?? '09:00').toString(),
      'price': appointment['precio_neto'] ?? appointment['precio'] ?? 0,
      'status': appointment['estado'] ?? 'pendiente',
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyAppointmentScreen(appointment: appointmentMap),
      ),
    );

    if (result == true && mounted) {
      _loadAppointments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelAppointment(dynamic appointment) async {
    final confirm = await ConfirmationHelper.showDeleteConfirmation(
      context: context,
      title: 'Cancelar Cita',
      message: '¿Estás seguro de que deseas cancelar tu cita del '
          '${appointment['fecha'].toString().split('T')[0]} a las ${appointment['hora_inicio']}?',
    );

    if (confirm) {
      final success = await _appointmentService.updateStatus(appointment['id_cita'], 'cancelada');
      if (success && mounted) {
        _loadAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada con éxito'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cancelar la cita. Inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rateAppointment(dynamic appointment) {
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Calificar Servicio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Cómo fue tu experiencia con ${appointment['barbero_nombre'] ?? 'tu barbero'}?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: rating > 0
                    ? () async {
                        Navigator.pop(context);
                        _submitRating(appointment, rating);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enviar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitRating(dynamic appointment, int rating) async {
    setState(() => _isLoading = true);
    
    // Parsear detalles_json original
    dynamic details;
    if (appointment['detalles_json'] != null) {
      if (appointment['detalles_json'] is String) {
        try {
          details = jsonDecode(appointment['detalles_json']);
        } catch (_) {
          details = {};
        }
      } else {
        details = Map<String, dynamic>.from(appointment['detalles_json']);
      }
    } else {
      details = {};
    }
    
    // Guardar la calificacion dentro de detalles_json
    details['calificacion'] = rating;
    
    final Map<String, dynamic> data = {
      'id_cliente': appointment['id_cliente'],
      'id_barbero': appointment['id_barbero'],
      'id_servicio': appointment['id_servicio'],
      'fecha': appointment['fecha'],
      'hora_inicio': appointment['hora_inicio'],
      'hora_fin': appointment['hora_fin'] ?? appointment['hora_inicio'],
      'estado': appointment['estado'],
      'detalles_json': details,
    };
    
    final success = await _appointmentService.update(appointment['id_cita'], data);
    
    if (success && mounted) {
      await _loadAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gracias por tu calificación de $rating estrellas'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la calificación. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
