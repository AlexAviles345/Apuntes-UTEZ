# Estrategias de Caché Sana — Explicación del Funcionamiento

Esta guía explica con palabras sencillas la práctica de versionamiento, límite de tamaño e inyección de tiempo en Cache Storage.

El enunciado completo se conserva en [Práctica dirigida 4.2 — Evolución de estrategias de caché sana](Práctica%20dirigida%204.2%20-%20Evolución%20de%20estrategias%20de%20caché%20sana.md).

## Resumen de la Implementación

La práctica aplica versionamiento, límite de tamaño y tiempo de vida a las respuestas almacenadas por el Service Worker.

| Elemento | Implementación |
|---|---|
| Nombres de caché | `static-v2` y `dynamic-v2` |
| Límite dinámico | Cinco elementos mediante `DYNAMIC_LIMIT` |
| TTL | 30 segundos mediante `TTL_MAX_SECONDS` |
| Limpieza | Lista blanca durante `activate` |
| Algoritmo de tamaño | FIFO recursivo que elimina `keys[0]` |
| Marca temporal | Cabecera personalizada `x-sw-timestamp` |
| Caché de archivos locales | Cache First con validación TTL |
| Caché de la API | Network First con TTL y contingencia |
| Programación asíncrona en `sw.js` | Encadenamiento con `.then()` y `.catch()` |
| API utilizada | `dragonball-api.com` |

La implementación se encuentra en [`sw.js`](pwa-practica-4.2/sw.js) y trabaja con la interfaz de catálogo definida por los demás archivos.

## Archivos de la Práctica

| Archivo | Responsabilidad |
|---|---|
| [`index.html`](pwa-practica-4.2/index.html) | Define el catálogo, los botones de paginación y el modal |
| [`styles.css`](pwa-practica-4.2/styles.css) | Presenta las tarjetas, el modal y la versión para celulares |
| [`app.js`](pwa-practica-4.2/app.js) | Consulta Dragon Ball API, llena la interfaz y registra el Service Worker |
| [`sw.js`](pwa-practica-4.2/sw.js) | Intercepta peticiones y administra las cachés, el TTL y el límite FIFO |

## Cómo Ejecutar el Proyecto

No se debe abrir `index.html` directamente mediante `file://`. Los Service Workers necesitan HTTPS o un servidor local.

La terminal debe ubicarse dentro de `pwa-practica-4.2/`.

### Live Server

Abre `index.html` con **Open with Live Server** desde VS Code.

### Python

```bash
python -m http.server 8080
```

Después abre `http://localhost:8080`.

### Node.js

```bash
npx http-server -p 8080
```

Después de cambiar `sw.js`, conviene abrir DevTools, entrar a **Application → Service Workers**, eliminar el registro anterior y recargar. Una versión antigua puede seguir controlando la página aunque el archivo ya se haya modificado.

## Qué Hace `index.html`

`index.html` contiene los espacios que JavaScript llenará posteriormente:

- `#personajes` recibe las tarjetas del catálogo.
- `#mensaje` informa si la carga terminó o falló.
- `#anterior` y `#siguiente` cambian de página.
- `#modal` muestra los datos de un personaje.
- `app.js` se carga con `defer`, por lo que se ejecuta después de interpretar el HTML.

El HTML no consulta la API ni utiliza Cache Storage directamente. Solo prepara la interfaz.

## Qué Hace `app.js`

La aplicación consulta:

```text
https://dragonball-api.com/api/characters
```

### Carga del catálogo

`cargarPersonajes()` construye una URL con la página y el límite:

```text
?page=1&limit=20
```

Después procesa `datos.items`, crea una tarjeta por personaje y actualiza los botones de paginación.

### Consulta del detalle

`verPersonaje(id)` solicita una dirección como:

```text
https://dragonball-api.com/api/characters/1
```

La respuesta se presenta dentro del modal.

### Registro del Service Worker

Al final del archivo se comprueba si el navegador admite Service Workers y se registra `./sw.js`.

El uso de `async/await` en `app.js` no incumple la actividad. La prohibición se limita expresamente a `sw.js`.

## Ciclo de Vida del Service Worker

