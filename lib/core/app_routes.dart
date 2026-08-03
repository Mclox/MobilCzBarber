import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

// Auth Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/register_screen.dart';

// Admin Screens
import '../screens/admin/admin_main_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_roles_screen.dart';
import '../screens/admin/manage_products_screen.dart';
import '../screens/admin/manage_appointments_screen.dart';
import '../screens/admin/kpis_screen.dart';
import '../screens/admin/manage_services_screen.dart';
import '../screens/admin/manage_sales_screen.dart';
import '../screens/admin/create_sale_screen.dart';


// Client Screens
import '../screens/main_screen.dart';
import '../screens/client/catalog_screen.dart';
import '../screens/client/book_appointment_screen.dart';

// Employee Screens
import '../screens/employee/employee_main_screen.dart';
import '../screens/employee/employee_agenda_screen.dart';
import '../screens/employee/availability_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: "/login",

  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final logged = auth.isLoggedIn;
    final location = state.uri.toString();

    // 📌 Paths permitidos sin login
    final noAuthRoutes = [
      "/login",
      "/reset-password",
      "/register",
    ];

    // Si NO está logueado → redirigir al login
    if (!logged && !noAuthRoutes.contains(location)) {
      return "/login";
    }

    // Si ya está logueado e intenta ir al login → redirigir según rol
    if (logged && location == "/login") {
      final role = auth.user?.role ?? "";

      switch (role) {
        case "admin":
          return "/admin/dashboard";
        case "employee":
          return "/employee/home";
        default:
          return "/client/home";
      }
    }

    return null;
  },

  routes: [
    /// AUTH
    GoRoute(path: "/login", builder: (_, __) => const LoginScreen()),
    GoRoute(path: "/reset-password", builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: "/register", builder: (_, __) => const RegisterScreen()),

    /// ADMIN
    GoRoute(path: "/admin/dashboard", builder: (_, __) => const AdminMainScreen()),
    GoRoute(path: "/admin/users", builder: (_, __) => const ManageUsersScreen()),
    GoRoute(path: "/admin/roles", builder: (_, __) => const ManageRolesScreen()),
    GoRoute(path: "/admin/products", builder: (_, __) => const ManageProductsScreen()),
    GoRoute(path: "/admin/appointments", builder: (_, __) => const ManageAppointmentsScreen()),
    GoRoute(path: "/admin/kpis", builder: (_, __) => const KpisScreen()),
    GoRoute(path: "/admin/services",builder: (_, __) => const ManageServicesScreen(),),
    GoRoute(path: "/admin/sales", builder: (_, __) => const ManageSalesScreen()),
    GoRoute(path: "/admin/sales/create", builder: (_, __) => const CreateSaleScreen()),
    



    /// CLIENT
    GoRoute(path: "/client/home", builder: (_, __) => const MainScreen()),
    GoRoute(path: "/client/catalog", builder: (_, __) => const CatalogScreen()),
    GoRoute(path: "/client/book", builder: (_, __) => const BookAppointmentScreen()),

    /// EMPLOYEE
    GoRoute(path: "/employee/home", builder: (_, __) => const EmployeeMainScreen()),
    GoRoute(path: "/employee/agenda", builder: (_, __) => const EmployeeAgendaScreen()),
    GoRoute(path: "/employee/availability", builder: (_, __) => const AvailabilityScreen()),
  ],
);
