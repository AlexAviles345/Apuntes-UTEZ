# EcoTrack Modos — Desarrollo Móvil Integral, Unidad 3

Práctica en Flutter para comparar **Debug, Profile y Release**, cambiar el ambiente con `--dart-define` y observar qué detalles se escriben en consola cuando se simula un consumo o se provoca un error controlado.

## Orden de lectura

1. [Arquitectura y explicación del código](01%20-%20EcoTrack%20Modos%20-%20Arquitectura%20y%20explicaci%C3%B3n%20del%20c%C3%B3digo.md). Explica `main.dart`, `Ambiente`, `LoggerSeguro`, `Diagnostico` y la relación entre el modo, la interfaz y los logs.
2. [Guía de ejecución y tabla de pruebas](02%20-%20EcoTrack%20Modos%20-%20Gu%C3%ADa%20de%20ejecuci%C3%B3n%20y%20tabla%20de%20pruebas.md). Incluye los comandos de la práctica, las siete pruebas y sus evidencias.

El [proyecto Flutter](ecotrack_modos/) se encuentra en la subcarpeta `ecotrack_modos/`. Ejecuta los comandos desde ahí, con una versión de Dart compatible con `^3.13.3`:

```bash
cd ecotrack_modos
flutter pub get
flutter run
```

Como referencia, [EcoTrack HTTP](../../../Unidad%202/Apuntes/proyecto%20-%20ecotrack_http/EcoTrack%20HTTP%20-%20Arquitectura%20y%20funcionamiento.md) también estudia la diferencia entre un dato de diagnóstico técnico y un mensaje mostrado en la interfaz.
