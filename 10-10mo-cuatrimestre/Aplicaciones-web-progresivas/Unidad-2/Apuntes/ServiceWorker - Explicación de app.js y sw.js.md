# Service Worker — Explicación de `app.js` y `sw.js`

Este ejemplo muestra el ciclo de vida básico de un Service Worker: la página solicita su registro, el navegador instala el script, prepara recursos en caché, activa la versión instalada y permite que atienda peticiones de las páginas que controla.

La explicación corresponde al código existente en [`ServiceWorker/`](ServiceWorker/) y relaciona cada bloque con su función dentro del ciclo de vida.

Para aprender desde cero qué significa cada objeto, método, propiedad y operador del código, consulta [Service Worker — Objetos y métodos explicados](ServiceWorker%20-%20Objetos%20y%20métodos%20explicados.md).

## Archivos del Ejemplo

| Archivo | Función |
|---|---|
| [`index.html`](ServiceWorker/index.html) | Carga la interfaz, `styles.css` y `app.js` |
| [`styles.css`](ServiceWorker/styles.css) | Define la presentación del encabezado |
| [`app.js`](ServiceWorker/app.js) | Comprueba la disponibilidad de la API y registra `sw.js` |
| [`sw.js`](ServiceWorker/sw.js) | Gestiona los eventos `install`, `activate` y `fetch` |

El ejemplo se concentra en el Service Worker. No incluye un manifiesto web, por lo que el registro del worker no representa por sí solo una PWA instalable desde el sistema operativo.

## Contextos de Ejecución

`app.js` se ejecuta en el hilo principal de la página. Utiliza `navigator.serviceWorker` para comunicarse con el sistema de Service Workers del navegador y dispone de `window`, `document` y el DOM.

`sw.js` se ejecuta separado de la interfaz. Su objeto global es `self`, que representa un `ServiceWorkerGlobalScope`. Desde ahí utiliza APIs asíncronas como `fetch`, Cache Storage y las promesas, pero no manipula directamente el DOM.

El navegador puede iniciar o suspender el worker según los eventos pendientes. Consulta [Tema 3.2 - Arquitectura y Naturaleza del Service Worker](../../contexto-general/Tema%203.2%20-%20Arquitectura%20y%20Naturaleza%20del%20Service%20Worker.md).

## Ciclo de Vida en este Ejemplo

| Etapa | Elemento que participa | Función en el ejemplo |
|---|---|---|
| Carga | `index.html` | Carga `app.js` junto con la interfaz |
| Registro | `navigator.serviceWorker.register('./sw.js')` | Solicita registrar o actualizar el worker |
| Instalación | Evento `install` | Abre `v1_cache_10A` y agrega los recursos iniciales |
| Espera | Navegador | Mantiene una versión nueva en espera si otra controla páginas |
| Activación | Evento `activate` | Conserva la caché actual y elimina las demás |
| Control | Navegador | Asocia el worker activo con páginas dentro de su alcance |
| Peticiones | Evento `fetch` | Recibe solicitudes de las páginas controladas |
| Actualización | Comparación de `sw.js` | Una versión distinta vuelve a recorrer el ciclo |

El archivo no utiliza `self.skipWaiting()` ni `self.clients.claim()`. Conserva el flujo normal del navegador: una actualización puede permanecer en espera mientras la anterior controla páginas, y la página que inició el primer registro no es reclamada inmediatamente.

Consulta [Tema 3.3 - El Ciclo de Vida del Service Worker](../../contexto-general/Tema%203.3%20-%20El%20Ciclo%20de%20Vida%20del%20Service%20Worker.md).

## Registro: `app.js`

```javascript
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js')
}
```

`'serviceWorker' in navigator` comprueba si el navegador expone la API. `register('./sw.js')` solicita descargar, evaluar y registrar el script cuando esa capacidad está disponible.

La ruta es relativa a la página. Como `index.html`, `app.js` y `sw.js` están juntos, señala el worker del ejemplo. Su alcance predeterminado corresponde al directorio donde está `sw.js`.

El registro requiere un contexto seguro, como HTTPS o `http://localhost`; no funciona mediante `file://`.

## Identificación de la Caché

