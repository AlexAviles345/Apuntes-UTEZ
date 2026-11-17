# Patrón Outbox — Explicación del Código

Esta guía explica cómo funciona la práctica de registro de incidencias con persistencia offline. El objetivo principal es evitar que un reporte se pierda cuando el usuario intenta enviarlo sin conexión.

La aplicación combina cuatro piezas:

- La interfaz HTML donde se captura el reporte.
- IndexedDB para conservar registros estructurados.
- `app.js` para decidir si un reporte queda sincronizado o pendiente.
- Un Service Worker para conservar el App Shell y abrir la interfaz sin conexión.

Para estudiar las preguntas de la actividad, consulta [Patrón Outbox — Respuestas para la defensa oral](Patrón%20Outbox%20-%20Respuestas%20para%20la%20defensa%20oral.md).

## Archivos de la Práctica

| Archivo | Responsabilidad |
|---|---|
| [`index.html`](pwa-outbox-practica/index.html) | Contiene el formulario, el indicador de red y la lista de registros |
| [`styles.css`](pwa-outbox-practica/styles.css) | Presenta la interfaz y los estados visuales |
| [`db-helper.js`](pwa-outbox-practica/db-helper.js) | Traduce la API de eventos de IndexedDB a funciones que devuelven promesas |
| [`app.js`](pwa-outbox-practica/app.js) | Administra la interfaz, los envíos, el Outbox y la reconexión |
| [`sw.js`](pwa-outbox-practica/sw.js) | Guarda el App Shell y atiende los archivos locales sin conexión |
| [`manifest.json`](pwa-outbox-practica/manifest.json) | Define la identidad, el alcance y el inicio de la PWA |
| `icon-192.png` y `icon-512.png` | Iconos declarados por el manifiesto |

## Arquitectura General

```text
Usuario
  │
  ├── abre la aplicación
  │     ├── Service Worker entrega el App Shell
  │     └── app.js lee IndexedDB y dibuja la bandeja
  │
  └── envía un reporte
        │
        ├── red disponible
        │     ├── POST a JSONPlaceholder
        │     └── IndexedDB: estado sincronizado
        │
        └── red no disponible
              └── IndexedDB: estado pendiente
                         │
                         └── evento online
                               ├── reenvía los pendientes
                               └── cambia su estado a sincronizado
```

El patrón se llama **Outbox** porque IndexedDB funciona como una bandeja de salida local. Un registro pendiente permanece allí hasta que la aplicación pueda enviarlo.

## Restricción de Programación Asíncrona

Los archivos JavaScript utilizan promesas explícitas:

```javascript
operacion()
  .then((resultado) => {
    // continuar
  })
  .catch((error) => {
    // atender el rechazo
  });
```

No se utiliza `async/await`. Las operaciones de IndexedDB, red y caché deben devolver sus promesas para que la siguiente parte de la cadena pueda esperar su resultado.

## `index.html`: Estructura de la Interfaz

La página contiene tres elementos principales:

| Elemento | Uso desde JavaScript |
|---|---|
| `#form-incidencia` | Captura el título y la descripción |
| `#badge-red` | Indica si el navegador reporta conexión |
| `#lista-outbox` | Presenta los registros recuperados de IndexedDB |
| `#btn-purgar` | Elimina los registros sincronizados |

Los scripts se cargan en este orden:

```html
<script src="./db-helper.js"></script>
<script src="./app.js"></script>
```

El orden es obligatorio. `db-helper.js` define funciones globales como `guardarRegistro()` y `obtenerTodosLosRegistros()`. Cuando `app.js` comienza, esas funciones ya deben existir.

Todas las rutas empiezan con `./`. Esto permite que los archivos funcionen dentro del subdirectorio utilizado por GitHub Pages.

---

## `db-helper.js`: Capa de Persistencia

IndexedDB utiliza eventos como `onsuccess`, `onerror` y `onupgradeneeded`. El helper envuelve esos eventos en promesas para que `app.js` pueda consumir todas las operaciones con `.then()` y `.catch()`.

### Identificadores de la Base de Datos

