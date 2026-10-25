# Ecotrack_reto — Reto El Impostor

Guía de estudio para separar una aplicación Flutter que concentra todas sus responsabilidades en un `State`. La solución utiliza tres capas —dominio, datos y presentación—, con MVVM en presentación, Repository e inyección por constructor.

## Orden de Lectura

1. [Actividad y criterios de solución](01%20-%20Ecotrack_reto%20-%20Actividad%20y%20criterios.md): objetivo, contratos, límites y comportamiento que se debe conservar.
2. [Antes: código mezclado](02%20-%20Ecotrack_reto%20-%20Antes%20del%20refactor.md): responsabilidades del archivo original y significado de las seis marcas MEZCLA.
3. [Resolución paso a paso](03%20-%20Ecotrack_reto%20-%20Resoluci%C3%B3n%20paso%20a%20paso.md): extracción de dominio, datos, ViewModel, vista y composición.
4. [Después: arquitectura y flujos](04%20-%20Ecotrack_reto%20-%20Arquitectura%20final%20y%20flujos.md): archivos finales, dependencias, comunicación, estado y comparación con el punto de partida.
5. [Pruebas y verificación](05%20-%20Ecotrack_reto%20-%20Pruebas%20y%20verificaci%C3%B3n.md): las 25 pruebas, alcance del script, comparación funcional y revisión de Git.

## Proyectos

| Carpeta | Uso |
|---|---|
| [`proyectos/ecotrack_reto - original/`](proyectos/ecotrack_reto%20-%20original/) | Punto de partida conservado; la aplicación se ejecuta con `lib/main_mezclado.dart` |
| [`proyectos/ecotrack_reto - final/`](proyectos/ecotrack_reto%20-%20final/) | Solución revisada y corregida; la aplicación se ejecuta con `lib/main.dart` |

Las guías están fuera de ambos proyectos. El código del original, las pruebas de la actividad y el script de verificación se conservan. La versión final también mantiene `main_mezclado.dart` como referencia.

## Ejecutar la Solución

Desde esta carpeta:

```bash
cd "proyectos/ecotrack_reto - final"
flutter pub get
flutter run
```

Desde la misma carpeta del proyecto final:

```bash
flutter test -r expanded
bash verificar_capas.sh
flutter analyze
```

En Windows, el comando `bash` requiere un entorno como Git Bash. Las pruebas verifican resultados; el script realiza comprobaciones estáticas de separación. Es necesario contrastar también las reglas escritas de la actividad.

[Volver al índice de Trabajos](../README.md).
