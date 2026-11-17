# Patrón Outbox — Respuestas para la Defensa Oral

Este documento responde los desafíos y las preguntas planteadas al final del Tema 5.2. Las respuestas se basan en la implementación de la carpeta `pwa-outbox-practica/`.

Para estudiar primero el flujo completo, consulta [Patrón Outbox — Explicación del código](Patrón%20Outbox%20-%20Explicación%20del%20código.md).

## Ubicación de las Respuestas en el Proyecto

| Tema | Archivo principal |
|---|---|
| Persistencia y CRUD | [`db-helper.js`](pwa-outbox-practica/db-helper.js) |
| Envío, reconexión e interfaz | [`app.js`](pwa-outbox-practica/app.js) |
| Apertura offline | [`sw.js`](pwa-outbox-practica/sw.js) |
| Rutas y alcance de la PWA | [`manifest.json`](pwa-outbox-practica/manifest.json) |

---

## Respuestas al Desafío de Ensamblado Autónomo

### 1. ¿Cómo se implementó `renderizarColaOutbox()`?

La función cumple la operación READ del CRUD. Su trabajo no es consultar la API, sino recuperar los objetos que ya existen en IndexedDB.

El primer paso es devolver la promesa producida por el helper:

```javascript
return obtenerTodosLosRegistros().then((registros) => {
  // renderizado
});
```

`obtenerTodosLosRegistros()` abre la base de datos, crea una transacción `readonly`, ejecuta `store.getAll()` y resuelve con un arreglo.

Cuando llega el arreglo, la función obtiene la lista de la interfaz y elimina su contenido anterior:

```javascript
const lista = document.getElementById('lista-outbox');
lista.textContent = '';
```

Limpiar la lista evita duplicar visualmente los elementos cada vez que se vuelve a consultar IndexedDB.

Después recorre los objetos:

```javascript
registros.forEach((registro) => {
  const item = document.createElement('li');
  item.textContent = registro.titulo + ' — ' + registro.estado + ' — ' +
    new Date(registro.fechaCreacion).toLocaleString('es-MX');
  lista.appendChild(item);
});
```

Cada `<li>` presenta los tres datos pedidos:

- El título del reporte.
- Su estado `pendiente` o `sincronizado`.
- La fecha de creación transformada a una representación legible.

La función devuelve la cadena de promesas. Esto permite que otras operaciones esperen a que la lectura y el renderizado terminen.

#### Respuesta corta para exposición

> `renderizarColaOutbox()` llama a `obtenerTodosLosRegistros()`, espera el arreglo con `.then()`, limpia el `<ul>` y crea un `<li>` por cada objeto guardado. Es la operación READ visible del patrón Outbox.

### 2. ¿Cómo se conectó el formulario?

El código registra un manejador para `submit`:

```javascript
document.getElementById('form-incidencia')
  .addEventListener('submit', (e) => {
    // flujo
  });
```

El primer paso es:

```javascript
e.preventDefault();
```

Sin esa instrucción, el comportamiento normal del formulario recargaría la página. La recarga interrumpiría el flujo controlado por JavaScript y dificultaría saber cuándo terminó el guardado.

Después se construye el objeto que representa el reporte:

```javascript
const datosFormulario = {
  titulo: document.getElementById('titulo').value,
  descripcion: document.getElementById('descripcion').value
};
```

Ese objeto se entrega a `procesarEnvioReporte()`. La función decide si queda como `sincronizado` o `pendiente`.

```javascript
procesarEnvioReporte(datosFormulario)
  .then(() => formulario.reset())
  .catch((error) => {
    console.error('[Outbox] Error al guardar el reporte:', error);
  });
```

El formulario se limpia después de resolver la promesa. Si el envío de red falla pero el respaldo en IndexedDB termina correctamente, la promesa también se resuelve: el dato ya está protegido localmente y el formulario puede limpiarse.

#### Respuesta corta para exposición

> El evento `submit` evita la recarga, extrae los dos campos y llama a `procesarEnvioReporte()`. El formulario solo se limpia cuando la cadena confirma que el reporte se envió o quedó guardado en IndexedDB.

### 3. ¿Cómo funciona la purga de enviados?

El botón debe borrar únicamente los registros cuyo estado sea `sincronizado`.

Primero recupera todos los objetos:

```javascript
obtenerTodosLosRegistros()
```

Después selecciona los que ya fueron enviados:

```javascript
const sincronizados = registros.filter(
  (item) => item.estado === 'sincronizado'
);
```

Cada objeto se transforma en una promesa de eliminación:

```javascript
sincronizados.map((item) => eliminarRegistro(item.id))
```

Finalmente se espera todo el conjunto:

```javascript
return Promise.all(
  sincronizados.map((item) => eliminarRegistro(item.id))
);
```

Al terminar se vuelve a consultar IndexedDB para actualizar la lista visual.

