# Ecotrack_patrones — Pruebas y Dependencias

La suite de [`test/casos_test.dart`](ecotrack_patrones/test/casos_test.dart) contiene **cinco casos: tres pruebas unitarias y dos pruebas de widgets**. Comprueban colaboraciones concretas de Adapter, Factory, Strategy, Observer e inyección de dependencias. Repository no tiene un caso específico en este archivo.

## Dependencias de Pruebas

El [`pubspec.yaml`](ecotrack_patrones/pubspec.yaml) declara:

```yaml
environment:
  sdk: ^3.13.3

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

| Declaración | Función en este proyecto |
|---|---|
| `flutter` | SDK utilizado por la aplicación y los widgets que se montan en las pruebas |
| `flutter_test` | Proporcionar el entorno de pruebas, `test`, `testWidgets`, `expect`, finders, matchers y `WidgetTester` |
| `flutter_lints` | Reglas de análisis estático; no ejecuta los casos ni verifica sus resultados |
| `sdk: ^3.13.3` | Requerir una versión de Dart compatible con ese rango; usar un Flutter que incluya un Dart apropiado |

[`analysis_options.yaml`](ecotrack_patrones/analysis_options.yaml) incluye `package:flutter_lints/flutter.yaml`. [`pubspec.lock`](ecotrack_patrones/pubspec.lock) registra las versiones resueltas; entre sus dependencias transitivas aparecen `test_api` y `matcher`, que no se declaran directamente en el manifiesto.

`dart:math`, utilizado para `Random(1)`, y `package:flutter/material.dart` no son paquetes de mocking. No se declaran `mockito`, `mocktail`, `integration_test`, Provider o Riverpod. La prueba de error utiliza una implementación concreta ya incluida en la aplicación: `LabQueFalla`.

## Cómo Se Organiza el Archivo

```text
main() de casos_test.dart
├── test: Adapter
├── test: Factory
├── test: Strategy
├── testWidgets: Observer
└── testWidgets: inyección de dependencias
```

Este `main()` registra las pruebas. No llama al `main()` de la aplicación ni abre su menú. Los imports apuntan a `package:ecotrack_patrones/casos/...`, utilizando el nombre declarado en `pubspec.yaml`.

Las pruebas unitarias llaman directamente a clases y métodos. Las de widgets construyen un árbol de interfaz dentro del entorno de Flutter, realizan acciones y buscan resultados visibles. La documentación oficial explica el papel de `pumpWidget`, `pump`, finders y matchers en este proceso. [Introducción a pruebas de widgets](https://docs.flutter.dev/cookbook/testing/widget/introduction).

## Las Tres Pruebas Unitarias

| Nombre existente | Preparación y acción | Comprobación | Alcance real |
|---|---|---|---|
| `el texto del medidor sale como double` | Crear `LectorMedidor(MedidorLegado(azar: Random(1)))` y leer | `isA<double>()` | Una lectura del simulador devuelve un número de ese tipo |
| `la forma del aviso depende del caso` | Pedir avisos con `50/50` y `45.5/50` | `cumplida` es `true` y el texto pendiente es `Faltan 4.5 L para la meta` | Se verifican igualdad con la meta y un texto pendiente concreto |
| `el mismo validador, dos reglas` | Validar `800` con `TopeAgua` y con `TopeLuz` | `aceptada` y `rechazada` | La misma clase de contexto produce resultados distintos al recibir otra estrategia |

Cada fila corresponde a un caso de prueba, aunque dentro haya más de un `expect`. Por ello, dos expectativas de Factory no cuentan como dos pruebas independientes.

### Adapter: Controlar el Generador

```dart
final lector = LectorMedidor(MedidorLegado(azar: Random(1)));
expect(lector.leerLitros(), isA<double>());
```

La semilla controla la secuencia del generador utilizado por esta ejecución del entorno. La prueba solo exige el tipo final; no fija el valor leído ni compara el texto original con el número convertido. Tampoco ensaya un formato inválido.

### Factory: Verificar el Producto

El caso llama directamente a `Aviso.paraMeta(...)`. No necesita montar `PantallaAviso` porque su objetivo es comprobar datos del aviso. El valor exacto de la meta prueba que la condición incluye la igualdad. La rama pendiente comprueba el cálculo y el formato a un decimal.

### Strategy: Sustituir la Regla

La prueba construye dos `ValidadorLectura`, uno por estrategia. No cambia un campo del mismo validador ni toca el selector de la interfaz. Comprueba que `800` satisface la regla de agua y supera la de luz.

## Prueba de Widgets de Observer

El flujo existente es:

```dart
await tester.pumpWidget(const MaterialApp(home: PantallaPaneles()));
await tester.tap(find.text('Guardar 12.5 L'));
await tester.pump();