```javascript
const DB_NAME = 'pwa-outbox-db';
const DB_VERSION = 1;
const STORE_NAME = 'transacciones_pendientes';
```

| Constante | Significado |
|---|---|
| `DB_NAME` | Nombre visible en DevTools → Application → IndexedDB |
| `DB_VERSION` | Versión entera del esquema |
| `STORE_NAME` | Nombre del almacén donde viven los reportes |

El nombre `transacciones_pendientes` no significa que todos sus registros deban permanecer pendientes. El mismo almacén conserva objetos con estado `pendiente` y `sincronizado`.

### `abrirDB()`

Esta función es la entrada a todas las operaciones:

```text
abrirDB()
   ↓
indexedDB.open(nombre, versión)
   ├── onupgradeneeded → crea el Object Store si no existe
   ├── onsuccess       → resolve(IDBDatabase)
   └── onerror         → reject(error)
```

Durante `onupgradeneeded` se crea el almacén:

```javascript
db.createObjectStore(STORE_NAME, {
  keyPath: 'id',
  autoIncrement: true
});
```

- `keyPath: 'id'` establece que la propiedad `id` es la llave primaria.
- `autoIncrement: true` permite que IndexedDB genere IDs como `1`, `2` y `3`.
- `objectStoreNames.contains()` evita intentar crear nuevamente el almacén.

`abrirDB()` resuelve su promesa con un objeto `IDBDatabase`. Las demás funciones utilizan ese objeto para abrir transacciones.

### `guardarRegistro(datos)` — CREATE

El guardado abre una transacción de escritura:

```javascript
const tx = db.transaction([STORE_NAME], 'readwrite');
const store = tx.objectStore(STORE_NAME);
const req = store.add(datos);
```

`store.add()` solicita insertar el objeto. Su evento `onsuccess` entrega el ID generado, pero la función espera `tx.oncomplete` antes de resolver:

```text
store.add(datos)
    ↓
req.onsuccess → obtiene idGenerado
    ↓
tx.oncomplete → confirma la transacción y resuelve la promesa
```

La promesa produce el ID asignado. Esperar la transacción completa representa mejor la confirmación de que la escritura terminó.

### `obtenerTodosLosRegistros()` — READ

La lectura utiliza una transacción `readonly`:

```javascript
const req = store.getAll();
```

`getAll()` devuelve mediante `onsuccess` un arreglo de objetos:

```javascript
[
  {
    id: 1,
    titulo: 'Falla en válvula',
    descripcion: 'La válvula no responde',
    estado: 'pendiente',
    fechaCreacion: 1794870000000
  }
]
```

Si el almacén está vacío, el resultado es `[]`, no `null`.

### `eliminarRegistro(id)` — DELETE

Esta función abre una transacción `readwrite` y ejecuta:

```javascript
store.delete(id);
```

La promesa resuelve `true` cuando `tx.oncomplete` confirma la eliminación. En esta práctica se utiliza únicamente para purgar reportes cuyo estado ya es `sincronizado`.

### `actualizarEstadoRegistro(id, nuevoEstado)` — UPDATE

La actualización necesita primero recuperar el objeto completo:

```text
store.get(id)
    ↓
modificar registro.estado
    ↓
agregar registro.fechaSincronizacion
    ↓
store.put(registro)
```

`get()` y `put()` ocurren dentro de la misma transacción `readwrite`. `put()` reconoce la propiedad `id` y sobrescribe el registro que ya utiliza esa llave.

Si `get(id)` no encuentra un objeto, la función rechaza la promesa con un `Error`. Si sí lo encuentra, modifica:

```javascript
registro.estado = nuevoEstado;
registro.fechaSincronizacion = Date.now();
```

Después `tx.oncomplete` confirma que la actualización concluyó.

### Modos de Transacción

| Modo | Operaciones permitidas | Uso en el helper |
|---|---|---|
| `readonly` | Consultar | `obtenerTodosLosRegistros()` |
| `readwrite` | Consultar, insertar, actualizar y borrar | Guardar, eliminar y actualizar |

Una llamada a `put()` dentro de una transacción `readonly` produciría un error porque ese modo no permite cambios.

