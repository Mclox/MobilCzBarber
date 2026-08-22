import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool isPassword;

  const CustomInput({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.isPassword = false,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      style: const TextStyle(
        fontSize: 15,
        color: AppTheme.darkText,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: AppTheme.primary),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.lightText,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        labelText: widget.label,
        labelStyle: const TextStyle(
          color: AppTheme.lightText,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
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
    );
  }
}
