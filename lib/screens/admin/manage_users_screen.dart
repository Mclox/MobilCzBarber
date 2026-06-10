import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../core/app_theme.dart';
import '../../core/ui_helpers.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService userService = UserService();

  List<User> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await userService.getAllUsers();
    setState(() {
      users = data;
      loading = false;
    });
  }

  void openUserForm({User? user}) {
    showDialog(
      context: context,
      builder: (_) => _UserForm(
        user: user,
        onSaved: () => loadUsers(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Usuarios"),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openUserForm(),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("No hay usuarios"))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            u.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(u.name),
                        subtitle: Text("${u.email} • Rol: ${u.role}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openUserForm(user: u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                debugPrint('ManageUsersScreen: Click en eliminar usuario - ${u.name}');
                                final confirm = await ConfirmationHelper.showDeleteConfirmation(context: context);
                                debugPrint('ManageUsersScreen: Resultado confirmación: $confirm');
                                if (confirm) {
                                  await userService.deleteUser(u.id!);
                                  loadUsers();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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
  final UserService userService = UserService();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  String role = "client";

  @override
  void initState() {
    super.initState();

    if (widget.user != null) {
      nameCtrl.text = widget.user!.name;
      emailCtrl.text = widget.user!.email;
      role = widget.user!.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? "Nuevo Usuario" : "Editar Usuario"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            CustomInput(
              controller: nameCtrl,
              label: "Nombre",
              icon: Icons.person,
            ),

            const SizedBox(height: 15),

            CustomInput(
              controller: emailCtrl,
              label: "Correo",
              icon: Icons.email,
            ),

            const SizedBox(height: 15),

            if (widget.user == null)
              CustomInput(
                controller: passCtrl,
                label: "Contraseña",
                icon: Icons.lock,
                isPassword: true,
              ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: "Rol"),
              items: const [
                DropdownMenuItem(value: "admin", child: Text("Administrador")),
                DropdownMenuItem(value: "employee", child: Text("Empleado")),
                DropdownMenuItem(value: "client", child: Text("Cliente")),
              ],
              onChanged: (value) => setState(() => role = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancelar"),
          onPressed: () => Navigator.pop(context),
        ),
        CustomButton(
          text: "Guardar",
          onPressed: () async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();

            if (name.isEmpty || email.isEmpty) return;

            if (widget.user == null) {
              // Crear usuario
              final newUser = User(
                name: name,
                email: email,
                password: passCtrl.text.trim(),
                role: role,
              );

              await userService.createUser(newUser);
            } else {
              // Actualizar usuario
              final updatedUser = User(
                id: widget.user!.id,
                name: name,
                email: email,
                password: widget.user!.password,
                role: role,
                avatarUrl: widget.user!.avatarUrl,
              );

              await userService.updateUser(widget.user!.id!, updatedUser);
            }

            widget.onSaved();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
