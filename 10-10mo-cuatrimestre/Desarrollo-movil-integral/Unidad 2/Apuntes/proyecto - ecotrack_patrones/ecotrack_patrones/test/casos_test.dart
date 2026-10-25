import 'dart:math';

import 'package:ecotrack_patrones/casos/factory.dart';
import 'package:ecotrack_patrones/casos/inyeccion_dependencias.dart';
import 'package:ecotrack_patrones/casos/adapter.dart';
import 'package:ecotrack_patrones/casos/observer.dart';
import 'package:ecotrack_patrones/casos/strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el texto del medidor sale como double', () {
    final lector = LectorMedidor(MedidorLegado(azar: Random(1)));
    expect(lector.leerLitros(), isA<double>());
  });

  test('la forma del aviso depende del caso', () {
    expect(Aviso.paraMeta(ahorrados: 50, meta: 50).cumplida, isTrue);
    expect(
      Aviso.paraMeta(ahorrados: 45.5, meta: 50).texto,
      'Faltan 4.5 L para la meta',
    );
  });

  test('el mismo validador, dos reglas', () {
    expect(ValidadorLectura(TopeAgua()).resultado(800), 'aceptada');
    expect(ValidadorLectura(TopeLuz()).resultado(800), 'rechazada');
  });

  testWidgets('historial y meta se enteran al guardar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaPaneles()));
    await tester.tap(find.text('Guardar 12.5 L'));
    await tester.pump();

    expect(find.text('1 registros'), findsOneWidget);
    expect(find.text('Quedan 37.5 L'), findsOneWidget);
  });

  testWidgets('la misma pantalla ensaya el fallo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PantallaRegistro(fuente: LabQueFalla())),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.textContaining('Error'), findsOneWidget);
  });
}
