import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';
import '../../core/api.dart';

import '../../providers/barber_appointment_provider.dart';
import '../../widgets/profile_tab_widget.dart';

/// Pestaña de Inicio para el Barbero/Empleado
class EmployeeHomeTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const EmployeeHomeTab({super.key, this.onNavigateToTab});

  @override
  State<EmployeeHomeTab> createState() => _EmployeeHomeTabState();
}

class _EmployeeHomeTabState extends State<EmployeeHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appointmentProvider = Provider.of<BarberAppointmentProvider>(context);

    final appointments = appointmentProvider.appointments;
    final isLoading = appointmentProvider.isLoading;

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final todayAppointments = appointments.where((a) {
      final fechaStr = a['fecha']?.toString() ?? '';
      return fechaStr.startsWith(todayStr);
    }).toList();

    final completedAppointments = todayAppointments.where((a) {
      final estado = a['estado']?.toString().toLowerCase() ?? '';
      return estado == 'completada' || estado == 'completado' || estado == 'realizada' || estado == 'realizado' || estado == 'completed';
    }).toList();

    final String citasHoyVal = isLoading ? '...' : todayAppointments.length.toString();
    final String completadasVal = isLoading ? '...' : completedAppointments.length.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ProfileTabWidget.showLogoutConfirmationDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO
              Row(
                children: [
                  _buildAvatarWidget(authProvider.user?.avatarUrl, 35),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, ${authProvider.user?.name ?? 'Barbero'}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "¡Listo para atender clientes!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              // Sección de estadísticas rápidas
              const Text(
                'Resumen de Hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.calendar_today,
                      label: 'Citas Hoy',
                      value: citasHoyVal,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _statCard(
                      icon: Icons.check_circle,
                      label: 'Completadas',
                      value: completadasVal,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Accesos rápidos
              const Text(
                'Accesos Rápidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _quickAccessCard(
                context: context,
                icon: Icons.calendar_month,
                title: 'Ver Agenda Completa',
                subtitle: 'Revisa todas tus citas programadas',
                onTap: () {
                  // Navegar a la pestaña de Agenda (índice 1)
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(1);
                  }
                },
              ),

              const SizedBox(height: 12),

              _quickAccessCard(
                context: context,
                icon: Icons.access_time,
                title: 'Configurar Disponibilidad',
                subtitle: 'Ajusta tus horarios de trabajo',
                onTap: () {
                  // Navegar a la pestaña de Disponibilidad (índice 2)
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2);
                  }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 🖼️ Construir avatar del usuario (Base64 o URL de red)
  Widget _buildAvatarWidget(String? avatarUrl, double radius) {
    ImageProvider? imageProvider;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final base64Str = avatarUrl.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64Str));
        } catch (_) {
          imageProvider = null;
        }
      } else if (avatarUrl.startsWith('http')) {
        imageProvider = NetworkImage(avatarUrl);
      } else {
        String cleanPath = avatarUrl.replaceAll('\\', '/');
        if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
        final serverUrl = Api.baseUrl.replaceAll('/api', '');
        imageProvider = NetworkImage('$serverUrl/$cleanPath');
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primary.withOpacity(0.15),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(Icons.person, size: radius * 1.1, color: AppTheme.primary)
          : null,
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _quickAccessCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
