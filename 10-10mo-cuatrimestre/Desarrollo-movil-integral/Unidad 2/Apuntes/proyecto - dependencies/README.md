# Dependencies — Índice

Aplicación Flutter para capturar consumo de agua y energía, revisar un resumen y consultar un historial. Utiliza un repositorio en memoria e inyección por constructor. El nombre del paquete Dart es `dpendencies`.

| Ubicación | Contenido |
|---|---|
| [`dependencies/`](dependencies/) | Código, pruebas, `pubspec.yaml` y configuración de la aplicación |
| Archivos Markdown de esta carpeta | Guías de arquitectura y pruebas, enlazadas abajo |

## Guías de Estudio

- [Dependencies - Arquitectura y flujo de EcoTrack](Dependencies%20-%20Arquitectura%20y%20flujo%20de%20EcoTrack.md).
- [Dependencies - Pruebas y dependencias de EcoTrack](Dependencies%20-%20Pruebas%20y%20dependencias%20de%20EcoTrack.md).

## Ejecutar

Desde esta carpeta contenedora, entre primero a la aplicación:

```bash
cd dependencies
flutter pub get
flutter run
```

Para ejecutar las pruebas de `test/`, desde esa misma carpeta `dependencies`:

```bash
flutter test
```

La prueba de integración se ejecuta por separado sobre una plataforma de destino. Consulte la guía de pruebas para sus comandos y el estado de sus comprobaciones.

[Volver al índice de Apuntes](../README.md).
