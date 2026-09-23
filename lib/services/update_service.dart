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
        final String remoteVersionName = data['version_name']?.toString() ?? '';
        final int remoteVersionCode = int.tryParse(data['version_code']?.toString() ?? '') ?? 0;
        final String downloadUrl = data['download_url']?.toString() ?? '';

        // Obtener versión local de la plataforma
        final packageInfo = await PackageInfo.fromPlatform();
        String localVersionName = packageInfo.version;
        String localBuildNumber = packageInfo.buildNumber;

        // Si la versión local contiene el símbolo '+' (ej. 0.1.21+22)
        if (localVersionName.contains('+')) {
          final parts = localVersionName.split('+');
          localVersionName = parts[0];
          if (localBuildNumber.isEmpty) {
            localBuildNumber = parts[1];
          }
        }

        final int localVersionCode = int.tryParse(localBuildNumber) ?? 0;

        debugPrint('AppVersionChecker: Local -> $localVersionName+$localVersionCode, Remota -> $remoteVersionName+$remoteVersionCode');

        bool isUpdateRequired = false;

        // Comparación por código de versión (entero incremental) si ambos están disponibles
        if (remoteVersionCode > 0 && localVersionCode > 0) {
          isUpdateRequired = remoteVersionCode > localVersionCode;
        } else if (remoteVersionName.isNotEmpty && localVersionName.isNotEmpty) {
          // Si los códigos de versión no están disponibles, comparar semánticamente los nombres
          isUpdateRequired = _compareVersionNames(remoteVersionName, localVersionName) > 0;
        }

        if (isUpdateRequired) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: true, // Permite cerrar el diálogo y seguir navegando
              builder: (context) => UpdateDialog(
                currentVersion: '$localVersionName${localVersionCode > 0 ? "+$localVersionCode" : ""}',
                newVersion: '$remoteVersionName${remoteVersionCode > 0 ? "+$remoteVersionCode" : ""}',
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

  /// Compara dos nombres de versión semánticos (ej: "0.1.21" vs "0.1.20").
  /// Retorna > 0 si v1 > v2, < 0 si v1 < v2, 0 si son iguales.
  static int _compareVersionNames(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }
}
