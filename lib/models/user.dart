class User {
  final int? id;
  final String name;
  final String email;
  final String? password;
  final String role;
  final String? avatarUrl;
  final String? document;
  final String? documentType;
  final String? phone;
  final String? address;
  final String? state;
  final int? roleId;

  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.avatarUrl,
    this.document,
    this.documentType,
    this.phone,
    this.address,
    this.state,
    this.roleId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Resolver el rol en el formato que espera la app (admin, employee, client)
    String resolvedRole = json["rol_nombre"] ?? json["role"] ?? json["rol"] ?? '';
    if (resolvedRole == 'Administrador') {
      resolvedRole = 'admin';
    } else if (resolvedRole == 'Barbero') {
      resolvedRole = 'employee';
    } else if (resolvedRole == 'Cliente') {
      resolvedRole = 'client';
    }

    return User(
      id: json["id_usuario"] ?? json["id"],
      name: json["nombre"] ?? json["name"] ?? '',
      email: json["email"] ?? '',
      password: json["password"] ?? json["contrasena"],
      role: resolvedRole.isEmpty ? 'client' : resolvedRole,
      avatarUrl: (json["img"] ?? json["avatarUrl"] ?? json["avatar"] ?? json["foto"])?.toString(),
      document: json["documento"] ?? json["identificacion"],
      documentType: json["tipo_documento"],
      phone: json["telefono"],
      address: json["direccion"],
      state: json["estado"] ?? json["estatus"],
      roleId: json["id_rol"] ?? json["role_id"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id_usuario": id,
        "id": id,
        "nombre": name,
        "name": name,
        "email": email,
        "password": password,
        "contrasena": password,
        "rol": role == 'admin' ? 'Administrador' : role == 'employee' ? 'Barbero' : 'Cliente',
        "role": role,
        "img": avatarUrl,
        "avatarUrl": avatarUrl,
        "documento": document,
        "identificacion": document,
        "tipo_documento": documentType,
        "telefono": phone,
        "direccion": address,
        "estado": state,
        "estatus": state,
        "id_rol": roleId,
        "role_id": roleId,
      };
}
