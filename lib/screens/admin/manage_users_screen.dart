import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../providers/role_provider.dart';
import '../../models/user.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../core/app_theme.dart';
import 'user_detail_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Cargar usuarios al inicializar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void openUserForm({User? user}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserForm(
        user: user,
        onSaved: () {
          Provider.of<UserProvider>(context, listen: false).fetchUsers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Usuarios"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openUserForm(),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar la lista de usuarios según la búsqueda
          final filteredUsers = provider.users.where((u) {
            if (_searchQuery.isEmpty) return true;
            final name = u.name.toLowerCase();
            final email = u.email.toLowerCase();
            final doc = (u.document ?? '').toLowerCase();
            final role = u.role.toLowerCase();
            return name.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                doc.contains(_searchQuery) ||
                role.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Barra de búsqueda de usuarios
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre, correo o documento...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(child: Text("No se encontraron usuarios"))
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, i) {
                          final u = filteredUsers[i];
                          final bool isActive = u.state == 'Activo';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserDetailScreen(user: u),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary,
                                child: Text(
                                  u.name.isNotEmpty ? u.name.substring(0, 1).toUpperCase() : "?",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                u.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                "${u.email}\nDoc: ${u.documentType ?? 'CC'} - ${u.document ?? 'N/A'}\nRol: ${u.role} • Estado: ${u.state ?? 'Activo'}",
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => openUserForm(user: u),
                                  ),
                                  // Botón de alternancia de estado (Activo/Inactivo)
                                  IconButton(
                                    icon: Icon(
                                      isActive ? Icons.toggle_on : Icons.toggle_off,
                                      color: isActive ? Colors.green : Colors.grey,
                                      size: 38,
                                    ),
                                    onPressed: () async {
                                      final String newState = isActive ? 'Inactivo' : 'Activo';
                                      
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(isActive ? "Desactivar Usuario" : "Activar Usuario"),
                                          content: Text("¿Realmente desea cambiar el estado de ${u.name} a $newState?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text("Cancelar"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isActive ? Colors.red : Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text(isActive ? "Desactivar" : "Activar"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final updatedUser = User(
                                          id: u.id,
                                          name: u.name,
                                          email: u.email,
                                          role: u.role,
                                          roleId: u.roleId,
                                          document: u.document,
                                          documentType: u.documentType,
                                          phone: u.phone,
                                          address: u.address,
                                          state: newState,
                                          avatarUrl: u.avatarUrl,
                                        );
                                        
                                        final success = await provider.updateUser(u.id!, updatedUser);
                                        if (mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Usuario actualizado a $newState.")),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Error al actualizar el estado del usuario."),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserForm extends StatefulWidget {
  final User? user;
  final VoidCallback onSaved;

  const _UserForm({this.user, required this.onSaved});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController documentCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();

  String documentType = "CC";
  String state = "Activo";
  int? roleId;
  String roleName = "";
  bool submitting = false;

  @override
  void initState() {
    super.initState();

    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    if (roleProvider.roles.isEmpty) {
      roleProvider.fetchRoles().then((_) {
        if (mounted && widget.user == null && roleProvider.roles.isNotEmpty) {
          setState(() {
            roleId = roleProvider.roles.first.id;
            roleName = roleProvider.roles.first.name;
          });
        }
      });
    }

    if (widget.user != null) {
      nameCtrl.text = widget.user!.name;
      emailCtrl.text = widget.user!.email;
      roleId = widget.user!.roleId;
      roleName = widget.user!.role;
      documentCtrl.text = widget.user!.document ?? '';
      documentType = widget.user!.documentType ?? 'CC';
      phoneCtrl.text = widget.user!.phone ?? '';
      addressCtrl.text = widget.user!.address ?? '';
      state = widget.user!.state ?? 'Activo';
    } else {
      if (roleProvider.roles.isNotEmpty) {
        roleId = roleProvider.roles.first.id;
        roleName = roleProvider.roles.first.name;
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    documentCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final roleProvider = Provider.of<RoleProvider>(context);

    return AlertDialog(
      title: Text(widget.user == null ? "Nuevo Usuario" : "Editar Usuario"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInput(
                controller: nameCtrl,
                label: "Nombre Completo",
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: documentType,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
                decoration: InputDecoration(
                  labelText: "Tipo de Documento",
                  labelStyle: const TextStyle(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "CC",
                    child: Text(
                      "Cédula de Ciudadanía (CC)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: "CE",
                    child: Text(
                      "Cédula de Extranjería (CE)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: "NIT",
                    child: Text(
                      "NIT",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: "PP",
                    child: Text(
                      "Pasaporte (PP)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => documentType = value!),
              ),
              const SizedBox(height: 12),
              CustomInput(
                controller: documentCtrl,
                label: "Número de Documento",
                icon: Icons.badge,
              ),
              const SizedBox(height: 12),
              CustomInput(
                controller: emailCtrl,
                label: "Correo Electrónico",
                icon: Icons.email,
              ),
              const SizedBox(height: 12),
              if (widget.user == null) ...[
                CustomInput(
                  controller: passCtrl,
                  label: "Contraseña",
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 12),
              ],
              CustomInput(
                controller: phoneCtrl,
                label: "Teléfono *",
                icon: Icons.phone,
              ),
              const SizedBox(height: 12),
              CustomInput(
                controller: addressCtrl,
                label: "Dirección",
                icon: Icons.home,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: state,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
                decoration: InputDecoration(
                  labelText: "Estado",
                  labelStyle: const TextStyle(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Activo",
                    child: Text("Activo", overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: "Inactivo",
                    child: Text("Inactivo", overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) => setState(() => state = value!),
              ),
              const SizedBox(height: 12),
              roleProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: roleId,
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkText,
                      ),
                      decoration: InputDecoration(
                        labelText: "Rol Asignado",
                        labelStyle: const TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: roleProvider.roles.map((r) {
                        return DropdownMenuItem<int>(
                          value: r.id,
                          child: Text(r.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final selectedRole = roleProvider.roles.firstWhere((r) => r.id == value);
                          setState(() {
                            roleId = value;
                            roleName = selectedRole.name;
                          });
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Cancelar", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: submitting
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : CustomButton(
                      text: "Guardar",
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final doc = documentCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final address = addressCtrl.text.trim();

                        if (name.isEmpty || doc.isEmpty || email.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Nombre, Documento, Correo y Teléfono son obligatorios.")),
                          );
                          return;
                        }

                        // Validar formato internacional (E.164)
                        final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                        final phoneRegex = RegExp(r'^\+[1-9]\d{9,14}$');
                        if (!phoneRegex.hasMatch(cleanPhone)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("El teléfono debe estar en formato internacional (ej: +573001234567)."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (widget.user == null && pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("La contraseña es obligatoria.")),
                          );
                          return;
                        }

                        if (roleId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Debe seleccionar un rol.")),
                          );
                          return;
                        }

                        setState(() => submitting = true);

                        bool success = false;
                        if (widget.user == null) {
                          final newUser = User(
                            name: name,
                            email: email,
                            password: pass,
                            role: roleName,
                            roleId: roleId,
                            document: doc,
                            documentType: documentType,
                            phone: phone,
                            address: address,
                            state: state,
                          );
                          success = await userProvider.createUser(newUser);
                        } else {
                          final updatedUser = User(
                            id: widget.user!.id,
                            name: name,
                            email: email,
                            role: roleName,
                            roleId: roleId,
                            document: doc,
                            documentType: documentType,
                            phone: phone,
                            address: address,
                            state: state,
                            avatarUrl: widget.user!.avatarUrl,
                          );
                          success = await userProvider.updateUser(widget.user!.id!, updatedUser);
                        }

                        if (mounted) {
                          setState(() => submitting = false);
                          if (success) {
                            widget.onSaved();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error al guardar el usuario."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