| Etapa | Frecuencia | Responsabilidad en esta práctica |
|---|---|---|
| Registro | Se solicita durante cada carga de `app.js` | Instala el worker por primera vez o busca una versión nueva |
| `install` | Una vez por cada versión nueva de `sw.js` | Debe preparar los recursos estáticos |
| `activate` | Una vez cuando la versión puede tomar el control | Elimina cachés obsoletas y reclama las páginas abiertas |
| `fetch` | Una vez por cada petición interceptada | Decide qué estrategia debe responder |

`install` y `activate` no ocurren con cada petición. `fetch` sí puede ejecutarse muchas veces durante una misma visita.

## Los Dos Contenedores de Caché

```javascript
const CACHE_STATIC_NAME = 'static-v2';
const CACHE_DYNAMIC_NAME = 'dynamic-v2';
```

| Contenedor | Contenido esperado |
|---|---|
| `static-v2` | HTML, CSS y JavaScript locales |
| `dynamic-v2` | Respuestas obtenidas dinámicamente desde la API |

El texto `v2` representa la versión. Cuando una actualización use otros nombres, el evento `activate` podrá reconocer que los contenedores anteriores ya no pertenecen a la lista blanca.

## Pilar 1: Versionamiento y Purga

El primer evento `activate` crea esta lista:

```javascript
const listaBlanca = [CACHE_STATIC_NAME, CACHE_DYNAMIC_NAME];
```

Después sigue este proceso:

```text
1. caches.keys() obtiene todos los nombres.
2. map() revisa cada nombre.
3. includes() comprueba si pertenece a la lista blanca.
4. caches.delete() elimina los contenedores obsoletos.
5. Promise.all() espera todas las eliminaciones.
6. self.clients.claim() permite que la versión activa controle las páginas.
```

Esta parte evita conservar indefinidamente cachés como `static-v1` o `dynamic-v1`.

## Pilar 2: Límite FIFO

FIFO significa **primero en entrar, primero en salir**.

`limpiarCacheLimitado()` abre la caché y obtiene sus peticiones mediante `cache.keys()`. El primer elemento del arreglo, `keys[0]`, representa la entrada más antigua según el orden manejado por Cache API.

```text
La caché contiene 6 elementos
        ↓
se elimina keys[0]
        ↓
la función se llama nuevamente
        ↓
la caché contiene 5 elementos
        ↓
termina la limpieza
```

La llamada recursiva permite corregir también una caché que supere el límite por más de un elemento.

Este control se aplica a `dynamic-v2`, no a `static-v2`.

## Pilar 3: Inyección de Timestamp

Las respuestas recibidas de `fetch()` no permiten modificar directamente sus cabeceras. Por ello, `crearRespuestaConTimestamp()` construye otra respuesta.

```text
Response original
├── headers → se copian con new Headers()
├── body → se lee mediante blob()
├── status y statusText → se conservan
└── x-sw-timestamp → se agrega con Date.now()
```

El valor de `Date.now()` es la cantidad de milisegundos transcurridos desde el 1 de enero de 1970. No tiene que ser legible para una persona; se utiliza para realizar cálculos.

La nueva cabecera se parece a esta:

```text
x-sw-timestamp: 1793808123456
```

## Cómo se Calcula el TTL

TTL significa **tiempo de vida**.

`esRespuestaFresca()` recupera `x-sw-timestamp`, calcula la diferencia con la hora actual y la convierte de milisegundos a segundos:

```text
(fechaActual - fechaGuardada) / 1000
```

Con `TTL_MAX_SECONDS = 30`:

| Edad de la respuesta | Resultado |
|---:|---|
| 5 segundos | Fresca; puede utilizarse |
| 29.9 segundos | Fresca; puede utilizarse |
| 30 segundos | Expirada |
| 45 segundos | Expirada |
| Sin `x-sw-timestamp` | Expirada |

La comparación utiliza `<`, por lo que una edad exactamente igual al límite ya no se considera fresca.

## Cache First Evolucionado

`cacheFirstEvolucionado()` está destinado a los archivos locales.

```text
Petición local
    ↓
caches.match(request)
    ├── existe y está fresca → devolver caché
    └── no existe o expiró
            ↓
          fetch(request)
            ↓
          inyectar timestamp
            ↓
          guardar en static-v2
            ↓
          devolver respuesta
```

