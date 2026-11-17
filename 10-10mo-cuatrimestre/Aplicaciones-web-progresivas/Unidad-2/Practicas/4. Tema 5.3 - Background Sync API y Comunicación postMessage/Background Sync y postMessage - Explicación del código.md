# Background Sync y `postMessage` — Explicación del Código

Esta guía explica la evolución del patrón Outbox para que los registros pendientes puedan sincronizarse desde el Service Worker, incluso cuando la página ya no está abierta.

La práctica combina:

- IndexedDB como almacenamiento persistente.
- `app.js` como controlador de la interfaz.
- `sw.js` como motor de sincronización en segundo plano.
- Background Sync como mecanismo de reintento.
- `postMessage` como puente entre el worker y el DOM.
- Un fallback mediante el evento `online` para navegadores sin `SyncManager`.

Para estudiar las preguntas de la actividad, consulta [Background Sync y postMessage — Respuestas para la defensa oral](Background%20Sync%20y%20postMessage%20-%20Respuestas%20para%20la%20defensa%20oral.md).

## Archivos de la Práctica

| Archivo | Responsabilidad |
|---|---|
| [`index.html`](pwa-outbox-practica/index.html) | Contiene el formulario, el indicador de conectividad y la bandeja |
| [`styles.css`](pwa-outbox-practica/styles.css) | Presenta la interfaz y sus estados visuales |
| [`db-helper.js`](pwa-outbox-practica/db-helper.js) | Expone operaciones promisificadas de IndexedDB para la página y el worker |
| [`app.js`](pwa-outbox-practica/app.js) | Administra la interfaz, guarda el Outbox y registra Background Sync |
| [`sw.js`](pwa-outbox-practica/sw.js) | Ejecuta el reenvío en segundo plano y comunica el resultado a las páginas |
| [`manifest.json`](pwa-outbox-practica/manifest.json) | Define inicio, alcance, presentación e iconos de la PWA |

## Objetivo de la Evolución

En la práctica anterior, la sincronización dependía de este evento de la página:

```javascript
window.addEventListener('online', () => {
  sincronizarPendientes();
});
```

Ese mecanismo funciona mientras `app.js` continúa ejecutándose. Si el usuario cierra la pestaña, ya no existe `window`, no se dispara el manejador de la aplicación y los registros permanecen pendientes hasta la siguiente visita.

La versión actual registra una tarea con la etiqueta `sync-reportes`. El navegador conserva esa tarea y puede despertar al Service Worker cuando detecta una conexión adecuada.

```text
POST falla
   ↓
guardar en IndexedDB
   ↓
registrar sync-reportes
   ↓
usuario puede cerrar la pestaña
   ↓
regresa la conexión
   ↓
el navegador activa sw.js
   ↓
evento sync
   ↓
sincronizarPendientesSW()
```

---

## Comparativa con la Práctica 5.2

| Aspecto | Tema 5.2 | Tema 5.3 |
|---|---|---|
| Motor de reenvío principal | `app.js` | `sw.js` |
| Disparador | Evento `online` | Evento `sync` con etiqueta `sync-reportes` |
| Funciona con la pestaña cerrada | No | Puede funcionar mediante Background Sync |
| Función de sincronización en UI | `sincronizarPendientes()` | `sincronizarPendientesFallback()` |
| Uso del evento `online` | Siempre intenta sincronizar | Solo sincroniza si no existe `SyncManager` |
| Acceso a IndexedDB | Principalmente la página | Página y Service Worker |
| Actualización de la interfaz | La misma función llama a `renderizarColaOutbox()` | El worker avisa mediante `postMessage` |
| Prevención de duplicados | No era necesaria | Evita que UI y worker envíen al mismo tiempo |
| Caché estática | `pwa-outbox-shell-v1` | `static-outbox-v2` |
| Comunicación entre contextos | No era necesaria | `cliente.postMessage()` y evento `message` |
| Compatibilidad sin Background Sync | Evento `online` | Degradación elegante con el fallback heredado |

Los archivos `index.html`, `db-helper.js`, `styles.css`, `manifest.json` e iconos permanecen iguales. La evolución se concentra en `app.js` y `sw.js`.