---

## `app.js`: Lógica del Patrón Outbox

`app.js` conecta la interfaz, la API y las funciones del helper.

### `procesarEnvioReporte(datosFormulario)`

Esta función recibe un objeto como:

```javascript
{
  titulo: 'Falla en válvula 4',
  descripcion: 'No responde al control remoto'
}
```

Después intenta enviarlo mediante `POST`:

```javascript
fetch(endpoint, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(datosFormulario)
})
```

#### Camino con red

```text
fetch POST
   ↓
respuesta.ok = true
   ↓
respuesta.json()
   ↓
guardarRegistro({ estado: 'sincronizado' })
   ↓
renderizarColaOutbox()
```

Aunque el servidor haya recibido el reporte, se guarda una bitácora local. El estado `sincronizado` indica que no necesita reenviarse.

#### Camino sin red

```text
fetch POST rechazado
   ↓
.catch()
   ↓
guardarRegistro({ estado: 'pendiente' })
   ↓
renderizarColaOutbox()
```

El reporte conserva su título, descripción y fecha. La aplicación puede cerrarse y los datos continúan en IndexedDB.

#### Por qué se revisa `respuesta.ok`

`fetch()` no rechaza automáticamente su promesa por recibir estados HTTP como `404` o `500`. Por eso se comprueba:

```javascript
if (!respuesta.ok) throw new Error('Error HTTP del servidor');
```

El `throw` convierte la respuesta HTTP fallida en un rechazo que llega al `.catch()`.

#### Alcance real del `.catch()`

El `.catch()` atiende cualquier rechazo producido antes de él en la cadena: la petición, la lectura del JSON o el primer guardado en IndexedDB. En el uso esperado, su función principal es capturar la falta de red y crear el registro pendiente.

### `sincronizarPendientes()`

Esta función se ejecuta cuando regresa la conexión.

#### 1. Leer la bandeja

```javascript
return obtenerTodosLosRegistros()
```

#### 2. Filtrar pendientes

```javascript
const pendientes = registros.filter(
  (item) => item.estado === 'pendiente'
);
```

Los registros ya sincronizados no se vuelven a enviar.

#### 3. Convertir registros en promesas

`map()` transforma cada registro pendiente en una cadena de envío y actualización:

```text
registro pendiente
    ↓
fetch POST
    ↓
actualizarEstadoRegistro(id, 'sincronizado')
    ↓
promesa
```

El resultado de `map()` es un arreglo de promesas.

#### 4. Esperar el lote

```javascript
return Promise.all(promesasDeEnvio);
```

`Promise.all()` permite que los envíos comiencen sin esperar uno por uno y crea una promesa que termina cuando todos concluyen. Después se vuelve a renderizar la bandeja.

Si alguna promesa se rechaza, `Promise.all()` también se rechaza y el `.catch()` final registra el error de sincronización masiva.

### Eventos `online` y `offline`

```javascript
window.addEventListener('online', () => {
  actualizarIndicadorRed();
  sincronizarPendientes();
});

window.addEventListener('offline', actualizarIndicadorRed);
```

- `offline` cambia el indicador visual.
- `online` cambia el indicador e intenta reenviar los pendientes.

Esta sincronización pertenece a la página. Para que el evento ejecute el reenvío, la aplicación debe encontrarse abierta cuando el navegador notifique el regreso de la conexión.

### `renderizarColaOutbox()`

Esta función implementa la parte READ visible:

```text
obtenerTodosLosRegistros()
    ↓
vaciar #lista-outbox
    ↓
crear un <li> por registro
    ↓
mostrar título, estado y fecha
```

Se utiliza `textContent` para construir cada elemento. Esto presenta el texto sin interpretarlo como HTML.

La fecha numérica se convierte mediante:

```javascript
new Date(registro.fechaCreacion).toLocaleString('es-MX')
```

### `actualizarIndicadorRed()`

La propiedad `navigator.onLine` se utiliza para seleccionar el mensaje y la clase:

| Valor | Texto | Clase |
|---|---|---|
| `true` | `En Línea` | `badge online` |
| `false` | `Sin conexión` | `badge offline` |

