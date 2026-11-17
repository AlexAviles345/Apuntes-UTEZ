# Tema 5.2 Patrón Outbox (CRUD Offline con IndexedDB) y Despliegue en GitHub Pages

**Asignatura:** Desarrollo de Aplicaciones Web Progresivas (PWA)

**Modalidad:** Trabajo Autónomo / Ensamblado Arquitectónico

**Restricciones Técnicas Obligatorias:**

1. Código escrito **100% en JavaScript Vanilla**.
2. **Prohibido el uso de `async/await`** y de librerías externas (`PouchDB`, `Dexie`, `idb`, `Workbox`). Toda la asincronía debe resolverse mediante `new Promise()`, `.then()`, `.catch()` y `Promise.all()`.
3. La aplicación debe quedar publicada y funcional bajo HTTPS en **GitHub Pages**.

## 1. Arquitectura del Patrón Outbox (Bandeja de Salida Offline)

En la práctica anterior resolviste la lectura offline de peticiones `GET` mediante la Cache API. Sin embargo, cuando un usuario envía un formulario (`POST`) sin conexión a internet, la Cache API no sirve.

Para evitar la pérdida de información en campo, implementarás el **Patrón Outbox** sobre tu mini-wrapper de IndexedDB, cubriendo las cuatro operaciones CRUD aplicadas a un caso real de resiliencia:

```
[ Usuario envía Formulario (POST) ]
               │
               ├── ¿Hay conexión a Internet?
               │         │
               │         ├── SÍ ──> Envía a la API ──> Guarda en IndexedDB como 'sincronizado'
               │         │
               │         └── NO (.catch) ──> CREATE: Guarda en IndexedDB como 'pendiente'
               │
[ Al cargar la página ] ───────────────────> READ: Lee IndexedDB y dibuja la cola en pantalla
               │
[ Evento global 'online' ] ────────────────> UPDATE: Reenvía 'pendientes' y actualiza estado
               │
[ Botón "Purgar Enviados" ] ───────────────> DELETE: Elimina registros ya sincronizados
```

## 2. Estructura de Archivos del Proyecto

Crea un repositorio en GitHub llamado `pwa-outbox-practica` con la siguiente estructura exacta:

```
pwa-outbox-practica/
├── index.html
├── styles.css
├── db-helper.js     # Mini-wrapper promisificado de IndexedDB
├── app.js           # Lógica de UI, envío resiliente y reconexión
├── sw.js            # Service Worker (App Shell con rutas relativas)
└── manifest.json    # Manifiesto configurado para subdirectorio de GitHub Pages
```

## 3. Fase 1: Evolución del Mini-Wrapper (`db-helper.js`)

Toma como base las cuatro funciones de tu guía de IndexedDB (`abrirDB`, `guardarRegistro`, `obtenerTodosLosRegistros`, `eliminarRegistro`) y añade la operación **Update** para poder cambiar el estado de una transacción de `'pendiente'` a `'sincronizado'`.

### Fragmento A: Actualización de Estado en una Misma Transacción

Analiza cómo dentro de una única transacción `'readwrite'` primero leemos el objeto actual con `store.get(id)` y, dentro de su `onsuccess`, lo sobrescribimos con `store.put(registro)`:

```jsx
function actualizarEstadoRegistro(id, nuevoEstado){
  return abrirDB().then((db) => {
    return new Promise((resolve, reject) => {
      const tx = db.transaction([STORE_NAME], 'readwrite');
      const store = tx.objectStore(STORE_NAME);

      // 1. Obtener el registro actual por su llave primaria
      const reqGet = store.get(id);

      reqGet.onsuccess = (event) => {
        const registro = event.target.result;
        if (!registro) {
          reject(new Error(`No se encontró el registro con ID: ${id}`));
          return;
        }

        // 2. Modificar la propiedad y sobrescribir con .put()
        registro.estado = nuevoEstado;
        registro.fechaSincronizacion = Date.now();
        store.put(registro);
      };

      // 3. Resolver la promesa cuando la transacción completa el guardado en disco
      tx.oncomplete = () => resolve(true);
      tx.onerror = (event) => reject(event.target.error);
    });
  });
}
```

## 4. Fase 2: Interfaz y Flujo Resiliente (`index.html` y `app.js`)

### Paso 4.1: Estructura HTML (`index.html`)

Asegúrate de importar `db-helper.js` **antes** de `app.js` para que las funciones de base de datos estén disponibles en el ámbito global. Usa **rutas relativas (`./`)** en todos tus enlaces:

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PWA Outbox - Sincronización Offline</title>
  <link rel="stylesheet" href="./styles.css">
  <link rel="manifest" href="./manifest.json">
