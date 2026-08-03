import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_routes.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/barber_provider.dart';
import 'providers/user_provider.dart';
import 'providers/role_provider.dart';
import 'providers/barber_availability_provider.dart';
import 'providers/barber_appointment_provider.dart'; // 👈 SI EXISTE
import 'providers/dashboard_provider.dart';
import 'providers/service_provider.dart';
import 'providers/sale_provider.dart';

import 'core/app_theme.dart'; // Add import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const CzBarberApp());
}

class CzBarberApp extends StatelessWidget {
  const CzBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        /// 🔐 AUTH
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        /// 🧑‍💼 ADMIN
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => BarberProvider()),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),


        /// 💈 BARBERO
        ChangeNotifierProvider(create: (_) => BarberAvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => BarberAppointmentProvider()),

      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'CzBarber',
        routerConfig: appRouter,
        theme: AppTheme.lightTheme, // Use custom theme
      ),
    );
  }
}