---

## `db-helper.js`: Base Compartida

El helper conserva las mismas operaciones CRUD de la práctica anterior:

| Función | Operación |
|---|---|
| `abrirDB()` | Abre o crea la base de datos |
| `guardarRegistro(datos)` | CREATE |
| `obtenerTodosLosRegistros()` | READ |
| `actualizarEstadoRegistro(id, estado)` | UPDATE |
| `eliminarRegistro(id)` | DELETE |

La diferencia arquitectónica es que ahora estas funciones se consumen desde dos contextos distintos:

```text
index.html
└── <script src="./db-helper.js">
      └── app.js puede usar sus funciones

sw.js
└── importScripts('./db-helper.js')
      └── el Service Worker puede usar las mismas funciones
```

## Por qué se puede compartir IndexedDB

La página y el Service Worker pertenecen al mismo origen. Ambos pueden abrir:

```javascript
const DB_NAME = 'pwa-outbox-db';
const STORE_NAME = 'transacciones_pendientes';
```

No son dos bases diferentes. Son dos contextos que acceden a la misma base y al mismo Object Store.

## Datos utilizados por la sincronización

Un registro pendiente contiene propiedades como:

```javascript
{
  id: 1,
  titulo: 'Falla en válvula 4',
  descripcion: 'No responde al control remoto',
  estado: 'pendiente',
  fechaCreacion: 1794870000000
}
```

Después de sincronizarlo, `actualizarEstadoRegistro()` agrega o modifica:

```javascript
registro.estado = 'sincronizado';
registro.fechaSincronizacion = Date.now();
```

## Promisificación

IndexedDB utiliza eventos, pero el helper devuelve promesas. Esto permite escribir en ambos contextos:

```javascript
obtenerTodosLosRegistros()
  .then((registros) => {
    // procesar registros
  })
  .catch((error) => {
    // atender el rechazo
  });
```

La práctica no utiliza `async/await` ni librerías externas.

---

## `app.js`: Interfaz y Registro de Background Sync

La página continúa siendo responsable del formulario, el indicador de red, la lista y la purga. Las nuevas responsabilidades son:

1. Escuchar mensajes enviados por el Service Worker.
2. Registrar `sync-reportes` después de guardar un reporte pendiente.
3. Mantener el reenvío anterior como fallback.
4. Evitar que el fallback compita con Background Sync.

### Recepción de `postMessage`

Al inicio del archivo se registra:

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data && event.data.tipo === 'OUTBOX_SINCRONIZADO') {
      renderizarColaOutbox();
    }
  });
}
```

El evento `message` recibe objetos enviados por un Service Worker. La validación comprueba dos cosas:

- Que `event.data` exista.
- Que el tipo sea exactamente `OUTBOX_SINCRONIZADO`.

La interfaz no confía en datos de registros enviados dentro del mensaje. Simplemente vuelve a leer IndexedDB, que es la fuente de verdad.

```text
mensaje recibido
    ↓
renderizarColaOutbox()
    ↓
obtenerTodosLosRegistros()
    ↓
repintar la lista
```

### Envío normal con red

`procesarEnvioReporte()` conserva el flujo del Tema 5.2:

```text
fetch POST exitoso
    ↓
guardarRegistro(... estado sincronizado)
    ↓
renderizarColaOutbox()
```

No se registra Background Sync cuando el `POST` terminó correctamente.

### Guardado pendiente y registro de `sync-reportes`

Cuando el envío falla, primero se protege la información:

```javascript
return guardarRegistro({
  ...datosFormulario,
  estado: 'pendiente',
  fechaCreacion: Date.now()
});
```

Solo después de completar el guardado se detecta el soporte:

```javascript
if ('serviceWorker' in navigator && 'SyncManager' in window) {
  // registrar tarea
}
```

El orden es importante:

```text
1. IndexedDB confirma el guardado
2. navigator.serviceWorker.ready espera un worker activo
3. registration.sync.register('sync-reportes') registra la tarea
```

Si la etiqueta se registrara antes de guardar el objeto, el navegador podría despertar al worker cuando la bandeja todavía estuviera vacía.

### `navigator.serviceWorker.ready`

```javascript
return navigator.serviceWorker.ready
  .then((registro) => {
    return registro.sync.register('sync-reportes');
  });
