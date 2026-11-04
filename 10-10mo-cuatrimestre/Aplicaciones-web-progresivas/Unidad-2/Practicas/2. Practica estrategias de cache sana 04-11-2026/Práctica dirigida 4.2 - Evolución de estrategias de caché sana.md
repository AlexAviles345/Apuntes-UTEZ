# Práctica Dirigida 4.2: Evolución de Estrategias de Caché Sana (Versionamiento, Tamaño e Inyección de TTL)

**Asignatura:** Desarrollo de Aplicaciones Web Progresivas (PWA)

**Modalidad:** Trabajo Autónomo / Práctica Individual

**Restricción Técnica Obligatoria:** Uso exclusivo de **JavaScript Vanilla** y encadenamiento de Promesas con `.then()` y `.catch()`. Queda **estrictamente prohibido el uso de `async/await`** dentro del Service Worker (`sw.js`).

## 1. Contexto y Reescritura del Problema

En aplicaciones reales, **no podemos confiar en que los servidores externos o APIs devuelvan la cabecera `Date`** (muchas APIs la omiten, la bloquean por políticas CORS o la eliminan mediante proxies).

Para evitar que los datos locales queden obsoletos sin control, resolveremos este problema desde el Service Worker aplicando **Inyección de Estampa de Tiempo (*Timestamp Injection*)**: cada vez que el Service Worker reciba una respuesta de la red, creará una copia sintética inyectando nuestra propia cabecera personalizada (`x-sw-timestamp`) con la hora exacta de recepción antes de guardarla en la Cache API.

## . Mapa de Archivos del Proyecto

Trabajarás sobre la siguiente estructura en tu carpeta de proyecto:

```
pwa-practica-4.2/
├── index.html
├── styles.css
├── app.js
└── sw.js
```

## 3. Ensamblado Modular del Service Worker (`sw.js`)

Analiza la responsabilidad de cada fragmento, su encadenamiento de promesas e intégralo en la ubicación correcta dentro de `sw.js`.

### PILAR 1: Versionamiento y Purga Automática en la Activación

#### Fragmento A: Identificadores de Versión

Coloca este bloque al inicio de `sw.js`:

```jsx
// Definición de contenedores versionados y límites
const CACHE_STATIC_NAME = 'static-v2';
const CACHE_DYNAMIC_NAME = 'dynamic-v2';
const DYNAMIC_LIMIT = 5; // Límite máximo de elementos en caché dinámica
const TTL_MAX_SECONDS = 30; // Tiempo de vida máximo de 30 segundos para pruebas
```

#### Fragmento B: Limpieza de Contenedores Obsoletos

Manejador para el evento `activate` que purga contenedores que no pertenezcan a la `listaBlanca`:

```jsx
self.addEventListener('activate', (event) => {
  const listaBlanca = [CACHE_STATIC_NAME, CACHE_DYNAMIC_NAME];

  event.waitUntil(
    caches.keys()
      .then((nombresCaches) => {
        return Promise.all(
          nombresCaches.map((nombreCache) => {
            if (!listaBlanca.includes(nombreCache)) {
              console.log('[SW] Purgando contenedor obsoleto:', nombreCache);
              return caches.delete(nombreCache);
            }
          })
        );
      })
      .then(() => self.clients.claim())
  );
});
```

### PILAR 2: Control de Tamaño Máximo (Algoritmo FIFO)

#### Fragmento C: Función Recurrente FIFO

Permite eliminar el elemento más antiguo (`keys[0]`) cuando se supera la cuota máxima permitida:

```jsx
function limpiarCacheLimitado(nombreCache, maxElementos){
  return caches.open(nombreCache)
    .then((cache) => {
      return cache.keys()
        .then((keys) => {
          if (keys.length > maxElementos) {
            return cache.delete(keys[0])
              .then(() => limpiarCacheLimitado(nombreCache, maxElementos));
          }
        });
    });
}
```

### PILAR 3: Inyección Manual de Timestamp y Validación TTL

Dado que las respuestas HTTP originales devueltas por `fetch()` son **inmutables** (sus cabeceras no se pueden modificar directamente), debemos clonar el cuerpo del recurso y generar un nuevo objeto `Response` inyectando la cabecera `x-sw-timestamp`.

#### Fragmento D1: Inyector de Cabecera Personalizada

Analiza cómo extraemos el cuerpo de la respuesta mediante `.blob()` y construimos una nueva `Response` con la estampa de tiempo en milisegundos:

```jsx
function crearRespuestaConTimestamp(respuestaOriginal){
  // 1. Copiar las cabeceras originales de la respuesta
  const nuevasCabeceras = new Headers(respuestaOriginal.headers);

  // 2. Inyectar nuestra cabecera personalizada con la fecha/hora actual
  nuevasCabeceras.append('x-sw-timestamp', Date.now().toString());

  // 3. Leer el cuerpo de la respuesta como Blob y reconstruir el objeto Response
  return respuestaOriginal.blob()
    .then((cuerpoBlob) => {
      return new Response(cuerpoBlob, {
        status: respuestaOriginal.status,
        statusText: respuestaOriginal.statusText,
        headers: nuevasCabeceras
      });
    });
}
```

#### Fragmento D2: Evaluador de Frescura Temporal (TTL)

Examina cómo leemos la cabecera personalizada `x-sw-timestamp` al recuperar el archivo desde la Cache API:

```jsx
function esRespuestaFresca(respuesta, maxSegundos){
  if (!respuesta) return false;

  // Extraer nuestra cabecera personalizada
  const timestampGuardado = respuesta.headers.get('x-sw-timestamp');
  if (!timestampGuardado) return false; // Si no tiene el timestamp inyectado, se considera obsoleta

  const fechaGuardada = parseInt(timestampGuardado, 10);
  const fechaActual = Date.now();
  const diferenciaSegundos = (fechaActual - fechaGuardada) / 1000;

  console.log(`[SW] Edad del recurso inyectado: ${diferenciaSegundos.toFixed(1)}s (Máximo permitido: ${maxSegundos}s)`);

  return diferenciaSegundos < maxSegundos;
}
```

## 4. Evolución de las Estrategias de Caching

Integra los fragmentos anteriores dentro de las funciones de almacenamiento principales.

### Paso 4.1: `cacheFirstEvolucionado` (Con Inyección y Validación de TTL)

El nuevo flujo debe:

1. Buscar el recurso en la caché local.
2. Si existe **Y** la función `esRespuestaFresca()` confirma que no ha superado el tiempo límite, entrega el recurso guardado.
3. Si expiró o no existe, descarga el recurso de la red, lo procesa con `crearRespuestaConTimestamp()`, guarda la copia estampada en la caché y la entrega al usuario.

#### Fragmento E: Estructura de `cacheFirstEvolucionado`

```jsx
function cacheFirstEvolucionado(request){
  return caches.match(request)
    .then((respuestaCache) => {
      // 1. Evaluar si existe en caché y si aún está fresca según el TTL inyectado
      if (respuestaCache && esRespuestaFresca(respuestaCache, TTL_MAX_SECONDS)) {
        return respuestaCache;
      }

      console.log('[SW] Recurso no disponible o expirado. Solicitando a la red:', request.url);

      // 2. Si falló la caché o expiró, salir a la red
      return fetch(request)
        .then((respuestaRed) => {
          // Inyectar timestamp antes de almacenar en la Cache API
          return crearRespuestaConTimestamp(respuestaRed)
            .then((respuestaConTimestamp) => {
              return caches.open(CACHE_STATIC_NAME)
                .then((cache) => {
                  cache.put(request, respuestaConTimestamp.clone());
                  return respuestaConTimestamp;
                });
            });
        });
    });
}
```

### Paso 4.2: `networkFirstEvolucionado` (Con Inyección, Tamaño Limitado y Contingencia TTL)

El nuevo flujo debe:

1. Consultar a la red primero.
2. Si la red responde (HTTP 200), inyecta la estampa de tiempo con `crearRespuestaConTimestamp()`, guarda la copia resultante en `CACHE_DYNAMIC_NAME` e invoca la limpieza por tamaño (`limpiarCacheLimitado`).
3. Si la red falla (`.catch()`), consulta la caché. Entrega los datos guardados **únicamente si no han superado el TTL**. Si la caché expiró o está vacía, devuelve el mensaje de contingencia JSON sintético.

#### Fragmento F: Estructura de `networkFirstEvolucionado`

```jsx
function networkFirstEvolucionado(request){
  return fetch(request)
    .then((respuestaRed) => {
      if (respuestaRed.status === 200) {
        // Transformar la respuesta inyectando el timestamp
        return crearRespuestaConTimestamp(respuestaRed)
          .then((respuestaConTimestamp) => {
            return caches.open(CACHE_DYNAMIC_NAME)
              .then((cache) => {
                cache.put(request, respuestaConTimestamp.clone());
                // Aplicar restricción de tamaño en la caché dinámica
                limpiarCacheLimitado(CACHE_DYNAMIC_NAME, DYNAMIC_LIMIT);
                return respuestaConTimestamp;
              });
          });
      }
      return respuestaRed;
    })
    .catch(() => {
      console.warn('[SW] Falla de red. Verificando respaldo en caché con TTL inyectado...');

      return caches.match(request)
        .then((respuestaCache) => {
          // Validar existencia Y frescura del timestamp inyectado
          if (respuestaCache && esRespuestaFresca(respuestaCache, TTL_MAX_SECONDS)) {
            return respuestaCache;
          }

          // Fallback si no hay red y los datos cacheados expiraron
          return new Response(
            JSON.stringify({
              error: true,
              mensaje: "La conexión falló y los datos locales han expirado o no existen."
            }),
            { headers: { 'Content-Type': 'application/json' } }
          );
        });
    });
}
```

### Paso 4.3: Conexión con el Enrutador `fetch`

#### Fragmento G: Registro de Rutas

Vincular el evento `fetch` con las funciones evolucionadas:

```jsx
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Rutas estáticas locales
  if (url.origin === location.origin && !url.pathname.includes('/api/')) {
    event.respondWith(cacheFirstEvolucionado(event.request));
    return;
  }

  // Rutas a APIs dinámicas
  if (url.hostname.includes('jsonplaceholder.typicode.com')) {
    event.respondWith(networkFirstEvolucionado(event.request));
    return;
  }
});
```

## 5. Guía de Pruebas de Control en DevTools

1. **Inspección de la Cabecera Inyectada:**
    - Haz una petición a la API desde la interfaz con la red activa.
    - Ve a DevTools → **Application** → **Cache Storage** →`dynamic-v2`.
    - Selecciona el recurso guardado y revisa sus cabeceras devueltas en el panel derecho. Confirma que la cabecera `x-sw-timestamp` fue insertada con un valor numérico en milisegundos.
2. **Prueba de Expiración TTL:**
    - Configura `TTL_MAX_SECONDS = 15`.
    - Haz una petición para poblar la caché.
    - Activa el modo **Offline** en DevTools.
    - Si presionas el botón antes de 15 segundos, los datos se servirán desde la caché.
    - Si esperas 20 segundos y presionas el botón, la consola mostrará que la edad del recurso superó el límite, la función `esRespuestaFresca` devolverá `false` y la PWA desplegará el mensaje JSON de contingencia.
