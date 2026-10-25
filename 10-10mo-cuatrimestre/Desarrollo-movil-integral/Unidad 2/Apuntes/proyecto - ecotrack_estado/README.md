# Ecotrack_estado — Índice

La misma aplicación de registro de consumo de agua con tres variantes de gestión de estado: ChangeNotifier, Provider y Riverpod.

| Ubicación | Contenido |
|---|---|
| [`ecotrack_estado/`](ecotrack_estado/) | Aplicación Flutter completa, sus pruebas y su configuración |
| Archivos Markdown de esta carpeta | Guías de cada variante, pruebas y comparación, enlazadas abajo |

## Orden de Lectura

1. [Comparativa general: diferencias, ventajas y desventajas](01%20-%20Ecotrack_estado%20-%20Comparativa%20de%20gesti%C3%B3n%20de%20estado.md).
2. [ChangeNotifier y patrón Observer](02%20-%20Ecotrack_estado%20-%20ChangeNotifier%20y%20Observer.md).
3. [Provider e inyección de dependencias](03%20-%20Ecotrack_estado%20-%20Provider%20e%20inyecci%C3%B3n%20de%20dependencias.md).
4. [Riverpod y Notifier](04%20-%20Ecotrack_estado%20-%20Riverpod%20y%20Notifier.md).
5. [Apuntes de referencia sobre estado](05%20-%20Ecotrack_estado%20-%20Apuntes%20de%20referencia.md).
6. [Pruebas de las tres variantes](06%20-%20Ecotrack_estado%20-%20Pruebas%20de%20las%20tres%20variantes.md).

La numeración de los archivos sigue este orden: visión general, variantes, referencia complementaria y pruebas al final.

## Ejecutar la Aplicación y las Pruebas

Desde esta carpeta contenedora, entre a la aplicación y resuelva sus dependencias:

```bash
cd ecotrack_estado
flutter pub get
```

Desde `ecotrack_estado/`, elija una de las entradas:

```bash
flutter run
flutter run -t lib/main_provider.dart
flutter run -t lib/main_riverpod.dart
```

`flutter test` ejecuta los nueve casos de widgets de las tres variantes:

```bash
flutter test
```

[Volver al índice de Apuntes](../README.md).
