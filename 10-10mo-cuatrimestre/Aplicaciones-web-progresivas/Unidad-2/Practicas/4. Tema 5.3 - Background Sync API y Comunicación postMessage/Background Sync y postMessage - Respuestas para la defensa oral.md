# Background Sync y `postMessage` — Respuestas para la Defensa Oral

Esta guía responde detalladamente los escenarios de defensa del Tema 5.3 y explica cómo señalarlos en el proyecto.

Para estudiar primero la arquitectura, consulta [Background Sync y postMessage — Explicación del código](Background%20Sync%20y%20postMessage%20-%20Explicación%20del%20código.md).

## Archivos que Debes Poder Identificar

| Pregunta | Archivo principal |
|---|---|
| Registro de `sync-reportes` | [`app.js`](pwa-outbox-practica/app.js) |
| Fallback mediante `online` | [`app.js`](pwa-outbox-practica/app.js) |
| Recepción de mensajes | [`app.js`](pwa-outbox-practica/app.js) |
| Motor de sincronización | [`sw.js`](pwa-outbox-practica/sw.js) |
| Evento `sync` y reintento | [`sw.js`](pwa-outbox-practica/sw.js) |
| Envío de `postMessage` | [`sw.js`](pwa-outbox-practica/sw.js) |
| Persistencia compartida | [`db-helper.js`](pwa-outbox-practica/db-helper.js) |

---

## Desafío de Ensamblado: Fallback de Sincronización

### ¿Qué ocurrió con `sincronizarPendientes()` de la práctica anterior?

La función se conservó y se renombró:

```javascript
function sincronizarPendientesFallback() {
  // reenvío desde app.js
}
```

Su algoritmo continúa siendo:

```text
leer IndexedDB
  → filtrar estado pendiente
  → crear un fetch por registro
  → actualizar cada estado
  → Promise.all()
  → renderizar la lista
```

Lo que cambió es cuándo se utiliza. Ya no es el mecanismo principal en navegadores compatibles con Background Sync.

```javascript
window.addEventListener('online', () => {
  actualizarIndicadorRed();

  if (!('SyncManager' in window)) {
    sincronizarPendientesFallback();
  }
});
```

El fallback permite que la aplicación siga sincronizando en un navegador que no tenga `SyncManager`, siempre que la página permanezca abierta.

### Respuesta corta

> La función anterior no se eliminó: se renombró como `sincronizarPendientesFallback()` y el evento `online` solo la ejecuta cuando el navegador no ofrece `SyncManager`. Así se mantiene compatibilidad sin competir con el Service Worker.

---

## Pregunta 1: Prueba de la Pestaña Cerrada

### Escenario

El usuario queda sin red, envía un reporte, verifica la etiqueta `sync-reportes`, cierra la pestaña, recupera internet y después vuelve a abrir la PWA.

### Paso 1: falla el envío inicial

`procesarEnvioReporte()` intenta el `POST`. Sin red, la promesa de `fetch()` se rechaza y entra al `.catch()`.

```javascript
return guardarRegistro({
  ...datosFormulario,
  estado: 'pendiente',
  fechaCreacion: Date.now()
});
```

El reporte queda en IndexedDB antes de registrar la tarea. Por eso cerrar la pestaña no elimina la información.

### Paso 2: se registra la tarea

Después del guardado:

```javascript
if ('serviceWorker' in navigator && 'SyncManager' in window) {
  return navigator.serviceWorker.ready
    .then((registro) => {
      return registro.sync.register('sync-reportes');
    });
}
```

La etiqueta `sync-reportes` queda asociada con el registro del Service Worker. No depende de que el objeto `window` continúe existiendo.

### Paso 3: se cierra la pestaña

Al cerrar la página desaparecen:

- El DOM.
- `window`.
- Los manejadores de `app.js`.
- La posibilidad de ejecutar el fallback de la interfaz.

Permanecen:

- El registro del Service Worker.
- La tarea de Background Sync.
- IndexedDB y el reporte pendiente.
- Cache Storage y el App Shell.

### Paso 4: el navegador detecta conectividad

Cuando el navegador decide atender la tarea, inicia el Service Worker y dispara:

```javascript
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-reportes') {
    event.waitUntil(
      sincronizarPendientesSW()
    );
  }
});
```

La función que ejecuta el envío mientras la página está cerrada es:

```javascript
sincronizarPendientesSW()
```

Esta función:

1. Lee IndexedDB mediante `obtenerTodosLosRegistros()`.
2. Filtra `estado === 'pendiente'`.
3. Reenvía los reportes mediante `fetch()`.
4. Cambia su estado con `actualizarEstadoRegistro()`.
5. Espera el lote mediante `Promise.all()`.

### Paso 5: notificación sin pestañas abiertas

