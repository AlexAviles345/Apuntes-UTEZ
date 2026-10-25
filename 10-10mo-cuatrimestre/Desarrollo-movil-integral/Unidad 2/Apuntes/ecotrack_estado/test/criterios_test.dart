// Dos filas de la tabla de criterios, comprobadas en las tres variantes:
//   Dato compartido: lo guardado en Registro aparece en Historial.
//   Sustitución: se entrega otra fuente de datos y las pantallas no cambian.

// Importa el contrato y el repositorio en memoria.
import 'package:ecotrack_estado/datos/consumo_repository.dart';
// Importa la entidad Consumo.
import 'package:ecotrack_estado/dominio/consumo.dart';
// Importa la app de la variante A.
import 'package:ecotrack_estado/variantes/a_change_notifier.dart';
// Importa la app de la variante provider.
import 'package:ecotrack_estado/variantes/b_provider.dart';
// Importa la app de la variante riverpod y su repositorioProvider.
import 'package:ecotrack_estado/variantes/b_riverpod.dart';
// Importa los widgets de Material (Key, Widget...).
import 'package:flutter/material.dart';
// Importa ProviderScope para montar la variante riverpod en el test.
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa las herramientas de pruebas de widgets (testWidgets, find, expect...).
import 'package:flutter_test/flutter_test.dart';

// Repositorio falso que anota lo que recibe, para comprobar la sustitución.
class RepositorioEspia implements ConsumoRepository {
  // Consumos que le llegaron.
  final List<Consumo> recibidos = [];

  // Indica que cumple el contrato de ConsumoRepository.
  @override
  // Guarda el consumo en la lista del espía.
  Future<void> guardar(Consumo consumo) async => recibidos.add(consumo);

  // Indica que cumple el contrato de ConsumoRepository.
  @override
  // Devuelve una copia de lo recibido.
  Future<List<Consumo>> todos() async => List.of(recibidos);
}

// Pasos comunes: registrar 12.5 L y cambiar a la pestaña Historial.
Future<void> guardarYVerHistorial(WidgetTester tester) async {
  // Escribe 12.5 en el campo con clave 'litros'.
  await tester.enterText(find.byKey(const Key('litros')), '12.5');
  // Toca el botón "Guardar".
  await tester.tap(find.text('Guardar'));
  // Espera a que terminen animaciones y tareas pendientes.
  await tester.pumpAndSettle();
  // Toca la pestaña "Historial".
  await tester.tap(find.text('Historial'));
  // Espera a que se redibuje.
  await tester.pumpAndSettle();
}

// Punto de entrada de las pruebas.
void main() {
  // Mapa nombre -> función que construye la app de cada variante con un repositorio dado.
  final variantes = <String, Widget Function(ConsumoRepository)>{
    // Variante A: el repositorio se pasa por constructor.
    'A · ChangeNotifier': (repo) => AppChangeNotifier(repositorio: repo),
    // Variante provider: el repositorio se pasa por constructor.
    'B · provider': (repo) => AppProvider(repositorio: repo),
    // Variante riverpod: se monta dentro de un ProviderScope...
    'B · riverpod': (repo) => ProviderScope(
      // ...y se reemplaza repositorioProvider por el repositorio del test.
      overrides: [repositorioProvider.overrideWithValue(repo)],
      // App de riverpod sin cambios.
      child: const AppRiverpod(),
    ),
  };

  // Recorre cada variante, separando su nombre y su función constructora.
  for (final MapEntry(key: nombre, value: crear) in variantes.entries) {
    // Agrupa las pruebas bajo el nombre de la variante.
    group(nombre, () {
      // Prueba del criterio "Dato compartido".
      testWidgets('Dato compartido: Registro guarda, Historial lo ve', (
        // Herramienta que controla la app durante la prueba.
        tester,
      ) async {
        // Monta la app con el repositorio en memoria.
        await tester.pumpWidget(crear(MemoriaConsumoRepository()));
        // Guarda 12.5 L y abre Historial.
        await guardarYVerHistorial(tester);

        // Comprueba que Historial muestra exactamente un texto con el total.
        expect(find.text('Total: 12.5 L'), findsOneWidget);
      });

      // Prueba del criterio "Sustitución".
      testWidgets('Sustitución: otra fuente de datos, mismas pantallas', (
        // Herramienta que controla la app durante la prueba.
        tester,
      ) async {
        // Crea el repositorio espía.
        final espia = RepositorioEspia();
        // Monta la app con el espía en lugar del repositorio en memoria.
        await tester.pumpWidget(crear(espia));
        // Guarda 12.5 L y abre Historial.
        await guardarYVerHistorial(tester);

        // Comprueba que el espía recibió un solo consumo y que es de 12.5 L.
        expect(espia.recibidos.single.litros, 12.5);
      });

      // Prueba del criterio "Capas".
      testWidgets('Capas: la regla del dominio llega como error a la vista', (
        // Herramienta que controla la app durante la prueba.
        tester,
      ) async {
        // Monta la app con el repositorio en memoria.
        await tester.pumpWidget(crear(MemoriaConsumoRepository()));
        // Escribe 0, que la regla del dominio rechaza.
        await tester.enterText(find.byKey(const Key('litros')), '0');
        // Toca "Guardar".
        await tester.tap(find.text('Guardar'));
        // Espera a que se redibuje.
        await tester.pumpAndSettle();

        // Comprueba que el mensaje de validarLitros aparece en pantalla.
        expect(
          // Busca el texto del error.
          find.text('Los litros deben ser mayores que cero'),
          // Debe aparecer exactamente una vez.
          findsOneWidget,
        );
      });
    });
  }
}
