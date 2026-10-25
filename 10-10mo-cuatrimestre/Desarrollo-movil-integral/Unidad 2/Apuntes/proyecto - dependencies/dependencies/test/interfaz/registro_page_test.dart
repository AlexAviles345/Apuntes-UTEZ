//import para widget
import 'dart:math';

import 'package:dpendencies/datos/consumo_repositorio.dart';
import 'package:dpendencies/presentacion/registro_page.dart';
import 'package:dpendencies/presentacion/resumen_page.dart';
import 'package:flutter_test/flutter_test.dart';
//import para tess
import 'package:flutter/material.dart';

//Se arma la pantalla a probar, esta es la uqe usaremos en cada test
Widget pantalla()=> MaterialApp(home: RegistroPage(repositorio: MemoriaConsumoRepository()));

//Punto de entrdaa aqui se declaran todos los casos de prueba del Widet o pantalla a probar
void main() {

  //Caso 1: Litros vacios

  testWidgets('Con litros vacios, se lee el mensaje y la pantalla de resumen no aparece', (tester) async {
    await tester.pumpWidget(pantalla());

    await tester.enterText(find.byKey(const Key ('campoKwh')), '3');

    await tester.tap(find.text('Continuar'));

    await tester.pumpAndSettle();
    expect(find.text('Escribe litros'), findsOneWidget);
    expect(find.byType(ResumenPage), findsNothing);
  });


  // Caso 2 litros en 0
  testWidgets('Con litros en cero, se lee el mensaje de rango', (tester) async {


    await tester.pumpWidget(pantalla());

    await tester.enterText(find.byKey(const Key('campoLitros')), '0');

    await tester.enterText(find.byKey(const Key('campoKwh')), '3');

    await tester.tap(find.text('Continuar'));

    await tester.pumpAndSettle();

    expect(find.text('los litros deben ser mayores que cero'), findsOneWidget);
    expect(find.byType(ResumenPage), findsNothing);
  });

  // Caso 3 probar con todos los datos validos
  testWidgets('Con datos válidos, no hay errores y aparece el resumen', (tester) async {

    await tester.pumpWidget(pantalla());

    await tester.enterText(find.byKey(const Key('campoLitros')), '100');

    await tester.enterText(find.byKey(const Key('campoKwh')), '3');

    await tester.tap(find.text('Continuar'));

    await tester.pumpAndSettle();
    expect(find.text('Escribe litros'), findsNothing);
    expect(find.text('Escribe kwh'), findsNothing);
    expect(find.text('los litros deben ser mayores que cero'), findsNothing);

  });

  testWidgets('Con litros=5 y kWh=3 navega al resumen', (tester) async {
    await tester.pumpWidget(pantalla());

    await tester.enterText(find.byKey(const Key('campoLitros')), '5');
    await tester.enterText(find.byKey(const Key('campoKwh')), '3');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(ResumenPage), findsOneWidget);
    expect(find.text('Escribe los litros'), findsNothing);
    expect(find.text('Los litros deben de ser mayores que cero'), findsNothing);
  });
}

