# Estrategias de Caché — Objetos y Métodos Explicados

Esta guía explica con palabras sencillas los elementos utilizados por [`app.js`](practica%20-%20estrategias%20de%20cache/app.js) y [`sw.js`](practica%20-%20estrategias%20de%20cache/sw.js).

Para estudiar el flujo, las estrategias y las capturas de DevTools, consulta [Estrategias de caché — Explicación de app.js y sw.js](Estrategias%20de%20caché%20-%20Explicación%20de%20app.js%20y%20sw.js.md).

## Conceptos Básicos

### Objeto

Un objeto agrupa datos y acciones relacionadas. `caches`, por ejemplo, representa el almacén de cachés disponible para el sitio.

### Propiedad

Una propiedad es un dato contenido en un objeto:

```javascript
request.url
```

`url` es una propiedad del objeto `request`.

### Método

Un método es una acción que pertenece a un objeto:

```javascript
caches.open(CACHE_STATIC)
```

`open()` es una acción proporcionada por `caches`.

### Función

Una función agrupa instrucciones que pueden ejecutarse cuando se necesiten:

```javascript
function cacheFirst(request) {
    // instrucciones de la estrategia
}
```

### Constructor

Un constructor crea un objeto nuevo. Se utiliza con `new`:

```javascript
const url = new URL(request.url);
```

Aquí se crea un objeto `URL` a partir de un texto.

### Promesa

Una promesa representa un resultado que llegará después. Consultar la red o una caché toma tiempo, por lo que estas operaciones entregan promesas.

```text
Operación solicitada → pendiente → resultado disponible
```

### Callback

Un callback es una función entregada a otra operación para que se ejecute cuando ocurra un evento o llegue un resultado.

## Elementos de `app.js`

```javascript
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js')
}
```

### `if`

Significa «si la condición es verdadera, ejecuta este bloque».

### Operador `in`

`'serviceWorker' in navigator` pregunta si el objeto `navigator` contiene esa propiedad. Produce `true` o `false`.

### `navigator`

Es un objeto proporcionado por el navegador a la página. Su tipo es `Navigator`.

### `navigator.serviceWorker`

Es una propiedad cuyo valor es un objeto `ServiceWorkerContainer`. Administra los registros desde la página.

### `register()`

Es un método de `ServiceWorkerContainer`. Solicita registrar o revisar el archivo `sw.js` y devuelve una promesa.

## Constantes de `sw.js`

```javascript
const CACHE_DYNAMIC = 'app-dynamic';
const CACHE_STATIC = 'app-static';
```

- `const` declara una constante.
- `CACHE_DYNAMIC` y `CACHE_STATIC` son nombres elegidos por el proyecto.
- Los valores entre comillas son objetos de tipo `String`, es decir, texto.

## `self` y los Eventos

`self` representa el contexto global del Service Worker. Su tipo es `ServiceWorkerGlobalScope`; no representa la página ni el hilo principal.

### `addEventListener()`

Registra un callback para un evento. El proyecto escucha:

| Evento | Cuándo participa |
|---|---|
| `install` | Al instalar una versión nueva |
| `activate` | Cuando esa versión puede activarse |
| `fetch` | Al interceptar una petición controlada |

### `event`

Es el nombre asignado al objeto entregado por el navegador. En `install` y `activate` es un `ExtendableEvent`; en `fetch` es un `FetchEvent`.

## Objetos y Métodos de `install`

### `caches`

Es un objeto de tipo `CacheStorage`. Administra los contenedores de caché del origen.

### `caches.open()`

Abre una caché con el nombre recibido o la crea si no existe. Devuelve una promesa que entrega un objeto `Cache`.

### `.then()`

Es un método de `Promise`. Ejecuta un callback cuando llega correctamente el resultado pendiente.

### `cacheCreado`

Es el nombre local usado para recibir el objeto `Cache` entregado por `open()`. No es una clase definida por el proyecto.

### `cacheCreado.addAll()`

Es un método de `Cache`. Recibe un arreglo de rutas, solicita esos recursos y almacena sus respuestas.

### `event.waitUntil()`

Relaciona una promesa con la etapa actual. Durante `install`, mantiene la instalación vinculada con la apertura y llenado de `app-static`.

## Objetos y Métodos de `activate`

### `caches.keys()`

Devuelve una promesa cuyo resultado es un arreglo con los nombres de las cachés existentes.

### `keys.map()`

`keys` es el arreglo recibido. `map()` recorre cada elemento, ejecuta un callback y forma otro arreglo con los resultados.

### `cacheName`

Es el parámetro que recibe el nombre actual durante cada recorrido de `map()`.

### Operador `!==`

Comprueba si dos valores son diferentes. El código evalúa `cacheName !== CACHE_STATIC` y `cacheName !== CACHE_DYNAMIC` para saber si el nombre pertenece a una caché diferente de las dos actuales.

### Operador `&&`

Significa «y». La condición completa solo es verdadera cuando el nombre es diferente de `CACHE_STATIC` **y también** diferente de `CACHE_DYNAMIC`. Así se conservan ambas.

### `caches.delete()`

