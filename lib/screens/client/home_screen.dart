import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../services/notification_service.dart';
import '../../core/app_theme.dart';
import '../settings_screen.dart';
import '../../widgets/profile_tab_widget.dart';

/// Pantalla principal (Dashboard) del cliente rediseñada con datos del backend real
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ServiceProvider>(context, listen: false).loadServices();
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
        _fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoadingNotifications = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userRole = auth.user?.role ?? 'client';
    final data = await _notificationService.getRecentNotifications(userRole);
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success && mounted) {
      setState(() {
        _notifications = _notifications.map((n) => {...n, 'leido': true}).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final unreadCount = _notifications.where((n) => n['leido'] == false).length;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        await _markNotificationsAsRead();
                        setDialogState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Leer todas', style: TextStyle(fontSize: 12)),
                    )
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: _isLoadingNotifications
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? const Center(child: Text('No tienes notificaciones', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              final bool isUnread = item['leido'] == false;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.info_outline,
                                  color: isUnread ? AppTheme.primary : Colors.grey,
                                ),
                                title: Text(
                                  item['descripcion'] ?? 'Notificación',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  item['fecha_creacion'] != null 
                                      ? item['fecha_creacion'].toString().split('T')[0]
                                      : '',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showServiceDetails(BuildContext context, Map<String, dynamic> service) {
    final double priceTotal = double.tryParse(service['precio_neto'].toString()) ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.purple.withOpacity(0.12),
                        child: const Icon(Icons.content_cut, size: 28, color: Colors.purple),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['nombre'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Duración: ${service['duracion_minutos']} minutos",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text(
                    "Información de Tarifas",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Precio Total",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Text(
                        "\$${priceTotal.toStringAsFixed(2)} COP",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(1); // Go to book tab
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Reservar Cita", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final unreadCount = _notifications.where((n) => n['leido'] == false).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inicio CzBarber'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _showNotificationsDialog,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ProfileTabWidget.showLogoutConfirmationDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await serviceProvider.loadServices();
          await productProvider.loadProducts();
          await _fetchNotifications();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header con Bienvenida Degradado Premium (Estilo Administrador)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1565c0), Color(0xff1e88e5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff1e88e5).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Hola de nuevo! 👋',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user?.name ?? 'Cliente CzBarber',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Sección de Accesos Rápidos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accesos Rápidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAccessCard(
                            context: context,
                            icon: Icons.shopping_bag_outlined,
                            title: 'Catálogo',
                            subtitle: 'Ver productos',
                            color: Colors.purple,
                            onTap: () {
                              context.push('/client/catalog');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickAccessCard(
                            context: context,
                            icon: Icons.calendar_today_outlined,
                            title: 'Reservar',
                            subtitle: 'Agendar cita',
                            color: Colors.green,
                            onTap: () {
                              if (widget.onNavigateToTab != null) {
                                widget.onNavigateToTab!(1);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAccessCard(
                            context: context,
                            icon: Icons.list_alt_outlined,
                            title: 'Mis Citas',
                            subtitle: 'Ver mis estados',
                            color: Colors.orange,
                            onTap: () {
                              if (widget.onNavigateToTab != null) {
                                widget.onNavigateToTab!(2);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickAccessCard(
                            context: context,
                            icon: Icons.settings_outlined,
                            title: 'Configuración',
                            subtitle: 'Ajustes de app',
                            color: Colors.blueGrey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Sección de Servicios Destacados (desde el Backend)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Servicios Destacados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    serviceProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : serviceProvider.services.isEmpty
                            ? const Center(child: Text('No hay servicios disponibles.'))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: serviceProvider.services.length > 3 
                                    ? 3 
                                    : serviceProvider.services.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = serviceProvider.services[index];
                                  final double price = double.tryParse(item['precio_neto']?.toString() ?? '0') ?? 0.0;
                                  return _buildServiceCard(
                                    context: context,
                                    icon: Icons.content_cut,
                                    title: item['nombre'] ?? 'Servicio',
                                    description: item['descripcion'] ?? 'Servicio profesional',
                                    price: '\$${price.toStringAsFixed(0)}',
                                    color: AppTheme.primary,
                                    onTap: () => _showServiceDetails(context, item),
                                  );
                                },
                              ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. Sección de Catálogo de Productos (desde el Backend)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuestros Productos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    productProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : productProvider.products.isEmpty
                            ? const Center(child: Text('No hay productos disponibles.'))
                            : SizedBox(
                                height: 170,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: productProvider.products.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                                  itemBuilder: (context, index) {
                                    final prod = productProvider.products[index];
                                    return Container(
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 70,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 32,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            prod.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${prod.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String price,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
