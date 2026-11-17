# Tema 5.1 - Persistencia Estructurada con IndexedDB y Promisificación en Vanilla JS

**Asignatura: Desarrollo de Aplicaciones Web Progresivas (PWA)**

> **Regla Técnica del Curso: Todo código asíncrono debe construirse y consumirse mediante Promesas explícitas (new Promise, .then(), .catch()). Queda prohibido el uso de async/await y de librerías externas (PouchDB, Dexie, etc.).**

## 1. ¿Por qué necesitamos IndexedDB si ya tenemos Cache API y localStorage?

En la semanas pasadas resolvimos el almacenamiento de archivos estáticos y respuestas GET mediante la Cache API. Sin embargo, una PWA real necesita guardar datos estructurados generados por el usuario cuando no hay red (formularios, pedidos, lecturas de sensores o transacciones POST pendientes por enviar).

| Característica | localStorage | Cache API | IndexedDB |
|---|---|---|---|
| Tipo de datos | Solo cadenas de texto (String). | Pares Request / Response (HTTP GET). | Objetos JS complejos, JSON, arreglos, Blob, File. |
| Modelo de ejecución | Síncrono (bloquea el hilo principal). | Asíncrono (basado en Promesas). | Asíncrono (basado en Eventos del DOM). |
| Acceso desde sw.js | No disponible (arroja ReferenceError). | Disponible (caches). | Disponible (indexedDB). |
| Capacidad típica | ~5 MB fijos. | Compartida (hasta 10%–20% del disco libre). | Compartida (hasta 10%–20% del disco libre). |

> **Regla de Arquitectura: localStorage nunca se usa en una PWA seria porque es síncrono y el Service Worker no puede leerlo. IndexedDB es la única base de datos transaccional compartida entre la interfaz (app.js) y el Service Worker (sw.js).**

## 2. Anatomía y Jerarquía de IndexedDB

A diferencia de SQL (tablas y filas), IndexedDB es una base de datos orientada a objetos con esta jerarquía interna:

```
[ Base de Datos: "pwa-datos-v1" ]  (Versionada con enteros: 1, 2, 3...)
       │
       ├── [ Object Store: "pendientes" ]  (Equivalente a una tabla)
       │        ├── keyPath: "id" (Llave primaria única o autoIncrement)
       │        ├── Índice: "por_fecha"
       │        └── Registros: { id: 1, endpoint: "/api/ventas", payload: {...}}
       │
       └── [ Object Store: "catalogo" ]
                └── Registros: { sku: "A100", nombre: "Sensor", precio: 450 }
```

### Conceptos Clave que Debes Dominar

- Base de Datos (IDBDatabase): Se identifica por un nombre y un número de versión entero (1, 2, 3...).
- Almacén de Objetos (Object Store): Es el contenedor donde se guardan los registros. Cada registro debe tener una llave única (keyPath o autoIncrement: true).
- Transacción (IDBTransaction): Ninguna lectura o escritura ocurre de forma aislada. Toda operación exige abrir una transacción indicando qué Object Store se va a tocar y en qué modo:
- 'readonly': Para consultar datos (permite múltiples lecturas simultáneas).
- 'readwrite': Para insertar, actualizar o borrar datos (bloquea el almacén mientras escribe para evitar corrupción).

## 3. El Ciclo de Vida y el Evento onupgradeneeded

IndexedDB maneja un ciclo de vida de esquemas idéntico al versionamiento que aplicaste en el Service Worker:

```
indexedDB.open('mi-db', 1)
       │
       ├── ¿La BD no existe o el número de versión es mayor al actual?
       │         │
       │         ├── SÍ ──> Dispara 'onupgradeneeded' (ÚNICO lugar para crear/borrar Stores)
       │         │               │
       │         │               v
       │         └──────> Dispara 'onsuccess' (BD lista para abrir transacciones)
       │
       └── Si ocurre un fallo de permisos o versión menor ──> Dispara 'onerror'
```

> **Advertencia Crítica: Si intentas ejecutar db.createObjectStore(...) fuera del evento onupgradeneeded, el navegador lanzará una excepción InvalidStateError. Si necesitas agregar una nueva tabla en el futuro, debes subir la versión de 1 a 2.**

## 4. El Problema de la API Nativa y Por Qué Construiremos un Mini-Wrapper

La API nativa de IndexedDB fue diseñada antes de que existieran las Promesas en JavaScript. Por ello, cada operación devuelve un objeto IDBRequest al que debes asignarle callbacks manuales:

```
// ❌ ESTILO NATIVO PURO (Difícil de encadenar con fetch y Cache API)
const peticion = indexedDB.open('mi-db', 1);
peticion.onerror = function(evento){
  console.error('Error al abrir BD');
};
peticion.onsuccess = function(evento){
  const db = evento.target.result;
  const tx = db.transaction(['pendientes'], 'readwrite');
  const store = tx.objectStore('pendientes');
  const reqGuardar = store.add({ titulo: 'Pedido 1' });
  reqGuardar.onsuccess = function(){
    console.log('Guardado, pero en 4 niveles de anidación (Callback Hell)');
  };
};
```

Si mezclamos este estilo de eventos con las cadenas .then() y .catch() de fetch() en el Service Worker, el código se vuelve inmanejable. La solución de ingeniería es construir un Mini-Wrapper de ~45 líneas en Vanilla JS que traduzca esos eventos a new Promise((resolve, reject) => ...).