expect(find.text('1 registros'), findsOneWidget);
expect(find.text('Quedan 37.5 L'), findsOneWidget);
```

1. `pumpWidget` monta la pantalla con un `MaterialApp` y produce su primer frame. La pantalla crea el registro real y sus dos paneles.
2. `find.text` localiza el botón; `tap` ejecuta su interacción.
3. El botón llama a `guardar`, el registro agrega el dato y notifica a los listeners.
4. `pump` procesa un frame para reflejar las reconstrucciones pendientes.
5. Los dos `expect` verifican que el mismo guardado se refleja en historial y meta.

Esta prueba recorre varios componentes reales, pero sigue siendo una prueba de widgets. No abre la aplicación completa sobre un dispositivo ni usa infraestructura externa.

## Prueba de Widgets de Inyección

La preparación entrega directamente la fuente que falla:

```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: PantallaRegistro(fuente: LabQueFalla())),
  ),
);
await tester.tap(find.byType(FilledButton));
await tester.pump();

expect(find.textContaining('Error'), findsOneWidget);
```

`MaterialApp` aporta el entorno Material y el mensajero; `Scaffold` permite presentar el SnackBar. La pantalla recibe `LabQueFalla`, espera su `Future`, captura la excepción y pide mostrar el mensaje.

`pump()` permite procesar la continuación asíncrona y el frame necesario para esta comprobación. No equivale a esperar cualquier petición remota o animación arbitraria: en este caso la fuente simula el fallo inmediatamente y se busca el texto del mensaje.

El finder `textContaining('Error')` comprueba la presencia de una parte del texto. No verifica la excepción completa, el nombre del laboratorio, el argumento `12.5` ni el comportamiento del interruptor de `PantallaLab`.

## Cobertura Funcional y Límites

| Área | Qué falta comprobar en la suite actual |
|---|---|
| Repository | Guardar, recuperar, proteger la lista interna con la copia y capturar datos desde su pantalla |
| Adapter | Conversión de un texto conocido, rango, formato inválido y actualización de la suma en la interfaz |
| Factory | Valores por encima de la meta y comportamiento del slider e icono |
| Strategy | Fronteras `0`, `500`, `10000`, valores superiores y cambio de segmento |
| Observer | Varias pulsaciones, cantidad y suma acumuladas, vida del registro al cerrar la ruta |
| Inyección | Camino exitoso, datos recibidos por la fuente y sustitución mediante el interruptor |
| Navegación | Abrir cada opción desde `EcoTrackApp` y volver al menú |

Estas son observaciones del alcance, no pruebas adicionales implementadas. Cinco resultados correctos no equivalen a una cobertura completa del código. Tampoco se ha calculado un porcentaje de cobertura en esta revisión.

## Ejecutar las Pruebas

Desde la carpeta contenedora `proyecto - ecotrack_patrones`, entre a la aplicación:

```bash
cd ecotrack_patrones
flutter pub get
flutter test
```

Para ejecutar solo este archivo y ver los nombres de los casos:

```bash
flutter test test/casos_test.dart --reporter expanded
```

Para ejecutar únicamente el caso de Strategy:

```bash
flutter test test/casos_test.dart --plain-name "el mismo validador, dos reglas"
```

El comando `flutter analyze` revisa el código mediante el analizador y las reglas configuradas. Es una verificación diferente a ejecutar las expectativas de la suite.

**Resultado verificado:** `flutter test --no-pub --reporter expanded` completó los cinco casos correctamente. Se utilizó `--no-pub` después de resolver las dependencias; esa opción omite su resolución durante el comando de pruebas.

## Preguntas de Repaso

1. ¿Por qué una prueba con dos `expect` sigue siendo un solo caso?
2. ¿Qué aporta montar un `MaterialApp` en las pruebas de widgets?
3. ¿Qué cambia en la prueba al entregar `LabQueFalla` directamente?
4. ¿Por qué encontrar `Error` no verifica todos los argumentos del guardado?
5. ¿Qué patrón no se comprueba en esta suite y cómo se identifica esa ausencia?

[Anterior: Strategy](07%20-%20Ecotrack_patrones%20-%20Strategy.md) · [Volver a arquitectura general](01%20-%20Ecotrack_patrones%20-%20Arquitectura%20general%20y%20comparativa.md) · [Índice](README.md).