```javascript
const CACHE_NAME = 'v1_cache_10A';
```

`CACHE_NAME` identifica el contenedor usado por esta versión. Durante `install` indica qué caché abrir y durante `activate` indica cuál conservar. El prefijo `v1` es un identificador definido por el proyecto.

## Instalación: Evento `install`

```javascript
self.addEventListener('install', (event) => {
    console.log('Service Worker instalado');
    event.waitUntil(
        caches.open(CACHE_NAME)
        .then((cacheCreado) => {
            return cacheCreado.addAll([
                '/',
                '/index.html',
                '/styles.css',
                '/app.js'
            ])
        })
    );
});
```

El navegador dispara `install` cuando registra el worker por primera vez o detecta una versión diferente de `sw.js`.

- `self.addEventListener('install', ...)` registra el manejador de la instalación.
- `caches.open(CACHE_NAME)` abre `v1_cache_10A` o la crea si no existe.
- `cacheCreado` representa el objeto `Cache` entregado por la promesa.
- `cacheCreado.addAll(...)` solicita y almacena `/`, `/index.html`, `/styles.css` y `/app.js`.
- `event.waitUntil(...)` mantiene la fase vinculada a la cadena de promesas.

Esta preparación anticipada se conoce como **precaching**. Las rutas comienzan con `/`, por lo que se resuelven desde la raíz del origen.

```text
install
  → abrir v1_cache_10A
  → obtener el objeto Cache
  → solicitar y almacenar los recursos
  → finalizar la instalación
```

## Espera entre Versiones

Después de instalarse, una versión nueva puede entrar en estado `waiting` cuando otra versión todavía controla páginas abiertas.

Esta etapa no tiene un manejador explícito en `sw.js`; la administra el navegador. `waiting` es un estado, no uno de los eventos registrados en este código.

Como el ejemplo no utiliza `self.skipWaiting()`, la versión nueva permanece esperando mientras la anterior tenga páginas bajo su control. Normalmente se libera cuando se cierran o abandonan **todas las pestañas y ventanas controladas por la versión anterior**. No es obligatorio cerrar completamente todo el navegador si ya no queda ninguna página controlada abierta.

En la primera instalación no existe una versión anterior que reemplazar. El worker puede activarse, pero como tampoco se utiliza `self.clients.claim()`, la página que inició el registro no queda controlada inmediatamente; una recarga o navegación posterior permite que se abra bajo el worker activo.

## Cuántas Veces Ocurre Cada Evento

| Elemento | Frecuencia | Explicación |
|---|---|---|
| Ejecución de `register()` | Cada vez que se carga `app.js` | Solicitar el registro nuevamente no significa que el worker vuelva a instalarse |
| Evento `install` | Una vez por cada versión nueva de `sw.js` | Ocurre en el primer registro y cuando el navegador detecta una versión distinta |
| Estado `waiting` | Solo cuando una versión nueva debe esperar | Sucede si la versión anterior todavía controla alguna página |
| Evento `activate` | Una vez por cada versión instalada que llega a activarse | Ocurre cuando esa versión puede convertirse en la activa |
| Evento `fetch` | Muchas veces | Ocurre por cada petición realizada desde una página que ya está controlada |

Recargar una página sin cambiar `sw.js` puede volver a ejecutar `app.js` y `register()`, pero no repite automáticamente `install` ni `activate`. El navegador comprueba el script y conserva la versión existente cuando no detecta cambios.

## Activación: Evento `activate`

```javascript
self.addEventListener('activate', (event) => {
    console.log('Service Worker activado');
    event.waitUntil(
        caches.keys()
        .then((keys) => {
            return Promise.all(
                keys.map((cacheName) => {
                    if (cacheName !== CACHE_NAME) {
                        return caches.delete(cacheName);
                    }
                })
            )
        })
    );
});
```

La activación ocurre después de la instalación y del periodo de espera aplicable. En este ejemplo se utiliza para limpiar cachés distintas de la actual.

- `caches.keys()` obtiene los nombres de las cachés disponibles en el origen.
- `keys.map(...)` recorre cada nombre.
- `caches.delete(cacheName)` elimina cada contenedor distinto de `v1_cache_10A`.
- `Promise.all(...)` representa la finalización conjunta de las operaciones.
- `event.waitUntil(...)` mantiene activa esta fase mientras termina la limpieza.

