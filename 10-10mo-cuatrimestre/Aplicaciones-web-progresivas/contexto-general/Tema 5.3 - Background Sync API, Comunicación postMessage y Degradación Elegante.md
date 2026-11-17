# Tema 5.3 - Background Sync API, Comunicación `postMessage` y Degradación Elegante

**Asignatura:** Desarrollo de Aplicaciones Web Progresivas (PWA)

**Base de Trabajo:** Repositorio `pwa-outbox-practica` (desplegado en GitHub Pages)

**Restricciones Técnicas Obligatorias:**

1. Código escrito **100% en JavaScript Vanilla**.
2. **Prohibido el uso de `async/await`** y de librerías externas. Toda la asincronía debe resolverse mediante `new Promise()`, `.then()`, `.catch()` y `Promise.all()`.
3. Mantener compatibilidad total con despliegue en subdirectorio de **GitHub Pages** (rutas relativas `./`).

---

## 1. Evolución Arquitectónica: De `app.js` al Hilo del Service Worker

En la práctica anterior resolviste la sincronización mediante `window.addEventListener('online')`. Sin embargo, esa solución tiene una limitación crítica: **si el usuario envía un reporte sin red y cierra la pestaña o el navegador, los datos quedan atrapados en IndexedDB** hasta que vuelva a abrir la PWA manualmente.

En esta práctica migrarás el motor de sincronización hacia el **Service Worker (`sw.js`)** mediante la **Background Sync API**, conservando el evento `online` únicamente como respaldo (*fallback*) para navegadores que no soportan `SyncManager` (como Safari en iOS y Firefox):

```
[ app.js (Hilo Principal) ]                   [ sw.js (Hilo en Segundo Plano) ]
           │                                                  │
   Falla fetch POST                                           │
           ├──> Guarda en IndexedDB ('pendiente')             │
           └──> reg.sync.register('sync-reportes') ──────────>│ (El navegador registra la tarea)
                                                              │
   [ Usuario cierra la pestaña ]                              │
           X                                                  │ (Navegador detecta internet real)
                                                              ├──> Dispara evento 'sync'
                                                              ├──> Lee IndexedDB (db-helper.js)
                                                              ├──> Reenvía POST con Promise.all()
                                                              ├──> Actualiza estado a 'sincronizado'
   [ Si la pestaña sigue abierta ] <── cliente.postMessage() ─┘
           │
   Repinta la tabla en el DOM
```

---

## 2. Fase 1: Refactorización del Service Worker (`sw.js`)

Abre tu archivo `sw.js`. Como el Service Worker ejecuta en un hilo independiente sin acceso al DOM (`window` ni `document` existen aquí), deberás importar tu mini-wrapper de base de datos, trasladar la lógica de reenvío y notificar a la interfaz mediante mensajes.

---

### Fragmento A: Importación del Helper y Actualización de Versión

Al inicio de `sw.js`, importa `db-helper.js` usando ruta relativa para no romper el despliegue en GitHub Pages, e incrementa la versión de tu caché estática para forzar la actualización del Service Worker en producción:

```jsx
// Importar el mini-wrapper de IndexedDB en el contexto del Service Worker
importScripts('./db-helper.js');

const CACHE_STATIC_NAME = 'static-outbox-v2';
const STATIC_FILES = [
  './',
  './index.html',
  './styles.css',
  './db-helper.js',
  './app.js',
  './manifest.json'
];
```

---

### Fragmento B: Notificación del Worker hacia las Pestañas Abiertas (`postMessage`)

Dado que `sw.js` **no puede invocar funciones del DOM** como `renderizarColaOutbox()`, necesita enviar un mensaje a todas las ventanas abiertas de tu PWA cuando termine de sincronizar. Analiza cómo `self.clients.matchAll()` localiza las pestañas activas:

```jsx
function notificarClientesActualizacion() {
  return self.clients.matchAll({ type: 'window', includeUncontrolled: true })
    .then((clientes) => {
      clientes.forEach((cliente) => {
        cliente.postMessage({
          tipo: 'OUTBOX_SINCRONIZADO',
          timestamp: Date.now()
        });
      });
    });
}
```

