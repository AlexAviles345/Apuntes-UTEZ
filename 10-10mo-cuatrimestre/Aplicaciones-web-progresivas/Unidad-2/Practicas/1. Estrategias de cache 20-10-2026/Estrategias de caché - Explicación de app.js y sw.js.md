# Estrategias de Caché — Explicación de `app.js` y `sw.js`

Esta práctica presenta una tienda que consulta Fake Store API y utiliza un Service Worker para aplicar dos estrategias:

- **Cache First** para los recursos que no pertenecen al origen de Fake Store API.
- **Network First** para las peticiones dirigidas a `https://fakestoreapi.com`.

La separación produce dos contenedores: `app-static` y `app-dynamic`. La elección se realiza por el origen de cada URL, no solamente por la extensión del archivo.

Para estudiar desde cero cada objeto, método, clase, propiedad y operador, consulta [Estrategias de caché — Objetos y métodos explicados](Estrategias%20de%20caché%20-%20Objetos%20y%20métodos%20explicados.md).

## Archivos de la Práctica

| Archivo | Responsabilidad |
|---|---|
| [`index.html`](practica%20-%20estrategias%20de%20cache/index.html) | Contiene el catálogo, el modal y las referencias a los scripts |
| [`styles.css`](practica%20-%20estrategias%20de%20cache/styles.css) | Presenta el catálogo y el modal |
| [`script.js`](practica%20-%20estrategias%20de%20cache/script.js) | Consulta productos, crea las tarjetas y muestra el detalle |
| [`app.js`](practica%20-%20estrategias%20de%20cache/app.js) | Solicita el registro del Service Worker |
| [`sw.js`](practica%20-%20estrategias%20de%20cache/sw.js) | Administra el ciclo de vida, las peticiones y las cachés |

## Cómo Ejecutar la Práctica

No se debe abrir `index.html` mediante `file://`. Los Service Workers necesitan HTTPS o un servidor local.

La carpeta `practica - estrategias de cache/` debe funcionar como raíz. `sw.js` usa rutas como `/index.html`, resueltas desde la raíz del servidor.

### Live Server

En VS Code, abre `index.html` dentro de esa carpeta y selecciona **Open with Live Server**. La dirección suele ser `http://127.0.0.1:5500/`.

### Python

Desde una terminal ubicada en la carpeta de la práctica, ejecuta `python -m http.server 8080` y abre `http://localhost:8080`.

### Node.js

Desde esa misma carpeta también se puede ejecutar `npx http-server -p 8080` y abrir la dirección indicada por el servidor.

![Catálogo cargado en línea](imagenes/catalogo-en-linea.webp)

La captura muestra el resultado en línea: `script.js` obtuvo 20 productos, generó las tarjetas y solicitó sus imágenes.

## Registro: `app.js`

```javascript
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js')
}
```

`app.js` se ejecuta en la página. Primero comprueba que el navegador exponga la API y después solicita registrar `sw.js`.

La ruta relativa coloca el alcance predeterminado en la misma carpeta. El registro puede solicitarse en cada carga, pero `install` solo vuelve a ocurrir si es la primera instalación o el navegador detecta una versión diferente de `sw.js`.

## Peticiones Generadas por `script.js`

`script.js` no administra las cachés directamente. Su función es realizar las peticiones que después intercepta el Service Worker.

| Acción | Petición generada |
|---|---|
| Cargar el catálogo | `GET https://fakestoreapi.com/products` |
| Ver un producto | `GET https://fakestoreapi.com/products/{id}` |
| Mostrar imágenes | Solicitudes a la URL de `producto.image` |

Las imágenes utilizan `loading=lazy`. El navegador solicita primero las visibles y carga las demás conforme se aproximan al área visible. Por ello, no todas quedan necesariamente guardadas en una sola visita.

## Contenedores Declarados en `sw.js`

```javascript
const CACHE_DYNAMIC = 'app-dynamic';
const CACHE_STATIC = 'app-static';
```

| Caché | Uso en el código |
|---|---|
| `app-static` | Precaching durante `install` y almacenamiento de faltantes atendidos por Cache First |
| `app-dynamic` | Respuestas exitosas obtenidas por Network First |

Los nombres no vuelven estática o dinámica una respuesta por sí solos. La función que abre cada contenedor determina dónde se guarda.

## Instalación y Precaching Estático

Durante `install`, el worker abre `app-static` y solicita guardar:

```text
/
/index.html
/styles.css
/script.js
/app.js
```

`event.waitUntil()` relaciona la promesa de `caches.open()` y `addAll()` con la instalación. La versión termina de instalarse cuando finaliza esa cadena.

Estos archivos forman la base local de la interfaz. `sw.js` no aparece en la lista porque el navegador administra su descarga y actualización como parte del registro.

