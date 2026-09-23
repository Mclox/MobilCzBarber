import 'package:flutter/material.dart';
import '../../widgets/profile_tab_widget.dart';
import '../../core/app_theme.dart';
import '../../services/update_service.dart';
import 'employee_home_tab.dart';
import 'employee_agenda_screen.dart';
import 'availability_screen.dart';

/// Pantalla principal del Barbero/Empleado con BottomNavigationBar
class EmployeeMainScreen extends StatefulWidget {
  const EmployeeMainScreen({super.key});

  @override
  State<EmployeeMainScreen> createState() => EmployeeMainScreenState();
}

class EmployeeMainScreenState extends State<EmployeeMainScreen> {
  /// Índice de la pestaña activa (0-3)
  int _currentIndex = 0;

  /// Lista de pantallas correspondientes a cada pestaña
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      EmployeeHomeTab(onNavigateToTab: _onItemTapped), // Índice 0: Inicio
      const EmployeeAgendaScreen(),                     // Índice 1: Agenda
      const AvailabilityScreen(),                       // Índice 2: Disponibilidad
      const ProfileTabWidget(                           // Índice 3: Perfil
        primaryColor: AppTheme.primary,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppVersionChecker.checkForUpdates(context);
    });
  }

  /// Maneja el cambio de pestaña
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Cambia de pestaña públicamente
  void selectTab(int index) {
    _onItemTapped(index);
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
          // Pestaña 0: Inicio
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          
          // Pestaña 1: Agenda
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          
          // Pestaña 2: Disponibilidad
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Disponibilidad',
          ),
          
          // Pestaña 3: Perfil
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
