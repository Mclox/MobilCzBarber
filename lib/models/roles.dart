class RolePermission {
  final String modulo;
  bool crear;
  bool leer;
  bool actualizar;
  bool eliminar;

  RolePermission({
    required this.modulo,
    this.crear = false,
    this.leer = false,
    this.actualizar = false,
    this.eliminar = false,
  });

  factory RolePermission.fromJson(Map<String, dynamic> json) => RolePermission(
        modulo: json["modulo"] ?? '',
        crear: json["crear"] == true || json["crear"] == 1,
        leer: json["leer"] == true || json["leer"] == 1,
        actualizar: json["actualizar"] == true || json["actualizar"] == 1,
        eliminar: json["eliminar"] == true || json["eliminar"] == 1,
      );

  Map<String, dynamic> toJson() => {
        "modulo": modulo,
        "crear": crear,
        "leer": leer,
        "actualizar": actualizar,
        "eliminar": eliminar,
      };
}

class Role {
  final int id;
  final String name; // admin, employee, client / Administrador, Barbero, Cliente
  final String description;
  final String? state;
  final List<RolePermission> permissions;

  Role({
    required this.id,
    required this.name,
    required this.description,
    this.state,
    this.permissions = const [],
  });

  // JSON → Modelo
  factory Role.fromJson(Map<String, dynamic> json) {
    var rawPermisos = json["permisos"] as List?;
    List<RolePermission> parsedPermissions = rawPermisos != null
        ? rawPermisos.map((p) => RolePermission.fromJson(p)).toList()
        : [];
    
    return Role(
      id: json["id_rol"] ?? json["id"] ?? 0,
      name: json["nombre"] ?? json["name"] ?? '',
      description: json["descripcion"] ?? json["description"] ?? '',
      state: json["estado"] ?? 'Activo',
      permissions: parsedPermissions,
    );
  }

  // Modelo → JSON
  Map<String, dynamic> toJson() => {
        "id_rol": id,
        "id": id,
        "nombre": name,
        "name": name,
        "descripcion": description,
        "description": description,
        "estado": state ?? 'Activo',
        "permisos": permissions.map((p) => p.toJson()).toList(),
      };
}

