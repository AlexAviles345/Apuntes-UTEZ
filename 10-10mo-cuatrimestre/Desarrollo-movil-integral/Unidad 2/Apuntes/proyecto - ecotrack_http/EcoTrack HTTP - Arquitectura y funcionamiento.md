# EcoTrack HTTP — Guía de estudio

Esta práctica muestra cómo una aplicación Flutter consulta un servicio web, convierte una respuesta JSON en objetos de Dart y actualiza la interfaz según el resultado.

La aplicación solicita publicaciones a **JSONPlaceholder** mediante Dio. Al presionar **Cargar publicaciones**, puede mostrar una lista, una pantalla vacía o un mensaje comprensible cuando ocurre un error.

Para estudiar cada clase, objeto y método por separado, consulta [EcoTrack HTTP — Clases, objetos y métodos explicados](EcoTrack%20HTTP%20-%20Clases%2C%20objetos%20y%20métodos%20explicados.md).

## Qué se aprende en esta práctica

- Realizar una petición HTTP `GET` con Dio.
- Configurar una URL base, tiempos de espera y encabezados.
- Convertir JSON en objetos `Publicacion`.
- Separar dominio, datos y presentación.
- Representar los estados de una pantalla con clases.
- Actualizar widgets con `ChangeNotifier` y `ListenableBuilder`.
- Traducir errores técnicos a fallas conocidas y mensajes para la persona usuaria.
- Usar interceptores para registrar solicitudes y simular fallas.
- Crear y liberar dependencias en un solo lugar.

## La arquitectura que realmente utiliza

`ChangeNotifier` no es toda la arquitectura. Es el mecanismo con el que el ViewModel avisa que cambió el estado.

La organización completa es una arquitectura por capas con un flujo parecido a **MVVM**:

| Parte | Archivos principales | Responsabilidad |
|---|---|---|
| Vista | `publicaciones_pagina.dart`, `tarjeta_publicacion.dart` | Dibuja la interfaz y recibe acciones |
| ViewModel | `publicaciones_view_model.dart` | Coordina la carga y conserva el estado de pantalla |
| Dominio | `publicacion.dart`, `falla_red.dart` | Define los datos y errores que entiende la aplicación |
| Datos | `cliente_http.dart`, `publicaciones_api.dart` y los interceptores | Se comunica con el servicio y transforma su respuesta |
| Composición | `app.dart` | Crea Dio, la API y el ViewModel, y los conecta |

Se dice «parecida a MVVM» porque existe una Vista y un ViewModel bien definidos. No se usa un paquete de inyección de dependencias, un repositorio abstracto ni un framework MVVM; las dependencias se construyen manualmente y se pasan por los constructores.

## Flujo general

```text
Persona presiona el botón
        │
        ▼
PublicacionesPagina llama vm.cargar()
        │
        ▼
PublicacionesViewModel cambia a Cargando
        │
        ├── notifyListeners()
        │         └── ListenableBuilder reconstruye la pantalla
        ▼
PublicacionesApi.obtener()
        │
        ▼
Dio hace GET /posts?_limit=10
        │
        ▼
JSONPlaceholder responde con JSON
        │
        ▼
Publicacion.fromJson() crea objetos Dart
        │
        ▼
El ViewModel cambia a ConDatos, Vacio o ConError
        │
        └── notifyListeners() actualiza la interfaz
```

La Vista no realiza directamente la petición y Dio no modifica widgets. Cada parte entrega el resultado a la siguiente.

## Recorrido por los archivos

### `main.dart`: punto de entrada

```dart
void main() {
  runApp(const AppHttp());
}
```

`main()` inicia el programa. `runApp()` coloca `AppHttp` como raíz del árbol de widgets.

### `app.dart`: raíz de composición

`AppHttp` es un `StatefulWidget` porque conserva durante la vida de la aplicación tres objetos:

1. `FallaSimuladaInterceptor`, que guarda el modo de falla elegido.
2. `Dio`, el cliente que realiza las peticiones.
3. `PublicacionesViewModel`, que conserva el estado de la pantalla.

La creación sigue este orden:

```text
FallaSimuladaInterceptor
          │
          ▼
crearDio(interceptores)
          │
          ▼
PublicacionesApi(dio)
          │
          ▼
PublicacionesViewModel(api)
```

