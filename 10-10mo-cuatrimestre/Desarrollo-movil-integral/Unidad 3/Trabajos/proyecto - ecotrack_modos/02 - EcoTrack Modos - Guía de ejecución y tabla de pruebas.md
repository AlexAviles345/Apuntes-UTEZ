# 02 — EcoTrack Modos — Guía de ejecución y tabla de pruebas

Esta práctica combina un **modo de compilación** de Flutter con un **ambiente** de la app. QA y Producción se eligen con `AMBIENTE`. Debug, Profile y Release se eligen con los argumentos de Flutter.

## Preparación

Entra a `ecotrack_modos/`, donde está [pubspec.yaml](ecotrack_modos/pubspec.yaml), y prepara las dependencias y el dispositivo:

```bash
flutter pub get
flutter devices
```

Usa un emulador o un teléfono Android para Debug. Para ejecutar los comandos estándar de Profile y Release, selecciona un dispositivo físico Android. La compilación del APK se puede ejecutar sin dispositivo conectado. [Modos de compilación de Flutter](https://docs.flutter.dev/testing/build-modes).

## Comandos de la práctica

Ejecuta cada prueba por separado. Si Flutter mantiene la ejecución abierta, sal con `q` antes de cambiar de modo o ambiente:

```bash
# Debug con ambiente DEV predeterminado.
flutter run

# QA y Producción sin cambiar el modo Debug.
flutter run --dart-define=AMBIENTE=qa
flutter run --dart-define=AMBIENTE=prod

# Profile con ambiente DEV predeterminado.
flutter run --profile

# Ejecutar la versión Release en ambiente Producción.
flutter run --release --dart-define=AMBIENTE=prod

# Generar el APK para Android.
flutter build apk --release --dart-define=AMBIENTE=prod
```

Con varios dispositivos, selecciona el destino con `-d ID_DEL_DISPOSITIVO`. El APK estándar se escribe en `build/app/outputs/flutter-apk/app-release.apk`. Esta práctica usa la firma de Debug para la compilación Release de laboratorio. La firma y el modo de compilación son configuraciones separadas. [Configuración Android del proyecto](ecotrack_modos/android/app/build.gradle.kts).

En cada sesión revisa primero las dos tarjetas del panel. Después pulsa **1 · Simular registro + logs** y **2 · Provocar fallo controlado**. Compara lo que se agrega a la bitácora con la salida de la terminal.

## Tabla de pruebas

Se construyeron APK Android para los tres ambientes en Debug. Las capturas de esas tres filas vienen de una prueba que montó el panel Flutter a tamaño móvil (420 × 880), con una fuente legible para la evidencia. **Profile y Release** se observaron en un emulador Pixel 10, instalando sus APK con ADB. Los extractos de consola se reprodujeron en WebP a partir de la salida real de los comandos.

| # | Prueba | Modo / configuración utilizada | ¿Qué observé en la aplicación (UI)? | ¿Qué observé en consola? |
|---|---|---|---|---|
| 1 | Ejecución en Debug | Debug + DEV | El panel mostró `DEBUG`, `kDebugMode=true`, tema verde azulado y ambiente `DEV`. La bitácora empezó vacía. | El arranque indicó `ambiente=dev`. Se imprimió la línea de token ficticio y, al simular consumo, salieron `DEBUG` e `INFO`. |
| 2 | Ejecución en ambiente QA | Debug + `AMBIENTE=qa` | Se mantuvo el modo `DEBUG`. Cambiaron el tema a naranja y la API de ejemplo al dominio de QA. El consumo simulado se agregó a la bitácora. | Se leyó `ambiente=qa` en el arranque. El consumo produjo un `DEBUG` con los datos ficticios y un `INFO` de confirmación. |
| 3 | Ejecución en ambiente Producción | Debug + `AMBIENTE=prod` | El tema cambió a índigo y se mostró `PROD`. La tarjeta indicó «Logs verbosos: no» y «Banner de depuración: no». El modo siguió en `DEBUG` con su cinta diagonal. | Se leyó `ambiente=prod`. Siguieron apareciendo `INFO` y `DEBUG` porque la compilación era Debug. |
| 4 | Configuración de Profile | Profile + DEV | El APK instalado mostró `PROFILE` y `kProfileMode=true`. Los chips Debug y Release quedaron en `false` y desapareció la cinta de Flutter. | El APK se compiló e instaló. Aparecieron `INFO` de arranque y `DEBUG` del consumo en DEV. Al provocar el fallo, se registraron el mensaje y la traza. |
| 5 | Compilación en Release | Release + `AMBIENTE=prod` | En Android se mostró `RELEASE`, `kReleaseMode=true`, tema índigo y ambiente `PROD`, sin cinta Debug. El consumo simulado sí se agregó a la bitácora. | Flutter generó `app-release.apk` (43.6 MB según su salida) y ADB confirmó la instalación. En el log de la aplicación, el arranque y el consumo quedaron silenciados. Al pulsar el botón del fallo apareció `[ERROR][FalloControlado] StateError`. |
| 6 | Revisión de logs | Debug + DEV / QA / PROD. Contraste con Release + PROD. | El registro simulado se agregó a la bitácora en los tres ambientes de Debug. También quedó visible en Release + PROD. | Los tres casos de Debug mostraron el arranque y los logs del consumo. En Release + PROD solo se vio el tipo de error tras provocarlo. Los valores del correo y token que se ven en Debug son datos ficticios del código. |
| 7 | Manejo de errores | «Provocar fallo controlado» | El botón abrió «Análisis del fallo». El panel registró «Fallo capturado» y la aplicación siguió abierta. El diálogo mantuvo el mensaje detallado incluso en Release. | En Debug y Profile apareció el mensaje y la traza de la división inválida. La primera línea apunta a `Diagnostico.dividirLitros()`. En Release + PROD solo se imprimió `StateError`. |

## Evidencia de las pruebas

### Debug con DEV

![Panel de EcoTrack en Debug con ambiente DEV](imagenes/01-debug-dev-panel.webp)

![Salida de compilación y logs de la prueba con DEV](imagenes/01-debug-dev-consola.webp)

### Debug con QA

![Panel de EcoTrack en Debug con ambiente QA](imagenes/02-debug-qa-panel.webp)

![Consumo simulado y entrada en la bitácora de QA](imagenes/02-debug-qa-registro.webp)

![Salida de compilación y logs de la prueba con QA](imagenes/02-debug-qa-consola.webp)

### Debug con Producción

![Panel de EcoTrack en Debug con ambiente PROD](imagenes/03-debug-prod-panel.webp)

![Salida real de PROD en Debug que todavía muestra líneas DEBUG e INFO](imagenes/03-debug-prod-consola.webp)

### Profile con DEV

Se compiló el APK x86-64 y se instaló con ADB para comprobar la interfaz y los mensajes. Para medir rendimiento con DevTools, usa el comando `flutter run --profile` en un teléfono físico. [Perfilado de Flutter](https://docs.flutter.dev/perf/ui-performance).

![Captura Android del panel con kProfileMode verdadero y ambiente DEV](imagenes/04-profile-dev-panel.webp)

![Compilación, instalación y logcat de EcoTrack en Profile](imagenes/04-profile-dev-consola.webp)

### Release con Producción

Se generó el APK con `flutter build apk --release --dart-define=AMBIENTE=prod` y se instaló con ADB. En la prueba se usó `emulator-5560`. Puedes sustituirlo por el ID de tu destino:

```bash
adb -s emulator-5560 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5560 shell am start -W -n mx.edu.utez.ecotrack_modos/.MainActivity
```

El primer botón actualizó la bitácora, aunque la consola quedó en silencio. Después de pulsar el segundo botón, el extracto de `adb logcat` muestra el tipo del error. [Referencia de ADB](https://developer.android.com/tools/adb).

![Captura Android del panel Release con ambiente PROD](imagenes/05-release-prod-panel.webp)

![El consumo simulado se agrega a la bitácora en Release](imagenes/05-release-prod-registro.webp)

![Compilación, instalación y logcat de EcoTrack en Release con PROD](imagenes/05-release-prod-consola.webp)

### Fallo controlado

La aplicación le pasa un divisor de cero a `dividirLitros()`. El guardado de la bitácora y la apertura del diálogo ocurren en `catch`, después de que se lanza `StateError`.

![Diálogo Análisis del fallo en el panel de Debug](imagenes/01-debug-dev-fallo.webp)

![Diálogo Análisis del fallo en el APK Release](imagenes/05-release-prod-fallo.webp)

## Comprobaciones del proyecto

Ejecuté `flutter analyze` y `flutter test`. El análisis terminó sin problemas y pasó la prueba de widgets incluida. Las pruebas temporales de evidencia para DEV, QA y PROD en Debug también pasaron.

[Volver al índice](README.md)