![Contenido de la caché estática en DevTools](imagenes/cache-estatica-devtools.webp)

La captura muestra respuestas locales de tipo `basic`. En ese momento aparecen `/`, `app.js`, `script.js` y `styles.css`. El código actual también enumera `/index.html`; si no aparece, la captura corresponde a otro estado del registro o a una versión de caché ya instalada.

## Activación y Limpieza de Cachés Anteriores

El evento `activate` enumera las cachés y elimina las que no pertenecen a la práctica actual. La condición conserva los dos contenedores vigentes:

```javascript
if (cacheName !== CACHE_STATIC && cacheName !== CACHE_DYNAMIC) {
    return caches.delete(cacheName);
}
```

La expresión solo resulta verdadera para un nombre distinto de `app-static` y `app-dynamic`. Esas cachés ajenas u obsoletas se eliminan mediante `caches.delete()` y `Promise.all()` agrupa las operaciones antes de terminar la activación.

![Service Worker activo en DevTools](imagenes/service-worker-activo.webp)

En la captura, el indicador verde y el texto `activated and is running` muestran una versión activa. Los contenedores `app-static` y `app-dynamic` también aparecen en Cache Storage.

## Enrutamiento de las Peticiones

El evento `fetch` obtiene `event.request`, crea un objeto `URL` y compara `url.origin`.

```text
Petición interceptada
├── origen = https://fakestoreapi.com
│   └── Network First → app-dynamic
└── cualquier otro origen
    └── Cache First → app-static cuando falta el recurso
```

| Recurso | Estrategia esperada |
|---|---|
| HTML, CSS y JS locales | Cache First |
| `/products` y `/products/{id}` de Fake Store API | Network First |
| Imagen alojada en `fakestoreapi.com` | Network First |
| Recurso de cualquier otro dominio | Cache First |

Por ello, `app-static` no está limitado técnicamente a HTML, CSS y JS: cualquier petición cuyo origen no sea Fake Store API puede guardarse allí cuando Cache First no encuentra una coincidencia.

## Estrategia Cache First

`cacheFirst(request)` sigue este orden:

```text
1. Buscar la petición con caches.match()
2. Si existe → devolver la respuesta guardada
3. Si no existe → solicitarla con fetch()
4. Abrir app-static
5. Guardar una copia de la respuesta de red
6. Devolver la respuesta original a la página
```

La estrategia prioriza velocidad y disponibilidad para recursos que cambian poco. Los archivos precargados durante `install` normalmente se responden sin consultar la red.

### Por qué se utiliza `clone()`

Una respuesta contiene un cuerpo que se consume al leerlo. `respNetwork.clone()` crea otra referencia utilizable:

- La copia se entrega a `cacheStatic.put()`.
- La respuesta original se devuelve a la página.

El guardado se solicita con `cacheStatic.put(request, respNetwork.clone())`. El código devuelve `respNetwork` sin esperar explícitamente el resultado de `put()`.

Si el recurso no está en caché y la red no está disponible, la promesa de esta función se rechaza porque Cache First no contiene un bloque de recuperación adicional.

## Estrategia Network First

`networkFirst(request)` intenta obtener primero la versión más reciente:

```text
1. Solicitar el recurso mediante fetch()
2. Si responde la red → abrir app-dynamic
3. Guardar una copia y devolver la respuesta original
4. Si falla la red → buscar la petición en Cache Storage
5. Si existe → devolver la respuesta guardada
6. Si tampoco existe → devolver un Response con JSON de error
```

Se aplica a todas las URL cuyo origen es `https://fakestoreapi.com`. Esto incluye las consultas de productos y las imágenes alojadas en ese mismo origen.

![Contenido de la caché dinámica en DevTools](imagenes/cache-dinamica-devtools.webp)

La captura muestra rutas `/img/...`, `/products` y `/products/1`. Solo aparecen después de una solicitud de red exitosa; la caché dinámica no las descarga por adelantado.

### Cuando no Existe Red ni Caché

La función devuelve un objeto `Response` cuyo JSON contiene `error: No hay red ni cache`.

Como no especifica otro código de estado, utiliza `200`. `script.js` puede intentar procesar ese objeto como producto o lista; su bloque `catch` termina mostrando que no fue posible cargar la información.

### Qué Significa que `fetch()` Termine Correctamente

Las funciones del Service Worker no comprueban `respNetwork.ok` ni `respNetwor.ok` antes de guardar. Para `fetch()`, recibir una respuesta HTTP como 404 o 500 resuelve normalmente la promesa; los rechazos corresponden principalmente a fallas de red o restricciones de la solicitud.