</head>
<body>
  <header>
    <h1>Registro de Incidencias en Campo</h1>
    <span id="badge-red" class="badge online">En Línea</span>
  </header>

  <main>
    <section class="card">
      <h2>Nueva Incidencia</h2>
      <form id="form-incidencia">
        <input type="text" id="titulo" placeholder="Título del reporte (ej. Falla en válvula 4)" required>
        <textarea id="descripcion" placeholder="Detalle técnico..." required></textarea>
        <button type="submit">Enviar Reporte</button>
      </form>
    </section>

    <section class="card">
      <div class="header-lista">
        <h2>Bandeja de Salida (IndexedDB)</h2>
        <button id="btn-purgar" type="button">Purgar Sincronizados</button>
      </div>
      <ul id="lista-outbox"></ul>
    </section>
  </main>

  <script src="./db-helper.js"></script>
  <script src="./app.js"></script>
</body>
</html>
```

### Paso 4.2: Envío Resiliente con Fallback a IndexedDB (`app.js`)

Analiza el siguiente fragmento. Intenta enviar el reporte mediante `fetch` con método `POST`. Si hay internet, guarda una bitácora local marcada como `'sincronizado'`. Si la red falla, el bloque `.catch()` captura la excepción y encola el reporte en IndexedDB como `'pendiente'`:

#### Fragmento B: Captura de Mutaciones Fallidas (CREATE)

```jsx
function procesarEnvioReporte(datosFormulario){
  const endpoint = 'https://jsonplaceholder.typicode.com/posts';

  return fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(datosFormulario)
  })
    .then((respuesta) => {
      if (!respuesta.ok) throw new Error('Error HTTP del servidor');
      return respuesta.json();
    })
    .then(() => {
      // Envío exitoso en vivo: registrar en bitácora local como sincronizado
      return guardarRegistro({
        ...datosFormulario,
        estado: 'sincronizado',
        fechaCreacion: Date.now()
      });
    })
    .catch(() => {
      console.warn('[Outbox] Sin conexión. Encolando transacción localmente...');
      // Falla de red: guardar en IndexedDB como pendiente para reenvío posterior
      return guardarRegistro({
        ...datosFormulario,
        estado: 'pendiente',
        fechaCreacion: Date.now()
      });
    })
    .then(() => {
      // Actualizar la lista visual en ambos escenarios
      return renderizarColaOutbox();
    });
}
```

### Paso 4.3: Sincronización Automática al Recuperar Red (`app.js`)

Cuando el navegador dispara el evento `online`, debemos consultar todos los registros de IndexedDB, filtrar únicamente los que tengan `estado === 'pendiente'`, enviarlos en paralelo usando `Promise.all()` y actualizar su estado en la base de datos local:

#### Fragmento C: Barrido y Reenvío de Pendientes (UPDATE)

```jsx
function sincronizarPendientes(){
  console.log('[Outbox] Conexión detectada. Buscando registros pendientes...');

  return obtenerTodosLosRegistros()
    .then((registros) => {
      const pendientes = registros.filter((item) => item.estado === 'pendiente');

      if (pendientes.length === 0) {
        console.log('[Outbox] No hay transacciones pendientes por sincronizar.');
        return;
      }

      // Convertir cada registro pendiente en una promesa de envío + actualización
      const promesasDeEnvio = pendientes.map((item) => {
        return fetch('https://jsonplaceholder.typicode.com/posts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ title: item.titulo, body: item.descripcion })
        })
          .then((res) => {
            if (!res.ok) throw new Error('Falla al reintentar envío');
            // Actualizar estado en IndexedDB de 'pendiente' a 'sincronizado'
            return actualizarEstadoRegistro(item.id, 'sincronizado');
          });
      });

      // Esperar a que todos los reenvíos concluyan
      return Promise.all(promesasDeEnvio);
    })
    .then(() => {
      return renderizarColaOutbox();
    })
    .catch((error) => {
      console.error('[Outbox] Error durante la sincronización masiva:', error);
    });
}

// Escuchar el regreso de la conectividad
window.addEventListener('online', () => {
  actualizarIndicadorRed();
  sincronizarPendientes();
});

