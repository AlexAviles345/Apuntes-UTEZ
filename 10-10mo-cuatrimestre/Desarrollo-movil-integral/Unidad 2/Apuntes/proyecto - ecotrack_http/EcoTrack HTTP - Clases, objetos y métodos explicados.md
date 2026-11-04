# EcoTrack HTTP — Clases, objetos y métodos explicados

Esta guía explica las piezas de Dart, Flutter y Dio utilizadas en la práctica. Está pensada para leerse junto con el código, incluso si todavía no se domina la programación orientada a objetos.

Para comprender primero el recorrido completo, consulta [EcoTrack HTTP — Arquitectura y funcionamiento](EcoTrack%20HTTP%20-%20Arquitectura%20y%20funcionamiento.md).

## Conceptos básicos

### Clase y objeto

Una **clase** es una definición; un **objeto** es un ejemplar creado a partir de ella.

```dart
class Publicacion { /* definición */ }

final publicacion = Publicacion(/* datos */); // objeto
```

La clase indica qué datos y comportamientos existen. Cada objeto conserva sus propios valores.

### Constructor

Un constructor crea y prepara un objeto:

```dart
const Publicacion({
  required this.id,
  required this.autorId,
  required this.titulo,
  required this.cuerpo,
});
```

- `required` obliga a proporcionar el argumento.
- `this.id` asigna el argumento a la propiedad `id`.
- `const` permite crear objetos constantes cuando todos sus valores también lo son.
- Las llaves `{}` indican parámetros nombrados.

### Propiedad, método y función

- Una **propiedad** guarda un valor: `final int id`.
- Un **método** es una función que pertenece a una clase: `vm.cargar()`.
- Una **función** puede existir fuera de una clase: `crearDio()`.

### `final`, `const` y `late`

| Palabra | Significado en la práctica |
|---|---|
| `final` | La referencia se asigna una vez |
| `const` | El valor completo puede conocerse y fijarse como constante |
| `late final` | Se asigna una vez, pero su creación se pospone hasta que se necesita |

En `app.dart`, `_dio` y `_vm` son `late final`. Eso permite que `_vm` use el Dio creado anteriormente sin recrearlos en cada `build()`.

### Miembros privados con `_`

Dart considera privados dentro de su biblioteca los nombres que empiezan con guion bajo:

```dart
final Dio _dio;
void _cambiar(EstadoPublicaciones nuevo) { /* ... */ }
```

La intención es que otras partes usen la interfaz pública, no los detalles internos.

## `main.dart`

### `main()`

Es el punto donde comienza un programa Dart:

```dart
void main() {
  runApp(const AppHttp());
}
```

`void` significa que la función no devuelve un resultado.

### `runApp()`

Es una función de Flutter que recibe el widget raíz y lo coloca en pantalla. Desde `AppHttp` se construye el resto del árbol de widgets.

## `app.dart`

### `StatefulWidget` y `State`

`AppHttp` hereda de `StatefulWidget` porque necesita conservar objetos durante varias reconstrucciones:

```dart
class AppHttp extends StatefulWidget { /* ... */ }
class _AppHttpState extends State<AppHttp> { /* ... */ }
```

El widget describe su configuración. Su objeto `State` conserva `_falla`, `_dio` y `_vm`.

### `createState()`

Flutter llama a este método para crear el estado asociado con `AppHttp`:

```dart
State<AppHttp> createState() => _AppHttpState();
```

La flecha `=>` es una forma corta de devolver una sola expresión.

### Raíz de composición

`_AppHttpState` crea y conecta las dependencias:

```dart
final _falla = FallaSimuladaInterceptor();
late final Dio _dio = crearDio(
  interceptores: [BitacoraInterceptor(), _falla],
);
late final _vm = PublicacionesViewModel(PublicacionesApi(_dio));
```

Este lugar se llama **raíz de composición** porque arma el conjunto de objetos. La relación queda así:

```text
PublicacionesViewModel → PublicacionesApi → Dio
                                      Dio → interceptores
```

### `build()`

Flutter llama a `build()` cuando necesita describir la interfaz. Devuelve `MaterialApp`, que configura título, tema y pantalla inicial.

