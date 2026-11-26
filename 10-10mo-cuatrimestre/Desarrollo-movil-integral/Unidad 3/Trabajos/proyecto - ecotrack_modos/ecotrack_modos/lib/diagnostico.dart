/// Fallo controlado para practicar el ciclo: reproducir → diagnosticar → corregir.
class Diagnostico {
  Diagnostico._();

  /// Intencionalmente falla si `personas == 0` (división entre cero).
  static double dividirLitros({required double total, required int personas}) {
    if (personas <= 0) {
      throw StateError(
        'No se puede repartir $total L entre $personas personas (división inválida).',
      );
    }
    return total / personas;
  }

  /// Texto que el docente proyecta al analizar el fallo en clase.
  static String explicarFallo(Object error) {
    return '''
1) Reproducción
   Pulsar "Provocar fallo controlado" con personas = 0 (hardcodeado en la demo).

2) Diagnóstico
   Tipo: ${error.runtimeType}
   Mensaje: $error
   Causa raíz: no validamos el divisor antes de operar.
   Dónde mirar: lib/diagnostico.dart → dividirLitros

3) Corrección (para A04)
   Validar personas > 0 en dominio y mostrar un mensaje usable en UI
   en lugar de dejar que el error suba sin contexto.
''';
  }
}
