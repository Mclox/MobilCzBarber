import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/profile_tab_widget.dart';
import 'admin_dashboard_tab.dart';
import 'admin_users_tab.dart';
import 'admin_roles_tab.dart';
import 'admin_services_tab.dart';

/// Pantalla principal del Administrador con BottomNavigationBar
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  /// Índice de la pestaña activa (0-4)
  int _currentIndex = 0;

  /// Lista de pantallas correspondientes a cada pestaña
  final List<Widget> _screens = [
    const AdminDashboardTab(),  // Índice 0: Dashboard
    const AdminUsersTab(),      // Índice 1: Usuarios
    const AdminRolesTab(),      // Índice 2: Roles
    const AdminServicesTab(),   // Índice 3: Servicios
    const ProfileTabWidget(     // Índice 4: Perfil
      primaryColor: AppTheme.primary,
    ),
  ];

  /// Maneja el cambio de pestaña
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cuerpo: muestra la pantalla correspondiente al índice actual
      body: _screens[_currentIndex],

      // Barra de navegación inferior
      bottomNavigationBar: BottomNavigationBar(
        // Tipo fijo para mostrar todos los íconos y etiquetas
        type: BottomNavigationBarType.fixed,
        
        // Índice actual
        currentIndex: _currentIndex,
        
        // Función que se ejecuta al tocar un ítem
        onTap: _onItemTapped,
        
        // Color del ítem seleccionado
        selectedItemColor: AppTheme.primary,
        
        // Color del ítem no seleccionado
        unselectedItemColor: Colors.grey,
        
        // Tamaño de fuente
        selectedFontSize: 12,
        unselectedFontSize: 12,
        
        // Ítems de navegación
        items: const [
          // Pestaña 0: Dashboard
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          
          // Pestaña 1: Usuarios
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Usuarios',
          ),
          
          // Pestaña 2: Roles
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Roles',
          ),
          
          // Pestaña 3: Servicios
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Servicios',
          ),
          
          // Pestaña 4: Perfil
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
