import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/barber_appointment_provider.dart';

import '../../widgets/profile_tab_widget.dart';

/// Pestaña de Dashboard para el Administrador rediseñada de forma premium
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales en segundo plano para las métricas del dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).fetchUsers();
        Provider.of<ServiceProvider>(context, listen: false).loadServices();
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
        Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminName = authProvider.user?.name ?? 'Administrador';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Panel Administrador"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ProfileTabWidget.showLogoutConfirmationDialog(context, authProvider);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta de Bienvenida con Degradado Premium
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1565c0), Color(0xff1e88e5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff1e88e5).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 90,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "¡Bienvenido de vuelta! 👋",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Rol: Administrador General",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. Tarjetas de Métricas Rápidas (Live Counters)
              const Text(
                "Estado del Sistema",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Consumer<UserProvider>(
                      builder: (context, userProv, _) {
                        final count = userProv.isLoading ? "..." : "${userProv.users.length}";
                        return _statCard(
                          label: "Usuarios",
                          value: count,
                          icon: Icons.group,
                          color: Colors.indigo,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<ServiceProvider>(
                      builder: (context, serviceProv, _) {
                        final count = serviceProv.isLoading ? "..." : "${serviceProv.services.length}";
                        return _statCard(
                          label: "Servicios",
                          value: count,
                          icon: Icons.content_cut,
                          color: Colors.purple,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<ProductProvider>(
                      builder: (context, prodProv, _) {
                        final count = prodProv.isLoading ? "..." : "${prodProv.products.length}";
                        return _statCard(
                          label: "Productos",
                          value: count,
                          icon: Icons.shopping_bag,
                          color: Colors.orange,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Módulos de Gestión (Grid Rediseñado)
              const Text(
                "Módulos de Gestión",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: [
                  _menuCard(
                    context,
                    title: "Citas",
                    subtitle: "Calendario y agenda",
                    icon: Icons.calendar_month,
                    route: "/admin/appointments",
                    color: Colors.blue,
                  ),
                  _menuCard(
                    context,
                    title: "Usuarios",
                    subtitle: "Clientes y barberos",
                    icon: Icons.group_outlined,
                    route: "/admin/users",
                    color: Colors.indigo,
                  ),
                  _menuCard(
                    context,
                    title: "Servicios",
                    subtitle: "Tarifario y duración",
                    icon: Icons.content_cut,
                    route: "/admin/services",
                    color: Colors.purple,
                  ),
                  _menuCard(
                    context,
                    title: "Productos",
                    subtitle: "Modo Consulta",
                    icon: Icons.shopping_bag_outlined,
                    route: "/admin/products",
                    color: Colors.orange,
                  ),
                  _menuCard(
                    context,
                    title: "Ventas",
                    subtitle: "Facturación diaria",
                    icon: Icons.monetization_on_outlined,
                    route: "/admin/sales",
                    color: Colors.teal,
                  ),
                  _menuCard(
                    context,
                    title: "KPIs",
                    subtitle: "Reportes y métricas",
                    icon: Icons.bar_chart_outlined,
                    route: "/admin/kpis",
                    color: Colors.green,
                  ),
                  _menuCard(
                    context,
                    title: "Roles",
                    subtitle: "Permisos del sistema",
                    icon: Icons.admin_panel_settings_outlined,
                    route: "/admin/roles",
                    color: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
