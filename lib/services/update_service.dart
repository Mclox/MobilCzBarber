import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import '../core/api.dart';
import '../widgets/update_dialog.dart';

class AppVersionChecker {
  // Asegura que solo hagamos una verificación por sesión de la aplicación
  static bool _hasChecked = false;

  /// Realiza la consulta al backend y compara versiones.
  /// Si hay una versión superior, despliega el diálogo informativo.
  static Future<void> checkForUpdates(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final dio = Dio();
      
      // Tiempos de espera cortos para que si el servidor está apagado no ralentice la app
      dio.options.connectTimeout = const Duration(seconds: 4);
      dio.options.receiveTimeout = const Duration(seconds: 4);

      debugPrint('AppVersionChecker: Consultando la última versión en: ${Api.latestVersion}');
      final response = await dio.get(Api.latestVersion);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final String remoteVersionName = data['version_name'];
        final int remoteVersionCode = data['version_code'];
        final String downloadUrl = data['download_url'];

        // Obtener versión local de la plataforma
        final packageInfo = await PackageInfo.fromPlatform();
        final String localVersionName = packageInfo.version;
        final int localVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

        debugPrint('AppVersionChecker: Local -> $localVersionName+$localVersionCode, Remota -> $remoteVersionName+$remoteVersionCode');

        // Comparación simple por código de versión (entero incremental)
        if (remoteVersionCode > localVersionCode) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: true, // Permite cerrar el diálogo y seguir navegando
              builder: (context) => UpdateDialog(
                currentVersion: '$localVersionName+$localVersionCode',
                newVersion: '$remoteVersionName+$remoteVersionCode',
                downloadUrl: downloadUrl,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Fallamos de manera silenciosa para no interrumpir el flujo normal del usuario si falla la red
      debugPrint('AppVersionChecker: Error al verificar actualización: $e');
    }
  }
}