---

### Fragmento C: Motor de Sincronización en Segundo Plano (`sw.js`)

Traslada la lógica de `sincronizarPendientes()` hacia `sw.js`. Observa que al finalizar `Promise.all()`, encadenamos `notificarClientesActualizacion()` y **retornamos toda la cadena de promesas** para que `event.waitUntil()` sepa exactamente cuándo concluyó el trabajo:

```jsx
function sincronizarPendientesSW() {
  console.log('[SW-Sync] Ejecutando barrido de transacciones pendientes...');

  return obtenerTodosLosRegistros()
    .then((registros) => {
      const pendientes = registros.filter((item) => item.estado === 'pendiente');

      if (pendientes.length === 0) {
        console.log('[SW-Sync] Cola limpia. Nada por sincronizar.');
        return;
      }

      const promesasDeEnvio = pendientes.map((item) => {
        return fetch('<https://jsonplaceholder.typicode.com/posts>', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title: item.titulo,
            body: item.descripcion
          })
        })
          .then((respuesta) => {
            if (!respuesta.ok) {
              throw new Error(`Error HTTP ${respuesta.status} al sincronizar ID ${item.id}`);
            }
            return actualizarEstadoRegistro(item.id, 'sincronizado');
          });
      });

      return Promise.all(promesasDeEnvio)
        .then(() => notificarClientesActualizacion());
    });
}
```

---

### Fragmento D: Escucha del Evento `sync` en `sw.js`

Agrega el escuchador del evento `sync` en la sección de eventos del Service Worker. El navegador disparará este evento automáticamente cuando detecte conectividad estable:

```jsx
self.addEventListener('sync', (event) => {
  console.log('[SW-Sync] Evento sync disparado con etiqueta:', event.tag);

  if (event.tag === 'sync-reportes') {
    event.waitUntil(
      sincronizarPendientesSW()
        .catch((error) => {
          console.error('[SW-Sync] Falla en sincronización; el navegador reintentará luego:', error);
          // Relanzar el error indica al navegador que debe programar un reintento automático
          throw error;
        })
    );
  }
});
```

---

## 3. Fase 2: Refactorización de la Interfaz (`app.js`)

Ahora debes actualizar `app.js` para registrar la etiqueta `'sync-reportes'` cuando falle un envío, evitar duplicidad de peticiones con el evento `online` y escuchar los avisos provenientes de `sw.js`.

---

### Fragmento E: Registro de la Etiqueta `sync` al Fallar el `POST`

Modifica el bloque `.catch()` de tu función `procesarEnvioReporte(datosFormulario)` en `app.js`. Después de guardar el registro como `'pendiente'` en IndexedDB, verifica si el navegador soporta `SyncManager` para delegar el reenvío al Service Worker:

```jsx
    .catch(() => {
      console.warn('[Outbox] Sin conexión. Encolando en IndexedDB...');

      return guardarRegistro({
        ...datosFormulario,
        estado: 'pendiente',
        fechaCreacion: Date.now()
      })
        .then(() => {
          // Detección de soporte para Background Sync API
          if ('serviceWorker' in navigator && 'SyncManager' in window) {
            return navigator.serviceWorker.ready
              .then((registro) => {
                console.log('[Outbox] Registrando etiqueta sync-reportes en el SW...');
                return registro.sync.register('sync-reportes');
              });
          }
        });
    })
```

---

### Fragmento F: Prevención de Condiciones de Carrera en el Evento `online`

Si dejas `window.addEventListener('online')` ejecutándose sin restricciones en Chrome, tanto `app.js` como `sw.js` leerán IndexedDB al mismo milisegundo y **enviarán el `POST` duplicado al servidor**. Condiciona la sincronización del hilo principal únicamente para navegadores sin `SyncManager`:

```jsx
window.addEventListener('online', () => {
  actualizarIndicadorRed();

  // Degradación elegante: Solo sincronizar desde UI si el navegador NO soporta Background Sync (ej. Safari/iOS)
  if (!('SyncManager' in window)) {
    console.log('[Outbox] Navegador sin SyncManager. Ejecutando fallback por evento online...');
    sincronizarPendientesFallback();
  }
});
```

- **Desafío de Ensamblado:** Conserva tu función `sincronizarPendientes()` de la práctica anterior renombrándola como `sincronizarPendientesFallback()` en `app.js` para garantizar que tu PWA siga funcionando en dispositivos iOS.

---

### Fragmento G: Recepción de Mensajes del Service Worker (`app.js`)

Agrega este bloque al inicio de `app.js` (dentro de la validación `if ('serviceWorker' in navigator)`) para actualizar la interfaz automáticamente cuando `sw.js` avise que terminó de sincronizar en segundo plano:

```jsx
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data && event.data.tipo === 'OUTBOX_SINCRONIZADO') {
      console.log('[UI] Confirmación recibida del Service Worker. Actualizando bandeja...');
      renderizarColaOutbox();
    }
  });
}
```

---

## 4. Guía de Verificación: La Prueba de la Pestaña Cerrada

Sube tus cambios a tu repositorio en GitHub, espera a que **GitHub Pages** publique la nueva versión y ejecuta esta prueba definitiva en Google Chrome:

1. Abre tu URL pública de GitHub Pages y entra a DevTools (`F12`) $\rightarrow$ **Application** $\rightarrow$ **Service Workers**. Verifica que el nuevo SW (`static-outbox-v2`) esté activo.
2. En el menú lateral izquierdo de DevTools, ve a **Background Services** $\rightarrow$ **Background Sync** y presiona el botón de grabar (**Record** 🔴).
3. Ve a la pestaña **Network**, activa el modo **Offline** y envía dos reportes desde tu formulario.
4. En **Background Sync** verás aparecer el evento `Registered sync` con la etiqueta `sync-reportes`.
5. **Cierra por completo la pestaña de tu PWA** (dejando abierta otra pestaña cualquiera para mantener DevTools activo o revisando luego).
6. Restaura la conexión a internet (desactiva **Offline**).
7. Vuelve a abrir tu URL de GitHub Pages: los reportes enviados mientras la pestaña estaba cerrada aparecerán automáticamente en estado **`sincronizado`**.

---

## 5. Banco de Pruebas en Vivo para la Defensa Oral (60 Segundos)

Durante la sesión presencial se sorteará a los estudiantes para defender su despliegue en **GitHub Pages** respondiendo a uno de los siguientes escenarios:

1. **Prueba de la Pestaña Cerrada en Vivo:**

> *"Activa el modo Offline en tu URL de GitHub Pages, envía un reporte, verifica en DevTools $\rightarrow$ Background Sync que se registró la etiqueta `sync-reportes` y cierra la pestaña. Reconecta la red, vuelve a abrir tu enlace y muéstrame el registro sincronizado. Explica qué función de `sw.js` ejecutó el envío mientras la página estaba cerrada."*
> 
1. **Prevención de Peticiones Duplicadas (*Race Condition*):**

> *"Señala en tu archivo `app.js` la línea donde condicionaste el evento `online` con `!('SyncManager' in window)`. ¿Qué problema ocurriría en Chrome si borramos ese `if` y dejamos que `app.js` y `sw.js` sincronicen al mismo tiempo?"*
> 
1. **Aislamiento de Hilos (`postMessage`):**

> *"¿Por qué no pudimos llamar directamente a `renderizarColaOutbox()` al final de `sincronizarPendientesSW()` dentro de `sw.js`? Muéstrame las dos mitades del puente de comunicación (`postMessage` y `addEventListener('message')`) que resolvieron ese aislamiento."*
> 
1. **Comportamiento del `throw error` en el Evento `sync`:**

> *"En el bloque `.catch()` dentro de `self.addEventListener('sync')`, incluimos la instrucción `throw error;`. ¿Qué diferencia provoca en el navegador relanzar ese error en lugar de simplemente imprimirlo con `console.error()`?"*
>
