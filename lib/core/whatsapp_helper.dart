import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// Opens native WhatsApp app or web with recipient phone and pre-filled text message.
  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
    BuildContext? context,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay un número de teléfono válido para este destinatario.')),
        );
      }
      return false;
    }

    final encodedMsg = Uri.encodeComponent(message);
    final Uri url = Uri.parse("https://wa.me/$cleanPhone?text=$encodedMsg");

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
        );
      }
      return false;
    }
  }

  /// Message for the assigned barber when a client books a new appointment (pending confirmation).
  static String buildNewAppointmentBarberMessage({
    required String barberName,
    required String clientName,
    required String clientPhone,
    required String serviceName,
    required String dateStr,
    required String timeStr,
    String? endTimeStr,
    dynamic appointmentId,
  }) {
    final idStr = appointmentId != null ? " (ID: #$appointmentId)" : "";
    final timeFormatted = endTimeStr != null && endTimeStr.isNotEmpty ? "$timeStr - $endTimeStr" : timeStr;

    return "Hola $barberName, tienes una *NUEVA CITA PENDIENTE DE CONFIRMACIÓN*$idStr.\n\n"
        "👤 Cliente: $clientName\n"
        "📞 Teléfono: $clientPhone\n"
        "💈 Servicio: $serviceName\n"
        "📅 Fecha: $dateStr\n"
        "⏰ Hora: $timeFormatted\n\n"
        "Por favor, ingresa a la aplicación para revisar y confirmar esta cita.";
  }

  /// 30-minute reminder message for the client.
  static String build30MinClientReminder({
    required String clientName,
    required String timeStr,
    required String serviceName,
    required String barberName,
  }) {
    return "Hola, $clientName. Te recordamos que hoy tienes una cita a las $timeStr ($serviceName con $barberName). ¡No olvides llegar puntual!";
  }

  /// 30-minute reminder message for the barber.
  static String build30MinBarberReminder({
    required String barberName,
    required String clientName,
    required String timeStr,
    required String serviceName,
  }) {
    return "Hola, $barberName. Te recordamos que hoy tienes una cita a las $timeStr con el cliente $clientName ($serviceName).";
  }
}
