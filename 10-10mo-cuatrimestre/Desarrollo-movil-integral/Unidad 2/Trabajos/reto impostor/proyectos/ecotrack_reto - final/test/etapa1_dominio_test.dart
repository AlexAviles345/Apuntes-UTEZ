// ETAPA 1 — DOMINIO
// Pasa cuando existen lib/dominio/consumo.dart y lib/dominio/regla_consumo.dart
// con los nombres del contrato. No abre pantallas ni usa red.
//
//   flutter test test/etapa1_dominio_test.dart -r expanded
//
// NO EDITAR: el docente vuelve a correr una copia limpia de este archivo.

import 'package:ecotrack_reto/dominio/consumo.dart';
import 'package:ecotrack_reto/dominio/regla_consumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 9, 4, 10);

  Consumo con(double litros, {String laboratorio = 'Lab Química', DateTime? fecha}) =>
      Consumo(laboratorio: laboratorio, litros: litros, fecha: fecha ?? hoy);

  group('Consumo', () {
    test('guarda laboratorio, litros y fecha', () {
      final c = con(12.5);

      expect(c.laboratorio, 'Lab Química');
      expect(c.litros, 12.5);
      expect(c.fecha, hoy);
    });

    test('laboratoriosUtez tiene los tres laboratorios', () {
      expect(laboratoriosUtez, ['Lab Química', 'Lab Redes', 'Lab Física']);
    });
  });

  group('ReglaConsumo.validar', () {
    test('el tope es 10 000 litros', () {
      expect(ReglaConsumo.topeLitros, 10000);
    });

    test('acepta un consumo en rango', () {
      expect(ReglaConsumo.validar(con(12.5), hoy: hoy), isNull);
    });

    test('acepta exactamente el tope', () {
      expect(ReglaConsumo.validar(con(10000), hoy: hoy), isNull);
    });

    test('rechaza laboratorio vacío', () {
      expect(
        ReglaConsumo.validar(con(5, laboratorio: '  '), hoy: hoy),
        'El laboratorio es obligatorio',
      );
    });

    test('rechaza litros en cero o negativos', () {
      expect(
        ReglaConsumo.validar(con(0), hoy: hoy),
        'Los litros deben ser mayores que cero',
      );
      expect(ReglaConsumo.validar(con(-3), hoy: hoy), isNotNull);
    });

    test('rechaza litros sobre el tope', () {
      expect(
        ReglaConsumo.validar(con(10001), hoy: hoy),
        'Los litros superan el tope de 10000',
      );
    });

    test('rechaza fecha futura', () {
      final manana = hoy.add(const Duration(days: 1));

      expect(
        ReglaConsumo.validar(con(5, fecha: manana), hoy: hoy),
        'La fecha no puede ser futura',
      );
    });
  });
}
