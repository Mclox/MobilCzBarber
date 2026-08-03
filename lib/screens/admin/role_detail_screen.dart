import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/roles.dart';

class RoleDetailScreen extends StatelessWidget {
  final Role role;

  const RoleDetailScreen({super.key, required this.role});

  // Lista oficial de módulos en el mismo orden que React y el formulario
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

  @override
  Widget build(BuildContext context) {
    // Normalizar permisos del rol para asegurar que todos los módulos estén presentes en la vista
    final rolePermissions = role.permissions;
    final List<RolePermission> fullPermissions = appModules.map((modulo) {
      final existing = rolePermissions.firstWhere(
        (p) => p.modulo.toLowerCase() == modulo.toLowerCase(),
        orElse: () => RolePermission(modulo: modulo),
      );
      return existing;
    }).toList();

    Color statusColor = role.state == 'Activo' ? Colors.green : Colors.grey;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detalle del Rol"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado del Rol
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    role.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.state ?? 'Activo',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Información del Rol",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow(
                    icon: Icons.description_outlined,
                    title: "Descripción",
                    value: role.description.isEmpty ? "Sin descripción disponible" : role.description,
                  ),
                  _buildDetailRow(
                    icon: Icons.tag,
                    title: "ID del Rol en Base de Datos",
                    value: role.id.toString(),
                  ),

                  const Divider(height: 40),

                  const Text(
                    "Permisos por Módulo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Matriz de permisos en formato tabla scrollable horizontalmente
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text("Módulo", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Center(child: Text("Crear", style: TextStyle(fontWeight: FontWeight.bold)))),
                            DataColumn(label: Center(child: Text("Leer", style: TextStyle(fontWeight: FontWeight.bold)))),
                            DataColumn(label: Center(child: Text("Actualizar", style: TextStyle(fontWeight: FontWeight.bold)))),
                            DataColumn(label: Center(child: Text("Eliminar", style: TextStyle(fontWeight: FontWeight.bold)))),
                          ],
                          rows: fullPermissions.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p.modulo, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Center(child: _buildPermissionIndicator(p.crear))),
                                DataCell(Center(child: _buildPermissionIndicator(p.leer))),
                                DataCell(Center(child: _buildPermissionIndicator(p.actualizar))),
                                DataCell(
                                  Center(
                                    child: p.modulo == 'Roles'
                                        ? const Text("-", style: TextStyle(color: Colors.grey))
                                        : _buildPermissionIndicator(p.eliminar),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionIndicator(bool value) {
    return Icon(
      value ? Icons.check_circle : Icons.cancel_outlined,
      color: value ? Colors.green : Colors.grey.shade400,
      size: 20,
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
