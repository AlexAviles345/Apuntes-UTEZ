# 01 — EcoTrack Modos — Arquitectura y explicación del código

Flutter permite elegir dos configuraciones por separado. El **modo de compilación** determina cómo se construye la app. El **ambiente** determina qué configuración usa EcoTrack al ejecutarse. Por ejemplo, puedes compilar en Debug y seleccionar el ambiente Producción.

## Comparación rápida

| | Modo de compilación | Ambiente |
|---|---|---|
| **¿Qué define?** | Cómo se compila y empaqueta la app, qué optimizaciones aplica Flutter y qué herramientas de depuración están disponibles. | Qué valores usa la app, como la URL base de la API, el tema y las opciones de logs. |
| **¿Qué valores tiene?** | Debug, Profile y Release. | Desarrollo (`dev`), pruebas (`qa`) y producción (`prod`) en esta práctica. |
| **¿Cómo se elige?** | `flutter run` usa Debug por defecto. Se puede indicar `--debug`, `--profile` o `--release`. | Se pasa `--dart-define=AMBIENTE=valor` al ejecutar o compilar. |
| **¿Quién lo define?** | Flutter define los modos disponibles y el desarrollador elige uno para la ejecución o compilación. | El desarrollador define los ambientes, sus nombres y sus valores en el código de la app. |

## 1. Cómo se organiza el código

| Archivo | Responsabilidad |
|---|---|
| [main.dart](ecotrack_modos/lib/main.dart) | Arranca Flutter, muestra el panel y conecta los dos experimentos con el logger y la bitácora. |
| [ambiente.dart](ecotrack_modos/lib/ambiente.dart) | Selecciona nombre, URL de ejemplo, color y opciones de cada ambiente. |
| [logger_seguro.dart](ecotrack_modos/lib/logger_seguro.dart) | Decide qué información llega a la consola. |
| [diagnostico.dart](ecotrack_modos/lib/diagnostico.dart) | Comprueba el número de personas, provoca el error de clase y prepara su explicación. |

## 2. Cómo se lee el modo y el ambiente

### Modo de compilación

`modoActual()` consulta tres constantes de Flutter. Devuelve un `ModoInfo` con la etiqueta y la descripción de la tarjeta **Modo de ejecución**. El modo también se puede comprobar con los tres chips de la pantalla.

| Modo | Comando | Constante verdadera | Uso |
|---|---|---|---|
| Debug | `flutter run` | `kDebugMode` | Desarrollo diario con hot reload y herramientas de depuración. Se prioriza la iteración rápida. |
| Profile | `flutter run --profile` | `kProfileMode` | Medir tiempos de renderizado y uso de memoria con un comportamiento cercano a Release. Las mediciones se realizan en un dispositivo físico. |
| Release | `flutter run --release` | `kReleaseMode` | Ejecutar una versión optimizada. Para distribuirla se genera y firma un paquete con la configuración correspondiente. |