La diferencia respecto a un Cache First sencillo es que encontrar una entrada ya no basta. También debe superar la validación temporal.

Si el archivo está expirado y tampoco hay red, esta función no tiene un `catch()` propio. En ese caso la petición falla porque no existe un respaldo adicional.

## Network First Evolucionado

`networkFirstEvolucionado()` está destinado a los datos dinámicos.

```text
Petición de API
    ↓
intentar la red
    ├── HTTP 200
    │      ↓
    │   inyectar timestamp
    │      ↓
    │   guardar en dynamic-v2
    │      ↓
    │   aplicar límite FIFO
    │      ↓
    │   devolver respuesta
    │
    └── falla de red
           ↓
        buscar en caché
           ├── existe y está fresca → devolver caché
           └── no existe o expiró → devolver JSON de contingencia
```

Network First prioriza datos recientes. La caché se utiliza como respaldo cuando la red realmente rechaza la petición.

Una respuesta HTTP como `404` o `500` normalmente no activa `.catch()`: `fetch()` sí recibió una respuesta. El código solo almacena las respuestas cuyo estado es exactamente `200`.

## Respuesta Sintética de Contingencia

Cuando no hay red ni una copia fresca, el Service Worker construye manualmente un `Response` con JSON:

```json
{
  "error": true,
  "mensaje": "La conexión falló y los datos locales han expirado o no existen."
}
```

Como no se especifica otro estado, esta respuesta utiliza `200` por defecto.

La interfaz actual espera propiedades como `items` y `meta`. Por eso no muestra directamente el texto `mensaje`: al intentar procesar el JSON de contingencia se produce un error y el `catch` de `app.js` termina mostrando `No se pudieron cargar los personajes.`. El JSON sí puede revisarse en DevTools.

## Integración del Service Worker

### Instalación de `static-v2`

El evento `install` abre la caché declarada mediante `CACHE_STATIC_NAME` y utiliza `addAll()` para almacenar la base local de la aplicación:

```javascript
caches.open(CACHE_STATIC_NAME)
```

La lista incluye `/`, `/index.html`, `/styles.css` y `/app.js`.

### Activación única

El evento `activate` utiliza `listaBlanca`, `CACHE_STATIC_NAME` y `CACHE_DYNAMIC_NAME`. Cualquier contenedor cuyo nombre no aparezca en esa lista se elimina antes de ejecutar `self.clients.claim()`.

### Enrutamiento de Dragon Ball API

La condición de las rutas dinámicas reconoce el dominio consumido por `app.js`:

```javascript
url.hostname.includes('dragonball-api.com')
```

Por ello, las consultas del catálogo y de los detalles se entregan a `networkFirstEvolucionado()`.

## Punto de Integración del Precaching

`cache.addAll()` guarda respuestas originales sin la cabecera `x-sw-timestamp`. Después, `cacheFirstEvolucionado()` considera obsoleta cualquier respuesta que no tenga esa cabecera.

Esto produce el siguiente comportamiento:

1. `install` precarga HTML, CSS y JavaScript.
2. La primera petición controlada encuentra esos archivos.
3. Como no contienen `x-sw-timestamp`, se consideran expirados.
4. Se solicitan nuevamente a la red.
5. La nueva respuesta se estampa y reemplaza la entrada.

`addAll()` no inyecta la cabecera durante la instalación. La marca temporal se incorpora cuando `cacheFirstEvolucionado()` vuelve a obtener el recurso desde la red y reemplaza la entrada guardada.

## Alcance de la Caché Dinámica

Con el enrutador de Dragon Ball API, `dynamic-v2` almacena las peticiones que cumplen la condición del dominio y regresan con estado `200`, por ejemplo:

```text
GET https://dragonball-api.com/api/characters?page=1&limit=20
GET https://dragonball-api.com/api/characters/1
```

Las imágenes utilizan las direcciones recibidas en `personaje.image`. Solo entrarán a `dynamic-v2` si su hostname también coincide con la condición y la respuesta cumple la validación del código. No se debe asumir que todas las imágenes quedan guardadas únicamente por aparecer en pantalla.

