# Tema 4.1 - Anatomía de las Estrategias de Caching

## Guía de la fuente

> El texto analiza la anatomía de las estrategias de caching en Progressive Web Apps (PWAs), explicando cómo los desarrolladores deben clasificar los recursos digitales según su nivel de importancia y frecuencia de cambio para optimizar el rendimiento. Se detallan cuatro métodos fundamentales gestionados por un Service Worker, los cuales incluyen enfoques donde se prioriza la velocidad del almacenamiento local, la frescura de los datos en la red o combinaciones híbridas en segundo plano. Asimismo, se proporcionan ejemplos prácticos de código y una matriz de decisión orientada a evitar fallos críticos en la experiencia del usuario y garantizar un funcionamiento adecuado tanto online como offline.

---

**Objetivo de Aprendizaje:** Clasificar los activos de una PWA según su frecuencia de cambio y nivel de criticidad, comprender la mecánica de ejecución de las 4 estrategias de caché fundamentales (Cache First, Network First, Stale-While-Revalidate, Network/Cache Only) y seleccionar la estrategia adecuada evaluando el impacto en la experiencia de usuario y la coherencia de los datos.

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. Clasificación de Activos en una PWA

Antes de programar cualquier línea de código en un Service Worker, la primera tarea de ingeniería consiste en auditar y categorizar todos los recursos que consume la aplicación. Intentar aplicar una única regla de almacenamiento a todo el tráfico destruirá la experiencia de usuario o mostrará datos obsoletos.

```text
[ RECURSOS DE LA PWA ]
   │
   ├── 1. Estáticos Inmutables (App Shell: CSS, JS base, Fuentes, Logos)
   │      └── Estrategia: Cache First
   │
   ├── 2. Datos Dinámicos y Críticos (Saldos, Perfil, Inventario, Notificaciones)
   │      └── Estrategia: Network First
   │
   ├── 3. Contenido de Actualización Frecuente (Feeds, Artículos, Catálogos)
   │      └── Estrategia: Stale-While-Revalidate
   │
   └── 4. Transacciones Sensibles o Operaciones Offline Puras
          └── Estrategia: Network Only / Cache Only
```

#### Diferencia Clave: Cache HTTP vs. Cache API:

- **Cache HTTP (Navegador):** Mantenida automáticamente por el navegador según las cabeceras HTTP (Cache-Control, ETag) devueltas por el servidor. El desarrollador no tiene control fino por código en JS.
- **Cache API (Service Worker):** Almacén de objetos totalmente programable desde JavaScript mediante promesas. Permite interceptar la petición en el evento fetch, evaluar si existe conexión y decidir exactamente qué responder.

### B. Las 4 Estrategias Fundamentales de Caching

#### 1. Cache First (Cache con Fallback a Red)

- **Flujo de Ejecución:** El Service Worker intercepta la petición. Busca el recurso en la Cache API. Si lo encuentra, lo devuelve inmediatamente sin tocar la red. Si no existe en caché, realiza el fetch() a la red, entrega la respuesta al usuario y opcionalmente guarda una copia en la caché dinámica.
- **Casos de Uso Ideales:** El App Shell de la PWA (archivos .css, .js, fuentes web, íconos del sistema).
- **Ventaja:** Velocidad instantánea (0 ms de latencia de red) y funcionamiento offline total.
- **Riesgo:** Si el servidor actualiza el archivo en producción pero la versión de la caché no se invalida o renombra, el usuario verá la versión antigua de forma indefinida.

```text
Petición ---> [ Service Worker ] ---> ¿Existe en Cache API?
                     │
            ┌────────┴────────┐
            │ SÍ              │ NO
            v                 v
     [ Devuelve Caché ]   [ Fetch a Red ] ---> [ Devuelve y Guarda ]
```

#### 2. Network First (Red con Fallback a Caché)

