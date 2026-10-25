import 'package:dpendencies/datos/consumo_repositorio.dart';
import 'package:dpendencies/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:integration_test/integration_test.dart';
// Punto de entrada de la prueba: Flutter ejecuta lo que esté dentro de main().
void main() {
// Conecta el motor de pruebas con el dispositivo/emulador. Es obligatorio
// en pruebas de integración y debe ir antes de cualquier testWidgets.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

// Declara un caso de prueba que trabaja con widgets.
  testWidgets(
// Descripción del caso: es lo que aparece en la consola al ejecutarlo.
// Debe decir en lenguaje natural QUÉ se espera que ocurra.
    'Tras confirmar, el historial lista laboratorio, litros y kWh de esa captura',
// Cuerpo de la prueba. "tester" es el robot que dibuja la app, escribe,
// toca botones y espera a que la pantalla se actualice.
        (tester) async {
// Dibuja (monta) la app completa en pantalla, como si el usuario la abriera.
      await tester.pumpWidget(
// Le inyectamos un repositorio en memoria NUEVO y vacío, así cada
// ejecución empieza limpia y no depende de datos guardados antes.
        EcoTrackApp(repsitorio: MemoriaConsumoRepository(),),
      );

// --- PASO 1: Captura en la pantalla "Registrar consumo" ---

// Busca el campo de texto con la llave 'campoLitros' y escribe "12.5".
      await tester.enterText(find.byKey(const Key('campoLitros')), '12.5');
// Busca el campo de texto con la llave 'campoKwh' y escribe "3.2".
      await tester.enterText(find.byKey(const Key('campoKwh')), '3.2');
// No tocamos el selector de laboratorio: se queda con el valor por
// defecto, que es el primero de la lista ('Lab Química').
// Busca el botón que dice "Continuar" y lo toca. Esto valida el
// formulario y, si es válido, navega a la pantalla de Resumen.
      await tester.tap(find.text('Continuar'));
// Espera a que terminen todas las animaciones y cambios de pantalla
// (la transición de Registro a Resumen) antes de seguir.
      await tester.pumpAndSettle();

// --- PASO 2: Confirmación en la pantalla "Resumen" ---

// Busca el botón "Confirmar" y lo toca. Esto GUARDA el consumo en el
// repositorio y reemplaza la pantalla actual por el Historial.
      await tester.tap(find.text('Confirmar'));
// Vuelve a esperar a que se complete el guardado y la navegación,
// y a que el Historial termine de cargar la lista.
      await tester.pumpAndSettle();

// --- PASO 3: Verificación en la pantalla "Historial" ---

// Comprueba que estamos en el Historial: debe existir exactamente
// un texto "Historial" (el título de la barra superior).
      expect(find.text('Historial'), findsOneWidget);
// Comprueba que el registro guardado muestra el laboratorio correcto.
      expect(find.text('Lab Química'), findsOneWidget);
// Comprueba que el registro muestra los litros y kWh que capturamos,
// con el mismo formato que usa la pantalla de Historial.
      expect(find.text('12.5 L · 3.2 kWh'), findsOneWidget);
// Si los tres expect pasan, queda demostrado que Registro, el
// repositorio y el Historial cooperan correctamente.
    },
  );
}