Después del lote se ejecuta `notificarClientesActualizacion()`. Si la pestaña está cerrada, `clients.matchAll()` puede devolver un arreglo vacío.

Esto no deshace la sincronización. Los estados ya fueron actualizados en IndexedDB. Simplemente no existe un DOM abierto que necesite repintarse en ese instante.

### Paso 6: se vuelve a abrir la PWA

Al abrir la aplicación, `app.js` ejecuta:

```javascript
renderizarColaOutbox();
```

La función vuelve a leer IndexedDB y presenta los estados actuales. Por eso los reportes aparecen como sincronizados aunque no haya existido una página para recibir `postMessage`.

### ¿Qué función debes señalar durante la defensa?

En `sw.js`:

```javascript
function sincronizarPendientesSW() {
  // motor de reenvío
}
```

Y después el evento que la mantiene viva:

```javascript
event.waitUntil(sincronizarPendientesSW());
```

### Respuesta de 60 segundos

> El `POST` fallido se guarda primero en IndexedDB como pendiente. Después `app.js` registra la etiqueta `sync-reportes` mediante `registration.sync.register()`. Aunque cierre la pestaña, IndexedDB, el Service Worker y la tarea permanecen. Al regresar internet, el navegador dispara el evento `sync`; `event.waitUntil()` ejecuta `sincronizarPendientesSW()`, que lee los pendientes, los reenvía con `Promise.all()` y actualiza su estado. Si no hay pestaña abierta no se entrega ningún mensaje, pero al volver a abrir `renderizarColaOutbox()` lee los estados actualizados.

---

## Pregunta 2: Prevención de Peticiones Duplicadas

### ¿Dónde está la condición importante?

En el evento `online` de `app.js`:

```javascript
if (!('SyncManager' in window)) {
  sincronizarPendientesFallback();
}
```

### ¿Qué ocurriría si se elimina?

En un navegador compatible, la recuperación de la red puede provocar dos mecanismos:

```text
Mecanismo A
evento online de window
  → sincronizarPendientesFallback()

Mecanismo B
evento sync del Service Worker
  → sincronizarPendientesSW()
```

Ambas funciones consultan la misma base y filtran los mismos registros pendientes.

Una posible secuencia es:

```text
1. app.js lee el registro con estado pendiente
2. sw.js lee el mismo registro todavía pendiente
3. app.js envía POST
4. sw.js envía otro POST con los mismos datos
5. ambos intentan actualizar el mismo objeto
```

El resultado es una petición duplicada al servidor. Aunque IndexedDB termine mostrando un solo objeto sincronizado, el servidor pudo recibir dos reportes y crear dos recursos.

### ¿Qué es una condición de carrera?

Es una situación donde el resultado depende del orden temporal de operaciones concurrentes. Aquí los dos contextos compiten por procesar el mismo registro antes de que alguno cambie su estado.

La condición:

```javascript
!('SyncManager' in window)
```

asigna un único responsable:

| Navegador | Responsable del reenvío |
|---|---|
| Con `SyncManager` | Service Worker mediante Background Sync |
| Sin `SyncManager` | Página mediante evento `online` |

### ¿Por qué no basta con que ambos actualicen el mismo ID?

El problema principal no es la actualización local. El `POST` ocurre antes del Update. Dos `POST` pueden producir dos efectos remotos aunque después ambos escriban `sincronizado` sobre la misma llave local.

### Respuesta de 60 segundos

> Si elimino el `if`, Chrome puede ejecutar al mismo tiempo el evento `online` de `app.js` y el evento `sync` de `sw.js`. Ambos leen el mismo pendiente antes de que cambie de estado y ambos envían el `POST`, creando un duplicado remoto. La condición asigna el trabajo al worker cuando existe `SyncManager` y deja el fallback de la interfaz únicamente para navegadores sin soporte.

---

## Pregunta 3: Aislamiento de Contextos y `postMessage`

### ¿Por qué `sw.js` no puede llamar a `renderizarColaOutbox()`?

`renderizarColaOutbox()` utiliza:

```javascript
document.getElementById('lista-outbox')
document.createElement('li')
```

El Service Worker ejecuta en `ServiceWorkerGlobalScope`, representado por `self`. No tiene:

- `window`.
- `document`.
- Los elementos HTML.
- El árbol del DOM.

Aunque una función con el mismo nombre se escribiera dentro de `sw.js`, no podría acceder al DOM de las pestañas.

### Primera mitad del puente: `sw.js`

El worker obtiene los clientes abiertos:

```javascript
self.clients.matchAll({
  type: 'window',
  includeUncontrolled: true
})
```

Después envía un mensaje a cada cliente:

```javascript
cliente.postMessage({
  tipo: 'OUTBOX_SINCRONIZADO',
  timestamp: Date.now()
});
```

El mensaje no manipula la interfaz. Solo transporta datos entre contextos.