Esto es **inyección de dependencias manual**: cada objeto recibe desde afuera aquello que necesita. `PublicacionesApi` no crea su propio Dio y el ViewModel no crea su propia API.

Al cerrar el widget, `dispose()` libera el ViewModel y cierra Dio. Así se evita conservar recursos después de que dejaron de utilizarse.

### `dominio/publicacion.dart`: modelo de la información

`Publicacion` representa una publicación dentro de la aplicación:

| Propiedad en Dart | Campo del JSON |
|---|---|
| `id` | `id` |
| `autorId` | `userId` |
| `titulo` | `title` |
| `cuerpo` | `body` |

La fábrica `Publicacion.fromJson()` utiliza un patrón para comprobar que estén los cuatro campos y que tengan el tipo esperado. Si el JSON tiene otra forma, lanza `FormatException` en lugar de construir un objeto incompleto.

### `dominio/falla_red.dart`: errores entendibles para la app

`FallaRed` agrupa las fallas que la aplicación sabe manejar:

- `SinConexion`: no fue posible comunicarse con la red.
- `TiempoAgotado`: la respuesta tardó más de lo permitido.
- `ErrorDelServidor`: el servidor respondió con un código desde 500.
- `PeticionRechazada`: la solicitud recibió otro código de error, como 404.
- `RespuestaInvalida`: llegó información con una estructura inesperada.

Estas clases no contienen textos de interfaz. Su trabajo es describir qué pasó sin depender de un widget.

### `datos/cliente_http.dart`: configuración de Dio

`crearDio()` centraliza la configuración del cliente:

```text
URL base:          https://jsonplaceholder.typicode.com
Conexión máxima:   5 segundos
Respuesta máxima:  8 segundos
Tipo esperado:     JSON
Encabezado:        Accept: application/json
```

También recibe una lista de interceptores y la agrega a Dio. De esta manera, el cliente se configura una sola vez.

### `datos/publicaciones_api.dart`: acceso al servicio

`PublicacionesApi.obtener()` solicita diez publicaciones con:

```http
GET https://jsonplaceholder.typicode.com/posts?_limit=10
```

El método espera una respuesta que sea una lista. Después comprueba que cada elemento sea un mapa JSON y llama a `Publicacion.fromJson()`.

Su resultado es `Future<List<Publicacion>>`: la lista llegará en el futuro porque una operación de red no termina inmediatamente.

Si Dio produce un `DioException`, la API lo convierte en una `FallaRed` mediante `traducirError()`. Si la conversión del JSON produce `FormatException`, devuelve conceptualmente una `RespuestaInvalida`.

### `datos/traducir_error.dart`: traducción técnica

Dio conoce errores técnicos como `connectionError`, `receiveTimeout` y `badResponse`. El resto de la aplicación conoce `SinConexion`, `TiempoAgotado` y las demás fallas del dominio.

`traducirError()` funciona como un adaptador entre esos dos vocabularios:

| Error de Dio | Falla usada por la aplicación |
|---|---|
| Timeout de conexión, envío, recepción o transformación | `TiempoAgotado` |
| Respuesta con código 500 o superior | `ErrorDelServidor(codigo)` |
| Otra respuesta HTTP rechazada | `PeticionRechazada(codigo)` |
| JSON con formato incorrecto | `RespuestaInvalida` |
| Error de conexión, certificado, cancelación u otro desconocido | `SinConexion` |

### Interceptores

Un interceptor se coloca en el recorrido de las peticiones. Puede observarlas, continuarlas, rechazarlas o responder sin consultar al servidor.

`BitacoraInterceptor` registra en la consola:

- método y ruta al enviar una petición;
- código HTTP y duración al recibir una respuesta;
- tipo de error y duración cuando la operación falla.

No imprime la consulta, los encabezados ni el cuerpo, porque podrían contener información sensible.

`FallaSimuladaInterceptor` existe para practicar escenarios que no siempre ocurren durante una clase:

| Modo | Resultado simulado |
|---|---|
| Normal | La petición continúa |
| Sin red | Produce un error de conexión |
| Lento | Espera y produce un timeout |
| Servidor 500 | Produce una respuesta fallida 500 |
| Ruta 404 | Produce una respuesta fallida 404 |
| Respuesta vacía | Entrega una lista sin elementos |
| JSON con otra forma | Entrega un objeto cuando se esperaba una lista |