El indicador describe el estado reportado por el navegador. La confirmación real de que la API responde se obtiene al ejecutar `fetch()`.

### Evento `submit` del Formulario

El manejador sigue este orden:

```text
submit
  ↓
preventDefault()
  ↓
leer título y descripción
  ↓
procesarEnvioReporte()
  ↓
reset() cuando termina correctamente
```

`preventDefault()` evita que el navegador recargue la página y pierda el flujo controlado por promesas.

### Evento `click` de Purga

El botón no elimina toda la base de datos. Primero filtra:

```javascript
const sincronizados = registros.filter(
  (item) => item.estado === 'sincronizado'
);
```

Después crea una promesa de eliminación por cada objeto y espera el conjunto:

```javascript
return Promise.all(
  sincronizados.map((item) => eliminarRegistro(item.id))
);
```

Los reportes pendientes permanecen protegidos en la bandeja.

### Inicio de la Aplicación

Al cargar la página se ejecuta:

```javascript
actualizarIndicadorRed();
renderizarColaOutbox();
```

La segunda llamada es la que recupera los reportes después de cerrar y volver a abrir la pestaña. No depende de la API: lee directamente IndexedDB.

Finalmente se registra el Service Worker con una ruta relativa:

```javascript
navigator.serviceWorker.register('./sw.js')
```

---

## `sw.js`: App Shell Offline

El Service Worker no administra el Outbox ni reenvía los `POST` en este tema. Su responsabilidad es mantener disponibles los archivos necesarios para abrir la aplicación.

### Nombre y Archivos de Caché

```javascript
const CACHE_NAME = 'pwa-outbox-shell-v1';
```

El arreglo `APP_SHELL` incluye:

- La raíz `./`.
- `index.html`.
- `styles.css`.
- `db-helper.js`.
- `app.js`.
- `manifest.json`.
- Los dos iconos.

Las rutas relativas se resuelven desde el alcance del Service Worker, por lo que son compatibles con el subdirectorio de GitHub Pages.

### Evento `install`

```text
caches.open(CACHE_NAME)
    ↓
cache.addAll(APP_SHELL)
    ↓
self.skipWaiting()
```

`event.waitUntil()` relaciona toda la cadena con la instalación. Si alguno de los archivos de `APP_SHELL` no puede descargarse, `addAll()` se rechaza y esa versión no completa la instalación.

`skipWaiting()` solicita que la versión instalada avance sin esperar indefinidamente a que desaparezca el worker anterior.

### Evento `activate`

Durante la activación se buscan cachés cuyo nombre empiece con `pwa-outbox-shell-`. Se eliminan las versiones diferentes de `CACHE_NAME`.

Después:

```javascript
self.clients.claim()
```

Esto permite que la versión activa tome control de las páginas dentro de su alcance.

### Evento `fetch`

Antes de intervenir, el worker comprueba:

```javascript
if (event.request.method !== 'GET' ||
    url.origin !== self.location.origin) return;
```

Por tanto:

| Petición | ¿La atiende este Service Worker? |
|---|---|
| HTML, CSS y JavaScript locales mediante GET | Sí |
| Navegación local | Sí |
| `POST` a JSONPlaceholder | No; continúa hacia la red |
| Recurso externo de otro origen | No |

Los `POST` deben llegar a la red para que su rechazo sea detectado por `app.js` y el reporte pueda guardarse como pendiente.

Para los archivos locales se utiliza una estrategia Cache First:

```text
caches.match(request)
    ├── coincidencia → devolver caché
    └── sin coincidencia → fetch(request)
```

Si una navegación falla y pertenece al alcance de la PWA, el worker entrega `./index.html` como respaldo.

El código no guarda dinámicamente la respuesta obtenida por `fetch()` en esta etapa. Los recursos offline principales son los que se precargan mediante `APP_SHELL`.

---

## `manifest.json`: Configuración Relevante

