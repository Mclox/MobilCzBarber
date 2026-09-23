class Api {
  // URL base del backend
  // Cambia esto por tu IP o dominio
  static const String baseUrl = "https://barbersite-backend.onrender.com/api";

  // AUTH
  static const String login = "$baseUrl/auth/login";

  // USERS
  static const String users = "$baseUrl/users";
  static String userById(int id) => "$users/$id";

  // ROLES
  static const String roles = "$baseUrl/roles";

  // PRODUCTS
  static const String products = "$baseUrl/products";
  static String productById(int id) => "$products/$id";

  // PROVIDERS
  static const String providers = "$baseUrl/providers";
  static String providerById(int id) => "$providers/$id";

  // APPOINTMENTS (citas)
  static const String appointments = "$baseUrl/appointments";
  static String appointmentById(int id) => "$appointments/$id";

  // BARBERS (empleados)
  static const String barbers = "$baseUrl/barbers";
  static String barberById(int id) => "$barbers/$id";

  // SERVICES (servicios de la barbería)
  static const String services = "$baseUrl/services";
  static String serviceById(int id) => "$services/$id";

  // PAYMENTS
  static const String payments = "$baseUrl/payments";
  static String paymentById(int id) => "$payments/$id";

  // SALES
  static const String sales = "$baseUrl/sales";
  static String saleById(int id) => "$sales/$id";
  static String saleDetails(int id) => "$sales/$id/details";

  // DASHBOARD / KPI
  static const String dashboard = "$baseUrl/dashboard";
  static const String dashboardSales = "$baseUrl/dashboard/sales";
  static const String dashboardAppointments = "$baseUrl/dashboard/appointments";
  static const String dashboardTopServices = "$baseUrl/dashboard/topservices";

  // APP VERSION
  static const String latestVersion = "$baseUrl/app-version/latest";
}
