# Ecotrack_patrones — Índice

Aplicación Flutter con seis ejemplos de diseño: Factory, inyección de dependencias, Adapter, Repository, Observer y Strategy. Las guías están directamente en esta carpeta; la aplicación completa conserva su nombre en [`ecotrack_patrones/`](ecotrack_patrones/).

## Orden de Lectura

1. [Arquitectura general y comparativa](01%20-%20Ecotrack_patrones%20-%20Arquitectura%20general%20y%20comparativa.md): organización, diferencias, dependencias y duración del estado.
2. [Factory](02%20-%20Ecotrack_patrones%20-%20Factory.md): construcción de avisos según la meta.
3. [Inyección de dependencias](03%20-%20Ecotrack_patrones%20-%20Inyecci%C3%B3n%20de%20dependencias.md): selección externa de una fuente exitosa o que falla.
4. [Adapter](04%20-%20Ecotrack_patrones%20-%20Adapter.md): traducción de la lectura textual a `double`.
5. [Repository](05%20-%20Ecotrack_patrones%20-%20Repository.md): almacenamiento detrás de un contrato.
6. [Observer](06%20-%20Ecotrack_patrones%20-%20Observer.md): notificaciones a historial y meta.
7. [Strategy](07%20-%20Ecotrack_patrones%20-%20Strategy.md): reglas intercambiables de agua y luz.
8. [Pruebas y dependencias](08%20-%20Ecotrack_patrones%20-%20Pruebas%20y%20dependencias.md): tres casos unitarios y dos de widgets, su ejecución y alcance.

Cada guía enlaza el código que estudia y explica los componentes, las llamadas, la dirección de dependencias y los límites de la implementación. La numeración comienza con la visión general y termina con las pruebas.

## Ejecutar

Desde esta carpeta contenedora:

```bash
cd ecotrack_patrones
flutter pub get
flutter run
```

Desde esa misma carpeta de la aplicación:

```bash
flutter test
```

Las seis pantallas se abren desde el menú de `EcoTrackApp`. Son ejemplos independientes: las operaciones de una pantalla no se conectan automáticamente con las de las demás.

[Volver al índice de Apuntes](../README.md).
