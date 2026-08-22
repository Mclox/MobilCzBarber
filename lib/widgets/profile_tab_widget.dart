import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/settings_screen.dart';

/// Widget reutilizable para la pestaña de perfil
/// Usado por Admin, Barbero y Cliente
class ProfileTabWidget extends StatelessWidget {
  final String? photoUrl;
  final Color? primaryColor;
  final List<ProfileOption>? additionalOptions;

  const ProfileTabWidget({
    super.key,
    this.photoUrl,
    this.primaryColor,
    this.additionalOptions,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final color = primaryColor ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con foto y datos del usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Foto de perfil
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: color,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre
                  Text(
                    user?.name ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rol
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getRoleLabel(user?.role ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Opciones adicionales personalizadas
            if (additionalOptions != null)
              ...additionalOptions!.map((option) => _buildOption(
                    context,
                    icon: option.icon,
                    title: option.title,
                    subtitle: option.subtitle,
                    onTap: option.onTap,
                  )),

            // Opciones comunes
            _buildOption(
              context,
              icon: Icons.settings,
              title: 'Configuración',
              subtitle: 'Preferencias de la aplicación',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            _buildOption(
              context,
              icon: Icons.help_outline,
              title: 'Ayuda y Soporte',
              subtitle: '¿Necesitas ayuda?',
              onTap: () {
                // TODO: Navegar a ayuda
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayuda próximamente')),
                );
              },
            ),

            _buildOption(
              context,
              icon: Icons.info_outline,
              title: 'Acerca de',
              subtitle: 'Versión 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'CzBarber',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.content_cut),
                );
              },
            ),

            const SizedBox(height: 20),

            // Botón de Cerrar Sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context, authProvider);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: primaryColor ?? Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            )
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'employee':
        return 'Barbero';
      case 'client':
        return 'Cliente';
      default:
        return role;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showLogoutConfirmationDialog(context, authProvider);
  }

  static void showLogoutConfirmationDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

/// Clase para opciones personalizadas del perfil
class ProfileOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  ProfileOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