- **Flujo de Ejecución:** El Service Worker intercepta la petición e intenta primero obtener el recurso fresco desde la red mediante fetch(). Si la llamada a la red es exitosa (retorna HTTP 200), actualiza la copia guardada en la Cache API y entrega la respuesta fresca. Si la red falla (por estar sin conexión o por un tiempo de espera excedido), cae en el bloque .catch() y entrega la copia guardada previamente en la caché.
- **Casos de Uso Ideales:** Datos dinámicos de API, perfiles de usuario, saldos bancarios, estado de inventario o publicaciones de blog recientes.
- **Ventaja:** Garantiza la máxima frescura de los datos mientras haya conexión.
- **Riesgo:** La velocidad de carga depende 100% de la latencia de la red cuando hay conectividad. Si la red está muy lenta (Lie-Fi), la experiencia de usuario puede verse degradada antes de cambiar al respaldo de la caché.

```text
Petición ---> [ Service Worker ] ---> [ Intenta Fetch a Red ]
                                             │
                                    ┌────────┴────────┐
                                    │ Éxito           │ Falla (Offline)
                                    v                 v
                            [ Devuelve y Guarda ]  [ Busca en Cache API ]
```

#### 3. Stale-While-Revalidate (Obsoleto mientras se Revalida)

- **Flujo de Ejecución:** Es el patrón híbrido de mejor rendimiento percibido. El Service Worker consulta la Cache API y, si el recurso existe, se lo entrega inmediatamente a la interfaz de usuario. Al mismo tiempo, en segundo plano, dispara un fetch() a la red para descargar la versión más reciente del recurso y actualizar silenciosamente la Cache API. La nueva versión estará disponible la próxima vez que el usuario navegue a esa pantalla.
- **Casos de Uso Ideales:** Catálogos de productos, feeds de noticias, avatares de usuario, listas de precios no críticas.
- **Ventaja:** Combina la velocidad instantánea de Cache First con la actualización constante en segundo plano de Network First.
- **Riesgo:** Consume doble ancho de banda (sirve desde memoria y de todos modos consulta la red en cada petición) y el usuario siempre ve los datos con una versión de retraso hasta que refresca la pantalla.

```text
Petición ---> [ Service Worker ] ───┬───> [ Devuelve Caché al instante ] (Respuesta rápida)
                                   │
                                   └───> [ Fetch a Red en Segundo Plano ] ───> [ Actualiza Caché ]
```

#### 4. Network Only y Cache Only

- **Network Only:** Se omite por completo la Cache API. Si no hay conexión a internet, la petición falla directamente. Usado en pasarelas de pago, autenticación OAuth o peticiones de tipo POST, PUT o DELETE.
- **Cache Only:** La petición únicamente busca en la Cache API. Si no existe, falla sin intentar salir a la red. Útil cuando se quiere forzar el aislamiento total de un recurso previamente precacheado durante la fase de instalación.

## 2. Implementación de Código de Referencia (Vanilla JS)

**Proyecta y analiza los siguientes bloques dentro del manejador del evento fetch en el archivo sw.js:**

### Estructura del Enrutador en sw.js

