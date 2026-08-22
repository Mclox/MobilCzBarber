import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/profile_tab_widget.dart';
import 'admin_dashboard_tab.dart';
import 'manage_users_screen.dart';
import 'manage_services_screen.dart';
import 'manage_appointments_screen.dart';

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
    const AdminDashboardTab(),       // Índice 0: Dashboard
    const ManageUsersScreen(),       // Índice 1: Usuarios (Directo)
    const ManageServicesScreen(),    // Índice 2: Servicios (Directo)
    const ManageAppointmentsScreen(),// Índice 3: Citas (Directo)
    const ProfileTabWidget(          // Índice 4: Perfil
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
          
          // Pestaña 2: Servicios
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut),
            label: 'Servicios',
          ),
          
          // Pestaña 3: Citas
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
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