```

`ready` es una promesa que entrega un `ServiceWorkerRegistration` cuando existe un worker activo para la página. La propiedad `sync` pertenece a ese registro.

La etiqueta identifica el trabajo. El worker revisará el mismo texto dentro del evento `sync`.

### `sincronizarPendientesFallback()`

La función de sincronización del Tema 5.2 se conserva con un nombre que indica su nueva función:

```javascript
function sincronizarPendientesFallback() {
  // lectura, reenvío y actualización desde la página
}
```

Sigue realizando:

```text
getAll()
  → filtrar pendientes
  → map(fetch + actualizarEstadoRegistro)
  → Promise.all()
  → renderizar
```

No es el mecanismo principal en navegadores con Background Sync. Existe para mantener funcional la PWA cuando `SyncManager` no está disponible.

### Evento `online` sin condición de carrera

```javascript
window.addEventListener('online', () => {
  actualizarIndicadorRed();

  if (!('SyncManager' in window)) {
    sincronizarPendientesFallback();
  }
});
```

La condición separa los responsables:

| Navegador | Responsable del reenvío |
|---|---|
| Con `SyncManager` | Evento `sync` de `sw.js` |
| Sin `SyncManager` | Evento `online` de `app.js` |

Sin esta condición, la página y el Service Worker podrían leer los mismos pendientes y enviar dos `POST` para un solo reporte.

### Funciones que permanecen en la interfaz

Las siguientes piezas no cambian de responsabilidad:

- `renderizarColaOutbox()` lee IndexedDB y actualiza el DOM.
- `actualizarIndicadorRed()` muestra si el navegador reporta conexión.
- El evento `submit` obtiene los campos y llama a `procesarEnvioReporte()`.
- El botón de purga elimina únicamente los sincronizados.
- El inicio de la página recupera los registros guardados.
- `navigator.serviceWorker.register('./sw.js')` registra el worker con ruta relativa.

---

## `sw.js`: Motor de Sincronización

El Service Worker no tiene acceso a `window`, `document` ni a los elementos HTML. Puede trabajar con red, caché, IndexedDB, clientes y eventos del navegador.

### `importScripts('./db-helper.js')`

```javascript
importScripts('./db-helper.js');
```

Un Service Worker clásico no puede utilizar una etiqueta `<script>`. `importScripts()` descarga y ejecuta el helper dentro del contexto global del worker.

Después de esa instrucción están disponibles:

- `obtenerTodosLosRegistros()`.
- `actualizarEstadoRegistro()`.
- Las demás funciones y constantes globales del helper.

La ruta `./db-helper.js` es relativa al archivo `sw.js`, por lo que funciona en el subdirectorio de GitHub Pages.

### Versión del App Shell

```javascript
const CACHE_STATIC_NAME = 'static-outbox-v2';
```

El cambio de nombre distingue esta versión. Durante `activate`, el worker elimina contenedores anteriores que comiencen con `pwa-outbox-shell-` o `static-outbox-` y no coincidan con el nombre actual.

`STATIC_FILES` contiene los archivos esenciales de la interfaz:

```javascript
[
  './',
  './index.html',
  './styles.css',
  './db-helper.js',
  './app.js',
  './manifest.json'
]
```

### Ciclo de vida y estrategia de archivos

| Evento | Responsabilidad |
|---|---|
| `install` | Precarga `STATIC_FILES` y ejecuta `skipWaiting()` |
| `activate` | Elimina versiones anteriores y ejecuta `clients.claim()` |
| `fetch` | Atiende GET locales mediante Cache First y respaldo de navegación |

Los `POST` externos no se interceptan en `fetch`. Son enviados explícitamente por `app.js` o por `sincronizarPendientesSW()`.

### `notificarClientesActualizacion()`

Después de sincronizar, el worker necesita informar a las páginas abiertas:

```javascript
return self.clients.matchAll({
  type: 'window',
  includeUncontrolled: true
});
```

- `type: 'window'` solicita clientes que representan ventanas o pestañas.
- `includeUncontrolled: true` incluye páginas del origen aunque todavía no estén controladas por la versión actual.

Después recorre los clientes:

```javascript
clientes.forEach((cliente) => {
  cliente.postMessage({
    tipo: 'OUTBOX_SINCRONIZADO',
    timestamp: Date.now()
  });
});
```

El mensaje contiene:

| Propiedad | Función |
|---|---|
| `tipo` | Permite a la interfaz reconocer el mensaje |
| `timestamp` | Indica cuándo se generó la notificación |

Si no hay pestañas abiertas, `matchAll()` entrega un arreglo vacío. La sincronización sigue siendo válida: los estados ya quedaron escritos en IndexedDB. Al volver a abrir, `app.js` los recupera durante su renderizado inicial.

### `sincronizarPendientesSW()`

Esta función traslada el motor de sincronización al worker.

#### 1. Leer IndexedDB

```javascript
return obtenerTodosLosRegistros()
```

#### 2. Seleccionar pendientes

```javascript
const pendientes = registros.filter(
  (item) => item.estado === 'pendiente'
);
```

Si no hay pendientes, la función termina sin realizar solicitudes.

#### 3. Crear promesas de reenvío

Por cada objeto se ejecuta:

```text
fetch POST
   ↓
