# Gestión de estado — EcoTrack (solución de referencia)

**Equipo:** Docente  
**Fecha:** 15/09/2026  
**Biblioteca contrastada:** provider

## Problema

Qué pantallas de nuestro diagrama deben ver el mismo consumo: **Registro** escribe el consumo e **Historial** lo lista con el total. Si cada una tiene su lista, el historial se queda vacío (demo `05_problema_estado.dart`).

## Criterios

| Criterio | ChangeNotifier | Biblioteca elegida (provider) |
|---|---|---|
| Dato compartido | Sí: las dos pantallas escuchan el mismo `ConsumosViewModel` con `ListenableBuilder`, pero hay que pasárselo a cada una por constructor. | Sí: `ChangeNotifierProvider` pone un solo `ConsumosViewModel` en el árbol y cada pantalla lo pide con `context.watch`. |
| Capas | Las pantallas solo conocen el ViewModel; el repositorio se entrega en `main`. | Igual: provider solo entrega el ViewModel; las pantallas no importan el repositorio. |
| Encaje con el diagrama | El ViewModel orquesta y el repositorio guarda, sin cambios. | El mismo `ConsumosViewModel` de la columna A; provider no lo sustituye. |
| Explicación en 3 minutos | “El ViewModel avisa con `notifyListeners` y la vista se repinta.” Se explica con el Observer ya visto. | Lo mismo, más una frase: “provider lo cuelga arriba para no pasarlo a mano.” |
| Costo de adoptarla ahora | Ninguno extra: viene con Flutter. | Una dependencia y tres piezas nuevas (`ChangeNotifierProvider`, `watch`, `read`). |
| Sustitución de la fuente de datos | Se cambia la implementación en `main`; pantallas y ViewModel no se tocan. | Igual: se cambia el repositorio que recibe el `create` del provider. |

## Elección

Elegimos: **provider**, sobre el mismo `ConsumosViewModel` con `ChangeNotifier`. Con más de dos pantallas que leen consumos (registro, historial, meta), pasar el ViewModel por constructor se vuelve una cadena frágil; provider la elimina sin cambiar el ViewModel.  
Se mantiene esta pieza del diagrama: `ConsumosViewModel` y el contrato `ConsumoRepository`.  
Esta pieza es la que podría sustituirse después: `MemoriaConsumoRepository`, por un repositorio que hable con el servicio.

Comprobación: `test/criterios_test.dart` verifica “Dato compartido”, “Sustitución” y “Capas” en las tres variantes.