El comportamiento abarca todas las cachés con otro nombre disponibles en el mismo origen.

```text
activate
  → enumerar cachés del origen
  → conservar v1_cache_10A
  → eliminar las cachés con otro nombre
  → finalizar la activación
```

## Control y Evento `fetch`

Cuando el Service Worker está activo y controla una página dentro de su alcance, recibe sus peticiones mediante `fetch`.

```javascript
self.addEventListener('fetch', (event) => {
    console.log('Fetch', event.request.url);
    event.respondWith(
        caches.match(event.request) || fetch(event.request)
    )
});
```

- `event.request` es el objeto `Request` interceptado.
- `event.request.url` es la dirección mostrada en la consola.
- `caches.match(event.request)` busca una respuesta entre las cachés del origen y devuelve una promesa.
- `event.respondWith(...)` asocia el resultado con esa petición.

La expresión del ejemplo es:

```javascript
caches.match(event.request) || fetch(event.request)
```

El operador `||` evalúa inmediatamente la promesa devuelta por `caches.match()`. Como el objeto `Promise` se considera verdadero, la llamada situada después de `||` no se ejecuta.

| Estado del recurso | Resultado del código actual |
|---|---|
| Existe en caché | La promesa entrega la respuesta almacenada |
| No existe en caché | La promesa entrega `undefined` y no se realiza la llamada de red escrita después de `||` |

Así, este manejador entrega los recursos que ya estén en Cache Storage. Esta descripción corresponde al flujo que ejecuta actualmente `sw.js`.

| Método | Etapa | Responsabilidad |
|---|---|---|
| `event.waitUntil(promesa)` | `install` y `activate` | Extender una tarea del ciclo de vida |
| `event.respondWith(respuesta)` | `fetch` | Definir la respuesta de una petición |

Consulta [Tema 4.1 - Anatomía de las Estrategias de Caching](../../contexto-general/Tema%204.1%20-%20Anatomía%20de%20las%20Estrategias%20de%20Caching.md) para conocer el contexto teórico de las estrategias de caché.

## Flujo Funcional Completo

### Primera visita

1. El navegador descarga `index.html`, `styles.css` y `app.js`.
2. `app.js` comprueba la API de Service Workers.
3. `register('./sw.js')` solicita el registro.
4. El navegador evalúa `sw.js` y dispara `install`.
5. `install` abre `v1_cache_10A` y guarda los recursos indicados.
6. El navegador activa el worker.
7. Una página bajo su control genera eventos `fetch` para sus peticiones.

### Carga posterior

1. La página puede iniciar dentro del alcance del worker activo.
2. Cada petición controlada dispara `fetch`.
3. El manejador busca la petición en Cache Storage.
4. Si existe, entrega la respuesta almacenada.

### Actualización de `sw.js`

1. El navegador detecta una versión diferente del script.
2. Ejecuta `install` para esa versión.
3. La versión nueva puede permanecer en espera mientras la anterior controla páginas.
4. Cuando se activa, ejecuta `activate`.
5. La activación conserva `v1_cache_10A` y elimina los demás contenedores del origen.

## Ejecución y Observación

Desde la carpeta `Apuntes`, utiliza `ServiceWorker` como raíz del servidor:

```bash
cd ServiceWorker
python -m http.server 8080
```

Abre `http://localhost:8080`. Al servir esa carpeta como raíz, `/index.html`, `/styles.css` y `/app.js` corresponden con los recursos incluidos en `addAll()`.

En Chrome DevTools se puede observar:

- **Application → Service Workers:** registro y estado del worker.
- **Application → Cache Storage:** contenido de `v1_cache_10A`.
- **Console:** mensajes de `install`, `activate` y las URL recibidas por `fetch`.
- **Network:** solicitudes realizadas por la página.

Consulta [Tema 2.3 - Chrome DevTools como Centro de Mando PWA](../../contexto-general/Tema%202.3%20-%20Chrome%20DevTools%20como%20Centro%20de%20Mando%20PWA.md) para relacionar estos estados con las herramientas del navegador.