### Segunda mitad del puente: `app.js`

La página escucha:

```javascript
navigator.serviceWorker.addEventListener('message', (event) => {
  if (event.data && event.data.tipo === 'OUTBOX_SINCRONIZADO') {
    renderizarColaOutbox();
  }
});
```

`app.js` sí tiene acceso al DOM, por lo que puede llamar a la función de renderizado.

### Flujo completo

```text
sw.js termina el lote
   ↓
clients.matchAll()
   ↓
cliente.postMessage(datos)
   ↓
evento message en app.js
   ↓
validar event.data.tipo
   ↓
renderizarColaOutbox()
   ↓
actualizar DOM
```

### ¿Por qué el mensaje no contiene todos los registros?

No es necesario duplicar la información. IndexedDB ya contiene los estados actualizados. El mensaje funciona como una señal: «la bandeja cambió; vuelve a leerla».

Esto mantiene una sola fuente de verdad y evita que la interfaz dependa de una copia parcial enviada por el worker.

### ¿Qué pasa si hay varias pestañas?

`clients.matchAll()` puede devolver varias ventanas. `forEach()` envía la señal a todas, por lo que cada interfaz abierta puede volver a consultar IndexedDB.

### Respuesta de 60 segundos

> El Service Worker no tiene `window` ni `document`; por eso no puede ejecutar una función que modifica el DOM. En `sw.js`, `clients.matchAll()` obtiene las pestañas y `cliente.postMessage()` envía `OUTBOX_SINCRONIZADO`. En `app.js`, el evento `message` valida ese tipo y llama a `renderizarColaOutbox()`. Ese es el puente entre el contexto del worker y el hilo de la interfaz.

---

## Pregunta 4: Efecto de `throw error` en Background Sync

### Código relevante

```javascript
event.waitUntil(
  sincronizarPendientesSW()
    .catch((error) => {
      console.error('[SW-Sync] Falla en sincronización; el navegador reintentará luego:', error);
      throw error;
    })
);
```

### ¿Qué hace primero el `.catch()`?

Recibe el rechazo producido por operaciones como:

- Leer IndexedDB.
- Ejecutar un `fetch()`.
- Recibir una respuesta HTTP no exitosa.
- Actualizar un registro.
- Completar `Promise.all()`.

El `console.error()` permite observar el problema, pero imprimirlo no cambia por sí mismo el estado de la promesa.

### ¿Qué hace `throw error`?

Relanzar el error provoca que la promesa devuelta por `.catch()` quede rechazada.

```text
sincronizarPendientesSW() se rechaza
   ↓
catch imprime el error
   ↓
throw error
   ↓
la cadena continúa rechazada
   ↓
event.waitUntil() observa que el trabajo falló
```

Background Sync puede considerar que la tarea no terminó y programar otro intento según las políticas del navegador.

### ¿Qué pasa si se elimina `throw error`?

Un callback de `.catch()` que termina sin lanzar ni retornar un rechazo convierte la cadena en una promesa resuelta con `undefined`.

```javascript
.catch((error) => {
  console.error(error);
  // no se relanza
})
```

Entonces `waitUntil()` recibe una promesa que termina correctamente. El navegador podría considerar atendido el evento aunque los objetos sigan pendientes.

### ¿Relanzar el error pierde los datos?

No. Los reportes continúan guardados en IndexedDB con estado `pendiente`. El error solo informa que el lote no concluyó correctamente.

Si algunos registros ya se sincronizaron antes del fallo, no se revierten automáticamente. En el siguiente intento, el filtro selecciona únicamente los que aún sean pendientes.

### Respuesta de 60 segundos

> `console.error()` solo imprime. `throw error` vuelve a rechazar la promesa entregada a `event.waitUntil()`. Así el navegador sabe que el evento Sync falló y puede reintentarlo. Si no relanzo el error, el `.catch()` transforma la cadena en una promesa resuelta y el navegador puede considerar completada una sincronización que realmente dejó registros pendientes.

---

## Preguntas Adicionales de Preparación

### ¿Por qué se registra la etiqueta después de guardar en IndexedDB?

La tarea debe encontrar el objeto cuando se ejecute. Si primero se registrara Background Sync y después se iniciara el guardado, existiría la posibilidad de que el worker leyera la base antes de completar la transacción.

La cadena actual asegura:

```text
guardarRegistro()
  → tx.oncomplete
  → navigator.serviceWorker.ready
  → sync.register()
```

### ¿Qué entrega `navigator.serviceWorker.ready`?

Una promesa que resuelve con el registro del Service Worker activo para la página. Desde ese objeto se accede a:

```javascript
registro.sync.register('sync-reportes')
```

### ¿Por qué se valida `event.tag`?

Un mismo Service Worker podría recibir distintas tareas de Background Sync. La etiqueta permite seleccionar el procedimiento correcto.

