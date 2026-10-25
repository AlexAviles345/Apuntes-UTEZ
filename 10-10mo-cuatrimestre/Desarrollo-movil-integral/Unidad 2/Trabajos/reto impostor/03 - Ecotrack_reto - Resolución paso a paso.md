# Ecotrack_reto — Resolución Paso a Paso

La separación se realiza sobre el comportamiento de [`main_mezclado.dart`](proyectos/ecotrack_reto%20-%20original/lib/main_mezclado.dart). Se conservan sus textos, reglas, controles y operaciones; se cambia quién es responsable de cada parte.

Mover bloques literalmente no basta: el código mezclado usa mapas, estado de widget y acceso directo al reloj. La actividad exige introducir los contratos tipados y la comunicación que permiten separar esas responsabilidades.

## Paso 1: Extraer el Dominio

### Entidad y Laboratorios

[`dominio/consumo.dart`](proyectos/ecotrack_reto%20-%20final/lib/dominio/consumo.dart) contiene el catálogo `laboratoriosUtez` y la entidad:

```dart
class Consumo {
  final String laboratorio;
  final double litros;
  final DateTime fecha;

  const Consumo({
    required this.laboratorio,
    required this.litros,
    required this.fecha,
  });
}
```

El cambio de mapa a objeto elimina accesos como `c['litros']` en los consumidores del dominio. Ahora utilizan `consumo.litros`. Los nombres del catálogo y sus tres valores se mantienen.

`Consumo` no importa Flutter ni conoce el formato de almacenamiento. No contiene métodos JSON.

### Reglas

[`dominio/regla_consumo.dart`](proyectos/ecotrack_reto%20-%20final/lib/dominio/regla_consumo.dart) concentra `topeLitros = 10000.0` y las cuatro condiciones del original. Su firma es:

```dart
static String? validar(Consumo consumo, {required DateTime hoy})
```

El método devuelve el primer motivo de rechazo o `null`. Se preservan el orden, los límites y los mensajes. `hoy` es obligatorio; la regla compara `consumo.fecha.isAfter(hoy)` sin consultar `DateTime.now()`.

Así, una prueba puede entregar la misma fecha a la entidad y a la validación. No depende del instante en que se ejecute.

## Paso 2: Extraer los Datos

### Definir el Contrato

[`datos/consumo_repository.dart`](proyectos/ecotrack_reto%20-%20final/lib/datos/consumo_repository.dart) define:

```dart
abstract class ConsumoRepository {
  Future<void> guardar(Consumo consumo);
  Future<List<Consumo>> listarPorLaboratorio(String laboratorio);
}
```

El contrato habla de las operaciones que necesita la aplicación. No expone la lista interna, mapas, widgets o detalles de transporte. Tanto memoria como nube deben cumplir estas mismas operaciones.

### Implementar la Memoria

[`MemoriaConsumoRepository`](proyectos/ecotrack_reto%20-%20final/lib/datos/memoria_consumo_repository.dart) recibe la responsabilidad de `_memoria`:

- Conserva una `List<Consumo>` privada.
- `guardar` agrega el consumo.
- `listarPorLaboratorio` aplica `where` y devuelve una lista con los consumos de ese laboratorio.

Aunque esta implementación no necesita una espera de red, utiliza `Future` para cumplir el contrato compartido.

### Separar el Servicio Simulado

[`ConsumoService`](proyectos/ecotrack_reto%20-%20final/lib/datos/consumo_service.dart) recibe `_servidor` y las demoras del canal:

| Operación | Entrada o salida | Espera |
|---|---|---|
| `post` | Recibe un `Map<String, Object>` y lo agrega al servidor simulado | `600 ms` |
| `get` | Filtra por laboratorio y devuelve mapas | `400 ms` |

El servicio no importa `Consumo`, no valida el negocio y no muestra mensajes. Continúa siendo una lista local que simula una API.

### Traducir en el Repositorio de Nube

[`NubeConsumoRepository`](proyectos/ecotrack_reto%20-%20final/lib/datos/nube_consumo_repository.dart) recibe `ConsumoService` por constructor. Su método de guardado traduce:

```dart
await _service.post({
  'laboratorio': consumo.laboratorio,
  'litros': consumo.litros,
  'fecha': consumo.fecha.toIso8601String(),
});
```

Al listar, llama a `_service.get(laboratorio)` y reconstruye cada `Consumo`: convierte litros mediante `(json['litros']! as num).toDouble()` y la fecha mediante `DateTime.parse(...)`.

La traducción del formato pertenece a este repositorio. Poner `toJson` o `fromJson` en `Consumo` haría que el dominio conociera un detalle que las instrucciones asignan a datos.

## Paso 3: Extraer el ViewModel

[`RegistroViewModel`](proyectos/ecotrack_reto%20-%20final/lib/presentacion/registro_view_model.dart) extiende `ChangeNotifier` e importa `package:flutter/foundation.dart`. Recibe:

```dart
RegistroViewModel(this._repositorio, {DateTime Function()? reloj})
  : _reloj = reloj ?? DateTime.now;
```