Es una herramienta de demostración. El menú del icono superior cambia su propiedad `modo` y permite observar cómo responde la misma interfaz.

### `presentacion/publicaciones_view_model.dart`: estado y coordinación

`PublicacionesViewModel` hereda de `ChangeNotifier`. Conserva un solo objeto `_estado` y coordina la llamada a la API.

La pantalla solo puede estar en uno de estos cinco estados:

| Estado | Significado |
|---|---|
| `Inicial` | Todavía no se ha solicitado información |
| `Cargando` | La petición está en proceso |
| `ConDatos` | Llegó una lista con publicaciones |
| `Vacio` | La respuesta fue válida, pero no contenía publicaciones |
| `ConError` | Ocurrió una falla y existe un mensaje para mostrar |

Al usar clases distintas se evita una combinación contradictoria como «cargando y con error al mismo tiempo».

El método `cargar()` realiza este recorrido:

1. Si ya está cargando, termina para impedir peticiones duplicadas.
2. Cambia el estado a `Cargando`.
3. Espera el resultado de `PublicacionesApi.obtener()`.
4. Usa `Vacio` si la lista no tiene elementos o `ConDatos` si contiene publicaciones.
5. Convierte una `FallaRed` en `ConError` con un mensaje entendible.
6. Registra cualquier error no previsto y muestra un mensaje general.

Cada cambio pasa por `_cambiar()`, que asigna el nuevo estado y ejecuta `notifyListeners()`. Ese aviso no contiene la información nueva; solamente comunica: «mi estado cambió, vuelve a consultarlo».

### `presentacion/mensajes.dart`: textos para la persona usuaria

`mensajePara()` convierte una `FallaRed` en un texto útil. La interfaz no muestra `DioException`, URLs ni detalles internos.

Existe, por tanto, una traducción en dos pasos:

```text
DioException técnico
        │ traducirError()
        ▼
FallaRed del dominio
        │ mensajePara()
        ▼
Mensaje para la persona usuaria
```

### `presentacion/publicaciones_pagina.dart`: Vista reactiva

`PublicacionesPagina` recibe el ViewModel por su constructor. No lo crea y tampoco necesita saber cómo se configuró Dio.

`ListenableBuilder` escucha al ViewModel. Cuando este llama a `notifyListeners()`, ejecuta nuevamente su función `builder` y consulta `vm.estado`.

La función `_contenido()` dibuja un widget diferente para cada estado:

| Estado | Widget visible |
|---|---|
| `Inicial` | Instrucción para presionar el botón |
| `Cargando` | `CircularProgressIndicator` |
| `Vacio` | Mensaje «No hay publicaciones» |
| `ConError` | Icono, mensaje y botón para reintentar |
| `ConDatos` | Lista de tarjetas |

Mientras `vm.cargando` sea verdadero, `onPressed` recibe `null`; Flutter muestra el botón deshabilitado y no permite iniciar otra carga.

### `presentacion/tarjeta_publicacion.dart`: un elemento visual

`TarjetaPublicacion` recibe un objeto `Publicacion` y muestra su identificador, título, cuerpo y autor. Es un `StatelessWidget` porque no conserva ni modifica estado propio.

## Qué ocurre al presionar el botón

1. La Vista ejecuta `vm.cargar`.
2. El ViewModel publica el estado `Cargando`.
3. `ListenableBuilder` reconstruye su sección y aparece el indicador de progreso.
4. La API pide `/posts?_limit=10` mediante Dio.
5. Los interceptores observan o modifican el recorrido.
6. La API valida la estructura y construye objetos `Publicacion`.
7. El ViewModel publica el resultado.
8. La Vista se reconstruye y muestra tarjetas, vacío o error.

`setState()` y `notifyListeners()` cumplen papeles diferentes en esta práctica:

- `setState()` se utiliza en `AppHttp` para actualizar el icono del simulador de fallas.
- `notifyListeners()` se utiliza en el ViewModel para actualizar el contenido de publicaciones.

## Cómo ejecutar la práctica

Se necesita Flutter, un dispositivo o emulador disponible y conexión a Internet para el modo normal. `pubspec.yaml` exige un SDK de Dart compatible con `^3.13.5`, es decir, desde 3.13.5 y antes de 4.0.0.

