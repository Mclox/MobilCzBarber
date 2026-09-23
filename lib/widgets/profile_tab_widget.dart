import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/api.dart';
import '../providers/auth_provider.dart';
import '../screens/settings_screen.dart';

/// Widget reutilizable para la pestaña de perfil
/// Usado por Admin, Barbero y Cliente
class ProfileTabWidget extends StatefulWidget {
  final String? photoUrl;
  final Color? primaryColor;
  final List<ProfileOption>? additionalOptions;

  const ProfileTabWidget({
    super.key,
    this.photoUrl,
    this.primaryColor,
    this.additionalOptions,
  });

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

  @override
  State<ProfileTabWidget> createState() => _ProfileTabWidgetState();
}

class _ProfileTabWidgetState extends State<ProfileTabWidget> {
  bool _isUpdatingImage = false;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    // 🔄 Recargamos el perfil del usuario para obtener sincronización automática de la web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).reloadUser();
        _fetchAppVersion();
      }
    });
  }

  Future<void> _fetchAppVersion() async {
    try {
      final response = await http.get(Uri.parse(Api.latestVersion)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? versionStr;
        if (data is Map) {
          versionStr = data['version_name']?.toString() ??
              data['version']?.toString() ??
              data['version_number']?.toString() ??
              data['data']?['version_name']?.toString() ??
              data['data']?['version']?.toString();
        } else if (data is String) {
          versionStr = data;
        }
        if (versionStr != null && versionStr.isNotEmpty && mounted) {
          setState(() {
            _appVersion = versionStr!;
          });
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo versión de la app: $e");
    }
  }

  /// 🔗 Resolver la URL de la foto de perfil (Supabase, Base64 o servidor local)
  String? _resolveAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('http')) return avatarUrl;
    if (avatarUrl.startsWith('data:image')) return avatarUrl;
    
    // Si es una ruta relativa local
    String cleanPath = avatarUrl.replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    String serverUrl = Api.baseUrl.replaceAll('/api', '');
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }
    return "$serverUrl/$cleanPath";
  }

  /// 🖼️ Obtener el ImageProvider correspondiente (MemoryImage para Base64, NetworkImage para URLs)
  ImageProvider? _getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        print("Error al decodificar avatar en base64: $e");
        return null;
      }
    }
    return NetworkImage(url);
  }

  /// 📸 Seleccionar y subir la foto de perfil
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUpdatingImage = true;
      });

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.uploadProfileImage(pickedFile.path);

      if (!mounted) return;

      // La imagen ya fue aplicada localmente (optimistic update en AuthProvider)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingImage = false;
        });
      }
    }
  }

  /// 📑 Mostrar opciones de origen de la foto (Cámara / Galería)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cambiar Foto de Perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final color = widget.primaryColor ?? Theme.of(context).primaryColor;
    final currentPhotoUrl = _resolveAvatarUrl(widget.photoUrl ?? user?.avatarUrl);

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
                  // Foto de perfil con botón de edición superpuesto y barra de carga
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _getImageProvider(currentPhotoUrl),
                        child: currentPhotoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: color,
                              )
                            : null,
                      ),
                      if (_isUpdatingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUpdatingImage ? null : _showImagePickerOptions,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
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
            if (widget.additionalOptions != null)
              ...widget.additionalOptions!.map((option) => _buildOption(
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
              subtitle: 'Versión $_appVersion',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'CzBarber',
                  applicationVersion: _appVersion,
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
          color: (widget.primaryColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: widget.primaryColor ?? Theme.of(context).primaryColor,
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
    ProfileTabWidget.showLogoutConfirmationDialog(context, authProvider);
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