`build()` puede ejecutarse muchas veces. Por eso Dio y el ViewModel se crean como campos del estado y no dentro de este método.

### `MaterialApp` y `ThemeData`

`MaterialApp` prepara una aplicación con componentes de Material Design. En esta práctica:

- oculta la etiqueta de depuración;
- define el título `EcoTrack HTTP`;
- genera un esquema de colores a partir de verde azulado;
- coloca `PublicacionesPagina` como pantalla principal.

### `PopupMenuButton<ModoFalla>`

El tipo entre `< >` indica que el menú trabaja con valores de `ModoFalla`. Cada opción es un `PopupMenuItem` creado a partir de `ModoFalla.values`.

```dart
onSelected: (modo) => setState(() => _falla.modo = modo)
```

Cuando se elige una opción:

1. `modo` contiene el valor seleccionado.
2. Se asigna a `_falla.modo`.
3. `setState()` indica a Flutter que `AppHttp` debe reconstruirse.
4. El icono cambia entre red normal y error simulado.

### `dispose()`

Se ejecuta cuando el objeto `State` se retira definitivamente:

```dart
void dispose() {
  _vm.dispose();
  _dio.close();
  super.dispose();
}
```

Libera el ViewModel, cierra el cliente HTTP y finalmente permite que la clase base termine su limpieza.

## `dominio/publicacion.dart`

### Clase `Publicacion`

Es un modelo del dominio. Sus propiedades son inmutables porque están declaradas con `final`.

```dart
final int id;
final int autorId;
final String titulo;
final String cuerpo;
```

`int` representa enteros y `String` representa texto.

### Constructor de fábrica

```dart
factory Publicacion.fromJson(Map<String, dynamic> json)
```

Un constructor `factory` puede analizar información y decidir cómo crear el objeto. Aquí recibe un mapa JSON.

`Map<String, dynamic>` significa:

- las llaves son textos, por ejemplo `title`;
- los valores pueden ser de diferentes tipos.

### Patrón de mapa

```dart
return switch (json) {
  {
    'id': int id,
    'userId': int autorId,
    'title': String titulo,
    'body': String cuerpo,
  } => Publicacion(/* ... */),
  _ => throw FormatException(/* ... */),
};
```

El patrón comprueba simultáneamente los nombres y tipos de los campos. Si coinciden, extrae los valores y crea `Publicacion`. `_` representa cualquier otra forma y lanza una excepción.

### `FormatException`

Comunica que los datos tenían un formato inesperado. Lanzarla con `throw` detiene el recorrido normal y permite que una capa superior convierta el problema en `RespuestaInvalida`.

## `dominio/falla_red.dart`

### Clase sellada

```dart
sealed class FallaRed implements Exception
```

`sealed` define una familia cerrada de tipos. Dart conoce los subtipos declarados en la misma biblioteca y puede comprobar que un `switch` contemple todos los casos.

`implements Exception` permite lanzar estos objetos con `throw` y capturarlos como errores de la aplicación.

### Clases finales

`final class` impide crear subclases fuera de su biblioteca. Cada tipo representa un caso específico.

`ErrorDelServidor` y `PeticionRechazada` guardan un código HTTP:

```dart
final int codigo;
```

Las demás fallas no necesitan propiedades; su propio tipo ya comunica lo ocurrido.

### `extends` e `implements`

La mayoría de las fallas usa `extends FallaRed`, es decir, hereda de la clase base. `TiempoAgotado` usa `implements FallaRed`: cumple su interfaz sin heredar una implementación. Para el manejo mediante `FallaRed`, ambos son miembros de la misma familia sellada.

## `datos/cliente_http.dart`

### Dio

`Dio` es el objeto encargado de realizar operaciones HTTP. La dependencia aparece en `pubspec.yaml`.

### `crearDio()`

```dart
Dio crearDio({
  String baseUrl = urlBase,
  List<Interceptor> interceptores = const [],
})
```

La función acepta parámetros nombrados opcionales con valores predeterminados. Esto permite usar la configuración normal o sustituir la URL y los interceptores durante una prueba.

### `BaseOptions`

Agrupa opciones compartidas por todas las peticiones:

- `baseUrl`: inicio común de las direcciones.
- `connectTimeout`: tiempo máximo para establecer conexión.
- `receiveTimeout`: tiempo máximo para recibir la respuesta.
- `responseType: ResponseType.json`: solicita a Dio interpretar JSON.
- `headers`: agrega `Accept: application/json`.

### `dio.interceptors.addAll()`

`interceptors` es la colección de interceptores de Dio. `addAll()` agrega todos los objetos recibidos en la lista.

## `datos/publicaciones_api.dart`

### Inyección por constructor

```dart
PublicacionesApi(this._dio);
```

La API recibe un Dio ya configurado. Esto reduce el acoplamiento y permite sustituir el cliente en otros contextos.

### `Future<List<Publicacion>>`

`Future` representa un resultado que llegará después. El resultado esperado será una lista de publicaciones.

```dart
Future<List<Publicacion>> obtener({int limite = 10}) async
```

- `limite` es opcional y vale 10 de manera predeterminada.
- `async` permite utilizar `await` dentro del método.
- La llamada devuelve inmediatamente un `Future`, que se completa después.

### `_dio.get<Object?>()`

```dart
final respuesta = await _dio.get<Object?>(
  '/posts',
  queryParameters: {'_limit': limite},
);
```

`get()` realiza una petición HTTP GET. Dio combina la ruta con la URL base y transforma `queryParameters` en `?_limit=10`.

`Object?` indica que los datos pueden ser cualquier objeto o incluso `null`; por eso se validan antes de utilizarlos. `await` pausa este método hasta recibir una respuesta, sin congelar toda la aplicación.

### `Response` y `data`

El resultado de Dio es un objeto `Response`. Además del cuerpo en `data`, puede contener código de estado, encabezados y la petición original.

```dart
final datos = respuesta.data;
if (datos is! List) throw const RespuestaInvalida();
```

`is!` significa «no es». Si el cuerpo no es una lista, no se intenta recorrerlo.

### Comprensión de lista

```dart
return [
  for (final item in datos)
    switch (item) {
      Map<String, dynamic> json => Publicacion.fromJson(json),
      _ => throw const RespuestaInvalida(),
    },
];
```

El `for` dentro de `[ ]` crea una lista nueva. Cada elemento debe ser un mapa; luego `fromJson()` lo convierte en `Publicacion`.

### `try`, `on`, `catch` y `throw`

`try` contiene la operación que puede fallar. Los bloques siguientes manejan tipos concretos:

```dart
on DioException catch (e) {
  throw traducirError(e);
} on FormatException {
  throw const RespuestaInvalida();
}
```

Una falla de Dio se traduce. Un JSON mal formado se convierte en `RespuestaInvalida`. `throw` vuelve a enviar la nueva falla al ViewModel.

## `datos/traducir_error.dart`

### Expresión `switch`

```dart
return switch (e.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout => const TiempoAgotado(),
  // ...
};
```

El `switch` compara el tipo del error y devuelve una `FallaRed`. En este contexto, `||` une patrones alternativos: cualquiera de esos tipos produce el mismo resultado.

### Guardia `when`

```dart
DioExceptionType.unknown when e.error is FormatException =>
  const RespuestaInvalida()
```

`when` agrega una condición. El caso se acepta solamente si el error interno también es `FormatException`.

### `_porCodigo()`

La función privada clasifica códigos HTTP:

```text
sin código       → RespuestaInvalida
código >= 500    → ErrorDelServidor
otro código      → PeticionRechazada
```

## Interceptores de Dio

### Clase `Interceptor`

Los dos interceptores heredan de `Interceptor`. Dio llama a sus métodos durante distintas etapas:

| Método | Momento |
|---|---|
| `onRequest()` | Antes de enviar la petición |
| `onResponse()` | Después de obtener una respuesta válida |
| `onError()` | Cuando la operación termina con error |

`@override` indica que el método reemplaza el comportamiento definido por la clase base.

### Objetos `handler`

El manejador decide cómo continúa el recorrido:

- `handler.next(valor)`: continúa con la petición, respuesta o error.
- `handler.reject(error)`: termina esa etapa con un `DioException`.
- `handler.resolve(respuesta)`: entrega una respuesta sin esperar al servidor.

