# 01 — EcoTrack Modos — Arquitectura y explicación del código

La práctica muestra dos configuraciones independientes. El **modo de compilación** lo elige Flutter y afecta a la ejecución. El **ambiente** lo elige la aplicación a partir de `AMBIENTE` y determina los valores que muestra y algunas reglas del logger. Se pueden combinar, por ejemplo, Debug con el ambiente Producción.

## 1. Cómo se organiza el código

| Archivo | Responsabilidad |
|---|---|
| [main.dart](ecotrack_modos/lib/main.dart) | Arranca Flutter, muestra el panel y conecta los dos experimentos con el logger y la bitácora. |
| [ambiente.dart](ecotrack_modos/lib/ambiente.dart) | Selecciona nombre, URL de ejemplo, color y opciones de cada ambiente. |
| [logger_seguro.dart](ecotrack_modos/lib/logger_seguro.dart) | Decide qué información llega a la consola. |
| [diagnostico.dart](ecotrack_modos/lib/diagnostico.dart) | Comprueba el número de personas, provoca el error de clase y prepara su explicación. |

## 2. Cómo se lee el modo y el ambiente

`modoActual()` consulta tres constantes de Flutter. Devuelve un `ModoInfo` con la etiqueta y la descripción de la tarjeta **Modo de ejecución**. El modo también se puede comprobar con los tres chips de la pantalla.

| Modo | Constante verdadera | Uso |
|---|---|---|
| Debug | `kDebugMode` | Desarrollo, hot reload y diagnósticos detallados. Es el modo predeterminado de `flutter run`. |
| Profile | `kProfileMode` | Medición de desempeño con instrumentación. Las mediciones se realizan en un dispositivo físico. |
| Release | `kReleaseMode` | Compilación optimizada de distribución. |

[Modos de compilación de Flutter](https://docs.flutter.dev/testing/build-modes).

`Ambiente.actual` lee `String.fromEnvironment('AMBIENTE', defaultValue: 'dev')`. El valor se compara en minúsculas. Reconoce `qa`, `prod` y `production`. Si falta el argumento o el valor es desconocido, usa `dev`.

| Ambiente | URL que muestra | Color configurado | Logs verbosos | Campo «Banner de depuración» |
|---|---|---|---|---|
| DEV | `https://dev.ecotrack.utez.local/api` | Verde azulado | Sí | Sí |
| QA | `https://qa.ecotrack.utez.edu.mx/api` | Naranja | Sí | Sí |
| PROD | `https://api.ecotrack.utez.edu.mx` | Índigo | No | No |

La app usa esas URL para ilustrar cómo cambia una configuración. El experimento de consumo solo actualiza la pantalla y la consola. El campo **Banner de depuración** en la tarjeta muestra `ambiente.mostrarBanner`. La cinta diagonal **DEBUG** de Flutter se controla por separado: `MaterialApp` deja activa `debugShowCheckedModeBanner` y Flutter la dibuja en Debug. Por eso en Debug + PROD se puede leer «Banner de depuración: no» y seguir viendo la cinta.

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