```javascript
if (event.tag === 'sync-reportes') {
  // sincronizar Outbox
}
```

### ¿Qué función cumple `event.waitUntil()`?

Extiende la vida del evento hasta que finaliza la promesa. Sin él, el navegador podría detener el worker antes de concluir los `POST`, las escrituras de IndexedDB y la notificación.

### ¿Por qué se usa `Promise.all()` dentro del worker?

Cada pendiente produce una promesa compuesta por un `POST` y un Update. `Promise.all()` crea una promesa que representa al lote completo y permite encadenar la notificación después de todos los resultados exitosos.

### ¿Qué ocurre si no hay pendientes?

`sincronizarPendientesSW()` escribe un mensaje en consola y retorna. La promesa anterior de `obtenerTodosLosRegistros().then(...)` se resuelve sin enviar solicitudes.

### ¿Qué ocurre si no hay pestañas abiertas?

`clients.matchAll()` entrega un arreglo vacío. No se envía ningún mensaje, pero los estados de IndexedDB permanecen sincronizados. La próxima apertura los recupera mediante `renderizarColaOutbox()`.

### ¿Por qué `db-helper.js` se importa de dos maneras?

- La página utiliza `<script src="./db-helper.js">` porque dispone del DOM y HTML.
- El Service Worker utiliza `importScripts('./db-helper.js')` porque no procesa etiquetas `<script>`.

Ambos cargan las mismas funciones y acceden a la misma IndexedDB del origen.

### ¿Qué significa degradación elegante?

La aplicación aprovecha Background Sync cuando existe, pero conserva un camino funcional cuando no existe.

```text
SyncManager disponible
└── evento sync del Service Worker

SyncManager no disponible
└── evento online de app.js
```

La ausencia de una API avanzada reduce una capacidad —sincronizar con la pestaña cerrada—, pero no elimina el funcionamiento básico del Outbox.

### ¿Por qué se incrementó la versión de la caché?

El nombre `static-outbox-v2` identifica el App Shell de esta evolución. El evento `activate` elimina cachés anteriores y permite que los nuevos `app.js` y `sw.js` sustituyan a la versión previa.

### ¿Background Sync garantiza un momento exacto de ejecución?

No. La aplicación registra una tarea, pero el navegador decide cuándo existe una oportunidad adecuada para ejecutarla. Por eso el código debe conservar los datos en IndexedDB y no depender de una hora exacta.

---

## Comparación Rápida entre los Dos Motores

| Pregunta | Background Sync | Fallback `online` |
|---|---|---|
| ¿Dónde ejecuta? | `sw.js` | `app.js` |
| ¿Qué lo dispara? | Evento `sync` | Evento `online` |
| ¿Puede trabajar sin pestaña? | Sí, según el navegador | No |
| ¿Qué función llama? | `sincronizarPendientesSW()` | `sincronizarPendientesFallback()` |
| ¿Cómo actualiza el DOM? | `postMessage` a una página abierta | Llama directamente a `renderizarColaOutbox()` |
| ¿Cuándo se usa? | Cuando existe `SyncManager` | Cuando no existe `SyncManager` |

## Mapa para Señalar el Código

```text
app.js
├── addEventListener('message')
│   └── recibe OUTBOX_SINCRONIZADO
├── procesarEnvioReporte()
│   └── registration.sync.register('sync-reportes')
├── sincronizarPendientesFallback()
│   └── motor alternativo desde la UI
└── addEventListener('online')
    └── if (!('SyncManager' in window))

sw.js
├── importScripts('./db-helper.js')
├── notificarClientesActualizacion()
│   └── cliente.postMessage(...)
├── sincronizarPendientesSW()
│   └── Promise.all(promesasDeEnvio)
└── addEventListener('sync')
    ├── event.tag === 'sync-reportes'
    ├── event.waitUntil(...)
    └── throw error
```

## Lista de Comprobación Oral

- [ ] Puedo explicar por qué IndexedDB sobrevive al cierre de la pestaña.
- [ ] Puedo señalar `sincronizarPendientesSW()` como motor en segundo plano.
- [ ] Puedo explicar qué conserva el navegador al cerrar la página.
- [ ] Puedo describir el duplicado que ocurriría sin la condición de `SyncManager`.
- [ ] Puedo distinguir el contexto de `app.js` del contexto de `sw.js`.
- [ ] Puedo señalar las dos mitades del puente `postMessage`.
- [ ] Puedo explicar por qué el mensaje vuelve a leer IndexedDB.
- [ ] Puedo explicar el efecto de `throw error` sobre `waitUntil()`.
- [ ] Puedo describir la degradación elegante en navegadores sin Background Sync.
- [ ] Puedo explicar por qué las rutas continúan siendo relativas en GitHub Pages.