Por ello, una respuesta HTTP no exitosa también puede llegar a `put()`. Después, `script.js` sí revisa `respuesta.ok` y genera su propio error cuando el estado no está entre 200 y 299.

## Qué Demuestran las Pruebas Offline

### Recurso que Todavía no Estaba Guardado

![Detalle no disponible antes de guardarse](imagenes/detalle-no-disponible-offline.webp)

DevTools está en modo **Offline** y la solicitud del producto falla. El modal muestra el mensaje de `script.js`: «No se pudo cargar el producto».

Esto ocurre cuando Network First no obtiene la red y tampoco encuentra una respuesta previa compatible en caché. Estar registrado como PWA o tener algunas entradas guardadas no convierte automáticamente todos los recursos en disponibles offline.

### Recurso Guardado Previamente

![Respuesta recuperada desde caché sin conexión](imagenes/respuesta-desde-cache-offline.webp)

Después de haber consultado el detalle en línea, la ruta correspondiente puede aparecer en `app-dynamic`. Al repetirla sin conexión, Network First falla en la red, entra al `catch` y busca la respuesta almacenada.

En Network se observa una respuesta atendida por `(ServiceWorker)`, mientras otras imágenes fallan. Las imágenes faltantes no habían sido solicitadas o guardadas previamente; `loading=lazy` hace visible esta diferencia.

## Etapas y Frecuencia

| Etapa o evento | Cuándo ocurre | Participación en la práctica |
|---|---|---|
| Registro | Cada carga de `app.js` solicita `register()` | Comprueba o actualiza el registro |
| `install` | Una vez por cada versión nueva de `sw.js` | Prepara `app-static` |
| `waiting` | Cuando una versión nueva espera a la anterior | Es un estado administrado por el navegador |
| `activate` | Una vez cuando una versión puede activarse | Ejecuta la limpieza de cachés |
| `fetch` | Por cada petición de una página controlada | Selecciona Cache First o Network First |

Recargar sin cambiar `sw.js` no repite automáticamente `install` ni `activate`. `fetch` sí puede ocurrir muchas veces durante una sola carga: documento, CSS, scripts, consulta de productos e imágenes generan peticiones distintas.

## Flujo Completo

```text
index.html
├── script.js → pide productos y genera la interfaz
└── app.js → registra sw.js
              ├── install → precarga app-static
              ├── activate → intenta limpiar cachés
              └── fetch
                  ├── Fake Store API → networkFirst() → app-dynamic
                  └── otros orígenes → cacheFirst() → app-static
```

El Service Worker no llama directamente a `cargarProductos()` ni a `verProducto()`. `script.js` hace las solicitudes y el navegador permite que `sw.js` las intercepte cuando la página ya está controlada.

## Qué se Guarda Realmente

Cache API almacena pares formados por una petición y su respuesta:

```text
Request:  GET https://fakestoreapi.com/products/1
Response: JSON con los datos del producto
```

Para una imagen, la petición contiene su URL y la respuesta contiene los bytes recibidos. Guardar una entrada no significa guardar toda la API ni todas las variantes posibles de la URL.

`caches.match(request)` busca una entrada compatible entre los contenedores del origen. Por eso el respaldo de Network First puede localizar una respuesta de `app-dynamic` sin abrir primero esa caché por su nombre.

## Cómo Comprobarlo en DevTools

1. Ejecuta la práctica mediante Live Server, Python o Node.js.
2. Abre **Application → Service Workers** y revisa que el estado sea `activated and is running`.
3. En **Application → Cache Storage**, abre `app-static` y `app-dynamic`.
4. Con conexión, abre varios productos y desplázate por el catálogo para solicitar imágenes.
5. Actualiza la vista de Cache Storage y observa qué URL se agregó a cada contenedor.
6. En **Network**, selecciona **Offline**.
7. Repite primero una petición ya consultada y después otra que no se haya solicitado.

Si se usa **Clear site data**, se eliminan el registro y las cachés del origen. La siguiente visita empieza de nuevo y permite observar el ciclo desde `install`.

## Resultado Conceptual

| Situación | Resultado esperado por la estrategia |
|---|---|
| Recurso local precargado | Cache First lo devuelve desde `app-static` |
| Petición de API con red | Network First devuelve la red y guarda una copia |
| Petición de API sin red, previamente guardada | Network First recupera la respuesta de caché |
| Petición de API sin red, nunca guardada | Se genera la respuesta JSON de respaldo |
| Imagen de Fake Store ya solicitada | Puede recuperarse desde `app-dynamic` |
| Imagen todavía no solicitada | No existe una copia local que entregar |

Este resultado depende de que el Service Worker termine su activación y controle la página. Después de modificar `sw.js`, puede existir una versión nueva en espera hasta que se cierren o abandonen las páginas controladas por la versión anterior.