window.addEventListener('offline', actualizarIndicadorRed);
```

### Desafío de Ensamblado Autónomo (READ & DELETE en `app.js`)

Deberás programar por tu cuenta las siguientes tres piezas para completar `app.js`:

1. **Función `renderizarColaOutbox()` (READ):** Debe invocar `obtenerTodosLosRegistros().then(...)`, limpiar el `<ul id="lista-outbox">` e insertar un `<li>` por cada registro mostrando su `titulo`, su `estado` (`pendiente` o `sincronizado`) y la hora formateada.
2. **Conexión del Formulario (`submit`):** Escuchar el evento `submit` de `#form-incidencia`, prevenir la recarga con `e.preventDefault()`, extraer los valores de los inputs, llamar a `procesarEnvioReporte(...)` y limpiar el formulario.
3. **Purga de Registros Enviados (DELETE):** Escuchar el `click` del botón `#btn-purgar`. Debe leer los registros con `obtenerTodosLosRegistros()`, filtrar aquellos con `estado === 'sincronizado'`, eliminar cada uno mediante `eliminarRegistro(item.id)` dentro de un `Promise.all()` y volver a llamar a `renderizarColaOutbox()`.

## 5. Fase 3: Despliegue en GitHub Pages y la Trampa de las Rutas

GitHub Pages no publica tu proyecto en la raíz del dominio (`https://usuario.github.io/`), sino dentro de un subdirectorio con el nombre de tu repositorio:`https://usuario.github.io/pwa-outbox-practica/`

### Errores Críticos de Rutas que Debes Evitar

Si dejas diagonales iniciales (`/`) en tus rutas, el navegador buscará los archivos en la raíz del dominio y **todo fallará con error 404**:

| **Archivo** | **❌ Ruta Incorrecta (Falla en GitHub Pages)** | **✅ Ruta Correcta (Relativa al Subdirectorio)** |
| --- | --- | --- |
| **`app.js`** | `navigator.serviceWorker.register('/sw.js')` | `navigator.serviceWorker.register('./sw.js')` |
| **`sw.js`** | `const STATIC = ['/', '/index.html', '/app.js']` | `const STATIC = ['./', './index.html', './app.js', './db-helper.js']` |
| **`manifest.json`** | `"start_url": "/index.html"` | `"start_url": "./index.html"` |

### Pasos para Publicar y Validar en Producción

1. Sube todos los archivos de tu carpeta a la rama `main` de tu repositorio en GitHub.
2. En GitHub, ve a **Settings** $\rightarrow$ **Pages**. En *Source*, selecciona **Deploy from a branch**, elige la rama `main` y carpeta `/ (root)`, y presiona **Save**.
3. Espera ~2 minutos a que GitHub genere tu URL HTTPS.
4. Abre la URL en Google Chrome, entra a DevTools (`F12`) $\rightarrow$ **Application** y verifica:
    - Que el **Manifest** no marque advertencias de iconos o `start_url`.
    - Que el **Service Worker** esté activo (`activated and is running`) con su *Scope* apuntando a `/pwa-outbox-practica/`.
    - Que **Cache Storage** haya guardado el *App Shell* completo (incluyendo `./db-helper.js`).

## 6. Banco de Pruebas en Vivo para la Defensa Oral

En la próxima sesión se seleccionará a los estudiantes al azar. Abrirás tu enlace público de **GitHub Pages** en clase y tendrás **60 segundos** para ejecutar y explicar una de las siguientes pruebas:

1. **Prueba de Supervivencia Offline Total:**
    
    > *"Activa el modo Offline en DevTools. Envía dos reportes desde tu formulario, cierra por completo la pestaña del navegador y vuelve a abrir tu URL de GitHub Pages aún sin red. Muéstrame tus dos registros en la interfaz y en DevTools $\rightarrow$ IndexedDB, y señala en `app.js` qué promesa los rescató al iniciar la página."*
    > 
2. **Prueba de Sincronización en Lote (`Promise.all`):**
    
    > *"Con dos reportes en estado `'pendiente'` dentro de IndexedDB, desactiva el modo Offline en DevTools. Explícame paso a paso cómo `sincronizarPendientes()` transformó el arreglo de objetos de IndexedDB en un arreglo de promesas HTTP y por qué usamos `Promise.all()`."*
    > 
3. **Inspección de Transacción Doble (`get` + `put`):**
    
    > *"Abre tu archivo `db-helper.js` en la función `actualizarEstadoRegistro`. Explícame por qué `store.get(id)` y `store.put(registro)` pueden ejecutarse dentro de la misma transacción `'readwrite'` y qué pasaría si cambiáramos el modo de la transacción a `'readonly'`."*
    > 
4. **Diagnóstico de Despliegue en Subdirectorio:**
    
    > *"Muéstrame el Scope de tu Service Worker en tu URL de GitHub Pages. Si yo cambiara `register('./sw.js')` por `register('/sw.js')` en tu código de producción, ¿qué URL exacta intentaría descargar el navegador y por qué rompería el funcionamiento offline?"*
    >
