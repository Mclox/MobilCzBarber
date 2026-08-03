import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';

/// Pestaña de Dashboard para el Administrador
class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: AppTheme.background,
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _menuCard(
            context,
            title: "Citas",
            icon: Icons.calendar_month,
            route: "/admin/appointments",
            color: Colors.blue,
          ),
          _menuCard(
            context,
            title: "KPIs",
            icon: Icons.bar_chart,
            route: "/admin/kpis",
            color: Colors.green,
          ),
          _menuCard(
            context,
            title: "Productos",
            icon: Icons.shopping_bag,
            route: "/admin/products",
            color: Colors.orange,
          ),
          _menuCard(
            context,
            title: "Servicios",
            icon: Icons.content_cut,
            route: "/admin/services",
            color: Colors.purple,
          ),
          _menuCard(
            context,
            title: "Ventas",
            icon: Icons.monetization_on,
            route: "/admin/sales",
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
