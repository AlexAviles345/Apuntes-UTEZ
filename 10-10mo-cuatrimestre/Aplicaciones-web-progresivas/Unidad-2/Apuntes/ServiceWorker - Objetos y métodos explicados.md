# Service Worker — Objetos y Métodos Explicados

Esta guía explica, con palabras sencillas, los elementos utilizados en [`app.js`](ServiceWorker/app.js) y [`sw.js`](ServiceWorker/sw.js). No es necesario conocer programación avanzada para seguirla.

La explicación del flujo completo y de las etapas está en [Service Worker — Explicación de app.js y sw.js](ServiceWorker%20-%20Explicación%20de%20app.js%20y%20sw.js.md).

## Ideas Básicas antes de Leer el Código

### Variable y constante

Una variable es un nombre usado para guardar un valor. Una constante también guarda un valor, pero no permite asignarle otro después.

```javascript
const CACHE_NAME = 'v1_cache_10A';
```

- `const` declara una constante.
- `CACHE_NAME` es el nombre elegido para identificarla.
- `'v1_cache_10A'` es el texto almacenado.

### Objeto

Un objeto agrupa información y acciones relacionadas. Por ejemplo, `navigator` representa información y capacidades del navegador.

### Clase o tipo

Una clase o tipo describe qué características pueden tener ciertos objetos. El proyecto no escribe clases con la palabra `class`; los objetos usados son creados y entregados por el navegador.

Por ejemplo, `event.request` es un objeto cuyo tipo es `Request`.

### Propiedad

Una propiedad es un dato contenido dentro de un objeto. Se accede con un punto:

```javascript
event.request.url
```

Aquí `request` es una propiedad de `event` y `url` es una propiedad de `request`.

### Método

Un método es una acción perteneciente a un objeto:

```javascript
caches.open(CACHE_NAME)
```

`open()` es una acción del objeto `caches`. Los paréntesis indican que se está ejecutando.

### Función callback

Un callback es una función entregada a otra operación para que se ejecute después o cuando ocurra un evento.

```javascript
(event) => {
    console.log('Service Worker instalado');
}
```

`event` recibe información de lo ocurrido y `=>` separa los parámetros de las instrucciones.

### Promesa

Una promesa representa un resultado que llegará después. Abrir una caché, guardar archivos y consultar la red son operaciones asíncronas, por lo que no terminan necesariamente en el mismo instante en que se solicitan.

```text
Se solicita una operación → queda pendiente → termina y entrega un resultado
```

## Elementos de `app.js`

```javascript
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js')
}
```

### `if`

`if` significa «si se cumple esta condición, ejecuta lo que está entre llaves».

### Operador `in`

```javascript
'serviceWorker' in navigator
```

Pregunta si `navigator` contiene una propiedad llamada `serviceWorker`. El resultado es `true` o `false`.

### `navigator`

Es un objeto proporcionado por el navegador a la página. Permite consultar capacidades del entorno.

### `navigator.serviceWorker`

Es una propiedad de `navigator`. Su valor es un objeto de tipo `ServiceWorkerContainer`, encargado de administrar Service Workers desde la página.

### `register('./sw.js')`

`register()` es un método de `ServiceWorkerContainer`. Le solicita al navegador registrar o buscar una actualización del archivo `sw.js`.

Recibe como argumento la ruta `'./sw.js'`:

- `.` significa «desde la carpeta actual».
- `/sw.js` identifica el archivo.

El método devuelve una promesa. Cuando el registro termina correctamente, esa promesa puede entregar un objeto de tipo `ServiceWorkerRegistration`, aunque este ejemplo no guarda dicho resultado en una variable.

## Elementos Globales de `sw.js`

### `self`

Es el objeto global del Service Worker. Su tipo es `ServiceWorkerGlobalScope`.

Puede imaginarse como el «entorno de trabajo» donde vive `sw.js`. No es la página, no representa el DOM y no es una clase creada por el proyecto.

### `addEventListener()`

Es un método que registra una función para responder cuando ocurre un evento:

```javascript
self.addEventListener('install', callback)
```

Recibe dos argumentos:

1. El nombre del evento, como `'install'`.
2. La función que se ejecutará cuando ocurra.

El proyecto lo usa tres veces para escuchar `install`, `activate` y `fetch`.

### `event`

Es el nombre que el código asigna al objeto que describe el evento actual. El navegador lo entrega automáticamente al callback.

Su tipo depende del evento:

| Evento | Tipo del objeto `event` | Qué representa |
|---|---|---|
| `install` | `ExtendableEvent` | Instalación de una versión |
| `activate` | `ExtendableEvent` | Activación de una versión |
| `fetch` | `FetchEvent` | Petición interceptada |

### `console.log()`

`console` es un objeto disponible para diagnóstico y `log()` es un método que imprime información en la consola del navegador.

## Elementos Usados durante `install`

### `caches`

Es un objeto de tipo `CacheStorage` proporcionado por el navegador. Funciona como la entrada principal al conjunto de cachés del sitio.

`caches` no es una sola caché. Es el administrador que permite abrir, buscar, enumerar o eliminar cachés con nombre.

### `caches.open(CACHE_NAME)`

`open()` busca una caché con el nombre recibido. Si no existe, la crea. Devuelve una promesa que entrega un objeto de tipo `Cache`.

```text
CacheStorage (`caches`)
└── Cache (`v1_cache_10A`)
    ├── /index.html
    ├── /styles.css
    └── /app.js
```

### `.then()`

Es un método de una promesa. Recibe un callback que se ejecuta cuando la operación termina correctamente.

```javascript
caches.open(CACHE_NAME).then((cacheCreado) => {
    // Aquí ya está disponible el objeto Cache
})
```

`cacheCreado` es solo el nombre elegido para recibir el resultado. Su tipo es `Cache`.

### `cacheCreado.addAll()`

`addAll()` es un método del objeto `Cache`. Recibe un arreglo de rutas, solicita cada recurso y almacena sus respuestas.

```javascript
cacheCreado.addAll([
    '/',
    '/index.html',
    '/styles.css',
    '/app.js'
])
```

Los corchetes `[]` crean un arreglo: una lista ordenada de valores. Cada texto dentro del arreglo es una ruta.

### `return`

`return` entrega un resultado desde una función. En este caso entrega la promesa de `addAll()` para mantenerla conectada con la promesa iniciada por `open()`.

```text
open() → then() → addAll()
```

### `event.waitUntil()`

Es un método del evento de instalación o activación. Recibe una promesa y le indica al navegador que esa tarea forma parte de la etapa actual.

En `install`, la promesa representa abrir la caché y guardar los archivos. En `activate`, representa enumerar y eliminar cachés.

## Elementos Usados durante `activate`

### `caches.keys()`

`keys()` es un método de `CacheStorage`. Devuelve una promesa que entrega un arreglo con los nombres de las cachés disponibles.

Por ejemplo:

```javascript
['v0_cache_10A', 'v1_cache_10A']
```

El nombre `keys` utilizado en el callback representa ese arreglo.

### `keys.map()`

`map()` es un método de los arreglos. Recorre sus elementos uno por uno y ejecuta un callback para cada uno.

```javascript
keys.map((cacheName) => {
    // cacheName contiene un nombre distinto en cada recorrido
})
```

Si el arreglo contiene dos nombres, el callback se ejecuta dos veces. `map()` devuelve un nuevo arreglo con los resultados de esas ejecuciones.

### Operador `!==`

```javascript
cacheName !== CACHE_NAME
```

Significa «el valor de `cacheName` es diferente del valor de `CACHE_NAME`». El resultado es un booleano: `true` o `false`.

### `caches.delete(cacheName)`

`delete()` es un método de `CacheStorage`. Solicita eliminar por completo la caché cuyo nombre recibe y devuelve una promesa con un valor booleano.

No debe confundirse con la palabra reservada `delete` de JavaScript: aquí se está llamando a un método mediante `caches.delete()`.

### `Promise.all()`

