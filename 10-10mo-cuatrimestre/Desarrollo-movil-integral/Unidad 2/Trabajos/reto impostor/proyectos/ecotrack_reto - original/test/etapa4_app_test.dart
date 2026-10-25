// ETAPA 4 — VISTA Y RAÍZ DE COMPOSICIÓN
// Pasa cuando lib/main.dart arma EcoTrackApp con el repositorio que recibe
// y RegistroPage se ve y se comporta igual que main_mezclado.dart.
//
//   flutter test test/etapa4_app_test.dart -r expanded
//
// NO EDITAR: el docente vuelve a correr una copia limpia de este archivo.

import 'package:ecotrack_reto/datos/memoria_consumo_repository.dart';
import 'package:ecotrack_reto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() => EcoTrackApp(repositorio: MemoriaConsumoRepository());

  testWidgets('arranca vacía, igual que la versión mezclada', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('EcoTrack — Registro'), findsOneWidget);
    expect(find.text('Sin consumos todavía'), findsOneWidget);
    expect(find.text('Historial de Lab Química · 0.0 L'), findsOneWidget);
  });

  testWidgets('con litros válidos guarda, avisa y lista el consumo',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byKey(const Key('campoLitros')), '12.5');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Consumo guardado'), findsOneWidget);
    expect(find.text('12.5 L'), findsOneWidget);
    expect(find.text('Historial de Lab Química · 12.5 L'), findsOneWidget);
  });

  testWidgets('con litros en cero muestra el motivo y no guarda',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byKey(const Key('campoLitros')), '0');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Los litros deben ser mayores que cero'), findsOneWidget);
    expect(find.text('Sin consumos todavía'), findsOneWidget);
  });
}
