import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/role_provider.dart';
import '../../models/roles.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../core/app_theme.dart';
import 'role_detail_screen.dart';

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Cargar roles al inicializar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoleProvider>(context, listen: false).fetchRoles();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void openRoleForm({Role? role}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RoleForm(
        role: role,
        onSaved: () {
          Provider.of<RoleProvider>(context, listen: false).fetchRoles();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Roles"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openRoleForm(),
      ),
      body: Consumer<RoleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar la lista de roles según la búsqueda
          final filteredRoles = provider.roles.where((r) {
            if (_searchQuery.isEmpty) return true;
            final name = r.name.toLowerCase();
            final desc = r.description.toLowerCase();
            final state = (r.state ?? 'Activo').toLowerCase();
            return name.contains(_searchQuery) ||
                desc.contains(_searchQuery) ||
                state.contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Barra de búsqueda de roles
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
                    hintText: "Buscar por nombre, descripción o estado...",
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
                child: filteredRoles.isEmpty
                    ? const Center(
                        child: Text(
                          "No se encontraron roles",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredRoles.length,
                        itemBuilder: (_, i) {
                          final r = filteredRoles[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoleDetailScreen(role: r),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  color: AppTheme.primary,
                                ),
                              ),
                              title: Text(
                                r.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                "${r.description.isEmpty ? 'Sin descripción' : r.description}\nEstado: ${r.state ?? 'Activo'}",
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.green),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RoleDetailScreen(role: r),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => openRoleForm(role: r),
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

class _RoleForm extends StatefulWidget {
  final Role? role;
  final VoidCallback onSaved;

  const _RoleForm({this.role, required this.onSaved});

  @override
  State<_RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<_RoleForm> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  String state = "Activo";
  bool submitting = false;

  static const List<String> appModules = [
    'Roles',
    'Usuarios',
    'Productos',
    'Proveedores',
    'Compras',
    'DetalleCompras',
    'Devoluciones',
    'DevolucionesProveedor',
    'Consignaciones',
    'Servicios',
    'Citas',
    'Empleados',
    'Clientes',
    'Pagos',
    'Ventas',
    'VentasDetalle',
  ];

  List<RolePermission> permissions = [];

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      nameCtrl.text = widget.role!.name;
      descCtrl.text = widget.role!.description;
      state = widget.role!.state ?? "Activo";

      final rolePermissions = widget.role!.permissions;
      permissions = appModules.map((modulo) {
        final existing = rolePermissions.firstWhere(
          (p) => p.modulo.toLowerCase() == modulo.toLowerCase(),
          orElse: () => RolePermission(modulo: modulo),
        );
        return RolePermission(
          modulo: modulo,
          crear: existing.crear,
          leer: existing.leer,
          actualizar: existing.actualizar,
          eliminar: existing.eliminar,
        );
      }).toList();
    } else {
      permissions = appModules.map((modulo) => RolePermission(modulo: modulo)).toList();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoleProvider>(context, listen: false);

    return AlertDialog(
      title: Text(widget.role == null ? "Nuevo Rol" : "Editar Rol"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.75,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomInput(
                controller: nameCtrl,
                label: "Nombre del Rol",
                icon: Icons.admin_panel_settings,
              ),
              const SizedBox(height: 15),
              CustomInput(
                controller: descCtrl,
                label: "Descripción",
                icon: Icons.description,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: state,
                decoration: const InputDecoration(
                  labelText: "Estado",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: const [
                  DropdownMenuItem(value: "Activo", child: Text("Activo")),
                  DropdownMenuItem(value: "Inactivo", child: Text("Inactivo")),
                ],
                onChanged: (value) => setState(() => state = value!),
              ),
              const SizedBox(height: 20),
              const Text(
                "Permisos por Módulo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text("Módulo", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Center(child: Text("Crear", style: TextStyle(fontWeight: FontWeight.bold)))),
                        DataColumn(label: Center(child: Text("Leer", style: TextStyle(fontWeight: FontWeight.bold)))),
                        DataColumn(label: Center(child: Text("Actualizar", style: TextStyle(fontWeight: FontWeight.bold)))),
                        DataColumn(label: Center(child: Text("Eliminar", style: TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                      rows: permissions.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(Text(p.modulo, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(
                              Center(
                                child: Checkbox(
                                  value: p.crear,
                                  activeColor: AppTheme.primary,
                                  onChanged: (val) {
                                    setState(() => p.crear = val ?? false);
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Checkbox(
                                  value: p.leer,
                                  activeColor: AppTheme.primary,
                                  onChanged: (val) {
                                    setState(() => p.leer = val ?? false);
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Checkbox(
                                  value: p.actualizar,
                                  activeColor: AppTheme.primary,
                                  onChanged: (val) {
                                    setState(() => p.actualizar = val ?? false);
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: p.modulo == 'Roles'
                                    ? const Text("-", style: TextStyle(color: Colors.grey))
                                    : Checkbox(
                                        value: p.eliminar,
                                        activeColor: AppTheme.primary,
                                        onChanged: (val) {
                                          setState(() => p.eliminar = val ?? false);
                                        },
                                      ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancelar"),
          onPressed: () => Navigator.pop(context),
        ),
        submitting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
                  final desc = descCtrl.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("El nombre es requerido.")),
                    );
                    return;
                  }

                  setState(() => submitting = true);

                  bool success = false;
                  if (widget.role == null) {
                    final newRole = Role(
                      id: 0,
                      name: name,
                      description: desc,
                      state: state,
                      permissions: permissions,
                    );
                    success = await provider.createRole(newRole);
                  } else {
                    final updatedRole = Role(
                      id: widget.role!.id,
                      name: name,
                      description: desc,
                      state: state,
                      permissions: permissions,
                    );
                    success = await provider.updateRole(updatedRole);
                  }

                  if (mounted) {
                    setState(() => submitting = false);
                    if (success) {
                      widget.onSaved();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error al guardar el rol. Por favor intente de nuevo."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
      ],
    );
  }
}
