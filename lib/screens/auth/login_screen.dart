import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_users.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../core/app_theme.dart';
import '../../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del provider para que la UI se actualice al cargar
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
          child: Column(
            children: [
              // Logo
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "CzBarber",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Inicia sesión para continuar",
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 40),

              // Email
              CustomInput(
                controller: emailController,
                icon: Icons.email_outlined,
                label: "Correo electrónico",
              ),
              const SizedBox(height: 20),

              // Password
              CustomInput(
                controller: passwordController,
                icon: Icons.lock_outline,
                label: "Contraseña",
                isPassword: true,
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push("/reset-password"),
                  child: const Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),

              CustomButton(
                text: authProvider.isLoading ? "Validando..." : "Iniciar sesión",
                // Si está cargando, pasamos una función vacía () {} en vez de null
                onPressed: authProvider.isLoading 
                  ? () {} 
                  : () {
                      void performLogin() async {
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ingresa todos los datos"), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        // ⏳ Esperamos la respuesta del servidor Node.js
                        final user = await authProvider.login(email, password);

                        if (!context.mounted) return;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Credenciales incorrectas o error de servidor"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // 🔁 Redirección
                        switch (user.role) {
                          case "admin": context.go("/admin/dashboard"); break;
                          case "employee": context.go("/employee/home"); break;
                          case "client": context.go("/client/home"); break;
                          default: context.go("/login");
                        }
                      }
                      
                      performLogin();
                  },
              ),

              // Registro
              GestureDetector(
                onTap: () => context.push("/register"),
                child: const Text(
                  "¿No tienes cuenta? Regístrate aquí",
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}