## Cómo Probar la Práctica en DevTools

### Preparación

1. Ejecuta el proyecto desde `pwa-practica-4.2/` con un servidor local.
2. Abre DevTools.
3. En **Application → Service Workers**, elimina versiones anteriores.
4. En **Application → Cache Storage**, elimina cachés de pruebas anteriores.
5. Recarga dos veces: una para registrar/activar y otra para trabajar con la página ya controlada.

### Verificar las versiones

En **Application → Cache Storage** deben aparecer:

```text
static-v2
dynamic-v2
```

### Verificar el timestamp

1. Realiza una consulta con conexión.
2. Abre una entrada de `dynamic-v2`.
3. Revisa las cabeceras de la respuesta.
4. Confirma que exista `x-sw-timestamp` con un número.

### Verificar el TTL

1. Cambia temporalmente `TTL_MAX_SECONDS` a `15`.
2. Consulta una página o personaje con conexión.
3. Activa **Offline**.
4. Repite la consulta antes de 15 segundos: debe poder usar la copia fresca.
5. Espera más de 15 segundos y repite: debe utilizar la respuesta de contingencia.

Cada cambio en `sw.js` crea potencialmente una versión nueva. Asegúrate de que DevTools indique `activated and is running` antes de evaluar el resultado.

### Verificar FIFO

Realiza más de cinco peticiones distintas que sean almacenadas en `dynamic-v2`. Al finalizar la limpieza, deben quedar como máximo cinco. La entrada más antigua debe desaparecer primero.

### Verificar la purga

Si existen cachés con nombres anteriores como `static-v1` o `dynamic-v1`, activa la nueva versión y comprueba que `activate` las elimine mientras conserva `static-v2` y `dynamic-v2`.

## Objetos y Métodos Principales

| Elemento | Explicación sencilla |
|---|---|
| `self` | Contexto global del Service Worker |
| `caches` | Acceso general a Cache Storage |
| `caches.open()` | Abre o crea un contenedor |
| `caches.keys()` | Obtiene los nombres de los contenedores |
| `caches.match()` | Busca una respuesta guardada |
| `caches.delete()` | Elimina un contenedor completo |
| `cache.keys()` | Obtiene las peticiones guardadas en un contenedor |
| `cache.put()` | Guarda una petición junto con su respuesta |
| `cache.delete()` | Elimina una entrada particular |
| `fetch()` | Solicita un recurso a la red |
| `Headers` | Representa una colección de cabeceras HTTP |
| `Response` | Representa una respuesta HTTP |
| `Response.blob()` | Lee el cuerpo como datos binarios |
| `Response.clone()` | Crea una copia utilizable de la respuesta |
| `Date.now()` | Obtiene la hora actual en milisegundos |
| `parseInt()` | Convierte el timestamp de texto a número |
| `Promise.all()` | Espera un grupo de promesas |
| `.then()` | Continúa cuando una promesa se resuelve |
| `.catch()` | Atiende el rechazo de una promesa |
| `event.waitUntil()` | Vincula una promesa con `install` o `activate` |
| `event.respondWith()` | Indica qué respuesta atenderá una petición |

## Flujo General de la Aplicación

```text
index.html
├── styles.css → apariencia
└── app.js
    ├── consulta Dragon Ball API
    ├── crea tarjetas y modal
    └── registra sw.js
        ├── install → prepara static-v2
        ├── activate → purga versiones antiguas
        └── fetch
            ├── recurso local → cacheFirstEvolucionado()
            │   └── caché fresca o red + timestamp
            └── API dinámica → networkFirstEvolucionado()
                └── red + timestamp + FIFO o caché fresca + fallback
```

## Conclusión

La evolución de la práctica agrega tres controles que no existían en una estrategia básica:

1. **Versionamiento:** permite retirar contenedores anteriores.
2. **Límite FIFO:** impide que la caché dinámica crezca sin control.
3. **TTL inyectado:** permite decidir la antigüedad sin depender de la cabecera `Date` del servidor.

Las funciones centrales trabajan en conjunto: la instalación prepara `static-v2`, la activación conserva las cachés vigentes y el enrutador conecta las peticiones con la estrategia correspondiente.