Los registros pendientes no pasan el filtro, por lo que no se eliminan. Esta condición protege la información que todavía no ha llegado al servidor.

#### Respuesta corta para exposición

> La purga lee IndexedDB, filtra solamente `sincronizado`, convierte cada ID en una promesa de `eliminarRegistro()` y usa `Promise.all()` para esperar todas las eliminaciones antes de renderizar otra vez.

---

## Pregunta 1: Supervivencia Offline Total

### Escenario

El usuario activa Offline, envía dos reportes, cierra la pestaña y vuelve a abrir la PWA sin conexión.

### ¿Por qué sobreviven los reportes?

Al fallar cada `fetch()` de tipo `POST`, el `.catch()` de `procesarEnvioReporte()` ejecuta:

```javascript
return guardarRegistro({
  ...datosFormulario,
  estado: 'pendiente',
  fechaCreacion: Date.now()
});
```

`guardarRegistro()` escribe el objeto en IndexedDB. IndexedDB pertenece al almacenamiento persistente del origen; no depende de que la pestaña permanezca abierta.

Cerrar la pestaña destruye el DOM y termina la ejecución de `app.js`, pero no elimina automáticamente:

- La base `pwa-outbox-db`.
- El Object Store `transacciones_pendientes`.
- Los objetos guardados.
- La caché del App Shell.

### ¿Cómo puede abrirse la interfaz sin red?

El Service Worker instaló en Cache Storage:

- `index.html`.
- `styles.css`.
- `db-helper.js`.
- `app.js`.
- `manifest.json`.
- Los iconos.

Al reabrir la URL sin conexión, el evento `fetch` encuentra los archivos locales mediante `caches.match()` y los entrega desde la caché.

### ¿Qué promesa rescata los registros al iniciar?

Al final de `app.js` se llama:

```javascript
renderizarColaOutbox()
  .catch((error) => {
    console.error('[Outbox] Error al leer la bandeja:', error);
  });
```

Dentro de esa función, la cadena esencial es:

```javascript
return obtenerTodosLosRegistros()
  .then((registros) => {
    // crear los elementos de la lista
  });
```

La promesa de `obtenerTodosLosRegistros()` es la que recupera los objetos desde IndexedDB. La promesa retornada por `renderizarColaOutbox()` representa tanto la lectura como la actualización del DOM.

### Diferencia entre los dos almacenamientos

```text
Cache Storage
└── rescata la aplicación: HTML, CSS y JavaScript

IndexedDB
└── rescata los datos: reportes pendientes y sincronizados
```

Ninguno sustituye al otro. Sin el App Shell, la interfaz podría no abrir. Sin IndexedDB, la interfaz abriría pero no tendría los reportes del usuario.

### Respuesta corta para exposición

> Los `POST` fallidos se guardan en IndexedDB como pendientes. Al volver a abrir, el Service Worker recupera el App Shell y `renderizarColaOutbox()` devuelve la promesa de `obtenerTodosLosRegistros()`, que lee los objetos con `getAll()` y vuelve a dibujarlos.

---

## Pregunta 2: Sincronización en Lote con `Promise.all()`

### ¿Cómo se transforma IndexedDB en un arreglo de promesas HTTP?

El proceso comienza con:

```javascript
obtenerTodosLosRegistros()
```

La promesa entrega un arreglo de todos los objetos. Después se filtra:

```javascript
const pendientes = registros.filter(
  (item) => item.estado === 'pendiente'
);
```

Si hay dos pendientes, el arreglo se parece conceptualmente a:

```javascript
[
  { id: 1, titulo: 'Reporte A', estado: 'pendiente' },
  { id: 2, titulo: 'Reporte B', estado: 'pendiente' }
]
```

`map()` toma cada objeto y retorna una cadena de promesas:

```javascript
const promesasDeEnvio = pendientes.map((item) => {
  return fetch(endpoint, opciones)
    .then((res) => {
      if (!res.ok) throw new Error('Falla al reintentar envío');
      return actualizarEstadoRegistro(item.id, 'sincronizado');
    });
});
```

El resultado ya no es un arreglo de reportes, sino un arreglo de trabajos pendientes:

```text
[
  Promise del POST y UPDATE del registro 1,
  Promise del POST y UPDATE del registro 2
]
```

### ¿Por qué se usa `Promise.all()`?

```javascript
return Promise.all(promesasDeEnvio);
```

Se utiliza porque la aplicación necesita una sola promesa que represente el lote completo.

`Promise.all()` permite:

1. Iniciar los reenvíos del arreglo.
2. Esperar a que todos concluyan.
3. Evitar renderizar antes de que terminen las actualizaciones.
4. Propagar un rechazo si alguna cadena falla.

La siguiente llamada a `renderizarColaOutbox()` ocurre después de resolver la promesa conjunta.