Se trasladan aquí el laboratorio seleccionado, `cargando`, `error`, `historial` y la coordinación de las operaciones. El reloj se sustituye por una función; su valor predeterminado conserva la consulta al reloj del sistema.

### Operación `guardar`

```text
Texto recibido
    → trim y reemplazo de coma
    → double.tryParse
    → crear Consumo con _reloj()
    → ReglaConsumo.validar(consumo, hoy: _reloj())
    → activar cargando y notificar
    → await _repositorio.guardar(consumo)
    → recargar historial
    → devolver true
```

Si la conversión falla, el ViewModel publica `Escribe los litros con número`, notifica y devuelve `false`. Si el dominio devuelve un motivo, lo publica y también devuelve `false`. Ninguno de esos caminos llama a `guardar` en el repositorio.

### Cambio de Laboratorio y Total

`cambiarLaboratorio(nuevo)` cambia el filtro, limpia el error y llama a `_recargarHistorial()`. La recarga publica `cargando`, consulta el contrato, reemplaza el historial y avisa al terminar.

`totalLitros` suma los litros del historial actual con `fold`. El ViewModel no elige entre implementaciones, no genera mapas y no recibe un `BuildContext`.

## Paso 4: Conservar la Vista y Delegar

[`RegistroPage`](proyectos/ecotrack_reto%20-%20final/lib/presentacion/registro_page.dart) parte del árbol de widgets original. Los cambios principales son:

| Acceso anterior | Acceso final |
|---|---|
| `_laboratorio` | `_vm.laboratorio` |
| `_laboratorios` | `laboratoriosUtez` del dominio |
| `_error` y `_cargando` | `_vm.error` y `_vm.cargando` |
| `_historial` | `_vm.historial` |
| Suma calculada en `build` | `_vm.totalLitros` |
| Mapas `c['litros']` y `c['fecha']` | Propiedades `c.litros` y `c.fecha` |
| Coordinación completa dentro de `_guardar` | Una llamada a `_vm.guardar(_litros.text)` |

El cuerpo queda dentro de `ListenableBuilder(listenable: _vm, ...)`. Cuando el ViewModel notifica, se vuelve a representar con su estado actualizado. Este widget conecta las notificaciones con la reconstrucción del subárbol. [API de ListenableBuilder](https://api.flutter.dev/flutter/widgets/ListenableBuilder-class.html).

La vista conserva:

- El `TextEditingController`, la llave del campo, las etiquetas y el teclado decimal.
- El selector, su callback y los tres laboratorios.
- El indicador de carga y el bloqueo de `Guardar`.
- La lista invertida, el total con un decimal y el formato de la hora.
- La limpieza del campo y el SnackBar cuando `guardar` devuelve `true` y la vista sigue montada.

La versión final no agrega una consulta automática en `initState`: el original empieza con el historial vacío y no activa una carga inicial. Agregarla cambiaría el arranque visible, especialmente en nube.

La página recibe la propiedad del ViewModel creado para ella. Libera su controlador y el ViewModel en `dispose`; si recibe otra instancia mediante una actualización del widget, libera la anterior. No se plantea compartir ese mismo gestor con otra página.

## Paso 5: Componer en `main.dart`

[`main.dart`](proyectos/ecotrack_reto%20-%20final/lib/main.dart) contiene la única elección:

```dart
final ConsumoRepository repositorio = usarNube
    ? NubeConsumoRepository(ConsumoService())
    : MemoriaConsumoRepository();
```

`EcoTrackApp` recibe el contrato y construye:

```dart
RegistroPage(viewModel: RegistroViewModel(repositorio))
```

El tema, el título y la pantalla inicial conservan la presentación original. Cambiar `usarNube` y reiniciar la aplicación cambia la implementación, sin editar dominio, ViewModel o vista.

## Qué Se Ajustó al Revisar la Separación

| Situación detectada | Solución aplicada |
|---|---|
| `Consumo` tenía conversión JSON | Se trasladó a `NubeConsumoRepository` |
| La regla aceptaba omitir `hoy` y consultaba el sistema | Se restauró el parámetro obligatorio |
| El tope estaba declarado en dos lugares | Se dejó en `ReglaConsumo`, como indica el contrato |
| Se usaba un alias `total` y el catálogo se leía desde la regla | Se usan `totalLitros` y `laboratoriosUtez` directamente |
| El selector se bloqueaba durante la carga | Se conservó el callback habilitado del original |
| La vista iniciaba una consulta automática | Se conservó el arranque vacío del punto de partida |

Se corrigieron los archivos de solución dentro de la carpeta final; no fue necesario reemplazar el proyecto completo ni cambiar su configuración de plataformas. Las pruebas y el script entregados se conservaron.

[Anterior: antes del refactor](02%20-%20Ecotrack_reto%20-%20Antes%20del%20refactor.md) · [Siguiente: arquitectura final](04%20-%20Ecotrack_reto%20-%20Arquitectura%20final%20y%20flujos.md) · [Índice](README.md).