comprobar respuesta.ok
   ↓
actualizarEstadoRegistro(id, 'sincronizado')
```

La URL real no contiene los caracteres `<` y `>`:

```javascript
fetch('https://jsonplaceholder.typicode.com/posts', ...)
```

#### 4. Esperar el lote y notificar

```javascript
return Promise.all(promesasDeEnvio)
  .then(() => notificarClientesActualizacion());
```

La notificación se envía después de que todos los `POST` y todas las actualizaciones hayan terminado correctamente.

Si una promesa falla, `Promise.all()` se rechaza y no se ejecuta el `.then()` de notificación.

### Evento `sync`

```javascript
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-reportes') {
    event.waitUntil(
      sincronizarPendientesSW()
        .catch((error) => {
          throw error;
        })
    );
  }
});
```

El navegador puede manejar distintas etiquetas. La comparación evita que esta función responda a tareas que no le pertenecen.

### Importancia de `event.waitUntil()`

Un Service Worker puede detenerse cuando el navegador considera que no tiene trabajo. `event.waitUntil(promesa)` informa que el evento continúa ocupado hasta que esa promesa se resuelva o rechace.

La promesa incluye:

```text
leer IndexedDB
  → enviar todos los POST
  → actualizar estados
  → notificar clientes
```

Sin `waitUntil()`, el worker podría finalizar antes de completar el lote.

### Importancia de `throw error`

El `.catch()` imprime el problema y vuelve a lanzar el error. Al relanzarlo, la promesa entregada a `waitUntil()` queda rechazada.

Esto comunica al navegador que la sincronización no terminó correctamente y permite que Background Sync programe otro intento de acuerdo con sus políticas.

Si el error solo se imprimiera y no se relanzara, el `.catch()` resolvería la cadena. El navegador podría considerar concluido el evento aunque los registros continuaran pendientes.

---

## Puente Completo de Comunicación

```text
sw.js
└── cliente.postMessage({ tipo: 'OUTBOX_SINCRONIZADO' })
                         │
                         ▼
app.js
└── navigator.serviceWorker.addEventListener('message', ...)
                         │
                         ▼
                 renderizarColaOutbox()
                         │
                         ▼
                       DOM
```

El worker no manipula el DOM. La página no necesita ejecutar el reenvío en navegadores compatibles. Cada contexto realiza la tarea que sí puede ejecutar.

---

## `manifest.json`: Propiedades Relevantes

El manifiesto no necesita cambios especiales para Background Sync. Conserva rutas relativas compatibles con GitHub Pages:

| Propiedad | Valor y función |
|---|---|
| `start_url` | `./index.html`, abre dentro del repositorio publicado |
| `scope` | `./`, limita la PWA al subdirectorio actual |
| `display` | `standalone`, solicita apariencia de aplicación |
| `theme_color` | Define el color temático |
| `icons` | Declara imágenes relativas de 192×192 y 512×512 |

Background Sync depende del Service Worker y del contexto seguro, no de una propiedad adicional del manifiesto.

---

## Flujos Completos

### Envío exitoso

```text
formulario
  → POST exitoso
  → guardar sincronizado
  → renderizar