[Modos de compilación de Flutter](https://docs.flutter.dev/testing/build-modes).

### Ambiente

`--dart-define` pasa valores a la configuración de compilación. En [ambiente.dart](ecotrack_modos/lib/ambiente.dart), `Ambiente.actual` lee la opción así.

```dart
const raw = String.fromEnvironment('AMBIENTE', defaultValue: 'dev');
```

El código compara el valor en minúsculas. `qa` selecciona el ambiente de pruebas y `prod` o `production` seleccionan producción. Si falta el argumento o el valor es desconocido, usa `dev`. En este proyecto el valor para pruebas es `qa`. Escribir `AMBIENTE=pruebas` activaría la configuración predeterminada `dev`.

Para opciones que solo admiten `true` o `false`, Dart ofrece `const bool.fromEnvironment('OPCION', defaultValue: false)`. [Declaraciones de entorno en Dart](https://dart.dev/libraries/core/environment-declarations).

| Ambiente | URL que muestra | Color configurado | Logs verbosos | Campo «Banner de depuración» |
|---|---|---|---|---|
| DEV | `https://dev.ecotrack.utez.local/api` | Verde azulado | Sí | Sí |
| QA | `https://qa.ecotrack.utez.edu.mx/api` | Naranja | Sí | Sí |
| PROD | `https://api.ecotrack.utez.edu.mx` | Índigo | No | No |

La app usa esas URL para ilustrar cómo cambia una configuración. El experimento de consumo solo actualiza la pantalla y la consola. El campo **Banner de depuración** en la tarjeta muestra `ambiente.mostrarBanner`. La cinta diagonal **DEBUG** de Flutter se controla por separado: `MaterialApp` deja activa `debugShowCheckedModeBanner` y Flutter la dibuja en Debug. Por eso en Debug + PROD se puede leer «Banner de depuración: no» y seguir viendo la cinta.

### Ejemplos de combinación

```bash
# Release con la configuración del ambiente de pruebas.
flutter run --release --dart-define=AMBIENTE=qa

# Debug con la configuración del ambiente de desarrollo.
flutter run --dart-define=AMBIENTE=dev
```

El primer comando conserva las optimizaciones de Release y selecciona la configuración QA. La [tabla de pruebas](02%20-%20EcoTrack%20Modos%20-%20Gu%C3%ADa%20de%20ejecuci%C3%B3n%20y%20tabla%20de%20pruebas.md#tabla-de-pruebas) muestra otra combinación observada en la práctica, Debug + PROD.

### Seguridad de la configuración

Usa `--dart-define` para valores que se puedan distribuir, como el nombre del ambiente o una URL pública. Los valores que usa la app pueden quedar incorporados en el binario y recuperarse. Guarda las claves privadas, contraseñas de servicios y tokens de administración en el backend. [Seguridad del código compilado en Flutter](https://docs.flutter.dev/deployment/obfuscate).

## 3. Qué hace el panel

- `main()` llama a `LoggerSeguro.info()` para anunciar el ambiente. En Debug emite además una línea con un token **ficticio** de la práctica.
- `EcoTrackModosApp.build()` crea `MaterialApp` con un tema de Material 3 basado en el color del ambiente.
- `PanelModosPage` es un `StatefulWidget` porque el panel recuerda su última acción y las entradas de la bitácora. `_registrar()` usa `setState()` para redibujar la vista. Muestra las ocho entradas más recientes, con hora y la más nueva primero.
- `_simularConsumo()` pide un log de nivel DEBUG con datos ficticios, un INFO de confirmación y agrega a la bitácora el mensaje de consumo simulado.
- `_tarjeta()` reutiliza la estructura visual de título y contenido para organizar el panel.

## 4. Qué se imprime en consola

`LoggerSeguro` aplica condiciones al recibir un mensaje. El cuadro describe la lógica de [logger_seguro.dart](ecotrack_modos/lib/logger_seguro.dart):

| Modo y ambiente | `debug()` | `info()` | `error()` |
|---|---|---|---|
| Debug con cualquier ambiente | Sí | Sí | Tipo o descripción del error y la traza si se entrega. |
| Profile en DEV o QA | Sí | Sí | Descripción y traza si se entrega. |
| Profile en PROD | Se omite | Sí | Descripción y traza si se entrega. |
| Release en DEV o QA | Se omite | Sí | Solo el tipo, por ejemplo `StateError`. |
| Release en PROD | Se omite | Se omite | Solo el tipo, por ejemplo `StateError`. |

La línea del arranque con el token ficticio tiene otra condición en `main()` y solo se intenta imprimir en Debug. El rótulo «Logs verbosos: no» en PROD representa la configuración del ambiente. En Debug, la condición de `LoggerSeguro.debug()` todavía permite mensajes DEBUG con PROD.

## 5. Cómo se provoca y se captura el fallo

```text
Botón «Provocar fallo controlado»
  → dividirLitros(total: 10, personas: 0)
  → StateError antes de efectuar la división
  → catch (e, st)
  → LoggerSeguro.error() + bitácora + diálogo «Análisis del fallo»
```

`dividirLitros()` devuelve `total / personas` para cualquier divisor positivo. En el experimento recibe cero y la validación lanza la excepción de forma deliberada. `explicarFallo()` prepara el texto de reproducción, diagnóstico y corrección que aparece en el diálogo. Ese texto es una nota didáctica de la práctica. El código actual ya detecta un divisor inválido antes de dividir.

La bitácora y el diálogo siguen mostrando el mensaje del error en la interfaz. El filtrado de Release se aplica a la **consola**. El `catch` evita que este fallo controlado termine la aplicación.

## 6. Qué comprueba el test existente

[test/widget_test.dart](ecotrack_modos/test/widget_test.dart) monta `EcoTrackModosApp` y verifica que se muestre el título del panel. La comparación de ambientes, la consola y el diálogo se cubren con los procedimientos de la [guía de pruebas](02%20-%20EcoTrack%20Modos%20-%20Gu%C3%ADa%20de%20ejecuci%C3%B3n%20y%20tabla%20de%20pruebas.md).

[Volver al índice](README.md)
