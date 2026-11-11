# Cafe_utez — Práctica Guiada Pre-Examen (Unidad II)

Aplicación Flutter para gestionar los pedidos pendientes de la **Cafetería UTEZ**, desarrollada como ejercicio pre-examen de la Unidad II. Implementa separación en tres capas (`dominio`, `datos`, `presentacion`), patrón **MVVM** con `ChangeNotifier`, contrato **Repository**, inyección y distribución en el árbol con **`provider`**, navegación entre dos pantallas (`Navigator.push` / `Navigator.pop`) y prueba unitaria del ViewModel.

## Orden de Lectura

1. [Práctica guiada pre-examen — Cafetería UTEZ](01%20-%20Cafe_utez%20-%20Pr%C3%A1ctica%20guiada%20pre-examen.md): instrucciones completas paso a paso (Pasos 0 al 10), hoja de contratos, errores frecuentes, preguntas de repaso, simulacro de 90 minutos y rúbrica de calificación.
2. [Explicación de componentes, arquitectura y flujos](02%20-%20Cafe_utez%20-%20Explicaci%C3%B3n%20de%20componentes%2C%20arquitectura%20y%20flujos.md): análisis detallado de cada archivo, diagramas de dependencias y secuencia, los cuatro tipos de estado, ubicación de `ChangeNotifierProvider` y verificación estática/unitaria.

## Proyecto

| Carpeta | Uso |
|---|---|
| [`cafe_utez/`](cafe_utez/) | Aplicación Flutter completa con la solución implementada, su prueba unitaria y el script `verificar_practica.sh` |

## Ejecutar la Solución y las Verificaciones

Desde esta carpeta (`Ejercicio pre-examen`):

```bash
cd cafe_utez
flutter pub get
flutter run -d chrome
```

Para comprobar el script de capas, el analizador estático y la prueba unitaria desde `cafe_utez/`:

```bash
bash verificar_practica.sh
flutter analyze lib
flutter test -r expanded
```

[Volver al índice de Trabajos](../README.md).