`Promise` es el tipo incorporado que representa operaciones asíncronas. `all()` es un método estático que recibe un arreglo de promesas y crea una promesa conjunta.

```text
eliminación 1 ─┐
eliminación 2 ─┼─→ Promise.all() → todas terminaron
eliminación 3 ─┘
```

En el ejemplo, permite relacionar el conjunto completo de eliminaciones con `event.waitUntil()`.

## Elementos Usados durante `fetch`

### `FetchEvent`

Es el tipo de evento que representa una petición interceptada por el Service Worker. El parámetro llamado `event` recibe un objeto de este tipo.

### `event.request`

Es una propiedad de `FetchEvent`. Contiene un objeto de tipo `Request`, que describe qué recurso se está solicitando.

### `event.request.url`

`url` es una propiedad del objeto `Request`. Contiene como texto la dirección completa de la petición.

### `caches.match(event.request)`

`match()` es un método de `CacheStorage`. Busca una respuesta guardada que coincida con la petición y devuelve una promesa.

El resultado futuro puede ser:

- Un objeto `Response` cuando encuentra el recurso.
- `undefined` cuando no encuentra una coincidencia.

### `fetch(event.request)`

`fetch()` es una función proporcionada por el entorno web. Inicia una petición de red y devuelve una promesa que entrega un objeto `Response`.

En el código actual aparece a la derecha del operador `||`.

### Operador `||`

`||` significa «o» y devuelve el primer operando que sea considerado verdadero.

```javascript
caches.match(event.request) || fetch(event.request)
```

`caches.match()` entrega inmediatamente un objeto `Promise`. Un objeto es considerado verdadero, aunque su resultado todavía no haya llegado. Por eso la expresión conserva esa promesa y no ejecuta la llamada `fetch()` situada a la derecha.

### `event.respondWith()`

Es un método de `FetchEvent`. Le indica al navegador qué respuesta debe usar para la petición interceptada.

Puede recibir un objeto `Response` o una promesa que produzca uno. En este proyecto recibe la promesa devuelta por `caches.match()`.

## Diferencia entre `waitUntil()` y `respondWith()`

| Método | Se usa en | Explicación sencilla |
|---|---|---|
| `waitUntil()` | `install` y `activate` | «Espera a que esta tarea termine antes de cerrar la etapa» |
| `respondWith()` | `fetch` | «Utiliza este resultado para responder esta petición» |

## Objetos y Tipos Presentes

| Nombre visto en el código | Tipo o clase | Explicación sencilla |
|---|---|---|
| `navigator` | `Navigator` | Representa capacidades del navegador para la página |
| `navigator.serviceWorker` | `ServiceWorkerContainer` | Administra los Service Workers desde la página |
| Resultado de `register()` | `ServiceWorkerRegistration` | Representa un registro administrado por el navegador |
| `self` | `ServiceWorkerGlobalScope` | Es el entorno global donde se ejecuta `sw.js` |
| `event` de `install` | `ExtendableEvent` | Describe la instalación actual |
| `event` de `activate` | `ExtendableEvent` | Describe la activación actual |
| `event` de `fetch` | `FetchEvent` | Describe una petición interceptada |
| `caches` | `CacheStorage` | Administra todas las cachés con nombre del origen |
| `cacheCreado` | `Cache` | Representa una caché concreta |
| `event.request` | `Request` | Describe el recurso solicitado |
| Resultado de `match()` o `fetch()` | `Response` | Contiene una respuesta HTTP |
| Resultado de operaciones asíncronas | `Promise` | Representa un resultado que llegará después |
| Lista entregada a `addAll()` | `Array` | Contiene varias rutas ordenadas |
| `keys` | `Array` | Contiene nombres de cachés |
| `CACHE_NAME` y `cacheName` | `String` | Contienen texto |
| Resultado de comparaciones | `Boolean` | Puede ser `true` o `false` |
| Ausencia de una coincidencia | `undefined` | Indica que no se obtuvo un valor |

