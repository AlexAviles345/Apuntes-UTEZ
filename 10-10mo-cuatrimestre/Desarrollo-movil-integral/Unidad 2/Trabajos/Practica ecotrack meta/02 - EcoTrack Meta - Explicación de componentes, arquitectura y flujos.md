# EcoTrack Meta — Explicación de componentes, arquitectura y flujos

## 1. ¿Qué se construyó?

EcoTrack Meta es una aplicación Flutter para registrar el consumo de agua de tres laboratorios de la UTEZ. Tiene tres pestañas:

- **Registro:** captura el laboratorio y los litros consumidos.
- **Historial:** muestra los consumos y el total.
- **Meta:** compara el total con una meta semanal ajustable.

El objetivo principal es comprender cómo varias pantallas comparten el mismo estado sin duplicarlo. La aplicación conecta el mismo ViewModel de dos maneras:

1. Con `ChangeNotifier` puro y paso por constructores.
2. Con `provider` y acceso desde el árbol de widgets.

El dominio, repositorio, ViewModel y las vistas son los mismos en ambas variantes. Solo cambia el cableado.

## 2. Mapa general de la arquitectura

```text
main*.dart
   │ crea la implementación concreta
   ▼
MemoriaConsumoRepository
   │ se entrega como ConsumoRepository
   ▼
ConsumosViewModel
   │ expone estado, acciones y notificaciones
   ▼
Adaptador de ChangeNotifier o Provider
   │ transforma el estado en datos y callbacks
   ▼
Vistas reutilizables
```

Las dependencias avanzan en una dirección:

```text
presentación ──► dominio
datos ─────────► dominio
variantes ─────► presentación y datos
main ──────────► variante y repositorio concreto
```

Así, el dominio no conoce Flutter, las vistas no conocen el repositorio y el ViewModel no depende de Provider.

## 3. Estructura importante

| Ruta | Responsabilidad |
|---|---|
| `lib/dominio/consumo.dart` | Modelo `Consumo`, laboratorios y validación. |
| `lib/dominio/meta.dart` | Reglas matemáticas de la meta. |
| `lib/datos/consumo_repository.dart` | Contrato de almacenamiento. |
| `lib/datos/memoria_consumo_repository.dart` | Implementación temporal en memoria. |
| `lib/presentacion/consumos_view_model.dart` | Estado compartido y acciones. |
| `lib/presentacion/vistas.dart` | Widgets que reciben datos y callbacks. |
| `lib/variantes/a_change_notifier.dart` | Cableado manual. |
| `lib/variantes/b_provider.dart` | Cableado con Provider. |
| `lib/main_change_notifier.dart` | Entrada de la variante A. |
| `lib/main.dart` | Entrada de la variante B. |

## 4. Tipos de estado

| Tipo | Ejemplo | Dueño |
|---|---|---|
| Efímero | Laboratorio seleccionado, texto e índice de pestaña | Widget que lo usa |
| Compartido | Consumos, error, guardando y meta | `ConsumosViewModel` |
| Derivado | Total, avance y meta superada | Getters del ViewModel |
| Guardado durante la ejecución | Lista en memoria | `MemoriaConsumoRepository` |

El estado derivado se calcula y no se guarda aparte. `total` suma `consumos`; `avance` usa `total` y `meta`. Esto evita valores contradictorios.

## 5. Capa de dominio

### 5.1. `Consumo`

[`consumo.dart`](ecotrack_meta/lib/dominio/consumo.dart) contiene un modelo inmutable:

- `laboratorio` identifica dónde ocurrió el consumo.
- `litros` almacena la cantidad.
- `laboratoriosUtez` contiene las opciones válidas.

`validarLitros(double? litros)` exige un número mayor que cero y dentro del límite. Devuelve un mensaje si falla o `null` si es válido. Esta regla pertenece al dominio porque describe el problema, no la interfaz.

### 5.2. Meta semanal

[`meta.dart`](ecotrack_meta/lib/dominio/meta.dart) define:

- `metaInicial = 100.0`.
- `pasoMeta = 10.0`.
- `metaMinima = 10.0`.
- `ajustarMeta()` cambia la meta sin bajar del mínimo.
- `avanceDeMeta()` calcula una proporción de 0 a 1.

Son funciones puras: reciben valores y devuelven resultados sin dibujar ni alterar objetos externos.

## 6. Capa de datos

### 6.1. Contrato

[`consumo_repository.dart`](ecotrack_meta/lib/datos/consumo_repository.dart) declara:

```dart
Future<void> guardar(Consumo consumo);
Future<List<Consumo>> todos();
```

El contrato expresa lo que necesita la aplicación, sin obligarla a usar memoria, una API o una base de datos.

### 6.2. Implementación

[`memoria_consumo_repository.dart`](ecotrack_meta/lib/datos/memoria_consumo_repository.dart) guarda en una lista privada:

- `guardar()` agrega un consumo.
- `todos()` devuelve una lista no modificable.

Esto protege el almacenamiento interno. Los datos se pierden al cerrar completamente la aplicación porque todavía no existe persistencia permanente.

## 7. El ViewModel

[`consumos_view_model.dart`](ecotrack_meta/lib/presentacion/consumos_view_model.dart) define `ConsumosViewModel extends ChangeNotifier`.

### Estado almacenado

- `consumos`: registros visibles.
- `error`: mensaje de validación.
- `guardando`: operación en curso.
- `meta`: objetivo semanal.

