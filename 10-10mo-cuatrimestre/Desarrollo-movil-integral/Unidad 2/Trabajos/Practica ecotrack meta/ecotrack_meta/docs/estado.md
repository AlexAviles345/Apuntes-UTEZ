# Gestión de estado — EcoTrack Meta

**Equipo:** Alexandro Jesus Ceron Aviles y Roberto Gustavo Mejia Barrera
**Fecha:** 27 de octubre de 2026

## Tipos de estado en nuestro código

| Dato | Tipo (efímero, compartido, derivado, persistido) | Dónde vive |
|---|---|---|
| Pestaña activa | Efímero: solo le importa a la pantalla que la dibuja y se cambia con `setState`. | Campo `_pestana` de `_PantallasEcoTrackState` en `lib/presentacion/vistas.dart`. |
| Texto del campo de litros | Efímero: nadie más lo lee hasta que se toca `Guardar`, y se limpia al guardar. | `TextEditingController _litros` de `_FormularioRegistroState` en `lib/presentacion/vistas.dart`, liberado en su `dispose()`. |
| consumos y meta | Compartido: lo leen Registro, Historial y Meta, y tiene un solo dueño. | Campos `consumos` y `meta` de `ConsumosViewModel` en `lib/presentacion/consumos_view_model.dart`. |
| total y metaSuperada | Derivado: se calcula a partir de `consumos` y `meta` cada vez, no se guarda. | Getters `total`, `avance` y `metaSuperada` de `ConsumosViewModel`; lo comprueba la prueba "total, avance y metaSuperada se derivan de consumos y meta" (`test/etapa3_viewmodel_test.dart`). |
| Lo que regresa todos() | Persistido: es la fuente de verdad y el ViewModel solo guarda una copia que vuelve a leer. | `_consumos` de `MemoriaConsumoRepository` en `lib/datos/memoria_consumo_repository.dart`, expuesto como copia con `List.unmodifiable`. |

## Criterios

| Criterio | A · ChangeNotifier puro | B · provider |
|---|---|---|
| Dato compartido | Las tres pestañas ven el mismo `_vm` creado en `_AppChangeNotifierState`; pasa "Dato compartido: Registro guarda, Historial y Meta lo ven" en `test/etapa4_change_notifier_test.dart`. | Las tres pestañas piden el mismo ViewModel al `ChangeNotifierProvider` de `AppProvider`; pasa la misma prueba en `test/etapa5_provider_test.dart`. |
| Capas | `vistas.dart` no conoce al ViewModel y el error sale de `validarLitros`; pasa "Capas: el error del dominio aparece y no se guarda nada" en `etapa4_change_notifier_test.dart` y los puntos 4 y 5 de `verificar_estado.sh`. | Las mismas vistas tontas sin cambios y el mismo ViewModel; pasa "Capas" en `etapa5_provider_test.dart` y los puntos 6 y 7 de `verificar_estado.sh`. |
| Encaje con el diagrama | Vista tonta → adaptador `*CN` con `ListenableBuilder` → `ConsumosViewModel` → `ConsumoRepository`, en `lib/variantes/a_change_notifier.dart`. | Vista tonta → adaptador `*Provider` con `context.watch`/`context.read` → `ConsumosViewModel` → `ConsumoRepository`, en `lib/variantes/b_provider.dart`. |
| Constructores que reciben vm | 3: `RegistroCN`, `HistorialCN` y `MetaCN` (`required this.vm`); una subpantalla nueva sería un cuarto. | 0: los adaptadores son `const` sin parámetros y lo piden al árbol; lo comprueba "Los adaptadores piden el ViewModel al árbol, no al constructor". |
| Quién libera el ViewModel | Nosotros, a mano: `_vm.dispose()` en `_AppChangeNotifierState.dispose()`, porque ese `State` lo creó. | El `ChangeNotifierProvider` lo libera solo cuando sale del árbol; en `b_provider.dart` no hay ningún `dispose()`. |
| Costo de adoptarla ahora | Cero dependencias, pero más código: `a_change_notifier.dart` necesitó un `StatefulWidget` y tres `ListenableBuilder` (50 líneas agregadas en el commit `feat(variante-a)`). | Una dependencia (`provider` en `pubspec.yaml`) y poco código: pasar de A a B tocó solo `b_provider.dart` y `main.dart` (41 líneas agregadas y 20 quitadas en el commit `feat(variante-b)`), sin una línea del ViewModel. |
| Sustitución de la fuente de datos | `AppChangeNotifier` recibe cualquier `ConsumoRepository`; con `RepositorioEspia` pasa "Sustitución: con otra fuente de datos las pantallas no cambian" en `etapa4_change_notifier_test.dart`. | `AppProvider` recibe cualquier `ConsumoRepository`; pasa la misma prueba de "Sustitución" en `etapa5_provider_test.dart`, y solo `main.dart` importa `MemoriaConsumoRepository`. |

## Elección

Elegimos: B · provider, porque ningún adaptador recibe `vm` por constructor y la liberación del ViewModel queda a cargo de `ChangeNotifierProvider` (`lib/variantes/b_provider.dart`).
Se mantiene esta pieza del diagrama: `ConsumosViewModel` (`lib/presentacion/consumos_view_model.dart`), que no cambió ni una línea entre el commit `feat(variante-a)` y el commit `feat(variante-b)`, y lo usan igual las dos variantes.
Esta pieza es la que podría sustituirse después: `MemoriaConsumoRepository`, por una fuente real (red o disco) que cumpla `ConsumoRepository`, cambiando solo `lib/main.dart`, como demuestra `RepositorioEspia` en las pruebas de "Sustitución".
