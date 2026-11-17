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