### ¿Qué ocurre si una promesa falla?

`Promise.all()` se rechaza cuando cualquiera de sus promesas se rechaza. El flujo llega al `.catch()` de `sincronizarPendientes()`.

Esto no revierte automáticamente las operaciones que ya terminaron. Por ejemplo, un reporte puede haberse actualizado como sincronizado antes de que otro falle. IndexedDB no crea una sola transacción que abarque todos los envíos HTTP.

En un intento posterior, el filtro vuelve a seleccionar únicamente los objetos que todavía tengan estado `pendiente`.

### ¿Se envían estrictamente uno después de otro?

No. `map()` crea las cadenas sin esperar la anterior. Las peticiones pueden estar activas al mismo tiempo. `Promise.all()` no es quien inicia las promesas; las recibe y espera su resultado conjunto.

### Respuesta corta para exposición

> Primero `getAll()` entrega los objetos, `filter()` conserva los pendientes y `map()` convierte cada objeto en una promesa de `fetch` seguida de un Update. `Promise.all()` crea una promesa del lote para renderizar solo después de que todos los reenvíos terminen.

---

## Pregunta 3: Transacción Doble con `get()` y `put()`

### ¿Por qué ambas operaciones pueden usar la misma transacción?

La función crea una transacción con permiso de escritura:

```javascript
const tx = db.transaction([STORE_NAME], 'readwrite');
const store = tx.objectStore(STORE_NAME);
```

Una transacción `readwrite` permite leer y modificar el almacén indicado. Por eso puede ejecutar:

```javascript
const reqGet = store.get(id);
```

y, dentro de `reqGet.onsuccess`:

```javascript
store.put(registro);
```

El callback `onsuccess` pertenece a una solicitud creada dentro de la transacción. Mientras ese callback se procesa, se agrega `put()` a la misma secuencia transaccional.

El flujo es:

```text
abrir transacción readwrite
    ↓
get(id)
    ↓
onsuccess recibe el objeto
    ↓
modificar propiedades
    ↓
put(objeto con la misma id)
    ↓
tx.oncomplete
```

### ¿Por qué se utiliza `put()` y no `add()`?

El registro ya existe y conserva su llave primaria `id`.

- `add()` intenta crear un registro nuevo y falla si la llave ya existe.
- `put()` inserta cuando no existe o reemplaza cuando encuentra la misma llave.

En esta función se busca reemplazar el estado del objeto existente.

### ¿Qué ocurriría con una transacción `readonly`?

`get(id)` seguiría siendo válido porque es una lectura. `put(registro)` no estaría permitido.

Al intentar modificar el Object Store en modo `readonly`, IndexedDB produciría un error de solo lectura, normalmente `ReadOnlyError`. La actualización no se guardaría y la promesa no debería resolverse como una operación exitosa.

### ¿Por qué se espera `tx.oncomplete`?

El éxito de `get()` solo confirma que el objeto fue leído. Incluso el éxito individual de una solicitud de escritura no representa necesariamente la finalización de toda la transacción.

```javascript
tx.oncomplete = () => resolve(true);
```

La función resuelve cuando IndexedDB informa que la transacción completa terminó.

### Respuesta corta para exposición

> `readwrite` permite leer y escribir en el mismo Object Store. `get()` recupera el objeto y, durante su `onsuccess`, `put()` sobrescribe la misma llave. Con `readonly`, `get()` funcionaría pero `put()` produciría `ReadOnlyError`. La promesa espera `tx.oncomplete` para confirmar toda la operación.

---

## Pregunta 4: Despliegue en Subdirectorio y Alcance

### URL utilizada como ejemplo

Si el usuario de GitHub es `usuario` y el repositorio se llama `pwa-outbox-practica`, GitHub Pages publica la aplicación en:

```text
https://usuario.github.io/pwa-outbox-practica/
```

La parte `/pwa-outbox-practica/` es un subdirectorio del dominio.

### ¿Qué resuelve `register('./sw.js')`?

Desde esa página, la ruta relativa:

```javascript
navigator.serviceWorker.register('./sw.js')
```

se convierte en:

```text
https://usuario.github.io/pwa-outbox-practica/sw.js
```

El Service Worker se encuentra dentro del repositorio publicado y su alcance predeterminado corresponde al directorio `/pwa-outbox-practica/`.

### ¿Qué resuelve `register('/sw.js')`?

La diagonal inicial significa «desde la raíz del dominio»:

```javascript
navigator.serviceWorker.register('/sw.js')
```

El navegador intentaría descargar:

```text
https://usuario.github.io/sw.js
```

Esa URL omite por completo `/pwa-outbox-practica/`.

Normalmente el archivo no existe en la raíz y la solicitud termina en `404`. Si el script no se descarga como JavaScript válido, el registro falla y la PWA queda sin el worker encargado del App Shell offline.