Los nombres `cacheCreado`, `keys` y `cacheName` fueron elegidos por la persona que escribió el código. Cambiar esos nombres de variable no cambia el tipo de objeto que reciben.

## Métodos y Funciones Presentes

| Método o función | Pertenece a | Qué hace |
|---|---|---|
| `register()` | `ServiceWorkerContainer` | Solicita registrar o actualizar `sw.js` |
| `addEventListener()` | `ServiceWorkerGlobalScope` | Registra una función para un evento |
| `log()` | `console` | Imprime información en la consola |
| `waitUntil()` | `ExtendableEvent` | Vincula una promesa con una etapa |
| `open()` | `CacheStorage` | Abre o crea una caché con nombre |
| `then()` | `Promise` | Ejecuta un callback cuando llega el resultado |
| `addAll()` | `Cache` | Solicita y guarda varios recursos |
| `keys()` | `CacheStorage` | Obtiene los nombres de las cachés |
| `map()` | `Array` | Recorre elementos y crea otro arreglo de resultados |
| `delete()` | `CacheStorage` | Elimina una caché por su nombre |
| `all()` | `Promise` | Agrupa varias promesas en una sola |
| `match()` | `CacheStorage` | Busca una respuesta almacenada |
| `respondWith()` | `FetchEvent` | Define la respuesta de una petición |
| `fetch()` | Entorno web | Inicia una petición de red |

## Propiedades Presentes

| Propiedad | Objeto que la contiene | Qué representa |
|---|---|---|
| `serviceWorker` | `navigator` | Acceso a la administración de Service Workers |
| `request` | Evento `fetch` | Petición que fue interceptada |
| `url` | `Request` | Dirección de la petición expresada como texto |

Una propiedad se consulta sin ejecutarla. Por eso `event.request.url` no lleva paréntesis. Un método sí representa una acción y se escribe con paréntesis, como `caches.keys()`.

## Símbolos y Palabras del Código

| Elemento | Significado sencillo |
|---|---|
| `const` | Declara una constante |
| `if` | Ejecuta un bloque cuando una condición es verdadera |
| `in` | Comprueba si una propiedad existe dentro de un objeto |
| `=>` | Declara una función flecha |
| `return` | Entrega el resultado de una función |
| `!==` | Comprueba que dos valores sean diferentes |
| `||` | Operador «o»; conserva el primer operando considerado verdadero |
| `.` | Accede a una propiedad o método de un objeto |
| `()` | Ejecuta una función o contiene sus parámetros |
| `{}` | Agrupa instrucciones dentro de un bloque |
| `[]` | Crea un arreglo o lista |
| `;` | Marca el final de una instrucción |

## Cómo Leer Algunas Líneas en Lenguaje Cotidiano

```javascript
self.addEventListener('install', (event) => { ... })
```

> En el Service Worker, guarda esta función para ejecutarla cuando ocurra la instalación; cuando suceda, llama `event` al objeto que describe ese evento.

```javascript
caches.open(CACHE_NAME).then((cacheCreado) => { ... })
```

> Solicita abrir la caché indicada por `CACHE_NAME` y, cuando esté disponible, llama `cacheCreado` al objeto recibido para utilizarlo dentro de la función.

```javascript
keys.map((cacheName) => { ... })
```

> Recorre la lista `keys`; en cada vuelta llama `cacheName` al elemento actual y ejecuta las instrucciones del bloque.

```javascript
event.respondWith(caches.match(event.request))
```

> Para esta petición, busca una respuesta almacenada en caché y utiliza el resultado de esa búsqueda como respuesta.

## Relación General

```text
app.js
└── navigator.serviceWorker.register()
    └── el navegador administra sw.js
        ├── install  → CacheStorage.open() → Cache.addAll()
        ├── activate → CacheStorage.keys() → CacheStorage.delete()
        └── fetch    → CacheStorage.match() → FetchEvent.respondWith()
```

La idea principal es que `app.js` solicita el registro, mientras que `sw.js` espera eventos. Los objetos son proporcionados por el navegador y los métodos indican qué acción se desea realizar con cada objeto.