Los simuladores usan `reject(..., true)` y `resolve(..., true)` para que Dio continúe el recorrido por los manejadores correspondientes en lugar de terminarlo inmediatamente.

## `datos/bitacora_interceptor.dart`

### Función recibida por el constructor

```dart
BitacoraInterceptor({void Function(String linea)? escribir})
```

El interceptor puede recibir una función que escriba cada línea. El signo `?` permite que sea `null`. Si no se proporciona, `??` elige `_alLog`, que usa `developer.log()`.

Esto facilita cambiar la salida sin modificar la lógica del interceptor.

### `Stopwatch`

`Stopwatch` mide tiempo transcurrido:

```dart
options.extra[_llaveCronometro] = Stopwatch()..start();
```

`..` es el operador de cascada: crea el cronómetro, llama a `start()` y conserva el mismo objeto.

`RequestOptions.extra` es un mapa para datos adicionales. Allí se guarda el cronómetro junto con la petición, de modo que `onResponse()` u `onError()` puedan recuperarlo.

### Acceso seguro y `??`

```dart
(o.extra[_llaveCronometro] as Stopwatch?)?.elapsedMilliseconds ?? 0
```

1. `as Stopwatch?` trata el valor como cronómetro o `null`.
2. `?.` consulta la duración solo si existe.
3. `?? 0` utiliza cero cuando no había cronómetro.

### Información registrada

El interceptor registra método, ruta, código, tipo de error y duración. Evita imprimir el cuerpo, los encabezados y la consulta para no exponer posibles datos privados.

## `datos/falla_simulada_interceptor.dart`

### `enum ModoFalla`

Un `enum` define un conjunto cerrado de opciones. Cada opción guarda una etiqueta para el menú:

```dart
enum ModoFalla {
  ninguna('Normal'),
  sinRed('Sin red'),
  // ...
}
```

`ModoFalla.values` devuelve todas las opciones y permite generar el menú sin escribir cada elemento por separado.

### `Future<void>` y `Future.delayed()`

`onRequest()` es asíncrono porque el modo lento espera antes de producir el error:

```dart
await Future<void>.delayed(esperaLento);
```

Esto simula una respuesta tardía sin bloquear el hilo de la interfaz.

### Respuestas simuladas

- `DioException.connectionError()` construye el error de conexión.
- `DioException.receiveTimeout()` construye el timeout.
- `DioException.badResponse()` representa un código HTTP rechazado.
- `Response(...)` crea una respuesta manual para la lista vacía o el JSON incorrecto.

`_conCodigo()` evita repetir la construcción usada por 404 y 500.

## `presentacion/publicaciones_view_model.dart`

### `ChangeNotifier`

```dart
class PublicacionesViewModel extends ChangeNotifier
```

`ChangeNotifier` mantiene una colección de funciones interesadas en sus cambios. El ViewModel llama a `notifyListeners()` y Flutter avisa a quienes lo escuchan.

No transporta automáticamente el estado. La Vista recibe el aviso y luego consulta el getter `estado`.

### Estados sellados

`EstadoPublicaciones` es la clase sellada base. Sus cinco subtipos representan posibilidades mutuamente excluyentes.

`ConDatos` guarda `List<Publicacion>` y `ConError` guarda un mensaje. Los demás estados no requieren información adicional.

### Estado privado y getter

```dart
EstadoPublicaciones _estado = const Inicial();
EstadoPublicaciones get estado => _estado;
```

La Vista puede leer `estado`, pero no puede asignarlo directamente. Solo el ViewModel decide cuándo cambiarlo.

Un getter se usa como una propiedad aunque por dentro sea un método de lectura.

### Getter `cargando`

```dart
bool get cargando => _estado is Cargando;
```

Devuelve `true` únicamente cuando el objeto actual pertenece a la clase `Cargando`.

### Método `cargar()`

```dart
Future<void> cargar() async {
  if (cargando) return;
  _cambiar(const Cargando());
  // llamada y manejo del resultado
}
```

El primer `if` funciona como una protección contra dobles pulsaciones. `return` termina el método cuando ya existe una petición en curso.

Después, `await _api.obtener()` espera la lista. El operador condicional elige el siguiente estado:

```dart
publicaciones.isEmpty ? const Vacio() : ConDatos(publicaciones)
```

Su forma es `condición ? valorSiEsVerdadera : valorSiEsFalsa`.

### Captura de errores

```dart
on FallaRed catch (falla) {
  _cambiar(ConError(mensajePara(falla)));
} catch (e, pila) {
  // error no previsto
}
```

El primer bloque maneja las fallas conocidas. El segundo evita que una excepción imprevista deje la pantalla cargando y registra su objeto y traza en la consola.

### `_cambiar()` y `notifyListeners()`

```dart
void _cambiar(EstadoPublicaciones nuevo) {
  _estado = nuevo;
  if (!_liberado) notifyListeners();
}
```

Primero reemplaza el estado y después notifica. `!` significa negación: solo avisa si el ViewModel todavía no fue liberado.

### `dispose()` y `_liberado`

Al liberar el ViewModel, `_liberado` cambia a `true` antes de llamar a `super.dispose()`. La comprobación evita emitir avisos desde una operación asíncrona que termine después de la liberación.

## `presentacion/mensajes.dart`

### Patrón por tipo

`mensajePara()` usa un `switch` sobre el objeto `FallaRed`. Cada patrón comprueba la clase concreta.

```dart
SinConexion() => 'Sin conexión...',
ErrorDelServidor(:final codigo) => 'El servidor... ($codigo).',
```

El segundo patrón también extrae la propiedad `codigo`.

### Patrón con valores alternativos

```dart
PeticionRechazada(codigo: 401 || 403) =>
  'No tienes permiso para ver esta información.'
```

El caso coincide cuando el código es 401 o 403. El siguiente `PeticionRechazada()` funciona como caso general para los códigos restantes.

## `presentacion/publicaciones_pagina.dart`

### `StatelessWidget`

`PublicacionesPagina` hereda de `StatelessWidget`. Recibe `vm` y `acciones`, pero no posee un objeto `State` separado.

Que sea sin estado propio no significa que nunca cambie. `ListenableBuilder` puede reconstruir una sección al escuchar un objeto externo.

### Parámetros con valor predeterminado

```dart
this.acciones = const []
```

Si no se entregan acciones, utiliza una lista constante vacía. `AppHttp` sí proporciona el menú de fallas.

### `Scaffold`

Proporciona la estructura visual básica de Material Design. En esta práctica tiene:

- `AppBar` como barra superior;
- `body` como contenido de la pantalla.

### `ListenableBuilder`

```dart
ListenableBuilder(
  listenable: vm,
  builder: (context, _) { /* widgets */ },
)
```

`listenable` es el objeto observado. `builder` es la función que se vuelve a ejecutar después de `notifyListeners()`.

El segundo parámetro se escribe `_` porque el código no necesita usarlo.

### Botón deshabilitado

```dart
onPressed: vm.cargando ? null : vm.cargar
```

En Flutter, un botón con `onPressed: null` queda deshabilitado. Cuando termina la carga, el getter devuelve `false` y el botón vuelve a recibir el método `vm.cargar`.

Se pasa la referencia al método, no se escribe `vm.cargar()`, porque Flutter debe ejecutarlo después del toque y no durante `build()`.

### Método `_contenido()`

El método recibe un `EstadoPublicaciones` y usa patrones para devolver el widget correspondiente.

```dart
ConError(:final mensaje) => /* widgets que usan mensaje */,
ConDatos(:final publicaciones) => /* lista */,
```

Los patrones extraen las propiedades que necesita la interfaz. Como la clase base es sellada, el compilador puede comprobar que se contemplen todos los estados.

### `ListView.separated`

Construye elementos visibles de la lista y coloca un separador entre ellos:

- `itemCount`: cantidad de publicaciones;
- `itemBuilder`: crea la tarjeta del índice solicitado;
- `separatorBuilder`: crea el espacio entre tarjetas.

`publicaciones[i]` obtiene el elemento ubicado en el índice `i`.

## `presentacion/tarjeta_publicacion.dart`

### `Theme.of(context)`

Obtiene el tema activo desde el árbol de widgets. Así la tarjeta usa estilos coherentes con `MaterialApp`.

### Widgets de distribución