```

### Envío sin red con `SyncManager`

```text
formulario
  → POST falla
  → guardar pendiente
  → registrar sync-reportes
  → renderizar pendiente
  → puede cerrarse la pestaña
  → regresa la red
  → evento sync
  → sincronizarPendientesSW()
  → actualizar IndexedDB
  → postMessage si hay clientes abiertos
```

### Envío sin red y sin `SyncManager`

```text
formulario
  → POST falla
  → guardar pendiente
  → no registrar Background Sync
  → evento online con página abierta
  → sincronizarPendientesFallback()
  → actualizar IndexedDB y DOM
```

### Sincronización con la pestaña cerrada

```text
IndexedDB conserva pendientes
  → el navegador despierta sw.js
  → sw.js actualiza estados
  → no hay cliente a quien enviar mensaje
  → al reabrir, app.js lee IndexedDB
  → la interfaz muestra los estados actuales
```

---

## Etapas y Frecuencia

| Etapa o evento | Cuándo participa |
|---|---|
| `install` | Una vez por versión nueva del worker |
| `activate` | Cuando la versión puede tomar control |
| `fetch` | En cada GET local controlado |
| Registro de `sync-reportes` | Después de guardar un POST fallido y si existe `SyncManager` |
| Evento `sync` | Cuando el navegador decide ejecutar la tarea registrada |
| `postMessage` | Después de sincronizar el lote, por cada cliente abierto |
| Evento `message` | Cuando una página recibe el aviso del worker |
| Evento `online` | Actualiza el indicador y ejecuta fallback solo sin `SyncManager` |

Background Sync no significa que el Service Worker permanezca ejecutándose todo el tiempo. El navegador lo inicia cuando necesita atender el evento y puede detenerlo al terminar.

---

## Cómo Probar la Práctica

La prueba debe realizarse en un contexto seguro, como GitHub Pages mediante HTTPS, y en un navegador compatible con Background Sync.

### Preparación

1. Abre la URL publicada.
2. En DevTools → Application → Service Workers, confirma que la versión actual esté activa.
3. En IndexedDB, localiza `pwa-outbox-db`.
4. En Background Services → Background Sync, inicia la grabación.

### Registro de la tarea

1. Activa Offline en Network.
2. Envía un reporte.
3. Confirma que el objeto aparezca como `pendiente` en IndexedDB.
4. Revisa que Background Sync muestre la etiqueta `sync-reportes`.

### Pestaña cerrada

1. Deja uno o más registros pendientes.
2. Cierra la pestaña de la PWA.
3. Restaura la conexión.
4. Espera que el navegador atienda la tarea.
5. Abre nuevamente la PWA.
6. Confirma que IndexedDB muestre los registros como `sincronizado`.

### Comunicación con una pestaña abierta

1. Conserva abierta la PWA.
2. Genera un pendiente sin red.
3. Restaura la conexión.
4. Observa el mensaje de confirmación en la consola.
5. Comprueba que la lista se actualice sin recargar manualmente.

### Fallback

En un navegador sin `SyncManager`, conserva abierta la página, genera un pendiente y recupera la conexión. El evento `online` debe llamar a `sincronizarPendientesFallback()`.

---

## Conceptos para Recordar

- IndexedDB es compartida por la página y el Service Worker del mismo origen.
- Background Sync registra una tarea; no mantiene al worker vivo permanentemente.
- `navigator.serviceWorker.ready` entrega el registro activo.
- La etiqueta enlaza `register('sync-reportes')` con `event.tag`.
- `event.waitUntil()` protege la vida del trabajo asíncrono.
- `throw error` comunica que el intento debe considerarse fallido.
- `postMessage` comunica contextos aislados.
- El Service Worker no puede acceder al DOM.
- El fallback mantiene la funcionalidad donde no existe `SyncManager`.
- La condición del evento `online` evita envíos duplicados.
- Las rutas relativas conservan la compatibilidad con GitHub Pages.
