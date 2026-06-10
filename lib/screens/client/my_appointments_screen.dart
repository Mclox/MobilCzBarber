import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';
import '../../providers/auth_provider.dart';
import 'modify_appointment_screen.dart';

/// Pantalla para gestionar citas pasadas y futuras
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - en producción vendría de un provider/API
  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'id': 1,
      'service': 'Corte de Cabello',
      'barber': 'Carlos Rodríguez',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '10:00',
      'price': 15,
      'status': 'confirmed',
    },
    {
      'id': 2,
      'service': 'Afeitado Premium',
      'barber': 'María González',
      'date': DateTime.now().add(const Duration(days: 5)),
      'time': '14:30',
      'price': 10,
      'status': 'confirmed',
    },
    {
      'id': 3,
      'service': 'Tratamiento Capilar',
      'barber': 'Juan Pérez',
      'date': DateTime.now().add(const Duration(days: 7)),
      'time': '16:00',
      'price': 20,
      'status': 'pending',
    },
  ];

  final List<Map<String, dynamic>> _pastAppointments = [
    {
      'id': 4,
      'service': 'Corte de Cabello',
      'barber': 'Ana Martínez',
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'time': '11:00',
      'price': 15,
      'status': 'completed',
    },
    {
      'id': 5,
      'service': 'Afeitado Premium',
      'barber': 'Carlos Rodríguez',
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'time': '15:00',
      'price': 10,
      'status': 'completed',
    },
    {
      'id': 6,
      'service': 'Corte + Afeitado',
      'barber': 'María González',
      'date': DateTime.now().subtract(const Duration(days: 45)),
      'time': '10:30',
      'price': 22,
      'status': 'completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingAppointments(),
          _buildPastAppointments(),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'No tienes citas programadas',
        subtitle: '¡Reserva tu próxima cita ahora!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _upcomingAppointments[index];
        return _buildAppointmentCard(appointment, isUpcoming: true);
      },
    );
  }

  Widget _buildPastAppointments() {
    if (_pastAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No tienes historial de citas',
        subtitle: 'Tus citas pasadas aparecerán aquí',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _pastAppointments[index];
        return _buildAppointmentCard(appointment, isUpcoming: false);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment,
      {required bool isUpcoming}) {
    final date = appointment['date'] as DateTime;
    final status = appointment['status'] as String;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Confirmada';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completada';
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelada';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help;
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
                  '${date.day}/${date.month}/${date.year}',
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
                            appointment['service'],
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
                              Text(
                                appointment['barber'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                                appointment['time'],
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
                      '\$${appointment['price']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),

                // Botones de acción (solo para citas próximas)
                if (isUpcoming && status != 'cancelled') ...[
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
                ],

                // Botón de reseña (solo para citas completadas)
                if (!isUpcoming && status == 'completed') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
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

  void _modifyAppointment(Map<String, dynamic> appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyAppointmentScreen(appointment: appointment),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        appointment['date'] = result['date'];
        appointment['time'] = result['time'];
        appointment['barber'] = result['barber'];
        // Cambiamos el estado de pending/confirmed a pending por si requiere re-confirmación, 
        // o lo dejamos igual. Asumiremos que se mantiene confirmado o pendiente.
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelAppointment(Map<String, dynamic> appointment) async {
    debugPrint('MyAppointmentsScreen: Intentando cancelar cita - ${appointment['service']}');
    final confirm = await ConfirmationHelper.showDeleteConfirmation(
      context: context,
      title: 'Cancelar Cita',
      message: '¿Estás seguro de que deseas cancelar tu cita de ${appointment['service']} '
          'el ${(appointment['date'] as DateTime).day}/${(appointment['date'] as DateTime).month}?',
    );
    debugPrint('MyAppointmentsScreen: Resultado confirmación: $confirm');

    if (confirm) {
      setState(() {
        appointment['status'] = 'cancelled';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita cancelada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rateAppointment(Map<String, dynamic> appointment) {
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
                  '¿Cómo fue tu experiencia con ${appointment['barber']}?',
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
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gracias por tu calificación de $rating estrellas'),
                            backgroundColor: Colors.green,
                          ),
                        );
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
}