## 5. Anatomía del Mini-Wrapper Promisificado (db-helper.js)

Estudia detenidamente cómo funciona cada una de las 4 piezas de nuestro mini-wrapper. Este único archivo podrá cargarse tanto en index.html (`<script src="db-helper.js">`) como dentro de sw.js mediante `importScripts('./db-helper.js')`.

### Pieza 1: Apertura y Migración de Esquema (abrirDB)

Envuelve indexedDB.open() en una promesa. Si es la primera vez que el usuario entra, onupgradeneeded crea el Object Store.

```
const DB_NAME = 'pwa-outbox-db';
const DB_VERSION = 1;
const STORE_NAME = 'transacciones_pendientes';
function abrirDB(){
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    // Se ejecuta solo si la BD es nueva o sube de versión
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        // keyPath 'id' con autoIncrement genera IDs numéricos automáticos (1, 2, 3...)
        db.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
      }
    };
    request.onsuccess = (event) => resolve(event.target.result);
    request.onerror = (event) => reject(event.target.error);
  });
}
```

### Pieza 2: Escritura Segura (guardarRegistro)

Observa un detalle fundamental: en IndexedDB, store.add() te devuelve el ID generado (req.onsuccess), pero el dato no está garantizado en disco hasta que dispara tx.oncomplete.

```
function guardarRegistro(datos){
  return abrirDB().then((db) => {
    return new Promise((resolve, reject) => {
      const tx = db.transaction([STORE_NAME], 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const req = store.add(datos);
      let idGenerado;
      req.onsuccess = (event) => {
        idGenerado = event.target.result;
      };
      // Resolvemos la promesa cuando la transacción completa su escritura en disco
      tx.oncomplete = () => resolve(idGenerado);
      tx.onerror = (event) => reject(event.target.error);
    });
  });
}
```

### Pieza 3: Lectura Completa (obtenerTodosLosRegistros)

Abre una transacción en modo 'readonly' y utiliza store.getAll() para recuperar un arreglo limpio con todos los objetos guardados.

```
function obtenerTodosLosRegistros(){
  return abrirDB().then((db) => {
    return new Promise((resolve, reject) => {
      const tx = db.transaction([STORE_NAME], 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const req = store.getAll();
      req.onsuccess = (event) => resolve(event.target.result);
      req.onerror = (event) => reject(event.target.error);
    });
  });
}
```

### Pieza 4: Eliminación por Llave Primaria (eliminarRegistro)

Indispensable para limpiar la cola de pendientes una vez que el servidor confirme que recibió los datos tras recuperar internet.

```
function eliminarRegistro(id){
  return abrirDB().then((db) => {
    return new Promise((resolve, reject) => {
      const tx = db.transaction([STORE_NAME], 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      store.delete(id);
      tx.oncomplete = () => resolve(true);
      tx.onerror = (event) => reject(event.target.error);
    });
  });
}
```

## 6. Consumo Limpio desde la Aplicación (app.js)

Gracias al mini-wrapper, interactuar con IndexedDB ahora respeta exactamente la misma sintaxis de promesas que usas con fetch() y caches:

```
// Ejemplo de guardado y lectura encadenada con .then() y .catch()
const nuevaOrden = {
  cliente: 'Empresa Logística SA',
  monto: 14500,
  fecha: Date.now()
};
guardarRegistro(nuevaOrden)
  .then((idAsignado) => {
    console.log('Registro encolado localmente con ID:', idAsignado);
    return obtenerTodosLosRegistros();
  })
  .then((listaCompleta) => {
    console.table(listaCompleta);
  })
  .catch((error) => {
    console.error('Falla en operación de IndexedDB:', error);
  });
```

## 7. Guía de Inspección en Chrome DevTools

Cuando pruebes este código en tu navegador, verifica el estado real de la base de datos sin depender de console.log:

- Abre DevTools (F12) → pestaña Application.
- En el menú lateral izquierdo, expande la sección IndexedDB.
- Haz clic en pwa-outbox-db → transacciones_pendientes.
- En el panel derecho verás una tabla limpia con las columnas Key y Value mostrando tus objetos JSON exactos.

> **Nota importante: Si modificas el código y cambias DB_VERSION o estructuras de prueba, usa el botón Refresh database en DevTools para visualizar los cambios en vivo.**

## 8. Cuestionario de Preparación Autónoma (Base para Defensa Oral)

Analiza el código del mini-wrapper y responde en tus apuntes antes de la siguiente sesión de laboratorio:

- Diferencia entre req.onsuccess y tx.oncomplete: En la función guardarRegistro, ¿por qué esperamos a tx.oncomplete para ejecutar resolve(idGenerado) en lugar de resolver la promesa directamente dentro de req.onsuccess?
- Error de Esquema: Si ya ejecutaste la aplicación con DB_VERSION = 1 y luego editas abrirDB() para agregar un segundo Object Store llamado 'logs_errores' sin cambiar el número 1 de DB_VERSION, ¿qué ocurrirá al recargar la página y por qué?
- Flujo de Promesas Anidadas: En guardarRegistro, explica qué ocurre si eliminamos la palabra return antes de new Promise((resolve, reject) => ...) dentro del .then((db) => ...).
- Importación de Código: ¿Qué instrucción nativa de JavaScript permite cargar db-helper.js dentro del archivo sw.js dado que los Service Workers clásicos no tienen acceso a etiquetas <script> del DOM?

