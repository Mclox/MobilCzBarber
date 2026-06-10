import 'package:flutter/material.dart';

class ConfirmationHelper {
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    String title = "¿Eliminar registro?",
    String message = "¿Realmente desea eliminar este registro? Esta acción no se puede deshacer.",
  }) async {
    debugPrint('ConfirmationHelper: Mostrando diálogo de confirmación - $title');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