### Estado derivado

- `total` suma los litros.
- `avance` calcula el progreso.
- `metaSuperada` indica si el total rebasó la meta.

### `cargar()`

Consulta `todos()`, actualiza `consumos` y llama a `notifyListeners()`.

### `guardar(laboratorio, litrosTexto)`

1. Convierte una coma decimal en punto.
2. Intenta obtener un `double`.
3. Ejecuta `validarLitros()`.
4. Si falla, publica el error y no guarda.
5. Si es válido, activa `guardando`.
6. Crea `Consumo` y lo envía al repositorio.
7. Consulta `todos()` otra vez para respetar la fuente de verdad.
8. Desactiva `guardando` y notifica.
9. Devuelve `true` o `false` para que el formulario decida si se limpia.

### `subirMeta()` y `bajarMeta()`

Usan `ajustarMeta()` y notifican el valor. La meta nunca baja de `metaMinima`.

### `notifyListeners()`

`ChangeNotifier` mantiene oyentes. `notifyListeners()` anuncia que el estado cambió y los widgets que escuchan reconstruyen su parte visual. El ViewModel no modifica widgets directamente.

## 8. Vistas tontas

[`vistas.dart`](ecotrack_meta/lib/presentacion/vistas.dart) no importa Provider, el ViewModel ni datos. Recibe valores y funciones.

- `FormularioRegistro` recibe estado, error y `onGuardar`. Conserva localmente el laboratorio y el texto.
- `ListaHistorial` recibe consumos y total; solo los representa.
- `PanelMeta` recibe total, meta, avance, estado y callbacks.
- `PantallasEcoTrack` conserva el índice de navegación y usa `IndexedStack`.

El texto del formulario y la pestaña activa son estado efímero: solo interesan al widget que los usa.

## 9. Variante A: `ChangeNotifier` puro

[`a_change_notifier.dart`](ecotrack_meta/lib/variantes/a_change_notifier.dart) hace manualmente lo siguiente:

1. `AppChangeNotifier` crea un solo `ConsumosViewModel`.
2. Llama a `cargar()` al iniciar.
3. Lo entrega a `RegistroCN`, `HistorialCN` y `MetaCN` por constructor.
4. Ejecuta `dispose()` al terminar.

Cada adaptador usa `ListenableBuilder` para escuchar. Es explícito y no requiere otro paquete, pero hay que transportar y liberar el ViewModel manualmente.

## 10. Variante B: Provider

[`b_provider.dart`](ecotrack_meta/lib/variantes/b_provider.dart) coloca un único `ConsumosViewModel` sobre `MaterialApp` mediante `ChangeNotifierProvider`.

- `context.watch<ConsumosViewModel>()` lee datos que deben redibujar.
- `context.read<ConsumosViewModel>()` ejecuta acciones en callbacks sin escuchar.

Provider libera el ViewModel que creó. Los adaptadores ya no lo reciben por constructor.

## 11. Comparación

| Aspecto | ChangeNotifier puro | Provider |
|---|---|---|
| Estado | Mismo ViewModel | Mismo ViewModel |
| Creación | `initState()` | `ChangeNotifierProvider.create` |
| Entrega | Constructor | Árbol de widgets |
| Escucha | `ListenableBuilder` | `context.watch` |
| Acciones | Objeto recibido | `context.read` |
| Liberación | Manual | Provider |
| Paquete extra | No | `provider` |

Provider no sustituye a `ChangeNotifier`; simplifica cómo se crea, encuentra, escucha y libera.

## 12. Flujos

### Guardar

```text
Formulario → onGuardar → ViewModel → validación de dominio
           → repositorio → ViewModel → notifyListeners()
           → Registro, Historial y Meta se actualizan
```

Las tres pestañas coinciden porque observan la misma instancia.

### Cambiar la meta

```text
Botón +10/-10 → callback → ViewModel → regla del dominio
              → notifyListeners() → progreso y mensaje se actualizan
```

## 13. Ejecución

Provider:

```bash
flutter run
```

[`main.dart`](ecotrack_meta/lib/main.dart) crea `MemoriaConsumoRepository` y arranca `AppProvider`.

ChangeNotifier puro:

```bash
flutter run -t lib/main_change_notifier.dart
```

[`main_change_notifier.dart`](ecotrack_meta/lib/main_change_notifier.dart) crea el mismo repositorio y arranca `AppChangeNotifier`.

Los `main*.dart` son el punto de composición: ahí se selecciona la implementación concreta.

## 14. Comprobaciones

Desde `ecotrack_meta/`:

```bash
flutter pub get
flutter analyze
flutter test
```

En Windows con Git Bash:

```bash
bash verificar_estado.sh
```

El proyecto requiere una versión compatible con `sdk: ^3.13.0`. Las 35 pruebas verifican dominio, repositorio, ViewModel, notificaciones, integración, sustitución de datos, capas y Provider.

## 15. Ideas clave

- `ChangeNotifier` sabe cuándo cambió el estado.
- `notifyListeners()` avisa a los interesados.
- El ViewModel posee el estado compartido.
- El repositorio es la fuente de los consumos.
- Las vistas reciben datos y callbacks.
- `watch` observa; `read` ejecuta.
- El estado derivado se calcula, no se duplica.
- Provider simplifica el cableado, no cambia las reglas.