Solicita eliminar por nombre un contenedor completo y devuelve una promesa.

### `Promise.all()`

Recibe un arreglo de promesas y crea una promesa conjunta que representa la finalización de todas.

## Objetos del Enrutamiento en `fetch`

### `event.request`

Es una propiedad de `FetchEvent`. Contiene un objeto `Request` que describe la petición interceptada.

### `request.url`

Es una propiedad de `Request`. Contiene la dirección completa expresada como texto.

### `new URL(request.url)`

`URL` es una clase incorporada. El constructor interpreta el texto y crea un objeto con partes accesibles, como `origin`, `hostname` y `pathname`.

### `url.origin`

Es una propiedad del objeto `URL`. Contiene protocolo, dominio y puerto. Por ejemplo:

```text
https://fakestoreapi.com
```

### Operador `===`

Comprueba que dos valores sean iguales sin convertir sus tipos. Aquí decide si la petición pertenece exactamente al origen de Fake Store API.

### `event.respondWith()`

Es un método de `FetchEvent`. Recibe una respuesta o una promesa de respuesta y le indica al navegador qué debe entregar para esa petición.

```javascript
event.respondWith(networkFirst(request));
```

La función se ejecuta primero y su promesa se entrega a `respondWith()`.

## Funciones `cacheFirst()` y `networkFirst()`

Ambas reciben un objeto `Request` y devuelven una promesa que debe terminar produciendo un objeto `Response`.

El nombre de la función expresa el orden de prioridad:

- `cacheFirst`: primero Cache Storage y después la red.
- `networkFirst`: primero la red y después Cache Storage.

### `return`

Entrega un resultado desde una función. En estas estrategias conecta las promesas para que el resultado final llegue hasta `event.respondWith()`.

## Métodos de Cache First

### `caches.match(request)`

Busca una respuesta compatible en los contenedores de Cache Storage. Devuelve una promesa cuyo resultado puede ser un `Response` o `undefined`.

### `respCache`

Es el nombre local usado para recibir el resultado de `match()`. Cuando contiene un objeto `Response`, el `if` lo devuelve sin consultar la red.

### `fetch(request)`

`fetch()` es una función del entorno web. Envía la petición a la red y devuelve una promesa que entrega un `Response`.

### `respNetwork`

Es el nombre local asignado a la respuesta recibida desde la red.

### `cacheStatic`

Es el objeto `Cache` que representa `app-static` después de ejecutar `caches.open(CACHE_STATIC)`.

### `cacheStatic.put()`

Guarda una pareja formada por la petición y su respuesta:

```javascript
cacheStatic.put(request, respNetwork.clone());
```

A diferencia de `addAll()`, `put()` trabaja con una petición y una respuesta que el código ya posee.

### `respNetwork.clone()`

`clone()` crea otra instancia utilizable de la respuesta. Una copia se guarda y la respuesta original se devuelve a la página.

```text
Response de red
├── copia → Cache Storage
└── original → página
```

### `undefined`

Es el valor que representa la ausencia de un resultado. `caches.match()` puede entregarlo cuando no existe una coincidencia.

## Métodos de Network First

### `respNetwor`

Es el nombre usado en el código para recibir el objeto `Response` de la red. Aunque le falte la letra final de “Network”, es un parámetro válido y se usa de forma consistente dentro del callback.

### `cacheDynamic`

Es el objeto `Cache` que representa `app-dynamic` después de ejecutar `caches.open(CACHE_DYNAMIC)`.

### `cacheDynamic.put()`

Guarda una copia de la respuesta de red asociada con la petición original. Esto permite que una solicitud posterior sin red encuentre el resultado.

### `.catch()`

Es un método de `Promise`. Su callback se ejecuta cuando una operación anterior de la cadena se rechaza.

En Network First, la cadena comienza con `fetch(request)`. Si la red falla, `.catch()` busca la misma petición en Cache Storage.

### `new Response()`

`Response` es una clase web. Su constructor crea manualmente una respuesta cuando no existe red ni una entrada guardada.

Recibe el cuerpo de la respuesta y un objeto de opciones con sus encabezados.

### `JSON.stringify()`

`JSON` es un objeto incorporado. `stringify()` convierte un objeto de JavaScript en texto JSON.

```javascript
JSON.stringify({ error: 'No hay red ni cache' })
```

Produce un texto con la propiedad `error` y su mensaje.

### `headers` y `Content-Type`

`headers` es una propiedad del objeto de opciones. `Content-Type: application/json` informa que el cuerpo contiene JSON.

El constructor no recibe una propiedad `status`, así que la respuesta creada utiliza el estado `200` predeterminado.

## Elementos de `script.js` Relacionados con la Caché

`script.js` crea las peticiones que intercepta el worker.

### `async`

Declara una función asíncrona. Esa función devuelve una promesa y puede utilizar `await`.

### `await`

Espera dentro de la función asíncrona el resultado de una promesa antes de continuar con la siguiente instrucción.

```javascript
const respuesta = await fetch(API_URL);
```

### `respuesta.ok`

Es una propiedad booleana de `Response`. Indica si el estado HTTP pertenece al intervalo exitoso de 200 a 299.

