import 'package:flutter/material.dart';

// Importar las pantallas del cliente
import 'client/home_screen.dart';
import 'client/booking_screen.dart';
import 'client/my_appointments_screen.dart';
import 'client/profile_screen.dart';

/// Pantalla principal con navegación inferior (BottomNavigationBar)
/// Contiene cuatro pestañas: Inicio, Reservar, Mis Citas y Perfil
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Índice de la pestaña activa (0-3)
  int _currentIndex = 0;

  /// Lista de pantallas correspondientes a cada pestaña
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToTab: _onItemTapped), // Índice 0: Inicio
      BookingScreen(onBack: () => _onItemTapped(0)), // Índice 1: Reservar
      MyAppointmentsScreen(onBack: () => _onItemTapped(0)), // Índice 2: Mis Citas
      const ProfileScreen(),                       // Índice 3: Perfil
    ];
  }

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
        
        // Color del ítem seleccionado (usa el color primario del tema)
        selectedItemColor: Theme.of(context).primaryColor,
        
        // Ítems de navegación
        items: const [
          // Pestaña 0: Inicio
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          
          // Pestaña 1: Reservar
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservar',
          ),
          
          // Pestaña 2: Mis Citas
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis Citas',
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
