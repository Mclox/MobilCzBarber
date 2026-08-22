import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre *")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Correo *")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Teléfono * (ej: +573001234567)")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña *")),
            TextField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: "Confirmar contraseña *")),
            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Todos los campos marcados con * son obligatorios.")),
                  );
                  return;
                }

                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Las contraseñas no coinciden")),
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

                final newUser = User(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  email: email,
                  phone: cleanPhone,
                  password: password,
                  role: "client", // 👈 por defecto
                );

                final success = await authProvider.register(newUser);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Usuario registrado correctamente")),
                  );
                  Navigator.pop(context); // vuelve al login
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al registrar usuario. Valida si el correo o teléfono ya existen."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Registrarme"),
            ),
          ],
        ),
      ),
    );
  }
}