| Propiedad | Función |
|---|---|
| `name` | Nombre completo de la aplicación |
| `short_name` | Nombre breve usado por el sistema |
| `start_url: "./index.html"` | Página que abre la PWA instalada |
| `scope: "./"` | Limita la PWA al directorio publicado |
| `display: "standalone"` | Solicita presentación similar a una aplicación |
| `background_color` | Color utilizado durante ciertas etapas de carga |
| `theme_color` | Color temático para la interfaz del navegador o sistema |
| `icons` | Declara recursos de 192×192 y 512×512 |

Las rutas relativas de `start_url`, `scope` e iconos evitan que GitHub Pages busque los archivos en la raíz de `usuario.github.io`.

---

## Flujos Completos

### Enviar con Conexión

```text
Formulario
  → fetch POST exitoso
  → guardar como sincronizado
  → leer IndexedDB
  → actualizar la lista
```

### Enviar sin Conexión

```text
Formulario
  → fetch POST rechazado
  → catch
  → guardar como pendiente
  → leer IndexedDB
  → actualizar la lista
```

### Recuperar la Conexión

```text
evento online
  → leer todos los registros
  → filtrar pendientes
  → crear promesas de POST
  → Promise.all
  → actualizar cada estado
  → renderizar nuevamente
```

### Cerrar y Abrir sin Red

```text
Service Worker
  → entrega index.html, CSS y JavaScript desde caché

app.js
  → obtenerTodosLosRegistros()
  → recupera IndexedDB
  → dibuja la bandeja
```

Cache Storage conserva los archivos de la aplicación. IndexedDB conserva los datos del usuario. Son almacenamientos distintos y cumplen responsabilidades diferentes.

## Etapas y Frecuencia

| Acción o evento | Cuándo ocurre |
|---|---|
| Registro del Service Worker | La página lo solicita durante cada carga |
| `install` | Una vez por cada versión nueva de `sw.js` |
| `activate` | Cuando la versión instalada puede activarse |
| `fetch` | Por cada petición controlada compatible |
| Lectura de IndexedDB al inicio | Cada vez que se ejecuta `app.js` |
| `submit` | Cada vez que el usuario envía el formulario |
| `online` | Cuando el navegador detecta el regreso de conectividad |
| `offline` | Cuando el navegador detecta que perdió conectividad |
| Purga | Cuando el usuario presiona el botón correspondiente |

## Cómo Probar la Práctica

La aplicación debe ejecutarse mediante HTTPS o un servidor local; no mediante `file://`.

### Servidor local con Python

Desde `pwa-outbox-practica/`:

```bash
python -m http.server 8080
```

Después abre `http://localhost:8080`.

### Prueba online

1. Abre DevTools → Application.
2. Envía un reporte con conexión.
3. Revisa IndexedDB → `pwa-outbox-db` → `transacciones_pendientes`.
4. Confirma que el objeto tenga estado `sincronizado`.

### Prueba offline

1. Activa **Offline** en DevTools → Network.
2. Envía uno o más reportes.
3. Confirma que aparezcan con estado `pendiente`.
4. Revisa los mismos objetos en IndexedDB.
5. Recarga sin conexión y confirma que la interfaz y la bandeja reaparezcan.

### Prueba de reconexión

1. Mantén abierta la página con registros pendientes.
2. Desactiva **Offline**.
3. Espera el evento `online`.
4. Confirma que los registros cambien a `sincronizado`.

### Prueba de purga

1. Conserva al menos un registro pendiente y uno sincronizado.
2. Presiona **Purgar Sincronizados**.
3. Confirma que desaparezca el sincronizado y permanezca el pendiente.

## Conceptos para Recordar

- Cache Storage conserva archivos y respuestas HTTP.
- IndexedDB conserva objetos estructurados.
- El Outbox protege mutaciones que no pudieron enviarse.
- `readonly` permite lectura; `readwrite` permite cambios.
- `Promise.all()` espera un conjunto de operaciones.
- `tx.oncomplete` confirma la finalización de una transacción.
- `online` inicia el reenvío mientras la página está abierta.
- El Service Worker permite abrir el App Shell sin conexión.
- Las rutas `./` son necesarias para trabajar dentro del subdirectorio de GitHub Pages.