### Relación con las demás rutas

La misma regla se aplica al precache y al manifiesto:

```javascript
const APP_SHELL = [
  './',
  './index.html',
  './styles.css',
  './db-helper.js',
  './app.js'
];
```

```json
{
  "start_url": "./index.html",
  "scope": "./"
}
```

Las rutas se mantienen dentro del directorio publicado.

### Respuesta corta para exposición

> `./sw.js` se resuelve dentro de `/pwa-outbox-practica/`. En cambio, `/sw.js` apunta a `https://usuario.github.io/sw.js`, omite el nombre del repositorio y normalmente devuelve 404. Sin el registro correcto no existe App Shell offline.

---

## Preguntas Adicionales de Preparación

### ¿Por qué Cache API no sustituye a IndexedDB para el Outbox?

Cache API está orientada a pares `Request` y `Response`. El Outbox necesita consultar y modificar objetos mediante propiedades como `id`, `estado`, `titulo` y `fechaCreacion`.

IndexedDB proporciona llaves, transacciones y operaciones CRUD para esos datos estructurados.

### ¿Por qué no se usa `localStorage`?

`localStorage` es síncrono, almacena cadenas y no está disponible dentro del Service Worker. IndexedDB es asíncrono y admite objetos estructurados.

### ¿Por qué también se guarda un registro cuando el POST fue exitoso?

La práctica utiliza IndexedDB como bandeja y bitácora visible. Un envío exitoso se guarda con estado `sincronizado`; uno fallido se guarda como `pendiente`.

Esto permite mostrar ambos estados y después purgar los objetos que ya llegaron al servidor.

### ¿Por qué el Service Worker no intercepta el POST?

`sw.js` contiene esta condición:

```javascript
if (event.request.method !== 'GET' ||
    url.origin !== self.location.origin) return;
```

El `POST` externo continúa hacia la red. Si falla, la promesa de `fetch()` en `app.js` se rechaza y el `.catch()` guarda el objeto pendiente.

### ¿Qué pasa si no se retorna una promesa dentro de `.then()`?

La cadena exterior no puede esperar una operación que no fue retornada. Podría avanzar al siguiente `.then()` antes de terminar el guardado, actualización o eliminación.

Los `return` conectan las promesas internas con el flujo principal.

### ¿Qué diferencia hay entre `req.onsuccess` y `tx.oncomplete`?

- `req.onsuccess` confirma el éxito de una solicitud particular, como obtener un ID.
- `tx.oncomplete` confirma que todas las solicitudes de la transacción terminaron correctamente.

Por eso `guardarRegistro()` obtiene el ID durante `req.onsuccess`, pero resuelve durante `tx.oncomplete`.

### ¿Qué limitación tiene el evento `online`?

El código de `app.js` solo existe mientras la página está abierta. Si el usuario cierra completamente la PWA, el evento registrado en `window` no puede ejecutarse.

Los datos no se pierden: permanecen pendientes en IndexedDB. Sin embargo, el reenvío espera hasta que el usuario abra nuevamente la aplicación y ocurra una oportunidad de sincronización desde la interfaz.

### ¿Qué demuestra la prueba offline total?

Demuestra tres responsabilidades distintas:

1. El formulario puede producir datos sin conexión.
2. IndexedDB conserva esos datos aunque desaparezca el DOM.
3. El Service Worker conserva los archivos necesarios para reconstruir la interfaz.

---

## Resumen Rápido para la Defensa

```text
CREATE
└── guardarRegistro()

READ
└── obtenerTodosLosRegistros() + renderizarColaOutbox()

UPDATE
└── get(id) + put(registro) en actualizarEstadoRegistro()

DELETE
└── eliminarRegistro() + Promise.all() durante la purga

OFFLINE
└── catch del POST → estado pendiente

RECONEXIÓN
└── online → filter → map → Promise.all → estado sincronizado

APERTURA OFFLINE
├── Cache Storage → archivos de la PWA
└── IndexedDB → reportes del usuario

GITHUB PAGES
└── rutas relativas ./ para conservar el subdirectorio
```

## Lista de Comprobación Oral

- [ ] Puedo explicar por qué el reporte no se pierde al cerrar la pestaña.
- [ ] Puedo distinguir Cache Storage de IndexedDB.
- [ ] Puedo señalar la promesa que lee IndexedDB al iniciar.
- [ ] Puedo explicar `filter()`, `map()` y `Promise.all()`.
- [ ] Puedo explicar por qué `get()` y `put()` comparten una transacción `readwrite`.
- [ ] Puedo decir qué error conceptual produce usar `readonly` para actualizar.
- [ ] Puedo resolver exactamente `./sw.js` y `/sw.js` en una URL de GitHub Pages.
- [ ] Puedo explicar por qué el evento `online` necesita que la página esté abierta.
