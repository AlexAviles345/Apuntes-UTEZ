import 'package:flutter/foundation.dart';

import 'ambiente.dart';

/// Logger que **no** imprime detalles sensibles en release ni en prod.
///
/// Regla de la clase: un `print` con token/correo/contraseña en release
/// es una fuga. Usen este envoltorio (o uno equivalente) en sus proyectos.
class LoggerSeguro {
  LoggerSeguro._();

  static void debug(String etiqueta, String mensaje) {
    if (!kDebugMode && !Ambiente.actual.logsVerbosos) return;
    if (kReleaseMode) return;
    // ignore: avoid_print
    print('[DEBUG][$etiqueta] $mensaje');
  }

  static void info(String etiqueta, String mensaje) {
    if (kReleaseMode && !Ambiente.actual.logsVerbosos) return;
    // ignore: avoid_print
    print('[INFO][$etiqueta] $mensaje');
  }

  static void error(String etiqueta, Object error, [StackTrace? stack]) {
    // En release solo el tipo/mensaje corto; el stack completo queda para debug/profile.
    if (kReleaseMode) {
      // ignore: avoid_print
      print('[ERROR][$etiqueta] ${error.runtimeType}');
      return;
    }
    // ignore: avoid_print
    print('[ERROR][$etiqueta] $error');
    if (stack != null) {
      // ignore: avoid_print
      print(stack);
    }
  }
}