| Widget | Función |
|---|---|
| `Card` | Superficie visual para una publicación |
| `Padding` | Espacio dentro de la tarjeta |
| `Column` | Coloca elementos verticalmente |
| `Row` | Coloca elementos horizontalmente |
| `Expanded` | Ocupa el espacio restante y evita desbordamientos |
| `SizedBox` | Agrega separación fija |
| `CircleAvatar` | Muestra el identificador dentro de un círculo |
| `Text` | Dibuja texto |

### Interpolación de texto

```dart
Text('${publicacion.id}')
Text('Autor #${publicacion.autorId}')
```

`${...}` inserta el resultado de una expresión dentro de un `String`.

## `setState()` frente a `notifyListeners()`

| Aspecto | `setState()` | `notifyListeners()` |
|---|---|---|
| Objeto que lo ejecuta | `_AppHttpState` | `PublicacionesViewModel` |
| Cambio observado | Modo del simulador | Estado de publicaciones |
| Quién reconstruye | El `StatefulWidget` asociado | El `ListenableBuilder` que escucha |
| Requiere `ChangeNotifier` | No | Sí |

Ambos indican que algo cambió, pero pertenecen a mecanismos diferentes.

## Objetos creados y duración

| Objeto | Quién lo crea | Cuánto dura aproximadamente |
|---|---|---|
| `AppHttp` | `main()` | Durante la ejecución de la app |
| `_AppHttpState` | Flutter | Mientras `AppHttp` permanezca en el árbol |
| `FallaSimuladaInterceptor` | `_AppHttpState` | Igual que el estado de la app |
| `Dio` | `crearDio()` | Hasta `dispose()` |
| `PublicacionesApi` | `_AppHttpState` | Referenciada por el ViewModel |
| `PublicacionesViewModel` | `_AppHttpState` | Hasta `dispose()` |
| `Publicacion` | `fromJson()` | Mientras la lista la conserve |
| Widgets de la pantalla | Métodos `build()` | Pueden recrearse muchas veces |

Los widgets pueden ser temporales. En cambio, Dio y el ViewModel deben conservarse para mantener sus recursos y estado entre reconstrucciones.

## Recorrido asíncrono simplificado

```text
vm.cargar()
│
├── cambia a Cargando y notifica
│
├── await _api.obtener()
│       │
│       ├── await dio.get()
│       └── convierte JSON
│
└── cambia al estado final y notifica
```

Mientras los `await` esperan, Flutter puede seguir dibujando la animación de carga y respondiendo a otros eventos.

## Glosario rápido de sintaxis

| Sintaxis | Lectura sencilla |
|---|---|
| `extends` | Hereda de una clase |
| `implements` | Se compromete a cumplir una interfaz |
| `@override` | Reemplaza un método heredado |
| `<Tipo>` | Tipo utilizado por una clase o método genérico |
| `Tipo?` | El valor también puede ser `null` |
| `?.` | Accede solamente si el objeto no es `null` |
| `??` | Usa el valor derecho si el izquierdo es `null` |
| `=>` | Devuelve una expresión de forma corta |
| `async` | El método puede esperar operaciones asíncronas |
| `await` | Espera el resultado de un `Future` |
| `throw` | Lanza una excepción |
| `try/catch` | Intenta una operación y captura fallas |
| `is` / `is!` | Comprueba si es / no es de un tipo |
| `!condicion` | Niega un valor booleano |
| `..` | Ejecuta operaciones sobre el mismo objeto |
| `${expresion}` | Inserta un valor en un texto |
| `for` dentro de `[ ]` | Genera elementos de una lista |
| `switch` | Elige un resultado según un valor o patrón |
| `_` en un patrón | Acepta cualquier otro caso |

## Relación que conviene memorizar

```text
PublicacionesPagina
        │ escucha y llama
        ▼
PublicacionesViewModel (ChangeNotifier)
        │ solicita
        ▼
PublicacionesApi
        │ usa
        ▼
Dio + interceptores
        │ GET
        ▼
JSONPlaceholder
```

En el regreso, el JSON se convierte en `Publicacion`; los errores se convierten en `FallaRed`; el ViewModel convierte el resultado en un estado y `ListenableBuilder` muestra el widget correspondiente.