### `respuesta.json()`

Es un método de `Response`. Lee el cuerpo y devuelve una promesa que produce el dato convertido desde JSON.

### `throw new Error()`

`Error` es una clase incorporada. `throw` interrumpe el flujo normal y envía ese error al bloque `catch` más cercano.

### `productos.forEach()`

`productos` es un arreglo obtenido de la API. `forEach()` ejecuta un callback una vez por cada producto para crear sus elementos HTML.

### `producto.image`

Es la propiedad que contiene la URL de la imagen. Al insertarla en `<img src=...>`, el navegador genera otra petición que el Service Worker puede interceptar.

### `loading=lazy`

Es un atributo HTML. Pide aplazar imágenes que todavía están lejos del área visible; por eso su petición y su almacenamiento pueden ocurrir más tarde.

## Resumen de Objetos y Tipos

| Elemento | Tipo o clase | Representa |
|---|---|---|
| `navigator` | `Navigator` | Capacidades del navegador para la página |
| `navigator.serviceWorker` | `ServiceWorkerContainer` | Administración de registros |
| `self` | `ServiceWorkerGlobalScope` | Contexto global de `sw.js` |
| `event` de instalación o activación | `ExtendableEvent` | Una etapa extensible con `waitUntil()` |
| `event` de petición | `FetchEvent` | Una petición interceptada |
| `caches` | `CacheStorage` | Conjunto de cachés del origen |
| `cacheCreado`, `cacheStatic`, `cacheDynamic` | `Cache` | Un contenedor de respuestas |
| `request` | `Request` | Petición HTTP |
| `respCache`, `respNetwork`, `respNetwor` | `Response` | Respuesta HTTP |
| `url` | `URL` | Dirección separada en partes |
| Resultado asíncrono | `Promise` | Valor que llegará después |
| `keys` y lista de `addAll()` | `Array` | Lista ordenada de valores |
| Nombres y direcciones | `String` | Texto |
| Comparaciones y `respuesta.ok` | `Boolean` | `true` o `false` |
| `error` | `Error` | Información de una falla |

## Resumen de Métodos y Funciones

| Elemento | Acción principal |
|---|---|
| `register()` | Solicita registrar `sw.js` |
| `addEventListener()` | Registra un callback para un evento |
| `waitUntil()` | Vincula una promesa con `install` o `activate` |
| `respondWith()` | Define la respuesta de un evento `fetch` |
| `caches.open()` | Abre o crea una caché |
| `caches.keys()` | Enumera nombres de cachés |
| `caches.match()` | Busca una respuesta almacenada |
| `caches.delete()` | Elimina una caché con nombre |
| `Cache.addAll()` | Solicita y guarda varios recursos |
| `Cache.put()` | Guarda una petición y una respuesta |
| `Response.clone()` | Crea otra instancia utilizable de la respuesta |
| `Promise.then()` | Continúa cuando una promesa se resuelve |
| `Promise.catch()` | Continúa cuando una promesa se rechaza |
| `Promise.all()` | Agrupa varias promesas |
| `fetch()` | Realiza una petición de red |
| `Response.json()` | Convierte un cuerpo JSON en datos de JavaScript |
| `JSON.stringify()` | Convierte datos de JavaScript en texto JSON |
| `Array.map()` | Recorre valores y crea otro arreglo |
| `Array.forEach()` | Ejecuta un callback por cada elemento |
| `console.log()` | Muestra información en la consola |

## Operadores y Símbolos

| Elemento | Significado sencillo |
|---|---|
| `const` | Declara una constante |
| `if` / `else` | Selecciona uno de dos caminos |
| `in` | Comprueba si existe una propiedad |
| `===` | Comprueba igualdad estricta |
| `!==` | Comprueba diferencia estricta |
| `&&` | Exige que dos condiciones sean verdaderas |
| `=>` | Declara una función flecha |
| `return` | Entrega el resultado de una función |
| `new` | Construye un objeto |
| `.` | Accede a una propiedad o método |
| `()` | Ejecuta una función o contiene argumentos |
| `{}` | Agrupa instrucciones o define un objeto literal |
| `[]` | Crea un arreglo |

## Cómo Leer las Estrategias en Lenguaje Cotidiano

```javascript
return caches.match(request).then((respCache) => { ... })
```

> Busca la petición en las cachés y, cuando llegue el resultado, llámalo `respCache` y continúa con las instrucciones.

```javascript
return fetch(request).then((respNetwor) => { ... }).catch(() => { ... })
```

> Intenta pedir el recurso a la red; si responde, utiliza `respNetwor`; si la operación falla, ejecuta el bloque de recuperación.

```javascript
cacheDynamic.put(request, respNetwor.clone())
```

> Guarda en la caché dinámica una copia de la respuesta asociada con la petición original.

## Relación General

```text
app.js → register()
            ↓
          sw.js
            ├── install  → app-static.addAll()
            ├── activate → keys() + delete()
            └── fetch
                 ├── cacheFirst()   → match() → fetch() → app-static.put()
                 └── networkFirst() → fetch() → app-dynamic.put() → catch() → match()
```