Primero se puede comprobar la versión incluida en Flutter:

```bash
flutter --version
```

Si Dart es anterior a 3.13.5, `flutter pub get` no podrá resolver las dependencias y será necesario usar una versión de Flutter que incluya un Dart compatible.

Desde la carpeta `ecotrack_http`:

```bash
flutter pub get
flutter run
```

Para elegir explícitamente un dispositivo:

```bash
flutter devices
flutter run -d <identificador>
```

El archivo `android/app/src/main/AndroidManifest.xml` ya declara el permiso `INTERNET`, necesario para que una compilación Android pueda comunicarse con JSONPlaceholder.

## Cómo estudiar los escenarios

1. Ejecuta la aplicación en modo **Normal**.
2. Presiona **Cargar publicaciones** y observa el estado de progreso y las diez tarjetas.
3. Abre el menú del icono de red o error en la barra superior.
4. Elige **Sin red**, **Lento**, **Servidor 500** o **Ruta 404** y vuelve a cargar.
5. Comprueba que cada error técnico termina en un mensaje sencillo.
6. Elige **Respuesta vacía** y observa el estado `Vacio`.
7. Elige **JSON con otra forma** y observa cómo la validación produce `RespuestaInvalida`.
8. Regresa a **Normal** para permitir solicitudes reales.

También se puede observar la consola para estudiar las líneas generadas por `BitacoraInterceptor`.

## Mapa de archivos escritos para la práctica

```text
lib/
├── main.dart                         inicia Flutter
├── app.dart                          crea y conecta las dependencias
├── dominio/
│   ├── publicacion.dart              modelo y conversión desde JSON
│   └── falla_red.dart                tipos de falla conocidos
├── datos/
│   ├── cliente_http.dart             configuración de Dio
│   ├── publicaciones_api.dart        petición y conversión de datos
│   ├── traducir_error.dart           DioException → FallaRed
│   ├── bitacora_interceptor.dart     registro seguro de operaciones
│   └── falla_simulada_interceptor.dart
└── presentacion/
    ├── publicaciones_view_model.dart estado y lógica de presentación
    ├── publicaciones_pagina.dart     pantalla principal
    ├── tarjeta_publicacion.dart      tarjeta de una publicación
    └── mensajes.dart                 FallaRed → texto visible
```

Las carpetas `android`, `ios`, `web`, `windows`, `linux` y `macos` contienen la integración de Flutter con cada plataforma. El comportamiento estudiado aquí se encuentra principalmente en `lib`.

## Ideas clave para recordar

- `ChangeNotifier` almacena y anuncia cambios; no dibuja widgets.
- `ListenableBuilder` escucha el anuncio y reconstruye una parte de la interfaz.
- El ViewModel coordina la acción, pero delega el acceso HTTP a `PublicacionesApi`.
- Dio trabaja con detalles de red; `FallaRed` protege al resto de la app de esos detalles.
- Un `Future` representa un resultado que todavía no está disponible.
- El JSON se valida antes de convertirse en un objeto del dominio.
- Los estados con clases selladas hacen explícitas todas las posibilidades de la pantalla.
- Los interceptores permiten aplicar comportamiento transversal sin repetirlo en cada petición.
- `dispose()` forma parte del ciclo de vida y libera los objetos de larga duración.

## Preguntas de repaso

1. ¿Por qué `PublicacionesPagina` no llama directamente a Dio?
2. ¿Qué diferencia existe entre `Cargando` y `Vacio`?
3. ¿Qué objeto llama a `notifyListeners()` y cuál lo escucha?
4. ¿Por qué se clona o se transforma el JSON antes de mostrarlo?
5. ¿Qué ventaja ofrece convertir `DioException` en `FallaRed`?
6. ¿Para qué sirven `handler.next()`, `handler.reject()` y `handler.resolve()`?
7. ¿Por qué `AppHttp` es un `StatefulWidget`?
8. ¿Qué evita la comprobación `if (cargando) return`?
9. ¿Qué diferencia hay entre `setState()` y `notifyListeners()` en este proyecto?
10. ¿Por qué esta organización se describe como «parecida a MVVM» y no solamente como ChangeNotifier?
