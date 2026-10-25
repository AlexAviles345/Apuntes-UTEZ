# Ecotrack_reto — Actividad y Criterios de Solución

El objetivo es **refactorizar una aplicación que ya funciona**: cambiar la distribución de responsabilidades sin rediseñar su interfaz ni reemplazar sus operaciones por otras. EcoTrack registra litros por laboratorio, valida la entrada, conserva un historial y calcula su total. Puede utilizar una lista en memoria o un servicio que simula una nube.

## Punto de Partida y Resultado Esperado

| Antes | Después |
|---|---|
| [`main_mezclado.dart`](proyectos/ecotrack_reto%20-%20original/lib/main_mezclado.dart) concentra interfaz, reglas, estado, almacenamiento y mapas | Nueve archivos reparten esas responsabilidades entre dominio, datos, presentación y el arranque |
| El `State` construye y consulta los datos | El ViewModel coordina un repositorio recibido por constructor |
| El botón contiene las reglas de consumo | `ReglaConsumo` concentra las reglas y recibe la fecha de referencia |
| La pantalla decide entre memoria y nube | `main.dart` elige la implementación y compone los objetos |
| Para probar el guardado es necesario montar la pantalla | Dominio, repositorios y ViewModel pueden probarse sin dibujar la interfaz |

El original solo contiene `lib/main_mezclado.dart` dentro de `lib/`. Sus pruebas ya describen la estructura futura; por eso pueden fallar por archivos inexistentes aunque la aplicación mezclada sí funcione al ejecutarla con su entrada específica.

## Qué Se Debe Conservar

- Los tres laboratorios: `Lab Química`, `Lab Redes` y `Lab Física`.
- Conversión de texto con espacios exteriores y coma decimal: `12,5` se interpreta como `12.5`.
- Rechazo de laboratorio vacío, litros no positivos, litros mayores que `10000` y fecha futura, en ese orden.
- Aceptación de exactamente `10000` litros.
- Filtrado por laboratorio, total del historial y registros mostrados del más reciente al más antiguo.
- Textos, tema verde, distribución de controles y la llave `Key('campoLitros')`.
- Limpieza del campo y SnackBar `Consumo guardado` solo después de un guardado exitoso.
- Indicador de carga y desactivación del botón mientras la operación está en curso.
- Esperas de la nube simulada: `600 ms` al guardar y `400 ms` al consultar.

Los flujos secuenciales se compararon con el original. Existe una diferencia identificada al cambiar de laboratorio durante un guardado en nube: se explica en la [guía de arquitectura final](04%20-%20Ecotrack_reto%20-%20Arquitectura%20final%20y%20flujos.md#cambiar-de-laboratorio-durante-un-guardado). La separación sigue el contrato que exige crear el `Consumo` antes de llamar al repositorio.

## Capas y Responsabilidades

| Lugar | Contenido | Qué debe desconocer |
|---|---|---|
| `dominio/` | `Consumo`, catálogo de laboratorios y `ReglaConsumo` | Flutter, widgets, JSON y fuente de almacenamiento |
| `datos/` | Contrato, repositorios y servicio simulado | Widgets, `BuildContext` y avisos de interfaz |
| `presentacion/registro_view_model.dart` | Estado, conversión de entrada y coordinación | Widgets concretos, implementación de repositorio y servicio |
| `presentacion/registro_page.dart` | Controles, representación, controlador de texto y SnackBar | Elección de memoria o nube y traducción de mapas |
| `main.dart` | Composición de la aplicación | Reglas de validación o implementación de la interfaz de registro |

El dominio recibe un `double`, no texto de un campo. La conversión de texto pertenece al ViewModel; las restricciones del consumo pertenecen al dominio. Esta diferencia evita duplicar reglas en la pantalla.

## Contratos que No Deben Cambiar

Las pruebas dependen de estos nombres y operaciones:

| Archivo | API requerida |
|---|---|
| `dominio/consumo.dart` | `laboratoriosUtez` y `Consumo(laboratorio:, litros:, fecha:)` |
| `dominio/regla_consumo.dart` | `ReglaConsumo.topeLitros` y `validar(Consumo, {required DateTime hoy})` |
| `datos/consumo_repository.dart` | `guardar(Consumo)` y `listarPorLaboratorio(String)` mediante `Future` |
| `datos/memoria_consumo_repository.dart` | `MemoriaConsumoRepository implements ConsumoRepository` |
| `datos/consumo_service.dart` | `ConsumoService.post(Map<String, Object>)` y `get(String)` |
| `datos/nube_consumo_repository.dart` | `NubeConsumoRepository(ConsumoService)` e implementación del mismo contrato |
| `presentacion/registro_view_model.dart` | `RegistroViewModel(ConsumoRepository, {DateTime Function()? reloj})`, estado, `cambiarLaboratorio`, `guardar` y `totalLitros` |
| `presentacion/registro_page.dart` | `RegistroPage({required RegistroViewModel viewModel})` |
| `main.dart` | `usarNube` y `EcoTrackApp({required ConsumoRepository repositorio})` |

`guardar(String litrosTexto)` devuelve `Future<bool>` en el ViewModel. Ese resultado permite que la vista distinga un rechazo de un guardado confirmado sin conocer las reglas ni acceder al repositorio.

## Restricciones Arquitectónicas

1. `dominio/` y `datos/` no importan paquetes de Flutter.
2. El ViewModel importa `foundation.dart` para `ChangeNotifier`, no `material.dart`.
3. El ViewModel conoce el contrato `ConsumoRepository` y no crea una implementación concreta.
4. El servicio solo maneja mapas. La conversión entre `Consumo` y mapas vive en el repositorio de nube.
5. `Consumo` no tiene `toJson` ni `fromJson`.
6. La fecha `hoy` de la regla es obligatoria: el dominio no consulta el reloj del sistema.
7. El SnackBar permanece en la vista.
8. Solo `main.dart` decide qué fuente utiliza la solución.
9. Las pruebas entregadas y `verificar_capas.sh` se conservan sin cambios.

## Orden de Resolución

```text
Dominio
    → contrato y datos
    → ViewModel
    → vista y composición
    → comprobación funcional y de dependencias
```

Este orden permite construir cada parte sobre contratos ya definidos. Mover bloques sin ajustar sus dependencias puede repartir el archivo en carpetas y mantener la mezcla original.

La solución aplica separación en tres capas con MVVM en presentación. La guía oficial de Flutter también distingue vistas, ViewModels, repositorios y servicios como responsabilidades diferentes; aquí se utiliza la distribución concreta exigida por el ejercicio. [Guía de arquitectura de Flutter](https://docs.flutter.dev/app-architecture/guide).

[Siguiente: antes del refactor](02%20-%20Ecotrack_reto%20-%20Antes%20del%20refactor.md) · [Índice](README.md).