```javascript
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // 1. Patrón CACHE FIRST: Para archivos estáticos del App Shell
  if (url.origin === location.origin && (url.pathname.endsWith('.css') || url.pathname.endsWith('.js'))) {
    event.respondWith(cacheFirst(event.request));
    return;
  }

  // 2. Patrón NETWORK FIRST: Para llamadas a la API de datos
  if (url.pathname.startsWith('/api/v1/')) {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // 3. Patrón STALE-WHILE-REVALIDATE: Para imágenes o catálogos
  if (event.request.destination === 'image') {
    event.respondWith(staleWhileRevalidate(event.request));
    return;
  }
});

// --- FUNCIONES DE ESTRATEGIA ---

// Función Cache First
async function cacheFirst(request){
  const respuestaCache = await caches.match(request);
  if (respuestaCache) {
    return respuestaCache;
  }
  const respuestaRed = await fetch(request);
  const cache = await caches.open('dinamico-estaticos-v1');
  cache.put(request, respuestaRed.clone());
  return respuestaRed;
}

// Función Network First
async function networkFirst(request){
  const cache = await caches.open('dinamico-api-v1');
  try {
    const respuestaRed = await fetch(request);
    // Guardar copia fresca en caché
    cache.put(request, respuestaRed.clone());
    return respuestaRed;
  } catch (error) {
    console.warn('[SW] Red no disponible, recuperando de caché:', request.url);
    const respuestaCache = await cache.match(request);
    if (respuestaCache) {
      return respuestaCache;
    }
    // Si tampoco está en caché, lanzar excepción o devolver respuesta de fallback
    return new Response(JSON.stringify({ error: 'Sin conexión a red ni datos en caché' }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Función Stale-While-Revalidate
async function staleWhileRevalidate(request){
  const cache = await caches.open('dinamico-imagenes-v1');
  const respuestaCache = await cache.match(request);

  // Promesa en segundo plano para actualizar la caché con la versión de red
  const promesaRed = fetch(request).then((respuestaRed) => {
    cache.put(request, respuestaRed.clone());
    return respuestaRed;
  }).catch(() => console.log('[SW] No se pudo revalidar en segundo plano'));

  // Retornar la caché si existe, si no esperar a la red
  return respuestaCache || promesaRed;
}
```

## 3. Preguntas de Razonamiento Socrático (Anti-IA)

> **Pregunta:** "Un equipo de desarrollo construyó una PWA para un hospital y aplicó la estrategia Stale-While-Revalidate a la ruta /api/v1/paciente/habitacion. ¿Qué problema operativo grave puede ocurrir cuando el médico consulta la app durante su ronda?"

**Respuesta Esperada:** El médico verá la habitación o asignación anterior del paciente guardada en la caché de la visita previa (versión desactualizada). Dado que Stale-While-Revalidate entrega el dato viejo e invalida en segundo plano, el médico tomará decisiones clínicas con un dato desfasado. La ruta exigía la estrategia Network First.

> **Pregunta:** "Si la estrategia Cache First devuelve los archivos sin consultar la red, ¿cómo logramos que un usuario reciba una nueva versión corregida de styles.css cuando hacemos un despliegue a producción?"

**Respuesta Esperada:** Cambiando el nombre de la versión del contenedor de la caché en el evento install del Service Worker (ejemplo: de static-v1 a static-v2) o utilizando técnicas de cache busting / hash en los nombres de los archivos (styles.a8f9d.css). Esto fuerza al evento activate a purgar la caché obsoleta.

## 4. Hoja de Referencia (Cheat Sheet) / Matriz de Decisión

| Tipo de Recurso | Estrategia Recomendada | ¿Funciona Offline? | Riesgo Principal / Trade-off |
| --- | --- | --- | --- |
| App Shell (HTML base, CSS, JS core, Fuentes) | Cache First | Sí | Si no se invalida la versión de la caché en sw.js, el usuario no verá los cambios de código. |
| APIs de Datos Frecuentes (Perfil, Saldo, Carrito) | Network First | Sí (Si existe historial previo) | Si la red está muy lenta (Lie-Fi), la respuesta tardará en caer al fallback de caché. |
| Feeds, Noticiero, Imágenes de Producto, Avatares | Stale-While-Revalidate | Sí | Consume doble ancho de banda y muestra contenido con una versión de retraso. |
| Pasarela de Pago, Autenticación, Acciones POST | Network Only | No | Falla intencionalmente sin red para evitar transacciones duplicadas o desincronizadas. |
| Pantallas de Fallback (offline.html, fallback.svg) | Cache Only | Sí | Requiere que el recurso haya sido obligatoriamente precacheado durante la fase install. |
